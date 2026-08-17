import 'package:autoshare/services/location_service.dart';

void main() async {
  try {
    print('Testing reverseGeocode...');
    final prediction = await LocationService.reverseGeocode(
      22.5991247,
      72.8176373,
    );
    print(
      'Returned Prediction: ${prediction.latitude}, ${prediction.longitude}',
    );
  } catch (e) {
    print('Error: $e');
  }
}
