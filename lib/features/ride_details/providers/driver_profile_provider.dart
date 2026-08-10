import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/providers.dart';
import '../../../core/utils/result.dart';

final userProfileProvider = FutureProvider.autoDispose.family<UserModel, String>((ref, uid) async {
  final repo = ref.watch(userRepositoryProvider);
  final result = await repo.getUser(uid);
  if (result is Success<UserModel>) {
    return result.data;
  } else {
    throw Exception((result as Failure).message);
  }
});
