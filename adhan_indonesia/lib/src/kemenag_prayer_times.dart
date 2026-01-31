import 'dart:math';

/// Pure Dart implementation of Kemenag RI Prayer Time Calculator.
///
/// This class implements the official calculation method used by the
/// Ministry of Religious Affairs of Indonesia (Kemenag RI) following
/// MABIMS standards.
///
/// Uses NOAA/Jean Meeus algorithms for accurate solar position calculation.
class KemenagPrayerTimes {
  // ============================================================
  // CONSTANTS - Kemenag/MABIMS Standard
  // ============================================================

  /// Fajr (Subuh) angle: Sun is 20° below eastern horizon
  static const double fajrAngle = -20.0;

  /// Isha (Isya) angle: Sun is 18° below western horizon
  static const double ishaAngle = -18.0;

  /// Maghrib altitude: geometric sunset with refraction correction
  /// Standard: -0.8333° (accounts for refraction + sun semi-diameter)
  static const double maghribAltitude = -0.8333;

  /// Sunrise altitude (same as sunset)
  static const double sunriseAltitude = -0.8333;

  /// Dhuha angle: Sun is 4.5° above the horizon (Kemenag standard)
  static const double dhuhaAngle = 4.5;

  /// Ikhtiyat (safety margin) in minutes
  static const int ikhtiyatMinutes = 2;

  // ============================================================
  // INSTANCE VARIABLES
  // ============================================================

  final double latitude;
  final double longitude;
  final double timezone;
  final DateTime date;
  final double elevation;

  // Calculated values
  late double _julianDay;
  late double _julianCentury;
  late double _solarDeclination;
  late double _equationOfTime;
  late double _solarNoon;

  // Prayer times in decimal hours
  late double _fajrTime;
  late double _sunriseTime;
  late double _dhuhrTime;
  late double _dhuhaTime;
  late double _asrTime;
  late double _maghribTime;
  late double _ishaTime;

  /// Creates a new KemenagPrayerTimes instance.
  ///
  /// [latitude] Location latitude in degrees (negative for South)
  /// [longitude] Location longitude in degrees (negative for West)
  /// [timezone] Timezone offset from UTC (e.g., 7.0 for WIB)
  /// [date] The date for calculation
  /// [elevation] Elevation above sea level in meters (default: 0)
  KemenagPrayerTimes({
    required this.latitude,
    required this.longitude,
    this.timezone = 7.0,
    required this.date,
    this.elevation = 0.0,
  }) {
    _calculate();
  }

  // ============================================================
  // MATHEMATICAL HELPER FUNCTIONS
  // ============================================================

  /// Convert degrees to radians
  double _toRadians(double degrees) => degrees * pi / 180.0;

  /// Convert radians to degrees
  double _toDegrees(double radians) => radians * 180.0 / pi;

  /// Normalize angle to 0-360 range
  double _normalize360(double angle) {
    double result = angle % 360.0;
    return result < 0 ? result + 360.0 : result;
  }

  /// Calculate Julian Day from date
  double _calculateJulianDay(DateTime date) {
    int year = date.year;
    int month = date.month;
    int day = date.day;

    // Adjust for January and February
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final double a = (year / 100).floor().toDouble();
    final double b = 2 - a + (a / 4).floor();

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  /// Calculate Julian Century from Julian Day
  double _calculateJulianCentury(double julianDay) {
    return (julianDay - 2451545.0) / 36525.0;
  }

  // ============================================================
  // SOLAR POSITION CALCULATIONS (NOAA Algorithm)
  // ============================================================

  /// Calculate the geometric mean longitude of the Sun (degrees)
  double _geometricMeanLongitudeSun(double julianCentury) {
    double L0 =
        280.46646 + julianCentury * (36000.76983 + 0.0003032 * julianCentury);
    return _normalize360(L0);
  }

  /// Calculate the geometric mean anomaly of the Sun (degrees)
  double _geometricMeanAnomalySun(double julianCentury) {
    return 357.52911 +
        julianCentury * (35999.05029 - 0.0001537 * julianCentury);
  }

  /// Calculate the eccentricity of Earth's orbit
  double _eccentricityEarthOrbit(double julianCentury) {
    return 0.016708634 -
        julianCentury * (0.000042037 + 0.0000001267 * julianCentury);
  }

  /// Calculate the equation of center for the Sun (degrees)
  double _sunEquationOfCenter(double julianCentury) {
    final double M = _geometricMeanAnomalySun(julianCentury);
    final double mRad = _toRadians(M);

    final double sinM = sin(mRad);
    final double sin2M = sin(2 * mRad);
    final double sin3M = sin(3 * mRad);

    return sinM *
            (1.914602 - julianCentury * (0.004817 + 0.000014 * julianCentury)) +
        sin2M * (0.019993 - 0.000101 * julianCentury) +
        sin3M * 0.000289;
  }

  /// Calculate the true longitude of the Sun (degrees)
  double _sunTrueLongitude(double julianCentury) {
    return _geometricMeanLongitudeSun(julianCentury) +
        _sunEquationOfCenter(julianCentury);
  }

  /// Calculate the apparent longitude of the Sun (degrees)
  double _sunApparentLongitude(double julianCentury) {
    final double trueLong = _sunTrueLongitude(julianCentury);
    final double omega = 125.04 - 1934.136 * julianCentury;
    return trueLong - 0.00569 - 0.00478 * sin(_toRadians(omega));
  }

  /// Calculate the mean obliquity of the ecliptic (degrees)
  double _meanObliquityOfEcliptic(double julianCentury) {
    final double seconds = 21.448 -
        julianCentury *
            (46.8150 + julianCentury * (0.00059 - julianCentury * 0.001813));
    return 23.0 + (26.0 + (seconds / 60.0)) / 60.0;
  }

  /// Calculate the corrected obliquity of the ecliptic (degrees)
  double _obliquityCorrection(double julianCentury) {
    final double meanObliquity = _meanObliquityOfEcliptic(julianCentury);
    final double omega = 125.04 - 1934.136 * julianCentury;
    return meanObliquity + 0.00256 * cos(_toRadians(omega));
  }

  /// Calculate the declination of the Sun (degrees)
  double _sunDeclination(double julianCentury) {
    final double obliquity = _obliquityCorrection(julianCentury);
    final double apparentLong = _sunApparentLongitude(julianCentury);

    final double sinDec =
        sin(_toRadians(obliquity)) * sin(_toRadians(apparentLong));
    return _toDegrees(asin(sinDec));
  }

  /// Calculate the variable Y used in equation of time
  double _varY(double julianCentury) {
    final double obliquity = _obliquityCorrection(julianCentury);
    final double tanHalfObliquity = tan(_toRadians(obliquity / 2));
    return tanHalfObliquity * tanHalfObliquity;
  }

  /// Calculate the Equation of Time (minutes)
  double _equationOfTimeMinutes(double julianCentury) {
    final double y = _varY(julianCentury);
    final double L0 = _toRadians(_geometricMeanLongitudeSun(julianCentury));
    final double e = _eccentricityEarthOrbit(julianCentury);
    final double M = _toRadians(_geometricMeanAnomalySun(julianCentury));

    final double sin2L0 = sin(2 * L0);
    final double sinM = sin(M);
    final double cos2L0 = cos(2 * L0);
    final double sin4L0 = sin(4 * L0);
    final double sin2M = sin(2 * M);

    final double eot = y * sin2L0 -
        2 * e * sinM +
        4 * e * y * sinM * cos2L0 -
        0.5 * y * y * sin4L0 -
        1.25 * e * e * sin2M;

    return _toDegrees(eot) * 4; // Convert to minutes
  }

  // ============================================================
  // HOUR ANGLE CALCULATIONS
  // ============================================================

  /// Calculate hour angle for a given sun altitude (degrees)
  ///
  /// Returns the hour angle in degrees, or null if the sun never reaches
  /// that altitude (polar regions)
  double? _hourAngle(double altitude, double declination) {
    final double latRad = _toRadians(latitude);
    final double decRad = _toRadians(declination);
    final double altRad = _toRadians(altitude);

    final double cosHA =
        (sin(altRad) - sin(latRad) * sin(decRad)) / (cos(latRad) * cos(decRad));

    // Check if sun never reaches this altitude
    if (cosHA < -1 || cosHA > 1) {
      return null;
    }

    return _toDegrees(acos(cosHA));
  }

  /// Calculate the adjusted altitude considering elevation
  double _adjustedMaghribAltitude() {
    if (elevation <= 0) return maghribAltitude;

    // Kemenag altitude correction formula: D' = 1.76 * sqrt(elevation) / 60 degrees
    final double elevationCorrection = 1.76 * sqrt(elevation) / 60.0;
    return maghribAltitude - elevationCorrection;
  }

  /// Calculate the adjusted sunrise altitude considering elevation
  double _adjustedSunriseAltitude() {
    if (elevation <= 0) return sunriseAltitude;

    // Same correction as maghrib but applied opposite direction
    final double elevationCorrection = 1.76 * sqrt(elevation) / 60.0;
    return sunriseAltitude - elevationCorrection;
  }

  /// Get Kemenag altitude correction in minutes
  int get altitudeCorrectionMinutes {
    if (elevation <= 0) return 0;
    // Kemenag table-based correction
    if (elevation < 250) return 0;
    if (elevation < 700) return 1;
    if (elevation < 1000) return 2;
    if (elevation < 1300) return 3;
    if (elevation < 1700) return 4;
    if (elevation < 2000) return 5;
    if (elevation < 2500) return 6;
    return 6 + ((elevation - 2500) / 250).ceil();
  }

  // ============================================================
  // PRAYER TIME CALCULATIONS
  // ============================================================

  /// Calculate solar noon (Dhuhr time) in decimal hours
  double _calculateSolarNoon() {
    // Solar noon = 12 - EoT/60 - Longitude/15 + Timezone
    return 12.0 - _equationOfTime / 60.0 - longitude / 15.0 + timezone;
  }

  /// Calculate time from solar noon and hour angle
  double _timeFromNoon(double hourAngle, bool afterNoon) {
    final double hourAngleHours = hourAngle / 15.0; // Convert degrees to hours
    if (afterNoon) {
      return _solarNoon + hourAngleHours;
    } else {
      return _solarNoon - hourAngleHours;
    }
  }

  /// Calculate Asr time using Shafi'i standard
  double _calculateAsrTime() {
    // Shadow ratio = 1 (Shafi'i)
    // tan(altitude) = 1 / (tan(|lat - dec|) + 1)
    final double latMinusDec = (latitude - _solarDeclination).abs();
    final double shadowRatio = 1.0 + tan(_toRadians(latMinusDec));
    final double asrAltitude = _toDegrees(atan(1.0 / shadowRatio));

    final double? hourAngle = _hourAngle(asrAltitude, _solarDeclination);
    if (hourAngle == null) return double.nan;

    return _timeFromNoon(hourAngle, true);
  }

  /// Main calculation method
  void _calculate() {
    // Step 1: Calculate Julian Day and Century
    _julianDay = _calculateJulianDay(date);
    _julianCentury = _calculateJulianCentury(_julianDay);

    // Step 2: Calculate solar position values
    _solarDeclination = _sunDeclination(_julianCentury);
    _equationOfTime = _equationOfTimeMinutes(_julianCentury);

    // Step 3: Calculate solar noon (Dhuhr)
    _solarNoon = _calculateSolarNoon();
    _dhuhrTime = _solarNoon;

    // Step 4: Calculate Fajr (Subuh)
    final double? fajrHA = _hourAngle(fajrAngle, _solarDeclination);
    _fajrTime = fajrHA != null ? _timeFromNoon(fajrHA, false) : double.nan;

    // Step 5: Calculate Sunrise (Terbit) with altitude correction
    final double adjustedSunrise = _adjustedSunriseAltitude();
    final double? sunriseHA = _hourAngle(adjustedSunrise, _solarDeclination);
    _sunriseTime =
        sunriseHA != null ? _timeFromNoon(sunriseHA, false) : double.nan;

    // Step 6: Calculate Dhuha (sun at 4.5° above horizon)
    final double? dhuhaHA = _hourAngle(dhuhaAngle, _solarDeclination);
    _dhuhaTime = dhuhaHA != null ? _timeFromNoon(dhuhaHA, false) : double.nan;

    // Step 7: Calculate Asr (Ashar)
    _asrTime = _calculateAsrTime();

    // Step 8: Calculate Maghrib with altitude correction
    final double adjustedMaghrib = _adjustedMaghribAltitude();
    final double? maghribHA = _hourAngle(adjustedMaghrib, _solarDeclination);
    _maghribTime =
        maghribHA != null ? _timeFromNoon(maghribHA, true) : double.nan;

    // Step 9: Calculate Isha (Isya)
    final double? ishaHA = _hourAngle(ishaAngle, _solarDeclination);
    _ishaTime = ishaHA != null ? _timeFromNoon(ishaHA, true) : double.nan;
  }

  // ============================================================
  // TIME FORMATTING
  // ============================================================

  /// Convert decimal hours to HH:mm string
  String _formatTime(double decimalHours) {
    if (decimalHours.isNaN) return '--:--';

    // Normalize to 0-24 range
    double hours = decimalHours % 24;
    if (hours < 0) hours += 24;

    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();

    // Handle minute overflow
    if (m == 60) {
      return '${((h + 1) % 24).toString().padLeft(2, '0')}:00';
    }

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Apply Ikhtiyat (safety margin) and format time
  String _formatWithIkhtiyat(double decimalHours, int ikhtiyatMinutes) {
    if (decimalHours.isNaN) return '--:--';

    final double adjustedTime = decimalHours + ikhtiyatMinutes / 60.0;
    return _formatTime(adjustedTime);
  }

  // ============================================================
  // PUBLIC GETTERS - RAW TIMES (without Ikhtiyat)
  // ============================================================

  /// Get Equation of Time in minutes
  double get equationOfTime => _equationOfTime;

  /// Get Solar Declination in degrees
  double get solarDeclination => _solarDeclination;

  /// Get raw Fajr time (without Ikhtiyat)
  String get rawFajr => _formatTime(_fajrTime);

  /// Get raw Sunrise time (without Ikhtiyat)
  String get rawSunrise => _formatTime(_sunriseTime);

  /// Get raw Dhuhr time (without Ikhtiyat)
  String get rawDhuhr => _formatTime(_dhuhrTime);

  /// Get raw Asr time (without Ikhtiyat)
  String get rawAsr => _formatTime(_asrTime);

  /// Get raw Maghrib time (without Ikhtiyat)
  String get rawMaghrib => _formatTime(_maghribTime);

  /// Get raw Isha time (without Ikhtiyat)
  String get rawIsha => _formatTime(_ishaTime);

  // ============================================================
  // PUBLIC GETTERS - FINAL TIMES (with Ikhtiyat + Altitude)
  // ============================================================

  /// Get Imsak time (10 minutes before Fajr)
  String get imsak => _formatWithIkhtiyat(_fajrTime - 10 / 60.0, 0);

  /// Get Fajr (Subuh) time with +2 min Ikhtiyat
  String get fajr => _formatWithIkhtiyat(_fajrTime, ikhtiyatMinutes);

  /// Get Sunrise (Terbit) time with -2 min Ikhtiyat and altitude correction
  /// Sunrise is EARLIER at higher elevations (subtract correction)
  String get sunrise => _formatWithIkhtiyat(
      _sunriseTime - altitudeCorrectionMinutes / 60.0, -ikhtiyatMinutes);

  /// Get Dhuha time calculated using 4.5° sun angle (Kemenag standard)
  /// At higher elevations, Dhuha is LATER (sun takes longer to reach 4.5° from true horizon)
  String get dhuha =>
      _formatWithIkhtiyat(_dhuhaTime + altitudeCorrectionMinutes / 60.0, 0);

  /// Get Dhuhr (Dzuhur) time with +2 min Ikhtiyat
  String get dhuhr => _formatWithIkhtiyat(_dhuhrTime, ikhtiyatMinutes);

  /// Get Asr (Ashar) time with +2 min Ikhtiyat
  String get asr => _formatWithIkhtiyat(_asrTime, ikhtiyatMinutes);

  /// Get Maghrib time with +2 min Ikhtiyat and altitude correction
  /// Maghrib is LATER at higher elevations (add correction)
  String get maghrib => _formatWithIkhtiyat(
      _maghribTime + altitudeCorrectionMinutes / 60.0, ikhtiyatMinutes);

  /// Get Isha (Isya) time with +2 min Ikhtiyat
  String get isha => _formatWithIkhtiyat(_ishaTime, ikhtiyatMinutes);

  // ============================================================
  // DEBUG OUTPUT
  // ============================================================

  /// Print detailed calculation results
  void printDetails() {
    print('╔════════════════════════════════════════════════════════╗');
    print('║        JADWAL SHALAT - KEMENAG RI METHOD               ║');
    print('╠════════════════════════════════════════════════════════╣');
    print(
        '║ Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}');
    print(
        '║ Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    print('║ Timezone: UTC+${timezone.toStringAsFixed(1)}');
    print('║ Elevation: ${elevation.toStringAsFixed(0)} m');
    print('╠════════════════════════════════════════════════════════╣');
    print('║ SOLAR DATA:');
    print('║   Julian Day:        ${_julianDay.toStringAsFixed(5)}');
    print(
        '║   Equation of Time:  ${_equationOfTime.toStringAsFixed(3)} minutes');
    print('║   Solar Declination: ${_solarDeclination.toStringAsFixed(4)}°');
    print('╠════════════════════════════════════════════════════════╣');
    print('║ RAW TIMES (before Ikhtiyat):');
    print('║   Fajr:    $rawFajr');
    print('║   Sunrise: $rawSunrise');
    print('║   Dhuhr:   $rawDhuhr');
    print('║   Asr:     $rawAsr');
    print('║   Maghrib: $rawMaghrib');
    print('║   Isha:    $rawIsha');
    print('╠════════════════════════════════════════════════════════╣');
    print('║ FINAL SCHEDULE (with Ikhtiyat ±2 min):');
    print('║   Imsak:   $imsak');
    print('║   Subuh:   $fajr     (+2 min)');
    print('║   Terbit:  $sunrise     (-2 min)');
    print('║   Dhuha:   $dhuha');
    print('║   Dzuhur:  $dhuhr     (+2 min)');
    print('║   Ashar:   $asr     (+2 min)');
    print('║   Maghrib: $maghrib     (+2 min)');
    print('║   Isya:    $isha     (+2 min)');
    print('╚════════════════════════════════════════════════════════╝');
  }

  /// Get all prayer times as a map
  Map<String, String> toMap() {
    return {
      'imsak': imsak,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuha': dhuha,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  @override
  String toString() {
    return 'KemenagPrayerTimes(${date.year}-${date.month}-${date.day}, '
        'lat: $latitude, lng: $longitude, tz: $timezone)';
  }
}

// ============================================================
// MAIN FUNCTION FOR TESTING
// ============================================================

void main() {
  print('');
  print('Testing Kemenag Prayer Times Calculator');
  print('========================================');
  print('');

  // Test Case 1: Istiqlal Mosque, Jakarta
  final jakartaTimes = KemenagPrayerTimes(
    latitude: -6.1702,
    longitude: 106.8310,
    timezone: 7.0,
    date: DateTime(2026, 2, 1), // Today's date
    elevation: 10, // Jakarta is near sea level
  );

  print('TEST CASE 1: Istiqlal Mosque, Jakarta');
  jakartaTimes.printDetails();

  print('');
  print('');

  // Test Case 2: Bandung (for comparison with Kemenag data)
  final bandungTimes = KemenagPrayerTimes(
    latitude: -6.9179131,
    longitude: 107.6072436,
    timezone: 7.0,
    date: DateTime(2026, 2, 1),
    elevation: 708, // Bandung altitude
  );

  print('TEST CASE 2: Bandung');
  bandungTimes.printDetails();

  print('');
  print('');

  // Comparison with Kemenag data for Bandung (01/02/2026)
  print('╔════════════════════════════════════════════════════════╗');
  print('║ COMPARISON: Bandung 01/02/2026                         ║');
  print('╠════════════════════════════════════════════════════════╣');
  print('║ Prayer      | Kemenag  | Ours     | Diff              ║');
  print('╠════════════════════════════════════════════════════════╣');

  final kemenag = {
    'Imsak': '04:22',
    'Subuh': '04:32',
    'Terbit': '05:43',
    'Dhuha': '06:16',
    'Dzuhur': '12:07',
    'Ashar': '15:25',
    'Maghrib': '18:23',
    'Isya': '19:31',
  };

  final ours = {
    'Imsak': bandungTimes.imsak,
    'Subuh': bandungTimes.fajr,
    'Terbit': bandungTimes.sunrise,
    'Dhuha': bandungTimes.dhuha,
    'Dzuhur': bandungTimes.dhuhr,
    'Ashar': bandungTimes.asr,
    'Maghrib': bandungTimes.maghrib,
    'Isya': bandungTimes.isha,
  };

  for (final prayer in kemenag.keys) {
    final k = kemenag[prayer]!;
    final o = ours[prayer]!;
    print('║ ${prayer.padRight(11)} | $k    | $o    |                   ║');
  }

  print('╚════════════════════════════════════════════════════════╝');
}
