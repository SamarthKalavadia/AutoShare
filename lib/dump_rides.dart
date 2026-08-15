import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:autoshare/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print("STARTING FIRESTORE DUMP...");
  try {
    final snapshot = await FirebaseFirestore.instance.collection('rides')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
        
    for (var doc in snapshot.docs) {
      print("--------------------------------------------------");
      print("DOC ID: ${doc.id}");
      final data = doc.data();
      for (var key in data.keys) {
        final val = data[key];
        if (val is Timestamp) {
          print("$key: ${val.toDate()} (Timestamp)");
        } else {
          print("$key: $val (${val.runtimeType})");
        }
      }
    }
  } catch (e) {
    print("FAILED! Error: $e");
  }
}
