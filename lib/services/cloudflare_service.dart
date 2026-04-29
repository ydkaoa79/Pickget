import 'dart:io';
import 'package:dio/dio.dart';
import '../core/supabase_config.dart';

class CloudflareService {
  final Dio _dio = Dio();

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      // 1. Get Presigned URL from Worker (or just upload directly to Worker if it handles it)
      // Assuming the worker handles the upload directly for simplicity if it's a "PUT" uploader
      
      String uploadUrl = CloudflareConfig.workerUrl;
      if (!uploadUrl.endsWith('/')) uploadUrl += '/';
      
      print('Uploading to: $uploadUrl$fileName');
      final response = await _dio.put(
        '$uploadUrl$fileName',
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': _getContentType(fileName),
            'X-Access-Key': CloudflareConfig.accessKey, 
          },
        ),
      );
      print('Upload response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return '$uploadUrl$fileName';
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }

  String _getContentType(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
