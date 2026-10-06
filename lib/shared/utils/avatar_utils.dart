import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Safely returns an [ImageProvider] for network URLs, base64 data URIs, raw base64, or local files.
ImageProvider? getAvatarImageProvider(String? url) {
  if (url == null || url.trim().isEmpty) return null;
  final clean = url.trim();

  // Base64 Data URI
  if (clean.startsWith('data:image/') || clean.startsWith('data:')) {
    final base64Str = clean.contains(',') ? clean.split(',').last : clean;
    try {
      final sanitized = base64.normalize(base64Str.replaceAll(RegExp(r'\s+'), ''));
      final bytes = base64Decode(sanitized);
      if (bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
    } catch (_) {
      return null;
    }
  }

  // HTTP / HTTPS Web URL
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }

  // Local File path (e.g. /data/user/0/..., /storage/emulated/0/...)
  // Exclude strings starting with /9j/ which are raw JPEG base64 strings
  if ((clean.startsWith('/') && !clean.startsWith('/9j/')) || clean.startsWith('file://')) {
    try {
      final filePath = clean.startsWith('file://') ? clean.substring(7) : clean;
      final file = File(filePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
  }

  // Raw Base64 string (e.g. JPEG starting with /9j/, PNG with iVBOR, or general base64)
  if (clean.length > 50) {
    try {
      final sanitized = base64.normalize(clean.replaceAll(RegExp(r'\s+'), ''));
      final bytes = base64Decode(sanitized);
      if (bytes.isNotEmpty) {
        return MemoryImage(bytes);
      }
    } catch (_) {
      return null;
    }
  }

  return null;
}

