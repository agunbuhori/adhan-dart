import 'dart:math';
import 'package:adhan/adhan.dart';

/// Extended Coordinates class that includes altitude/elevation.
///
/// Altitude affects sunrise and sunset times - at higher elevations,
/// the horizon is lower, so sunrise appears earlier and sunset later.
class CoordinatesWithAltitude extends Coordinates {
  /// Altitude above sea level in meters
  final double altitude;

  /// Creates coordinates with altitude.
  ///
  /// [latitude] The latitude in degrees
  /// [longitude] The longitude in degrees
  /// [altitude] Altitude above sea level in meters (default: 0)
  /// [validate] If true, throws ArgumentError for invalid coordinates
  CoordinatesWithAltitude(
    double latitude,
    double longitude, {
    this.altitude = 0,
    bool validate = false,
  }) : super(latitude, longitude, validate: validate) {
    if (validate && altitude < 0) {
      throw ArgumentError('Altitude cannot be negative');
    }
  }

  /// Creates coordinates from an existing Coordinates object with altitude.
  factory CoordinatesWithAltitude.fromCoordinates(
    Coordinates coordinates, {
    double altitude = 0,
  }) {
    return CoordinatesWithAltitude(
      coordinates.latitude,
      coordinates.longitude,
      altitude: altitude,
    );
  }

  /// Calculates the dip of horizon angle correction based on altitude.
  ///
  /// Formula: D' = 1.76 × √(altitude_meters) / 60 (in degrees)
  /// This is the Kemenag standard formula.
  double get horizonDipDegrees {
    if (altitude <= 0) return 0;
    return 1.76 * sqrt(altitude) / 60.0;
  }

  /// Gets the adjusted solar altitude for sunrise/sunset calculation.
  ///
  /// The standard solar altitude is -50/60 degrees (-0.833°), which accounts for:
  /// - Atmospheric refraction (~34 arc minutes)
  /// - Sun's semi-diameter (~16 arc minutes)
  ///
  /// At higher altitudes, we subtract the horizon dip to get earlier sunrise
  /// and later sunset times.
  double get adjustedSolarAltitude {
    const standardSolarAltitude = -50.0 / 60.0; // -0.833 degrees
    return standardSolarAltitude - horizonDipDegrees;
  }

  /// Gets the altitude correction in minutes based on Kemenag's practical table.
  ///
  /// This is a simplified correction used by Indonesian Ministry of Religious Affairs:
  /// - 0 - 250m: 0 minutes
  /// - 250 - 700m: 1 minute
  /// - 700 - 1000m: 2 minutes
  /// - 1000 - 1300m: 3 minutes
  /// - 1300 - 1700m: 4 minutes
  /// - 1700 - 2000m: 5 minutes
  /// - 2000 - 2500m: 6 minutes
  /// - > 2500m: calculated based on formula
  int get kemenagAltitudeCorrection {
    if (altitude < 250) return 0;
    if (altitude < 700) return 1;
    if (altitude < 1000) return 2;
    if (altitude < 1300) return 3;
    if (altitude < 1700) return 4;
    if (altitude < 2000) return 5;
    if (altitude < 2500) return 6;
    // For higher altitudes, calculate based on formula
    // Approximate 1 minute per ~250m after 2500m
    return 6 + ((altitude - 2500) / 250).ceil();
  }

  /// Gets the altitude correction in minutes based on formula calculation.
  ///
  /// **WARNING**: This formula-based correction may not match Kemenag exactly.
  /// For production apps, consider using `kemenagAltitudeCorrection` instead
  /// which uses Kemenag's official table.
  ///
  /// Formula:
  /// - Horizon dip (degrees) = 1.76 × √(altitude_meters) / 60
  /// - Time correction (minutes) = horizon dip × 4
  int get formulaAltitudeCorrection {
    if (altitude <= 0) return 0;
    final correctionMinutes = horizonDipDegrees * 4;
    return correctionMinutes.round();
  }

  @override
  String toString() {
    return 'CoordinatesWithAltitude(lat: $latitude, lng: $longitude, alt: ${altitude}m)';
  }
}
