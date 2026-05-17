import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moharek_app/core/config/app_config.dart';

// Safe platform check for File import
import 'dart:io' show File;

class WordPressUploadService {
  static const _storage = FlutterSecureStorage();

  static Future<String> _getSecretKey() async {
    try {
      final key = await _storage.read(key: 'wp_media_api_secret');
      return key ?? 'omarmahmoud23112002';
    } catch (e) {
      debugPrint('WordPressUploadService: Error reading secret key, falling back. Error: $e');
      return 'omarmahmoud23112002';
    }
  }

  /// Uploads a local file from a path (Mobile/Desktop only).
  static Future<String> uploadFile(String filePath, String fileName) async {
    final secretKey = await _getSecretKey();
    
    // Build URL with secret_key as query parameter to bypass CDN/Nginx header stripping
    final baseUri = Uri.parse(AppConfig.wordpressMediaUrl);
    final url = baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'secret_key': secretKey,
      },
    );

    final request = http.MultipartRequest('POST', url);
    
    // Set headers in multiple formats for maximum compatibility
    request.headers['X-Secret-Key'] = secretKey;
    request.headers['x-secret-key'] = secretKey;
    
    // Also include in multipart fields
    request.fields['secret_key'] = secretKey;

    // Platform-safe file addition
    if (!kIsWeb) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('WordPressUploadService: File does not exist at path: $filePath');
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );
    } else {
      throw UnsupportedError('WordPressUploadService: File path upload is not supported on web. Use uploadBytes.');
    }

    debugPrint('==================================================');
    debugPrint('🚀 [WORDPRESS UPLOAD STARTING]');
    debugPrint('📁 File Name: $fileName');
    debugPrint('🔗 API URL: ${AppConfig.wordpressMediaUrl}');
    debugPrint('==================================================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mediaUrl = data['url'] as String;
      
      debugPrint('==================================================');
      debugPrint('✅ [WORDPRESS UPLOAD SUCCESS]');
      debugPrint('📁 File Name: $fileName');
      debugPrint('🌎 Public URL: $mediaUrl');
      debugPrint('==================================================');
      
      return mediaUrl;
    } else {
      debugPrint('==================================================');
      debugPrint('❌ [WORDPRESS UPLOAD FAILED]');
      debugPrint('📁 File Name: $fileName');
      debugPrint('⚠️ Status Code: ${response.statusCode}');
      debugPrint('💥 Response Body: ${response.body}');
      debugPrint('==================================================');
      
      throw Exception('WordPressUploadService: Upload failed with status ${response.statusCode}: ${response.body}');
    }
  }

  /// Uploads raw binary bytes (Platform-safe, works on Web, Mobile, Desktop).
  static Future<String> uploadBytes(Uint8List bytes, String fileName, {String? mimeType}) async {
    final secretKey = await _getSecretKey();
    
    // Build URL with secret_key as query parameter to bypass CDN/Nginx header stripping
    final baseUri = Uri.parse(AppConfig.wordpressMediaUrl);
    final url = baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'secret_key': secretKey,
      },
    );

    final request = http.MultipartRequest('POST', url);
    
    // Set headers in multiple formats for maximum compatibility
    request.headers['X-Secret-Key'] = secretKey;
    request.headers['x-secret-key'] = secretKey;
    
    // Also include in multipart fields
    request.fields['secret_key'] = secretKey;

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    debugPrint('==================================================');
    debugPrint('🚀 [WORDPRESS UPLOAD STARTING]');
    debugPrint('📁 File Name: $fileName');
    debugPrint('🔗 API URL: ${AppConfig.wordpressMediaUrl}');
    debugPrint('==================================================');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final mediaUrl = data['url'] as String;
      
      debugPrint('==================================================');
      debugPrint('✅ [WORDPRESS UPLOAD SUCCESS]');
      debugPrint('📁 File Name: $fileName');
      debugPrint('🌎 Public URL: $mediaUrl');
      debugPrint('==================================================');
      
      return mediaUrl;
    } else {
      debugPrint('==================================================');
      debugPrint('❌ [WORDPRESS UPLOAD FAILED]');
      debugPrint('📁 File Name: $fileName');
      debugPrint('⚠️ Status Code: ${response.statusCode}');
      debugPrint('💥 Response Body: ${response.body}');
      debugPrint('==================================================');
      
      throw Exception('WordPressUploadService: Upload failed with status ${response.statusCode}: ${response.body}');
    }
  }
}
