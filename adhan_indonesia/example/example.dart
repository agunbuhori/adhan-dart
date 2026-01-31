import 'package:adhan_indonesia/adhan_indonesia.dart';

void main() {
  print('=== Adhan Indonesia Example ===\n');

  // Example 1: Using pre-defined city (Bandung)
  print('1. Prayer Times for Bandung');
  print('----------------------------');
  final bandungTimes = PrayerTimesIndonesia.today(IndonesianCities.bandung);

  print('Location: Bandung (${bandungTimes.coordinates.altitude}m altitude)');
  print(
    'Altitude correction: +${bandungTimes.altitudeCorrectionMinutes} minutes',
  );
  print(
    'Night duration: ${bandungTimes.nightDuration.inHours}h ${bandungTimes.nightDuration.inMinutes % 60}m',
  );
  print('');
  print('Imsak:      ${_formatTime(bandungTimes.imsak)}');
  print('Fajr:       ${_formatTime(bandungTimes.fajr)}');
  print('Sunrise:    ${_formatTime(bandungTimes.sunrise)}');
  print('Dhuha:      ${_formatTime(bandungTimes.dhuha)}');
  print('Dhuhr:      ${_formatTime(bandungTimes.dhuhr)}');
  print('Asr:        ${_formatTime(bandungTimes.asr)}');
  print('Maghrib:    ${_formatTime(bandungTimes.maghrib)}');
  print('Isha:       ${_formatTime(bandungTimes.isha)}');
  print('Half Night: ${_formatTime(bandungTimes.halfNight)}');
  print('Last Third: ${_formatTime(bandungTimes.lastThird)}');
  print('');

  // Example 2: Compare highland city with coastal city
  print('2. Comparison: Puncak (1326m) vs Jakarta (8m)');
  print('----------------------------------------------');

  final puncakTimes = PrayerTimesIndonesia.today(IndonesianCities.puncak);
  final jakartaTimes = PrayerTimesIndonesia.today(IndonesianCities.jakarta);

  print(
    'Puncak altitude correction:  +${puncakTimes.altitudeCorrectionMinutes} minutes',
  );
  print(
    'Jakarta altitude correction: +${jakartaTimes.altitudeCorrectionMinutes} minutes',
  );
  print('');
  print('              Puncak      Jakarta     Difference');
  print(
    'Sunrise:      ${_formatTime(puncakTimes.sunrise)}   ${_formatTime(jakartaTimes.sunrise)}   ${_diffMinutes(puncakTimes.sunrise, jakartaTimes.sunrise)}',
  );
  print(
    'Maghrib:      ${_formatTime(puncakTimes.maghrib)}   ${_formatTime(jakartaTimes.maghrib)}   ${_diffMinutes(puncakTimes.maghrib, jakartaTimes.maghrib)}',
  );
  print('');

  // Example 3: Using custom coordinates with altitude
  print('3. Custom Location with Altitude');
  print('---------------------------------');

  final customCoords = CoordinatesWithAltitude(
    -7.2000, // latitude (Dieng area)
    109.9167, // longitude
    altitude: 2093, // Dieng Plateau - highest inhabited area in Java
  );

  final diengTimes = PrayerTimesIndonesia.today(customCoords);

  print('Location: Dieng Plateau (${customCoords.altitude}m altitude)');
  print(
    'Altitude correction: +${diengTimes.altitudeCorrectionMinutes} minutes',
  );
  print('Maghrib: ${_formatTime(diengTimes.maghrib)}');
  print('');

  // Example 4: Without altitude correction (for comparison)
  print('4. With vs Without Altitude Correction (Lembang 1312m)');
  print('-------------------------------------------------------');

  final withCorrection = PrayerTimesIndonesia.today(
    IndonesianCities.lembang,
    useAltitudeCorrection: true,
  );

  final withoutCorrection = PrayerTimesIndonesia.today(
    IndonesianCities.lembang,
    useAltitudeCorrection: false,
  );

  print(
    'With altitude correction (+${withCorrection.altitudeCorrectionMinutes} min):',
  );
  print('  Sunrise: ${_formatTime(withCorrection.sunrise)}');
  print('  Maghrib: ${_formatTime(withCorrection.maghrib)}');
  print('');
  print('Without altitude correction:');
  print('  Sunrise: ${_formatTime(withoutCorrection.sunrise)}');
  print('  Maghrib: ${_formatTime(withoutCorrection.maghrib)}');
  print('');

  // Example 5: List all highland cities
  print('5. Highland Cities in Indonesia (altitude > 500m)');
  print('--------------------------------------------------');

  IndonesianCities.highlandCities.forEach((name, coords) {
    final correction = coords.kemenagAltitudeCorrection;
    print('$name: ${coords.altitude}m -> +$correction min correction');
  });
}

String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _diffMinutes(DateTime a, DateTime b) {
  final diff = a.difference(b).inMinutes;
  if (diff == 0) return '  0 min';
  return diff > 0 ? '+${diff} min' : '$diff min';
}
