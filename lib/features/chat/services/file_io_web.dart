import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation — reads file bytes from a blob URL
Future<Uint8List?> readFileBytes(String path) async {
  return await readBlobAsBytes(path);
}

/// Delete a temp file — no-op on web
Future<void> deleteTempFile(String path) async {
  // no-op on web
}

/// Fetches bytes from a blob:// URL using XMLHttpRequest
Future<Uint8List?> readBlobAsBytes(String url) async {
  final completer = Completer<Uint8List?>();
  final xhr = html.HttpRequest();
  xhr.open('GET', url);
  xhr.responseType = 'arraybuffer';

  xhr.onLoad.listen((e) {
    if (xhr.status == 200) {
      final buffer = xhr.response as ByteBuffer;
      completer.complete(Uint8List.view(buffer));
    } else {
      completer.complete(null);
    }
  });

  xhr.onError.listen((e) => completer.complete(null));
  xhr.send();

  return completer.future;
}
