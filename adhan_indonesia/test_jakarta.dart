import 'lib/src/kemenag_prayer_times.dart';

void main() {
  // Test Jakarta with user-provided coordinates
  final pt = KemenagPrayerTimes(
    latitude: -6.2297401,
    longitude: 106.7471177,
    date: DateTime(2026, 2, 1),
    elevation: 10, // Jakarta near sea level
    timezone: 7.0,
  );

  print('');
  print('╔════════════════════════════════════════════════════════╗');
  print('║        JAKARTA COMPARISON (01/02/2026)                 ║');
  print('╠════════════════════════════════════════════════════════╣');
  print('║ Coordinates: -6.2297401, 106.7471177                   ║');
  print('║ Elevation: 10m                                         ║');
  print('╠════════════════════════════════════════════════════════╣');
  print('║ Prayer      | Kemenag  | Ours     | Diff              ║');
  print('╠════════════════════════════════════════════════════════╣');

  final kemenag = {
    'Imsak': '04:26',
    'Subuh': '04:36',
    'Terbit': '05:52',
    'Dhuha': '06:20',
    'Zuhur': '12:10',
    'Asar': '15:29',
    'Magrib': '18:21',
    'Isya': '19:33',
  };

  final ours = {
    'Imsak': pt.imsak,
    'Subuh': pt.fajr,
    'Terbit': pt.sunrise,
    'Dhuha': pt.dhuha,
    'Zuhur': pt.dhuhr,
    'Asar': pt.asr,
    'Magrib': pt.maghrib,
    'Isya': pt.isha,
  };

  int totalDiff = 0;
  for (final prayer in kemenag.keys) {
    final k = kemenag[prayer]!;
    final o = ours[prayer]!;

    // Calculate difference
    final kParts = k.split(':');
    final oParts = o.split(':');
    final kMin = int.parse(kParts[0]) * 60 + int.parse(kParts[1]);
    final oMin = int.parse(oParts[0]) * 60 + int.parse(oParts[1]);
    final diff = oMin - kMin;
    totalDiff += diff.abs();

    final diffStr = diff == 0
        ? '  0 min ✓'
        : diff > 0
            ? ' +$diff min'
            : ' $diff min';
    final status = diff.abs() <= 1 ? '✓' : (diff.abs() <= 2 ? '~' : '✗');

    print('║ ${prayer.padRight(11)} | $k    | $o    | $diffStr $status     ║');
  }

  print('╠════════════════════════════════════════════════════════╣');
  print(
      '║ Average difference: ${(totalDiff / 8).toStringAsFixed(1)} minutes                      ║');
  print('╚════════════════════════════════════════════════════════╝');

  print('');
  print('SOLAR DATA:');
  print('  Equation of Time: ${pt.equationOfTime.toStringAsFixed(3)} minutes');
  print('  Solar Declination: ${pt.solarDeclination.toStringAsFixed(4)}°');
}
