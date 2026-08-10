import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/maps_config.dart';
import 'package:geolocator/geolocator.dart';

/// Model representing a place prediction from the Google Places Autocomplete API.
class PlacePrediction {
  final String placeId;
  final String description;
  final String primaryText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.primaryText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      primaryText: structured['main_text'] as String? ?? '',
      secondaryText: structured['secondary_text'] as String? ?? '',
    );
  }

  PlacePrediction copyWith({double? latitude, double? longitude}) {
    return PlacePrediction(
      placeId: placeId,
      description: description,
      primaryText: primaryText,
      secondaryText: secondaryText,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Service that interacts with Google Maps Platform APIs.
class LocationService {
  // Cache for place details to avoid repeated network calls.
  static final Map<String, PlacePrediction> _detailsCache = {};

  /// Fetch autocomplete predictions for a given query.
  /// Returns at most 5 predictions for performance.
  static Future<List<PlacePrediction>> fetchPredictions(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
    final response = await http.post(
      uri,
      headers: {
        'X-Goog-Api-Key': MapsConfig.googleMapsApiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'input': query.trim(),
        'includedRegionCodes': ['IN'],
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      if (response.statusCode == 403) {
        throw HttpException('OVER_QUERY_LIMIT or REQUEST_DENIED');
      }
      throw HttpException(
          'Autocomplete request failed: HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];

    return suggestions.take(5).map((e) {
      final suggestion = e as Map<String, dynamic>;
      final prediction = suggestion['placePrediction'] as Map<String, dynamic>? ?? {};
      final placeId = prediction['place'] as String? ?? prediction['placeId'] as String? ?? '';
      
      final textObj = prediction['text'] as Map<String, dynamic>? ?? {};
      final description = textObj['text'] as String? ?? '';

      final structuredFormat = prediction['structuredFormat'] as Map<String, dynamic>? ?? {};
      final mainTextObj = structuredFormat['mainText'] as Map<String, dynamic>? ?? {};
      final secondaryTextObj = structuredFormat['secondaryText'] as Map<String, dynamic>? ?? {};
      
      final primaryText = mainTextObj['text'] as String? ?? description;
      final secondaryText = secondaryTextObj['text'] as String? ?? '';

      return PlacePrediction(
        placeId: placeId,
        description: description,
        primaryText: primaryText,
        secondaryText: secondaryText,
      );
    }).toList();
  }

  /// Retrieve full place details including geometry (lat/lng).
  static Future<PlacePrediction> fetchPlaceDetails(String placeId) async {
    if (_detailsCache.containsKey(placeId)) return _detailsCache[placeId]!;

    final uri = Uri.https('places.googleapis.com', '/v1/places/$placeId');
    final response = await http.get(
      uri,
      headers: {
        'X-Goog-Api-Key': MapsConfig.googleMapsApiKey,
        'X-Goog-FieldMask': 'id,formattedAddress,displayName,location',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw HttpException('Place Details request failed: HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    final location = data['location'] as Map<String, dynamic>? ?? {};
    final displayNameObj = data['displayName'] as Map<String, dynamic>? ?? {};

    final prediction = PlacePrediction(
      placeId: data['id'] as String? ?? placeId,
      description: data['formattedAddress'] as String? ?? displayNameObj['text'] as String? ?? '',
      primaryText: displayNameObj['text'] as String? ?? '',
      secondaryText: data['formattedAddress'] as String? ?? '',
      latitude: (location['latitude'] as num?)?.toDouble(),
      longitude: (location['longitude'] as num?)?.toDouble(),
    );

    _detailsCache[placeId] = prediction;
    return prediction;
  }

  /// Reverse geocode coordinates to a human-readable address.
  static Future<PlacePrediction> reverseGeocode(double lat, double lng) async {
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': MapsConfig.googleMapsApiKey,
      'language': 'en',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw HttpException('Reverse Geocode failed: HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? '';

    if (status != 'OK') {
      throw HttpException('Reverse Geocode error: $status');
    }

    final results = data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) throw HttpException('Reverse Geocode returned no results.');

    final best = results.first as Map<String, dynamic>;
    final placeId = best['place_id'] as String? ?? '';
    final formatted = best['formatted_address'] as String? ?? '';
    final location =
        (best['geometry'] as Map<String, dynamic>?)?['location']
            as Map<String, dynamic>? ??
            {};
    final components = best['address_components'] as List<dynamic>? ?? [];
    final primaryText = components.isNotEmpty
        ? (components.first as Map<String, dynamic>)['long_name'] as String? ??
            formatted
        : formatted;

    final prediction = PlacePrediction(
      placeId: placeId,
      description: formatted,
      primaryText: primaryText,
      secondaryText: formatted,
      latitude: (location['lat'] as num?)?.toDouble(),
      longitude: (location['lng'] as num?)?.toDouble(),
    );

    _detailsCache[placeId] = prediction;
    return prediction;
  }

  /// Get device current location and reverse-geocode it.
  static Future<PlacePrediction> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PermissionException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw PermissionException('Location permission permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return reverseGeocode(position.latitude, position.longitude);
  }
}

class HttpException implements Exception {
  final String message;
  const HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => 'PermissionException: $message';
}
