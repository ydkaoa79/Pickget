import 'dart:io';
import 'package:dio/dio.dart';
import '../core/supabase_config.dart';

class CloudflareService {
  final Dio _dio = Dio();

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      String uploadUrl = CloudflareConfig.workerUrl;
      
      print('DEBUG [UPLOAD]: Attempting POST upload to $uploadUrl with filename: $fileName');

      // 🚀 POST 방식 + FormData로 포장해서 전송!
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
      );

      print('DEBUG [UPLOAD]: Server response -> ${response.statusCode}');

      if (response.statusCode == 200) {
        // 🎯 저장할 때는 CDN 주소로 리턴
        return '${CloudflareConfig.cdnUrl}$fileName';
      }
    } catch (e) {
      print('DEBUG [UPLOAD]: ERROR -> $e');
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
