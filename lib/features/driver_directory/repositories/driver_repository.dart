import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autoshare/core/services/firestore_service.dart';
import '../models/driver_model.dart';

/// Repository for driver data.
/// Fetches all registered users to display in the driver directory.
class DriverRepository {
  final FirestoreService _firestoreService;

  DriverRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Returns the full list of drivers (currently all users).
  Future<List<DriverModel>> fetchDrivers() async {
    try {
      final snapshot = await _firestoreService.usersCollection.get();
      final List<DriverModel> drivers = [];
      
      for (final doc in snapshot.docs) {
        final map = doc.data() as Map<String, dynamic>;
        drivers.add(DriverModel.fromMap(map, doc.id));
      }
      return drivers;
    } catch (e) {
      // Return empty list on failure rather than dummy data
      return [];
    }
  }
}
