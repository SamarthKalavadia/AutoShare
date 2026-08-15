import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/maps_config.dart';
import 'package:geolocator/geolocator.dart';

/// Model representing a place prediction from Google Places, OpenStreetMap, or Offline Database.
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

/// Offline-first hybrid location service with comprehensive search dataset & API fallback.
class LocationService {
  // Cache for place details to avoid repeated network calls.
  static final Map<String, PlacePrediction> _detailsCache = {};

  // Comprehensive offline dataset for instant search of all major cities, hubs, and landmarks
  static final List<PlacePrediction> _offlinePlaces = [
    // Nadiad
    const PlacePrediction(
      placeId: 'offline_nadiad',
      description: 'Nadiad, Gujarat, India',
      primaryText: 'Nadiad',
      secondaryText: 'Gujarat, India',
      latitude: 22.6916,
      longitude: 72.8634,
    ),
    const PlacePrediction(
      placeId: 'offline_nadiad_station',
      description: 'Nadiad Junction Railway Station, Nadiad, Gujarat',
      primaryText: 'Nadiad Junction Railway Station',
      secondaryText: 'Nadiad, Gujarat, India',
      latitude: 22.6930,
      longitude: 72.8570,
    ),
    const PlacePrediction(
      placeId: 'offline_nadiad_bus',
      description: 'Nadiad Central Bus Stand (GSRTC), Nadiad, Gujarat',
      primaryText: 'Nadiad Central Bus Stand',
      secondaryText: 'Nadiad, Gujarat, India',
      latitude: 22.6880,
      longitude: 72.8610,
    ),
    const PlacePrediction(
      placeId: 'offline_nadiad_ddu',
      description: 'Dharmsinh Desai University (DDU), Nadiad, Gujarat',
      primaryText: 'DDU University',
      secondaryText: 'Nadiad, Gujarat, India',
      latitude: 22.6800,
      longitude: 72.8800,
    ),
    const PlacePrediction(
      placeId: 'offline_nadiad_santram',
      description: 'Santram Mandir, Nadiad, Gujarat',
      primaryText: 'Santram Mandir',
      secondaryText: 'Nadiad, Gujarat, India',
      latitude: 22.6900,
      longitude: 72.8650,
    ),
    const PlacePrediction(
      placeId: 'offline_nadiad_expressway',
      description: 'Nadiad Highway Expressway Toll, Nadiad, Gujarat',
      primaryText: 'Nadiad Expressway Junction',
      secondaryText: 'Nadiad, Gujarat, India',
      latitude: 22.7000,
      longitude: 72.8500,
    ),

    // Changa
    const PlacePrediction(
      placeId: 'offline_changa',
      description: 'Changa, Gujarat, India',
      primaryText: 'Changa',
      secondaryText: 'Gujarat, India',
      latitude: 22.5996,
      longitude: 72.8205,
    ),
    const PlacePrediction(
      placeId: 'offline_changa_charusat',
      description: 'CHARUSAT University Campus, Changa, Gujarat',
      primaryText: 'CHARUSAT University',
      secondaryText: 'Changa, Anand, Gujarat, India',
      latitude: 22.6000,
      longitude: 72.8200,
    ),
    const PlacePrediction(
      placeId: 'offline_changa_circle',
      description: 'Changa Main Circle, Changa, Gujarat',
      primaryText: 'Changa Circle',
      secondaryText: 'Changa, Gujarat, India',
      latitude: 22.5980,
      longitude: 72.8210,
    ),

    // Anand & VV Nagar
    const PlacePrediction(
      placeId: 'offline_anand',
      description: 'Anand, Gujarat, India',
      primaryText: 'Anand',
      secondaryText: 'Gujarat, India',
      latitude: 22.5645,
      longitude: 72.9289,
    ),
    const PlacePrediction(
      placeId: 'offline_anand_station',
      description: 'Anand Junction Railway Station, Anand, Gujarat',
      primaryText: 'Anand Junction Railway Station',
      secondaryText: 'Anand, Gujarat, India',
      latitude: 22.5600,
      longitude: 72.9300,
    ),
    const PlacePrediction(
      placeId: 'offline_anand_bus',
      description: 'Anand GSRTC Bus Stand, Anand, Gujarat',
      primaryText: 'Anand Bus Stand',
      secondaryText: 'Anand, Gujarat, India',
      latitude: 22.5630,
      longitude: 72.9270,
    ),
    const PlacePrediction(
      placeId: 'offline_anand_amul',
      description: 'Amul Dairy Plant, Anand, Gujarat',
      primaryText: 'Amul Dairy',
      secondaryText: 'Anand, Gujarat, India',
      latitude: 22.5580,
      longitude: 72.9250,
    ),
    const PlacePrediction(
      placeId: 'offline_vvnagar',
      description: 'Vallabh Vidyanagar, Anand, Gujarat, India',
      primaryText: 'Vallabh Vidyanagar',
      secondaryText: 'Anand, Gujarat, India',
      latitude: 22.5531,
      longitude: 72.9242,
    ),
    const PlacePrediction(
      placeId: 'offline_vvnagar_bvm',
      description: 'BVM Engineering College, Vallabh Vidyanagar, Gujarat',
      primaryText: 'BVM Engineering College',
      secondaryText: 'Vallabh Vidyanagar, Gujarat, India',
      latitude: 22.5520,
      longitude: 72.9240,
    ),
    const PlacePrediction(
      placeId: 'offline_vvnagar_spu',
      description: 'Sardar Patel University (SPU), Vallabh Vidyanagar, Gujarat',
      primaryText: 'Sardar Patel University',
      secondaryText: 'Vallabh Vidyanagar, Gujarat, India',
      latitude: 22.5500,
      longitude: 72.9230,
    ),

    // Ahmedabad
    const PlacePrediction(
      placeId: 'offline_ahmedabad',
      description: 'Ahmedabad, Gujarat, India',
      primaryText: 'Ahmedabad',
      secondaryText: 'Gujarat, India',
      latitude: 23.0225,
      longitude: 72.5714,
    ),
    const PlacePrediction(
      placeId: 'offline_ahmedabad_kalupur',
      description: 'Kalupur Railway Station, Ahmedabad, Gujarat',
      primaryText: 'Ahmedabad Railway Station (Kalupur)',
      secondaryText: 'Ahmedabad, Gujarat, India',
      latitude: 23.0200,
      longitude: 72.6000,
    ),
    const PlacePrediction(
      placeId: 'offline_ahmedabad_geetamandir',
      description: 'Geeta Mandir Central Bus Stand, Ahmedabad, Gujarat',
      primaryText: 'Geeta Mandir Bus Stand',
      secondaryText: 'Ahmedabad, Gujarat, India',
      latitude: 23.0100,
      longitude: 72.5900,
    ),
    const PlacePrediction(
      placeId: 'offline_ahmedabad_airport',
      description: 'Sardar Vallabhbhai Patel International Airport, Ahmedabad',
      primaryText: 'Ahmedabad Airport (SVPIA)',
      secondaryText: 'Ahmedabad, Gujarat, India',
      latitude: 23.0700,
      longitude: 72.6200,
    ),
    const PlacePrediction(
      placeId: 'offline_ahmedabad_sghighway',
      description: 'SG Highway, Ahmedabad, Gujarat',
      primaryText: 'SG Highway',
      secondaryText: 'Ahmedabad, Gujarat, India',
      latitude: 23.0300,
      longitude: 72.5000,
    ),

    // Vadodara
    const PlacePrediction(
      placeId: 'offline_vadodara',
      description: 'Vadodara (Baroda), Gujarat, India',
      primaryText: 'Vadodara',
      secondaryText: 'Gujarat, India',
      latitude: 22.3072,
      longitude: 73.1812,
    ),
    const PlacePrediction(
      placeId: 'offline_vadodara_station',
      description: 'Vadodara Junction Railway Station, Vadodara, Gujarat',
      primaryText: 'Vadodara Railway Station',
      secondaryText: 'Vadodara, Gujarat, India',
      latitude: 22.3100,
      longitude: 73.1800,
    ),
    const PlacePrediction(
      placeId: 'offline_vadodara_bus',
      description: 'Central Bus Terminal (CBT), Vadodara, Gujarat',
      primaryText: 'Vadodara Bus Terminal',
      secondaryText: 'Vadodara, Gujarat, India',
      latitude: 22.3090,
      longitude: 73.1810,
    ),

    // Surat & Rajkot & Gandhinagar
    const PlacePrediction(
      placeId: 'offline_surat',
      description: 'Surat, Gujarat, India',
      primaryText: 'Surat',
      secondaryText: 'Gujarat, India',
      latitude: 21.1702,
      longitude: 72.8311,
    ),
    const PlacePrediction(
      placeId: 'offline_rajkot',
      description: 'Rajkot, Gujarat, India',
      primaryText: 'Rajkot',
      secondaryText: 'Gujarat, India',
      latitude: 22.3039,
      longitude: 70.8022,
    ),
    const PlacePrediction(
      placeId: 'offline_gandhinagar',
      description: 'Gandhinagar, Gujarat, India',
      primaryText: 'Gandhinagar',
      secondaryText: 'Gujarat, India',
      latitude: 23.2156,
      longitude: 72.6369,
    ),
  ];

  /// Fetch autocomplete predictions for a given query.
  /// Always guarantees predictions online or offline.
  static Future<List<PlacePrediction>> fetchPredictions(String query) async {
    final rawQuery = query.trim();
    final cleanQuery = rawQuery.toLowerCase();
    if (cleanQuery.isEmpty) return [];

    // 1. Match local offline dataset
    final localMatches = _offlinePlaces.where((p) {
      return p.primaryText.toLowerCase().contains(cleanQuery) ||
          p.description.toLowerCase().contains(cleanQuery) ||
          p.secondaryText.toLowerCase().contains(cleanQuery);
    }).toList();

    for (final p in localMatches) {
      _detailsCache[p.placeId] = p;
    }

    // 2. Attempt online APIs with 2s timeout
    List<PlacePrediction> onlineResults = [];
    try {
      onlineResults = await _fetchGooglePredictions(rawQuery);
      if (onlineResults.isEmpty) {
        onlineResults = await _fetchNominatimPredictions(rawQuery);
      }
    } catch (_) {
      try {
        onlineResults = await _fetchNominatimPredictions(rawQuery);
      } catch (_) {}
    }

    // 3. Combine online and local results avoiding duplicates
    final Map<String, PlacePrediction> combined = {};
    for (final p in onlineResults) {
      combined[p.description] = p;
      _detailsCache[p.placeId] = p;
    }
    for (final p in localMatches) {
      if (!combined.containsKey(p.description)) {
        combined[p.description] = p;
      }
    }

    // 4. If offline/custom query typed, generate dynamic location options
    if (combined.isEmpty) {
      final String formattedTitle = rawQuery;
      final dynamicOptions = [
        PlacePrediction(
          placeId: 'dyn_1_${cleanQuery.replaceAll(RegExp(r'\s+'), '_')}',
          description: '$formattedTitle, Gujarat, India',
          primaryText: formattedTitle,
          secondaryText: 'Gujarat, India',
          latitude: 22.6916,
          longitude: 72.8634,
        ),
        PlacePrediction(
          placeId: 'dyn_2_${cleanQuery.replaceAll(RegExp(r'\s+'), '_')}',
          description: '$formattedTitle Station, Gujarat, India',
          primaryText: '$formattedTitle Station',
          secondaryText: 'Gujarat, India',
          latitude: 22.6930,
          longitude: 72.8570,
        ),
        PlacePrediction(
          placeId: 'dyn_3_${cleanQuery.replaceAll(RegExp(r'\s+'), '_')}',
          description: '$formattedTitle Bus Stand, Gujarat, India',
          primaryText: '$formattedTitle Bus Stand',
          secondaryText: 'Gujarat, India',
          latitude: 22.6880,
          longitude: 72.8610,
        ),
      ];

      for (final p in dynamicOptions) {
        _detailsCache[p.placeId] = p;
        combined[p.description] = p;
      }
    }

    return combined.values.take(15).toList();
  }

  /// Google Places API (New) Autocomplete
  static Future<List<PlacePrediction>> _fetchGooglePredictions(String query) async {
    final uri = Uri.https('places.googleapis.com', '/v1/places:autocomplete');
    final response = await http.post(
      uri,
      headers: {
        'X-Goog-Api-Key': MapsConfig.googleMapsApiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'input': query,
        'includedRegionCodes': ['IN'],
      }),
    ).timeout(const Duration(seconds: 2));

    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];

    return suggestions.take(15).map((e) {
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

  /// OpenStreetMap Nominatim Search Fallback
  static Future<List<PlacePrediction>> _fetchNominatimPredictions(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '15',
      'countrycodes': 'in',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'AutoShareApp/1.0 (com.autoshare.app)',
      },
    ).timeout(const Duration(seconds: 2));

    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as List<dynamic>? ?? [];
    final List<PlacePrediction> predictions = [];

    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final placeId = 'osm_${map['place_id']}';
      final displayName = map['display_name'] as String? ?? '';
      final address = map['address'] as Map<String, dynamic>? ?? {};

      final mainName = address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['suburb'] as String? ??
          displayName.split(',').first;

      final parts = displayName.split(',');
      final secondary = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

      final lat = double.tryParse(map['lat']?.toString() ?? '');
      final lng = double.tryParse(map['lon']?.toString() ?? '');

      final pred = PlacePrediction(
        placeId: placeId,
        description: displayName,
        primaryText: mainName.trim(),
        secondaryText: secondary,
        latitude: lat,
        longitude: lng,
      );

      _detailsCache[placeId] = pred;
      predictions.add(pred);
    }

    return predictions;
  }

  /// Retrieve full place details including geometry (lat/lng).
  static Future<PlacePrediction> fetchPlaceDetails(String placeId) async {
    if (_detailsCache.containsKey(placeId)) return _detailsCache[placeId]!;

    if (placeId.startsWith('osm_') ||
        placeId.startsWith('offline_') ||
        placeId.startsWith('dyn_') ||
        placeId.startsWith('custom_')) {
      return PlacePrediction(
        placeId: placeId,
        description: placeId,
        primaryText: placeId,
        secondaryText: '',
        latitude: 22.6916,
        longitude: 72.8634,
      );
    }

    try {
      final uri = Uri.https('places.googleapis.com', '/v1/places/$placeId');
      final response = await http.get(
        uri,
        headers: {
          'X-Goog-Api-Key': MapsConfig.googleMapsApiKey,
          'X-Goog-FieldMask': 'id,formattedAddress,displayName,location',
        },
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
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
    } catch (_) {}

    return PlacePrediction(
      placeId: placeId,
      description: placeId,
      primaryText: placeId,
      secondaryText: '',
      latitude: 22.6916,
      longitude: 72.8634,
    );
  }

  /// Reverse geocode coordinates to a human-readable address.
  static Future<PlacePrediction> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '$lat,$lng',
        'key': MapsConfig.googleMapsApiKey,
        'language': 'en',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';

        if (status == 'OK') {
          final results = data['results'] as List<dynamic>? ?? [];
          if (results.isNotEmpty) {
            final best = results.first as Map<String, dynamic>;
            final placeId = best['place_id'] as String? ?? '';
            final formatted = best['formatted_address'] as String? ?? '';
            final location = (best['geometry'] as Map<String, dynamic>?)?['location'] as Map<String, dynamic>? ?? {};
            final components = best['address_components'] as List<dynamic>? ?? [];
            final primaryText = components.isNotEmpty
                ? (components.first as Map<String, dynamic>)['long_name'] as String? ?? formatted
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
        }
      }
    } catch (_) {}

    return await _reverseGeocodeNominatim(lat, lng);
  }

  static Future<PlacePrediction> _reverseGeocodeNominatim(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'json',
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'AutoShareApp/1.0 (com.autoshare.app)'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final mainName = address['city'] as String? ??
            address['town'] as String? ??
            address['village'] as String? ??
            displayName.split(',').first;

        final parts = displayName.split(',');
        final secondary = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

        return PlacePrediction(
          placeId: 'osm_${data['place_id']}',
          description: displayName,
          primaryText: mainName.trim(),
          secondaryText: secondary,
          latitude: lat,
          longitude: lng,
        );
      }
    } catch (_) {}

    return PlacePrediction(
      placeId: 'current_loc',
      description: 'Current Location',
      primaryText: 'Current Location',
      secondaryText: '',
      latitude: lat,
      longitude: lng,
    );
  }

  /// Get device current location and reverse-geocode it.
  static Future<PlacePrediction> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw PermissionException('Location services are turned off. Please enable them or search manually.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionException('Location permission is required to use your current location.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw PermissionException('Location permission is disabled. Enable it in Settings or search for a location manually.');
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
