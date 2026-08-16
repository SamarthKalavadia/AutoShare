import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final usersCol = firestore.collection('users');

  final updates = {
    'Vijaybhai': '7874512833',
    'Rajubhai': '7990496596',
    'Kantibhai': '7990697077',
    'Sandipbhai': '9904264835',
    'Ghanshyambhai': '9824866946',
    'Rahul': '9727935297',
    'Dashrathbhai': '9265134763',
  };

  print('Starting Firestore driver updates...');

  try {
    for (final entry in updates.entries) {
      final name = entry.key;
      final newPhone = entry.value;

      final qs = await usersCol.where('name', isEqualTo: name).get();
      if (qs.docs.isNotEmpty) {
        for (var doc in qs.docs) {
          await doc.reference.update({
            'phoneNumber': newPhone,
          });
          print('✅ Updated driver "$name" (${doc.id}) to phone: $newPhone');
        }
      } else {
        print('⚠️ Could not find existing driver document for "$name".');
      }
    }
    print('✅ Finished Firestore driver updates.');
  } catch (e) {
    print('❌ Error updating drivers: $e');
  }

  // exit
  print('SCRIPT_COMPLETE');
}
