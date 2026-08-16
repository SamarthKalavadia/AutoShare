import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';

class DriverDirectoryRepository {
  final FirebaseFirestore _firestore;

  DriverDirectoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _directoryCollection =>
      _firestore.collection('driver_directory');

  /// Fetches drivers from the `driver_directory` Firestore collection.
  /// Seeds the collection with default records if it is empty.
  Future<List<DriverDirectoryModel>> fetchDrivers() async {
    try {
      var snapshot = await _directoryCollection.get();

      if (snapshot.docs.isEmpty) {
        // Seed database with default 7 drivers
        await _seedDefaultDrivers();
        snapshot = await _directoryCollection.get();
      }

      final List<DriverDirectoryModel> drivers = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        drivers.add(DriverDirectoryModel.fromMap(data, doc.id));
      }
      return drivers;
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      rethrow;
    }
  }

  /// Seeds default drivers into Firestore
  Future<void> _seedDefaultDrivers() async {
    final List<Map<String, String>> defaultDrivers = [
      {'Name': 'Vijay', 'Phone': '7874512833'},
      {'Name': 'Raju', 'Phone': '7990496596'},
      {'Name': 'Kanti', 'Phone': '7990697077'},
      {'Name': 'Sandip', 'Phone': '9904264835'},
      {'Name': 'Ghanshyam', 'Phone': '9824866946'},
      {'Name': 'Rahul', 'Phone': '9727935297'},
      {'Name': 'Dashrath', 'Phone': '9265134763'},
    ];

    for (final driver in defaultDrivers) {
      final id = driver['Name']!.toLowerCase();
      await _directoryCollection.doc(id).set(driver);
    }
  }
}
