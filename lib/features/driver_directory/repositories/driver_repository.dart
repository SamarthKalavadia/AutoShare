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
    return const [
      DriverModel(
        driverId: 'bhupabhai',
        name: 'Bhupabhai',
        phoneNumber: '91 74054 08910\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 5.0,
      ),
      DriverModel(
        driverId: 'dashrathbhai',
        name: 'Dashrathbhai',
        phoneNumber: '91 92651 34763\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 5.0,
      ),
      DriverModel(
        driverId: 'ghanshyam',
        name: 'Ghanshyam',
        phoneNumber: '91 98248 66946\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.8,
      ),
      DriverModel(
        driverId: 'rahul',
        name: 'Rahul',
        phoneNumber: '91 97279 35297\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.7,
      ),
      DriverModel(
        driverId: 'rajubhai',
        name: 'Rajubhai',
        phoneNumber: '91 79904 96596\n+91 87994 71402\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.9,
      ),
      DriverModel(
        driverId: 'vishalbhai',
        name: 'Vishalbhai',
        phoneNumber: '91 93273 44904\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.8,
      ),
      DriverModel(
        driverId: 'vijaybhai',
        name: 'Vijaybhai',
        phoneNumber: '91 78745 12833\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.6,
      ),
      DriverModel(
        driverId: 'kantibhai',
        name: 'Kantibhai',
        phoneNumber: '91 79906 97077\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.8,
      ),
      DriverModel(
        driverId: 'sandipbhai',
        name: 'Sandipbhai',
        phoneNumber: '91 99042 64835\nHome',
        area: 'Changa',
        city: 'Anand',
        available: true,
        verified: true,
        rating: 4.7,
      ),
    ];
  }
}
