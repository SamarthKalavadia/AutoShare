import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized service for accessing all Firestore collections.
/// Prevents magic strings and typos when accessing collections.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Root collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get ridesCollection => _firestore.collection('rides');
  CollectionReference get rideRequestsCollection => _firestore.collection('rideRequests');
  CollectionReference get vehiclesCollection => _firestore.collection('vehicles');
  CollectionReference get chatsCollection => _firestore.collection('chats');
  CollectionReference get messagesCollection => _firestore.collection('messages');
  CollectionReference get notificationsCollection => _firestore.collection('notifications');
  CollectionReference get feedbackCollection => _firestore.collection('feedback');
  CollectionReference get reportsCollection => _firestore.collection('reports');
  CollectionReference get ratingsCollection => _firestore.collection('ratings');
  CollectionReference get appConfigCollection => _firestore.collection('appConfig');
}
