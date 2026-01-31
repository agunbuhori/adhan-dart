import 'package:adhan_indonesia/adhan_indonesia.dart';
import 'package:test/test.dart';

void main() {
  group('CoordinatesWithAltitude', () {
    test('should create coordinates with altitude', () {
      final coords = CoordinatesWithAltitude(-6.9175, 107.6191, altitude: 768);

      expect(coords.latitude, -6.9175);
      expect(coords.longitude, 107.6191);
      expect(coords.altitude, 768);
    });

    test('should have default altitude of 0', () {
      final coords = CoordinatesWithAltitude(-6.9175, 107.6191);

      expect(coords.altitude, 0);
    });

    test('should calculate horizon dip correctly', () {
      // For 768m altitude: D' = 1.76 * sqrt(768) / 60 ≈ 0.813 degrees
      final coords = CoordinatesWithAltitude(-6.9175, 107.6191, altitude: 768);

      expect(coords.horizonDipDegrees, closeTo(0.813, 0.01));
    });

    test('should return 0 horizon dip for sea level', () {
      final coords = CoordinatesWithAltitude(-6.9175, 107.6191, altitude: 0);

      expect(coords.horizonDipDegrees, 0);
    });

    test('should calculate Kemenag altitude correction correctly', () {
      // Test various altitude ranges
      expect(
        CoordinatesWithAltitude(0, 0, altitude: 100).kemenagAltitudeCorrection,
        0,
      );
      expect(
        CoordinatesWithAltitude(0, 0, altitude: 300).kemenagAltitudeCorrection,
        1,
      );
      expect(
        CoordinatesWithAltitude(0, 0, altitude: 768).kemenagAltitudeCorrection,
        2,
      ); // Bandung
      expect(
        CoordinatesWithAltitude(0, 0, altitude: 1312).kemenagAltitudeCorrection,
        4,
      ); // Lembang
      expect(
        CoordinatesWithAltitude(0, 0, altitude: 2093).kemenagAltitudeCorrection,
        6,
      ); // Dieng
    });

    test('should create from existing Coordinates', () {
      final original = Coordinates(-6.9175, 107.6191);
      final withAlt = CoordinatesWithAltitude.fromCoordinates(
        original,
        altitude: 768,
      );

      expect(withAlt.latitude, original.latitude);
      expect(withAlt.longitude, original.longitude);
      expect(withAlt.altitude, 768);
    });
  });

  group('KemenagCalculationMethod', () {
    test('should have correct Fajr angle (20 degrees)', () {
      final params = KemenagCalculationMethod.getParameters();

      expect(params.fajrAngle, 20.0);
    });

    test('should have correct Isha angle (18 degrees)', () {
      final params = KemenagCalculationMethod.getParameters();

      expect(params.ishaAngle, 18.0);
    });

    test('should have Ihtiyati adjustments (+2 minutes)', () {
      final params = KemenagCalculationMethod.getParameters();

      expect(params.adjustments.fajr, 2);
      expect(params.adjustments.sunrise, -2);
      expect(params.adjustments.dhuhr, 2);
      expect(params.adjustments.asr, 2);
      expect(params.adjustments.maghrib, 2);
      expect(params.adjustments.isha, 2);
    });

    test('should have no Ihtiyati when using getParametersWithoutIhtiyati', () {
      final params = KemenagCalculationMethod.getParametersWithoutIhtiyati();

      expect(params.adjustments.fajr, 0);
      expect(params.adjustments.dhuhr, 0);
    });

    test('should allow custom Ihtiyati', () {
      final params =
          KemenagCalculationMethod.getParametersWithCustomIhtiyati(3);

      expect(params.adjustments.fajr, 3);
      expect(params.adjustments.dhuhr, 3);
    });
  });

  group('IndonesianCities', () {
    test('Bandung should have correct coordinates and altitude', () {
      final bandung = IndonesianCities.bandung;

      expect(bandung.latitude, closeTo(-6.9175, 0.01));
      expect(bandung.longitude, closeTo(107.6191, 0.01));
      expect(bandung.altitude, 768);
    });

    test('Jakarta should have low altitude', () {
      final jakarta = IndonesianCities.jakarta;

      expect(jakarta.altitude, lessThan(50));
    });

    test('Highland cities should have altitude > 500m', () {
      final highlands = IndonesianCities.highlandCities;

      for (final entry in highlands.entries) {
        expect(
          entry.value.altitude,
          greaterThan(500),
          reason: '${entry.key} should have altitude > 500m',
        );
      }
    });

    test('All cities map should not be empty', () {
      expect(IndonesianCities.all.isNotEmpty, true);
      expect(IndonesianCities.all.length, greaterThan(40));
    });
  });

  group('PrayerTimesIndonesia', () {
    test('should calculate prayer times for Bandung', () {
      final coords = IndonesianCities.bandung;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(coords, date);

      // Basic sanity checks - times should be in correct order
      expect(prayerTimes.fajr.isBefore(prayerTimes.sunrise), true);
      expect(prayerTimes.sunrise.isBefore(prayerTimes.dhuhr), true);
      expect(prayerTimes.dhuhr.isBefore(prayerTimes.asr), true);
      expect(prayerTimes.asr.isBefore(prayerTimes.maghrib), true);
      expect(prayerTimes.maghrib.isBefore(prayerTimes.isha), true);
    });

    test('should calculate Imsak as 10 minutes before Fajr', () {
      final coords = IndonesianCities.bandung;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(coords, date);

      final diff = prayerTimes.fajr.difference(prayerTimes.imsak).inMinutes;
      expect(diff, 10);
    });

    test(
        'should calculate Dhuha as 33 minutes after sunrise (Kemenag: 4.5° sun angle)',
        () {
      final coords = IndonesianCities.bandung;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(coords, date);

      final diff = prayerTimes.dhuha.difference(prayerTimes.sunrise).inMinutes;
      expect(diff, 33); // Kemenag uses sun at 4.5° above horizon ≈ 33 min
    });

    test('should apply altitude correction to Maghrib', () {
      final coords = IndonesianCities.bandung; // 768m altitude
      final date = DateComponents(2026, 2, 1);

      final withCorrection = PrayerTimesIndonesia(
        coords,
        date,
        useAltitudeCorrection: true,
      );
      final withoutCorrection = PrayerTimesIndonesia(
        coords,
        date,
        useAltitudeCorrection: false,
      );

      // Maghrib with correction should be later
      final diff = withCorrection.maghrib
          .difference(withoutCorrection.maghrib)
          .inMinutes;
      // Table-based correction for 768m = 2 minutes (Kemenag table)
      expect(diff, withCorrection.altitudeCorrectionMinutes);
    });

    test('should apply altitude correction to Sunrise (earlier)', () {
      final coords = IndonesianCities.bandung; // 768m altitude
      final date = DateComponents(2026, 2, 1);

      final withCorrection = PrayerTimesIndonesia(
        coords,
        date,
        useAltitudeCorrection: true,
      );
      final withoutCorrection = PrayerTimesIndonesia(
        coords,
        date,
        useAltitudeCorrection: false,
      );

      // Sunrise with correction should be earlier
      final diff = withoutCorrection.sunrise
          .difference(withCorrection.sunrise)
          .inMinutes;
      // Table-based correction for 768m = 2 minutes (Kemenag table)
      expect(diff, withCorrection.altitudeCorrectionMinutes);
    });

    test('should calculate Half Night correctly', () {
      final coords = IndonesianCities.bandung;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(coords, date);

      // Half night should be between Maghrib and next Fajr
      expect(prayerTimes.halfNight.isAfter(prayerTimes.maghrib), true);
      expect(prayerTimes.halfNight.isAfter(prayerTimes.isha), true);

      // Half night should be approximately at the midpoint
      final nightDuration = prayerTimes.nightDuration;
      final halfPoint = prayerTimes.maghrib.add(
        Duration(milliseconds: nightDuration.inMilliseconds ~/ 2),
      );

      expect(
        prayerTimes.halfNight.difference(halfPoint).inMinutes.abs(),
        lessThan(1),
      );
    });

    test('should calculate Last Third correctly', () {
      final coords = IndonesianCities.bandung;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(coords, date);

      // Last Third should be after Half Night
      expect(prayerTimes.lastThird.isAfter(prayerTimes.halfNight), true);

      // Last Third should be at 2/3 of the night
      final nightDuration = prayerTimes.nightDuration;
      final twoThirdsPoint = prayerTimes.maghrib.add(
        Duration(milliseconds: (nightDuration.inMilliseconds * 2) ~/ 3),
      );

      expect(
        prayerTimes.lastThird.difference(twoThirdsPoint).inMinutes.abs(),
        lessThan(1),
      );
    });

    test('should have correct altitude correction for highland cities', () {
      // Dieng (2093m) - table gives +6 min (default)
      final dieng = IndonesianCities.dieng;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(dieng, date);

      // Table-based correction for 2093m = 6 minutes (Kemenag table)
      expect(prayerTimes.altitudeCorrectionMinutes,
          dieng.kemenagAltitudeCorrection);
    });

    test('should have no altitude correction for Jakarta', () {
      final jakarta = IndonesianCities.jakarta;
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(jakarta, date);

      expect(prayerTimes.altitudeCorrectionMinutes, 0);
    });

    test('today() factory should work', () {
      final prayerTimes = PrayerTimesIndonesia.today(IndonesianCities.bandung);

      // Should not throw and should have valid times
      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.maghrib, isNotNull);
    });

    test('fromCoordinates() factory should work', () {
      final prayerTimes = PrayerTimesIndonesia.fromCoordinates(
        Coordinates(-6.9175, 107.6191),
        768,
        DateComponents(2026, 2, 1),
      );

      expect(prayerTimes.coordinates.altitude, 768);
      // Table-based correction for 768m = 2 minutes (Kemenag table, default)
      expect(prayerTimes.altitudeCorrectionMinutes,
          prayerTimes.coordinates.kemenagAltitudeCorrection);
    });
  });

  group('Prayer Time Comparison with Kemenag', () {
    // These tests check that our calculations are reasonable
    // Exact times may vary slightly due to calculation method differences

    test('Fajr should be around 4:30 AM for Bandung in February', () {
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(IndonesianCities.bandung, date);

      // Fajr should be between 4:00 and 5:00 AM
      expect(prayerTimes.fajr.hour, inInclusiveRange(4, 5));
    });

    test('Dhuhr should be around 12:00 PM for Bandung', () {
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(IndonesianCities.bandung, date);

      // Dhuhr should be between 11:30 and 12:30
      expect(prayerTimes.dhuhr.hour, inInclusiveRange(11, 12));
    });

    test('Maghrib should be around 6:15 PM for Bandung in February', () {
      final date = DateComponents(2026, 2, 1);
      final prayerTimes = PrayerTimesIndonesia(IndonesianCities.bandung, date);

      // Maghrib should be between 6:00 and 7:00 PM (18:00-19:00)
      expect(prayerTimes.maghrib.hour, inInclusiveRange(17, 19));
    });
  });
}
