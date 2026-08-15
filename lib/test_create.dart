import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autoshare/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("STARTING TEST RIDE CREATE...");
  try {
    final userCred = await FirebaseAuth.instance.signInAnonymously();
    final uid = userCred.user?.uid ?? 'test_uid';
    print("Signed in anonymously as: $uid");

    final docRef = FirebaseFirestore.instance.collection('rides').doc();
    print("Attempting to write to ${docRef.path}");
    
    await docRef.set({
      'id': docRef.id,
      'driverId': uid,
      'boardingLocation': 'Test Location',
      'destination': 'Test Destination',
      'departureTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      'availableSeats': 1,
      'farePerSeat': 100.0,
      'vehicleNumber': '',
      'description': 'Test Ride',
      'isGirlsOnly': false,
      'status': 'active',
      'createdAt': Timestamp.now(),
      'driverName': 'Test Driver',
      'driverRating': 5.0,
      'estimatedDuration': '',
      'distance': '',
    });
        
    print("SUCCESS! Created test ride.");
  } catch (e) {
    print("FAILED TO CREATE RIDE! Error: $e");
  }
}
