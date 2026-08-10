import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({required this.placeId, required this.mainText, required this.secondaryText});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'];
    return PlaceSuggestion(
      placeId: json['place_id'] as String,
      mainText: structured['main_text'] as String,
      secondaryText: structured['secondary_text'] as String,
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  PlaceDetails({required this.placeId, required this.name, required this.address, required this.lat, required this.lng});

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetails(
      placeId: json['place_id'] as String,
      name: json['name'] as String,
      address: json['formatted_address'] as String,
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
    );
  }
}

class PlacesService {
  // Insert your Google Places API key via --dart-define=GOOGLE_PLACES_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');
  static const String _autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';

  Future<List<PlaceSuggestion>> autocomplete(String query, {String sessionToken = ''}) async {
    final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: {
      'input': query,
      'key': _apiKey,
      'sessiontoken': sessionToken,
      'components': 'country:in', // restrict to India for example; adjust as needed
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = data['predictions'] as List<dynamic>;
        return predictions.map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Places API error: ${data['status']}');
      }
    } else {
      throw Exception('Network error: ${response.statusCode}');
    }
  }

  Future<PlaceDetails> getPlaceDetails(String placeId, {String sessionToken = ''}) async {
    final uri = Uri.parse(_detailsUrl).replace(queryParameters: {
      'place_id': placeId,
      'key': _apiKey,
      'sessiontoken': sessionToken,
      'fields': 'place_id,name,formatted_address,geometry',
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return PlaceDetails.fromJson(data['result'] as Map<String, dynamic>);
      } else {
        throw Exception('Place details error: ${data['status']}');
      }
    } else {
      throw Exception('Network error: ${response.statusCode}');
    }
  }
}
