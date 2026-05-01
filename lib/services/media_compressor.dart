import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaCompressor {
  
  /// 📸 이미지 압축 (화질은 살리고 용량은 1/10 토막!)
  static Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
      
    } catch (e) {
      print('DEBUG [COMPRESS]: 이미지 압축 실패 - $e');
      return file;
    }
  }

  /// 🎬 비디오 압축 + 오디오 완전 삭제 (6초 짧은 영상 전용)
  static Future<File?> compressVideo(File file) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: false, // 🔇 소리 완전 삭제!
      );

      if (mediaInfo == null || mediaInfo.file == null) return null;
      return mediaInfo.file;

    } catch (e) {
      print('DEBUG [COMPRESS]: 영상 압축 실패 - $e');
      return file; // 압축 실패해도 원본으로 진행
    }
  }

  /// 🖼️ 비디오 썸네일 생성 (첫 프레임)
  static Future<File?> generateThumbnail(String videoPath) async {
    try {
      final thumbFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 50,
        position: -1, // 첫 프레임
      );
      return thumbFile;
    } catch (e) {
      print('DEBUG [THUMBNAIL]: 썸네일 생성 실패 - $e');
      return null;
    }
  }

  /// ✂️ 비디오 트림 + 압축 + 오디오 삭제 (올인원!)
  static Future<File?> trimAndCompress(File file, int startMs, int durationMs) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        startTime: startMs ~/ 1000,     // 초 단위로 변환
        duration: durationMs ~/ 1000,   // 초 단위로 변환
        deleteOrigin: false,
        includeAudio: false, // 🔇 소리 완전 삭제!
      );

      if (mediaInfo == null || mediaInfo.file == null) return null;
      return mediaInfo.file;

    } catch (e) {
      print('DEBUG [TRIM]: 영상 트림+압축 실패 - $e');
      return file; // 실패 시 원본 반환
    }
  }
}
