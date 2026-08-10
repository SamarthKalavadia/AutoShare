import '../data/driver_dummy_data.dart';
import '../models/driver_model.dart';

/// Repository for driver data.
///
/// Currently reads from local static data ([kDummyDrivers]).
///
/// ── Future Firebase migration ───────────────────────────────────────────────
/// To switch to Firestore:
///   1. Inject [FirestoreService] into the constructor.
///   2. Replace the body of [fetchDrivers] with a Firestore query.
///   3. Uncomment DriverModel.fromMap() in driver_model.dart.
///   4. No changes needed to the Provider or UI layer.
/// ────────────────────────────────────────────────────────────────────────────
class DriverRepository {
  const DriverRepository();

  /// Returns the full list of drivers.
  ///
  /// Returns a [Future] so the signature is compatible with
  /// a future Firestore implementation.
  Future<List<DriverModel>> fetchDrivers() async {
    // Simulates a small async delay (remove when using real network data)
    await Future.delayed(const Duration(milliseconds: 300));
    return List<DriverModel>.from(kDummyDrivers);
  }
}
