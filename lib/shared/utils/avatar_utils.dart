import 'dart:convert';
import 'package:flutter/material.dart';

/// Safely returns an [ImageProvider] for network URLs, base64 data URIs, or local files.
ImageProvider? getAvatarImageProvider(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final clean = url.trim();

  // Base64 Data URI
  if (clean.startsWith('data:image/') || clean.startsWith('data:')) {
    final base64Str = clean.contains(',') ? clean.split(',').last : clean;
    try {
      final bytes = base64Decode(base64Str.trim());
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // HTTP / HTTPS Web URL
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }

  return null;
}
