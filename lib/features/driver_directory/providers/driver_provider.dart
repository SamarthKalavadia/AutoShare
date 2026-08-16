import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../repositories/driver_repository.dart';

final driverDirectoryRepositoryProvider = Provider<DriverDirectoryRepository>((
  ref,
) {
  return DriverDirectoryRepository();
});

final driverDirectoryListProvider = FutureProvider<List<DriverDirectoryModel>>((
  ref,
) async {
  final repository = ref.watch(driverDirectoryRepositoryProvider);
  return repository.fetchDrivers();
});
