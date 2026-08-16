import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/rating_model.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../core/utils/result.dart';

final userProfileProvider = FutureProvider.family<UserModel, String>((
  ref,
  userId,
) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final result = await userRepo.getUser(userId);
  if (result is Success<UserModel>) {
    return result.data;
  } else if (result is Failure<UserModel>) {
    throw Exception((result).message);
  }
  throw Exception('Unknown error fetching user');
});

final userRatingsProvider = StreamProvider.family<List<RatingModel>, String>((
  ref,
  userId,
) {
  final ratingRepo = ref.watch(ratingRepositoryProvider);
  return ratingRepo.streamRatingsForUser(userId);
});
