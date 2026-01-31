import 'package:adhan_indonesia/adhan_indonesia.dart';

/// Test comparing our calculation with Kemenag official times for Bandung
/// Date: Sunday, 01/02/2026
///
/// Kemenag Official Times:
/// IMSAK  : 04:22
/// SUBUH  : 04:32
/// TERBIT : 05:43
/// DUHA   : 06:16
/// ZUHUR  : 12:07
/// ASAR   : 15:25
/// MAGRIB : 18:23
/// ISYA'  : 19:31
void main() {
  print('=== Kemenag vs Adhan Indonesia Comparison ===');
  print('Location: Bandung');
  print('Date: Sunday, 01/02/2026');
  print('Coordinates: -6.9179131, 107.6072436');
  print('Altitude: 708m');
  print('');

  // Use exact coordinates from user
  final bandung = CoordinatesWithAltitude(
    -6.9179131,
    107.6072436,
    altitude: 708,
  );

  final date = DateComponents(2026, 2, 1);

  // Test with formula-based correction (default)
  print('=== Method 1: Formula-based correction ===');
  final formulaTimes = PrayerTimesIndonesia(
    bandung,
    date,
    useFormulaCorrection: true,
  );
  _printComparison(formulaTimes);

  print('');
  print('=== Method 2: Table-based correction (Kemenag table) ===');
  final tableTimes = PrayerTimesIndonesia(
    bandung,
    date,
    useFormulaCorrection: false,
  );
  _printComparison(tableTimes);

  print('');
  print('=== Analysis ===');
  print('');
  print('The remaining differences (1-3 minutes) are due to:');
  print('1. Different base astronomical calculations in adhan package');
  print('2. Kemenag may use location-specific corrections');
  print('3. Slight differences in equation-of-time formulas');
  print('');
  print('For most practical purposes, a ±2 minute variance is acceptable.');
  print('');

  // Additional information
  print('=== Altitude Correction Details ===');
  print('Horizon dip:     ${bandung.horizonDipDegrees.toStringAsFixed(3)}°');
  print('Formula-based:   +${bandung.formulaAltitudeCorrection} minutes');
  print('Table-based:     +${bandung.kemenagAltitudeCorrection} minutes');
}

void _printComparison(PrayerTimesIndonesia prayerTimes) {
  print(
      'Altitude correction: +${prayerTimes.altitudeCorrectionMinutes} minutes');
  print('');

  // Official Kemenag times
  final kemenag = {
    'Imsak': '04:22',
    'Subuh': '04:32',
    'Terbit': '05:43',
    'Duha': '06:16',
    'Zuhur': '12:07',
    'Asar': '15:25',
    'Magrib': '18:23',
    'Isya': '19:31',
  };

  // Our calculated times
  final calculated = {
    'Imsak': _formatTime(prayerTimes.imsak),
    'Subuh': _formatTime(prayerTimes.fajr),
    'Terbit': _formatTime(prayerTimes.sunrise),
    'Duha': _formatTime(prayerTimes.dhuha),
    'Zuhur': _formatTime(prayerTimes.dhuhr),
    'Asar': _formatTime(prayerTimes.asr),
    'Magrib': _formatTime(prayerTimes.maghrib),
    'Isya': _formatTime(prayerTimes.isha),
  };

  print('Prayer      Kemenag    Ours       Diff');
  print('---------------------------------------');

  int totalDiff = 0;
  for (final prayer in kemenag.keys) {
    final official = kemenag[prayer]!;
    final ours = calculated[prayer]!;
    final diff = _timeDiff(official, ours);
    totalDiff += diff.abs();
    final status = diff.abs() <= 1 ? '✓' : (diff.abs() <= 2 ? '~' : '✗');

    print(
      '${prayer.padRight(10)} ${official.padRight(10)} ${ours.padRight(10)} ${_formatDiff(diff)} $status',
    );
  }

  print('');
  print(
      'Average difference: ${(totalDiff / kemenag.length).toStringAsFixed(1)} minutes');
}

String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

int _timeDiff(String time1, String time2) {
  final parts1 = time1.split(':');
  final parts2 = time2.split(':');

  final minutes1 = int.parse(parts1[0]) * 60 + int.parse(parts1[1]);
  final minutes2 = int.parse(parts2[0]) * 60 + int.parse(parts2[1]);

  return minutes2 - minutes1;
}

String _formatDiff(int diff) {
  if (diff == 0) return '  0 min';
  return diff > 0 ? '+$diff min' : '$diff min';
}
