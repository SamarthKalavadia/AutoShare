import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firestore_service.dart';
import '../../core/utils/result.dart';
import '../models/rating_model.dart';
import '../models/report_model.dart';

final ratingRepositoryProvider = Provider((ref) => RatingRepository());

class RatingRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore;

  RatingRepository({
    FirestoreService? firestoreService,
    FirebaseFirestore? firestore,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<void>> submitRating(RatingModel rating) async {
    try {
      final docRef = _firestoreService.ratingsCollection.doc();
      final ratingData = rating.copyWith(ratingId: docRef.id).toMap();

      if (rating.rating == 0) {
        // Skipped rating, just save it so we don't prompt again
        await docRef.set(ratingData);
        return const Success(null);
      }

      final userRef = _firestoreService.usersCollection.doc(rating.toUserId);

      // Use a transaction to safely update average rating and total reviews
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception("User not found");
        }
        
        final userData = userDoc.data() as Map<String, dynamic>;
        final int currentTotal = userData['totalReviews'] as int? ?? 0;
        final double currentAverage = (userData['averageRating'] as num?)?.toDouble() ?? 0.0;
        
        final newTotal = currentTotal + 1;
        final newAverage = ((currentAverage * currentTotal) + rating.rating) / newTotal;
        
        transaction.set(docRef, ratingData);
        transaction.update(userRef, {
          'totalReviews': newTotal,
          'averageRating': newAverage,
        });
      });

      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to submit rating', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  Future<bool> hasRated(String rideId, String fromUserId, String toUserId) async {
    final snapshot = await _firestoreService.ratingsCollection
        .where('rideId', isEqualTo: rideId)
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<RatingModel>> streamRatingsForUser(String userId) {
    return _firestoreService.ratingsCollection
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RatingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .where((r) => r.rating > 0)
              .toList();
          list.sort((a, b) {
            final cmp = b.rating.compareTo(a.rating);
            if (cmp != 0) return cmp;
            return b.createdAt.compareTo(a.createdAt);
          });
          return list;
        });
  }

  Future<Result<void>> reportUser(ReportModel report) async {
    try {
      final docRef = _firestoreService.reportsCollection.doc();
      final reportData = report.copyWith(reportId: docRef.id).toMap();
      await docRef.set(reportData);
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to submit report', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }

  Future<Result<void>> blockUser(String currentUserId, String userToBlockId) async {
    try {
      await _firestoreService.usersCollection.doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([userToBlockId])
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(e.message ?? 'Failed to block user', FirestoreException(e.code));
    } catch (e) {
      return Failure('An unexpected error occurred.', Exception(e.toString()));
    }
  }
}
