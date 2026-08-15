import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autoshare/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("STARTING TEST QUERY...");
  try {
    final snapshot = await FirebaseFirestore.instance.collection('rides')
        .where('status', isEqualTo: 'active')
        .where('availableSeats', isGreaterThanOrEqualTo: 1)
        .get();
        
    print("SUCCESS! Found ${snapshot.docs.length} rides.");
  } catch (e) {
    print("FAILED! Error: $e");
  }
}
