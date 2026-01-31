import 'package:adhan/adhan.dart';

/// Kemenag (Indonesian Ministry of Religious Affairs) calculation parameters.
///
/// Based on the official criteria from Kementerian Agama Republik Indonesia:
/// - Fajr: Sun at -20° below eastern horizon
/// - Isha: Sun at -18° below western horizon
/// - Ihtiyati (precautionary time): +2 minutes for all prayers
class KemenagCalculationMethod {
  KemenagCalculationMethod._();

  /// Standard Kemenag calculation parameters.
  ///
  /// Uses:
  /// - Fajr angle: 20°
  /// - Isha angle: 18°
  /// - Madhab: Shafi'i (default)
  /// - Ihtiyati: 2 minutes (applied via adjustments)
  static CalculationParameters getParameters() {
    final params = CalculationParameters(
      fajrAngle: 20.0,
      ishaAngle: 18.0,
      method: CalculationMethod.other,
      madhab: Madhab.shafi,
    );

    // Apply Ihtiyati (precautionary time) of 2 minutes
    params.adjustments.fajr = 2;
    params.adjustments.sunrise = -2; // Subtract for sunrise
    params.adjustments.dhuhr = 2;
    params.adjustments.asr = 2;
    params.adjustments.maghrib = 2;
    params.adjustments.isha = 2;

    return params;
  }

  /// Kemenag calculation parameters without Ihtiyati.
  ///
  /// Use this if you want raw calculation without the 2-minute adjustment.
  static CalculationParameters getParametersWithoutIhtiyati() {
    return CalculationParameters(
      fajrAngle: 20.0,
      ishaAngle: 18.0,
      method: CalculationMethod.other,
      madhab: Madhab.shafi,
    );
  }

  /// Kemenag calculation parameters for Ramadhan.
  ///
  /// Same as standard Kemenag but may include additional adjustments
  /// for Imsak (10 minutes before Fajr).
  static CalculationParameters getRamadhanParameters() {
    final params = getParameters();
    // Imsak is typically 10 minutes before Fajr
    // This is handled separately in PrayerTimesIndonesia
    return params;
  }

  /// Get parameters with custom Ihtiyati value.
  ///
  /// [ihtiyatiMinutes] The precautionary time in minutes (default: 2)
  static CalculationParameters getParametersWithCustomIhtiyati(
    int ihtiyatiMinutes,
  ) {
    final params = CalculationParameters(
      fajrAngle: 20.0,
      ishaAngle: 18.0,
      method: CalculationMethod.other,
      madhab: Madhab.shafi,
    );

    params.adjustments.fajr = ihtiyatiMinutes;
    params.adjustments.sunrise = -ihtiyatiMinutes;
    params.adjustments.dhuhr = ihtiyatiMinutes;
    params.adjustments.asr = ihtiyatiMinutes;
    params.adjustments.maghrib = ihtiyatiMinutes;
    params.adjustments.isha = ihtiyatiMinutes;

    return params;
  }
}
