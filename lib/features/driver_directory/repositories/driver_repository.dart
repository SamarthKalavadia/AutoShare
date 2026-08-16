import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autoshare/core/services/firestore_service.dart';
import '../models/driver_model.dart';

/// Repository for driver data.
/// Fetches all registered users to display in the driver directory.
class DriverRepository {
  final FirestoreService _firestoreService;

  DriverRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Returns the list of drivers from Firestore.
  Future<List<DriverModel>> fetchDrivers() async {
    try {
      final snapshot = await _firestoreService.usersCollection.get();
      
      final List<DriverModel> drivers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;
        
        // We only want to display drivers.
        if (role == 'driver' || role == 'auto_driver') {
          drivers.add(DriverModel.fromMap(data, doc.id));
        }
      }

      return drivers;
    } catch (e) {
      print('Error fetching drivers: $e');
      return [];
    }
  }

  /// Creates or updates a driver based on phone number.
  Future<void> saveDriver(DriverModel driver) async {
    try {
      final data = driver.toMap()..addAll({'role': 'driver'});

      // Check if driver exists with same phone
      final snapshot = await _firestoreService.usersCollection
          .where('phone', isEqualTo: driver.phoneNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Update existing
        await snapshot.docs.first.reference.update(data);
      } else {
        // Check by name just in case
        final nameSnapshot = await _firestoreService.usersCollection
            .where('name', isEqualTo: driver.name)
            .limit(1)
            .get();
        if (nameSnapshot.docs.isNotEmpty) {
          await nameSnapshot.docs.first.reference.update(data);
        } else {
           // Create new
          await _firestoreService.usersCollection.doc(driver.driverId).set(data);
        }
      }
    } catch (e) {
      print('Error saving driver: $e');
      rethrow;
    }
  }

  /// Deletes a driver.
  Future<void> deleteDriver(String driverId) async {
    try {
      await _firestoreService.usersCollection.doc(driverId).delete();
    } catch (e) {
      print('Error deleting driver: $e');
      rethrow;
    }
  }

}
