import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver_model.dart';
import '../repositories/driver_repository.dart';

// ── Repository provider ─────────────────────────────────────────────────────
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return const DriverRepository();
});

// ── Raw driver list ──────────────────────────────────────────────────────────
final driversProvider = FutureProvider<List<DriverModel>>((ref) {
  return ref.watch(driverRepositoryProvider).fetchDrivers();
});

// ── Search + filter state ────────────────────────────────────────────────────
enum DriverFilter { all, available, verified }

class DriverSearchState {
  final String query;
  final DriverFilter filter;

  const DriverSearchState({
    this.query = '',
    this.filter = DriverFilter.all,
  });

  DriverSearchState copyWith({String? query, DriverFilter? filter}) {
    return DriverSearchState(
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

class DriverSearchNotifier extends Notifier<DriverSearchState> {
  @override
  DriverSearchState build() => const DriverSearchState();

  void updateQuery(String q) => state = state.copyWith(query: q);
  void updateFilter(DriverFilter f) => state = state.copyWith(filter: f);
}

final driverSearchProvider = NotifierProvider<DriverSearchNotifier, DriverSearchState>(
  DriverSearchNotifier.new,
);

// ── Filtered driver list (derived) ───────────────────────────────────────────
final filteredDriversProvider = Provider<AsyncValue<List<DriverModel>>>((ref) {
  final allAsync = ref.watch(driversProvider);
  final search = ref.watch(driverSearchProvider);

  return allAsync.whenData((drivers) {
    var result = drivers;

    // Apply text search (name, area, city — case-insensitive)
    final q = search.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.area.toLowerCase().contains(q) ||
            d.city.toLowerCase().contains(q);
      }).toList();
    }

    // Apply chip filter
    switch (search.filter) {
      case DriverFilter.all:
        break;
      case DriverFilter.available:
        result = result.where((d) => d.available).toList();
      case DriverFilter.verified:
        result = result.where((d) => d.verified).toList();
    }

    return result;
  });
});
