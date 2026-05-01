import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaCompressor {
  
  /// 📸 1. 이미지 압축 (화질은 살리고 용량은 1/10 토막!)
  static Future<File?> compressImage(File file) async {
    try {
      // 임시 저장소 경로 가져오기
      final dir = await getTemporaryDirectory();
      // 원본과 이름이 안 겹치게 현재 시간으로 압축 파일명 생성
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,         // 화질 80% (사람 눈으로는 원본과 구분 불가, 용량은 대폭 감소)
        minWidth: 1080,      // 가로 최대 해상도 제한
        minHeight: 1080,     // 세로 최대 해상도 제한
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
      
    } catch (e) {
      print('DEBUG [COMPRESS]: 이미지 압축 실패 - $e');
      return file; // 압축 실패하면 튕기지 않고 일단 원본 파일 그대로 반환 (안전빵)
    }
  }

  /// 🎬 2. 비디오 압축 (서버 트래픽 폭탄 방지용)
  static Future<File?> compressVideo(File file) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: false, // 🚀 소리 완전 삭제! (사수님 지시)
      );

      if (mediaInfo == null || mediaInfo.file == null) return null;
      return mediaInfo.file;

    } catch (e) {
      print('DEBUG [COMPRESS]: 영상 압축 실패 - $e');
      return file;
    }
  }

  /// 🎬 3. 비디오 자르기 (사수님의 6초 룰! 전용 근육)
  static Future<File?> trimVideo(File file, int startMs, int durationMs) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        startTime: startMs ~/ 1000,
        duration: durationMs ~/ 1000,
        deleteOrigin: false,
        includeAudio: false, // 🚀 소리 완전 삭제! (사수님 지시)
      );

      if (mediaInfo == null || mediaInfo.file == null) return null;
      return mediaInfo.file;

    } catch (e) {
      print('DEBUG [TRIM]: 영상 자르기 실패 - $e');
      return file;
    }
  }
}
