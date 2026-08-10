import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../core/constants/cloudinary_constants.dart';
import '../core/utils/logger.dart';

class CloudinaryService {
  Future<String?> uploadImage(File imageFile) async {
    try {
      final mimeType = lookupMimeType(imageFile.path)?.split('/');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConstants.uploadUrl),
      );

      request.fields['upload_preset'] =
          CloudinaryConstants.uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: mimeType != null
              ? MediaType(mimeType[0], mimeType[1])
              : null,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(await response.stream.bytesToString());

        return responseData["secure_url"];
      }

      return null;
    } catch (e) {
      AppLogger.log("Cloudinary Upload Error: $e");
      return null;
    }
  }
}