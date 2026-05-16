import 'dart:io';
import 'package:flutter/foundation.dart';

/// Native (mobile/desktop) implementation — uses dart:io File
Future<Uint8List?> readFileBytes(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  } catch (e) {
    debugPrint('Error reading file: $e');
    return null;
  }
}

/// Delete a temp file on mobile/desktop
Future<void> deleteTempFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    debugPrint('Error deleting file: $e');
  }
}

Future<Uint8List?> readBlobAsBytes(String url) async {
  return null; // Blobs are web-only
}
