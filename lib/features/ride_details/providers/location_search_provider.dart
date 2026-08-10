import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/places_service.dart';

class LocationSearchState {
  final String query;
  final List<PlaceSuggestion> suggestions;
  final bool isLoading;
  final List<PlaceSuggestion> recent;

  const LocationSearchState({
    this.query = '',
    this.suggestions = const [],
    this.isLoading = false,
    this.recent = const [],
  });

  LocationSearchState copyWith({
    String? query,
    List<PlaceSuggestion>? suggestions,
    bool? isLoading,
    List<PlaceSuggestion>? recent,
  }) {
    return LocationSearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      recent: recent ?? this.recent,
    );
  }
}

class LocationSearchNotifier extends Notifier<LocationSearchState> {
  static const _recentKey = 'recent_locations';
  Timer? _debounce;
  final _service = PlacesService();
  final String _sessionToken = '';

  @override
  LocationSearchState build() {
    _loadRecent();
    return const LocationSearchState();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentKey) ?? [];
    final recent = raw.map((e) => PlaceSuggestion.fromJson(Map<String, dynamic>.from(jsonDecode(e)))).toList();
    state = state.copyWith(recent: recent);
  }

  Future<void> _saveRecent(List<PlaceSuggestion> recent) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = recent.map((e) => jsonEncode({
          'place_id': e.placeId,
          'structured_formatting': {
            'main_text': e.mainText,
            'secondary_text': e.secondaryText,
          },
        })).toList();
    await prefs.setStringList(_recentKey, raw);
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.isEmpty) {
      state = state.copyWith(suggestions: [], isLoading: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      state = state.copyWith(isLoading: true);
      try {
        final results = await _service.autocomplete(query, sessionToken: _sessionToken);
        state = state.copyWith(suggestions: results, isLoading: false);
      } catch (_) {
        state = state.copyWith(suggestions: [], isLoading: false);
      }
    });
  }

  Future<PlaceDetails?> selectSuggestion(PlaceSuggestion suggestion) async {
    try {
      final details = await _service.getPlaceDetails(suggestion.placeId, sessionToken: _sessionToken);
      // Update recent list (max 5)
      final List<PlaceSuggestion> updatedRecent = [suggestion, ...state.recent.where((e) => e.placeId != suggestion.placeId)].take(5).toList();
      state = state.copyWith(recent: updatedRecent);
      await _saveRecent(updatedRecent);
      // Reset query and suggestions
      state = state.copyWith(query: '', suggestions: [], isLoading: false);
      return details;
    } catch (_) {
      return null;
    }
  }
}

final locationSearchProvider = NotifierProvider<LocationSearchNotifier, LocationSearchState>(LocationSearchNotifier.new);
