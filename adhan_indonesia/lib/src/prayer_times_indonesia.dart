import 'package:adhan/adhan.dart';

import 'coordinates_with_altitude.dart';
import 'kemenag_calculation_method.dart';

/// Indonesian prayer times with altitude support.
///
/// This class extends the standard PrayerTimes calculation with:
/// - Altitude/elevation correction for sunrise and maghrib
/// - Kemenag standard calculation method
/// - Imsak time (10 minutes before Fajr)
/// - Dhuha time
/// - Half Night time (middle of the night for Qiyam)
/// - Last Third of Night time (recommended time for Tahajjud)
class PrayerTimesIndonesia {
  final PrayerTimes _basePrayerTimes;
  final CoordinatesWithAltitude coordinates;
  final bool useAltitudeCorrection;
  final bool useFormulaCorrection;

  late DateTime _fajr;
  DateTime get fajr => _fajr;

  late DateTime _sunrise;
  DateTime get sunrise => _sunrise;

  late DateTime _dhuhr;
  DateTime get dhuhr => _dhuhr;

  late DateTime _asr;
  DateTime get asr => _asr;

  late DateTime _maghrib;
  DateTime get maghrib => _maghrib;

  late DateTime _isha;
  DateTime get isha => _isha;

  late DateTime _imsak;

  /// Time for Imsak (start of fasting), 10 minutes before Fajr
  DateTime get imsak => _imsak;

  late DateTime _dhuha;

  /// Time for Dhuha prayer (15 minutes after sunrise)
  DateTime get dhuha => _dhuha;

  late DateTime _halfNight;

  /// The midpoint between Maghrib and Fajr (next day).
  ///
  /// This is the middle of the night, commonly used for Qiyamul Lail.
  /// Calculation: Maghrib + (Fajr - Maghrib) / 2
  DateTime get halfNight => _halfNight;

  late DateTime _lastThird;

  /// The beginning of the last third of the night.
  ///
  /// This is the recommended time for Tahajjud prayer, as mentioned in hadith
  /// that Allah descends to the lowest heaven in the last third of the night.
  /// Calculation: Maghrib + (Fajr - Maghrib) * 2 / 3
  DateTime get lastThird => _lastThird;

  /// Creates Indonesian prayer times with altitude correction.
  ///
  /// [coordinates] Location with altitude
  /// [dateComponents] The date for calculation
  /// [calculationParameters] Optional custom parameters (defaults to Kemenag)
  /// [useAltitudeCorrection] Whether to apply altitude correction (default: true)
  /// [useFormulaCorrection] If true, uses formula-based correction instead of
  ///   Kemenag's official table. Default is false (uses table).
  /// [utcOffset] Optional UTC offset for timezone
  PrayerTimesIndonesia(
    this.coordinates,
    DateComponents dateComponents, {
    CalculationParameters? calculationParameters,
    this.useAltitudeCorrection = true,
    this.useFormulaCorrection = false, // Default: use Kemenag table (safer)
    Duration? utcOffset,
  }) : _basePrayerTimes = PrayerTimes(
          coordinates,
          dateComponents,
          calculationParameters ?? KemenagCalculationMethod.getParameters(),
          utcOffset: utcOffset,
        ) {
    _calculateTimes();
  }

  /// Creates today's Indonesian prayer times with altitude correction.
  factory PrayerTimesIndonesia.today(
    CoordinatesWithAltitude coordinates, {
    CalculationParameters? calculationParameters,
    bool useAltitudeCorrection = true,
    bool useFormulaCorrection = false,
    Duration? utcOffset,
  }) {
    return PrayerTimesIndonesia(
      coordinates,
      DateComponents.from(DateTime.now()),
      calculationParameters: calculationParameters,
      useAltitudeCorrection: useAltitudeCorrection,
      useFormulaCorrection: useFormulaCorrection,
      utcOffset: utcOffset,
    );
  }

  /// Creates Indonesian prayer times from regular Coordinates with altitude.
  factory PrayerTimesIndonesia.fromCoordinates(
    Coordinates coordinates,
    double altitude,
    DateComponents dateComponents, {
    CalculationParameters? calculationParameters,
    bool useAltitudeCorrection = true,
    bool useFormulaCorrection = false,
    Duration? utcOffset,
  }) {
    return PrayerTimesIndonesia(
      CoordinatesWithAltitude.fromCoordinates(coordinates, altitude: altitude),
      dateComponents,
      calculationParameters: calculationParameters,
      useAltitudeCorrection: useAltitudeCorrection,
      useFormulaCorrection: useFormulaCorrection,
      utcOffset: utcOffset,
    );
  }

  void _calculateTimes() {
    // Choose correction method: formula-based is more accurate for specific altitudes
    int altitudeCorrection;
    if (!useAltitudeCorrection) {
      altitudeCorrection = 0;
    } else if (useFormulaCorrection) {
      altitudeCorrection = coordinates.formulaAltitudeCorrection;
    } else {
      altitudeCorrection = coordinates.kemenagAltitudeCorrection;
    }

    // Copy base times
    _fajr = _basePrayerTimes.fajr;
    _dhuhr = _basePrayerTimes.dhuhr;
    _asr = _basePrayerTimes.asr;
    _isha = _basePrayerTimes.isha;

    // Apply altitude correction to sunrise (subtract = earlier)
    _sunrise = _basePrayerTimes.sunrise.subtract(
      Duration(minutes: altitudeCorrection),
    );

    // Apply altitude correction to maghrib (add = later)
    _maghrib = _basePrayerTimes.maghrib.add(
      Duration(minutes: altitudeCorrection),
    );

    // Calculate Imsak (10 minutes before Fajr)
    _imsak = _fajr.subtract(const Duration(minutes: 10));

    // Calculate Dhuha - Kemenag uses sun at 4.5° above horizon
    // For tropical regions near equator, this is approximately 33 minutes after sunrise
    // The exact time depends on latitude and date, but 33 min is a good approximation
    // for Indonesian latitudes (-6° to -8°)
    _dhuha = _sunrise.add(const Duration(minutes: 33));

    // Calculate night duration (Maghrib to next day's Fajr)
    // We need to get tomorrow's Fajr for accurate calculation
    // For simplicity, we assume Fajr is always after midnight (next day)
    // so we add 24 hours to Fajr if it appears before Maghrib
    DateTime nextFajr = _fajr;
    if (_fajr.isBefore(_maghrib)) {
      // Fajr is the next day
      nextFajr = _fajr.add(const Duration(days: 1));
    }

    final nightDuration = nextFajr.difference(_maghrib);

    // Calculate Half Night (middle of the night)
    // Maghrib + (nightDuration / 2)
    _halfNight = _maghrib.add(Duration(
      milliseconds: nightDuration.inMilliseconds ~/ 2,
    ));

    // Calculate Last Third of Night
    // Maghrib + (nightDuration * 2 / 3)
    _lastThird = _maghrib.add(Duration(
      milliseconds: (nightDuration.inMilliseconds * 2) ~/ 3,
    ));
  }

  /// Get date components for this prayer times
  DateComponents get dateComponents => _basePrayerTimes.dateComponents;

  /// Get the underlying base prayer times (without altitude correction)
  PrayerTimes get basePrayerTimes => _basePrayerTimes;

  /// Get current prayer based on current time
  Prayer currentPrayer() {
    return currentPrayerByDateTime(DateTime.now());
  }

  /// Get current prayer based on specified time
  Prayer currentPrayerByDateTime(DateTime time) {
    final when = time.millisecondsSinceEpoch;
    if (isha.millisecondsSinceEpoch - when <= 0) {
      return Prayer.isha;
    } else if (maghrib.millisecondsSinceEpoch - when <= 0) {
      return Prayer.maghrib;
    } else if (asr.millisecondsSinceEpoch - when <= 0) {
      return Prayer.asr;
    } else if (dhuhr.millisecondsSinceEpoch - when <= 0) {
      return Prayer.dhuhr;
    } else if (sunrise.millisecondsSinceEpoch - when <= 0) {
      return Prayer.sunrise;
    } else if (fajr.millisecondsSinceEpoch - when <= 0) {
      return Prayer.fajr;
    } else {
      return Prayer.none;
    }
  }

  /// Get next prayer based on current time
  Prayer nextPrayer() {
    return nextPrayerByDateTime(DateTime.now());
  }

  /// Get next prayer based on specified time
  Prayer nextPrayerByDateTime(DateTime time) {
    final when = time.millisecondsSinceEpoch;
    if (isha.millisecondsSinceEpoch - when <= 0) {
      return Prayer.none;
    } else if (maghrib.millisecondsSinceEpoch - when <= 0) {
      return Prayer.isha;
    } else if (asr.millisecondsSinceEpoch - when <= 0) {
      return Prayer.maghrib;
    } else if (dhuhr.millisecondsSinceEpoch - when <= 0) {
      return Prayer.asr;
    } else if (sunrise.millisecondsSinceEpoch - when <= 0) {
      return Prayer.dhuhr;
    } else if (fajr.millisecondsSinceEpoch - when <= 0) {
      return Prayer.sunrise;
    } else {
      return Prayer.fajr;
    }
  }

  /// Get time for a specific prayer
  DateTime? timeForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
      case Prayer.none:
      default:
        return null;
    }
  }

  /// Get the altitude correction in minutes
  int get altitudeCorrectionMinutes {
    if (!useAltitudeCorrection) return 0;
    return useFormulaCorrection
        ? coordinates.formulaAltitudeCorrection
        : coordinates.kemenagAltitudeCorrection;
  }

  /// Get the duration of the night (from Maghrib to next Fajr)
  Duration get nightDuration {
    DateTime nextFajr = _fajr;
    if (_fajr.isBefore(_maghrib)) {
      nextFajr = _fajr.add(const Duration(days: 1));
    }
    return nextFajr.difference(_maghrib);
  }

  @override
  String toString() {
    return '''PrayerTimesIndonesia(
  location: $coordinates,
  altitudeCorrection: ${altitudeCorrectionMinutes}min,
  imsak: $imsak,
  fajr: $fajr,
  sunrise: $sunrise,
  dhuha: $dhuha,
  dhuhr: $dhuhr,
  asr: $asr,
  maghrib: $maghrib,
  isha: $isha,
  halfNight: $halfNight,
  lastThird: $lastThird,
)''';
  }
}
