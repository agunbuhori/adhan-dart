# Adhan Indonesia

Indonesian prayer times calculation with altitude support, based on **Kemenag (Ministry of Religious Affairs)** standards.

This package extends the [adhan](https://pub.dev/packages/adhan) package with:
- ✅ **Altitude/Elevation correction** for sunrise and maghrib times
- ✅ **Kemenag calculation method** (Fajr: -20°, Isha: -18°, Ihtiyati: +2 min)
- ✅ **Pre-defined Indonesian cities** with accurate altitude data
- ✅ **Imsak time** (10 minutes before Fajr)
- ✅ **Dhuha time** (15 minutes after sunrise)
- ✅ **Half Night time** (middle of the night for Qiyamul Lail)
- ✅ **Last Third time** (beginning of last third for Tahajjud)

## Why Altitude Matters

For cities at high altitude like Bandung (768m), the horizon is lower:
- **Sunrise appears earlier** (you can see the sun sooner)
- **Sunset appears later** (you can see the sun longer)

This affects the timing of **Fajr**, **Sunrise**, **Maghrib**, and **Isha** prayers.

### Kemenag Altitude Correction Table

| Altitude (meters) | Correction |
|-------------------|------------|
| 0 - 250m | 0 minutes |
| 250 - 700m | +1 minute |
| 700 - 1000m | +2 minutes |
| 1000 - 1300m | +3 minutes |
| 1300 - 1700m | +4 minutes |
| 1700 - 2000m | +5 minutes |
| 2000 - 2500m | +6 minutes |

## Usage

### Basic Usage with Pre-defined Cities

```dart
import 'package:adhan_indonesia/adhan_indonesia.dart';
import 'package:intl/intl.dart';

void main() {
  // Use pre-defined city
  final prayerTimes = PrayerTimesIndonesia.today(
    IndonesianCities.bandung, // 768m altitude, +2 min correction
  );

  print('Prayer Times for Bandung (${prayerTimes.coordinates.altitude}m)');
  print('Altitude correction: ${prayerTimes.altitudeCorrectionMinutes} minutes');
  print('---');
  print('Imsak:   ${DateFormat.jm().format(prayerTimes.imsak)}');
  print('Fajr:    ${DateFormat.jm().format(prayerTimes.fajr)}');
  print('Sunrise: ${DateFormat.jm().format(prayerTimes.sunrise)}');
  print('Dhuha:   ${DateFormat.jm().format(prayerTimes.dhuha)}');
  print('Dhuhr:   ${DateFormat.jm().format(prayerTimes.dhuhr)}');
  print('Asr:     ${DateFormat.jm().format(prayerTimes.asr)}');
  print('Maghrib: ${DateFormat.jm().format(prayerTimes.maghrib)}');
  print('Isha:    ${DateFormat.jm().format(prayerTimes.isha)}');
}
```

### Custom Coordinates with Altitude

```dart
import 'package:adhan_indonesia/adhan_indonesia.dart';

void main() {
  // Custom location with altitude
  final coordinates = CoordinatesWithAltitude(
    -6.9175,  // latitude
    107.6191, // longitude
    altitude: 768, // meters above sea level
  );

  final prayerTimes = PrayerTimesIndonesia.today(coordinates);
  
  print('Maghrib: ${prayerTimes.maghrib}');
  // Maghrib will be 2 minutes later than sea-level calculation
}
```

### Using Different Calculation Parameters

```dart
import 'package:adhan_indonesia/adhan_indonesia.dart';

void main() {
  // Without Ihtiyati (raw calculation)
  final params = KemenagCalculationMethod.getParametersWithoutIhtiyati();
  
  final prayerTimes = PrayerTimesIndonesia.today(
    IndonesianCities.bandung,
    calculationParameters: params,
  );
}
```

### Compare with/without Altitude Correction

```dart
import 'package:adhan_indonesia/adhan_indonesia.dart';

void main() {
  final coords = IndonesianCities.puncak; // 1326m altitude
  
  // With altitude correction (+3 minutes)
  final withCorrection = PrayerTimesIndonesia.today(
    coords,
    useAltitudeCorrection: true,
  );
  
  // Without altitude correction
  final withoutCorrection = PrayerTimesIndonesia.today(
    coords,
    useAltitudeCorrection: false,
  );
  
  print('Puncak (${coords.altitude}m)');
  print('Maghrib with correction:    ${withCorrection.maghrib}');
  print('Maghrib without correction: ${withoutCorrection.maghrib}');
  // Difference: 3 minutes
}
```

### Available Indonesian Cities

```dart
// Highland cities (altitude > 500m)
IndonesianCities.bandung      // 768m
IndonesianCities.lembang      // 1312m
IndonesianCities.puncak       // 1326m
IndonesianCities.dieng        // 2093m
IndonesianCities.garut        // 717m
IndonesianCities.batu         // 871m
IndonesianCities.bukittinggi  // 930m

// Major cities
IndonesianCities.jakarta      // 8m
IndonesianCities.surabaya     // 3m
IndonesianCities.semarang     // 2m
IndonesianCities.yogyakarta   // 114m
IndonesianCities.medan        // 26m
IndonesianCities.makassar     // 5m

// Get all cities
final allCities = IndonesianCities.all;

// Get highland cities only
final highlands = IndonesianCities.highlandCities;
```

## Kemenag Calculation Method

This package implements the official Kemenag criteria:

| Prayer | Criteria |
|--------|----------|
| **Fajr (Subuh)** | Sun at -20° below horizon + 2 min ihtiyati |
| **Sunrise (Terbit)** | Sunrise - 2 min ihtiyati |
| **Dhuha** | Sunrise + 15 minutes |
| **Dhuhr (Dzuhur)** | Sun at zenith (transit) + 2 min ihtiyati |
| **Asr** | Shadow = object + noon shadow + 2 min ihtiyati |
| **Maghrib** | Sunset + altitude correction + 2 min ihtiyati |
| **Isha** | Sun at -18° below horizon + 2 min ihtiyati |
| **Imsak** | Fajr - 10 minutes |

## Formula

### Horizon Dip (Kerendahan Ufuk)

```
D' = 1.76 × √(altitude_meters) / 60  (in degrees)
```

This value is:
- **Subtracted** from sunrise time (earlier sunrise)
- **Added** to maghrib time (later sunset)

## License

MIT License - See LICENSE file for details.

## Credits

- Based on [adhan-dart](https://github.com/iamriajul/adhan-dart) by @iamriajul
- Kemenag formula reference from Bimas Islam Kementerian Agama RI
