import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_editor/video_editor.dart';
import '../services/media_compressor.dart';

class VideoEditScreen extends StatefulWidget {
  final File file;
  const VideoEditScreen({super.key, required this.file});

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  late VideoEditorController _controller;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController.file(
      widget.file,
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 6),
    )..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTrim() async {
    setState(() => _isExporting = true);
    
    try {
      final int startMs = _controller.startTrim.inMilliseconds;
      final int durationMs = (_controller.endTrim - _controller.startTrim).inMilliseconds;

      final File? trimmedFile = await MediaCompressor.trimVideo(
        widget.file, 
        startMs, 
        durationMs
      );

      if (mounted) {
        setState(() => _isExporting = false);
        if (trimmedFile != null) {
          Navigator.pop(context, trimmedFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('영상 편집에 실패했습니다.'))
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('영상 자르기 (6초)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          if (_controller.initialized)
            TextButton(
              onPressed: _isExporting ? null : _handleTrim,
              child: const Text('완료', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _controller.initialized
          ? Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: CropGridViewer.edit(
                          controller: _controller,
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        height: 160,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🚀 v3.0.0 정석 이름 'TrimSlider' 사용!
                            TrimSlider(
                              controller: _controller,
                              height: 60,
                            ),
                            const SizedBox(height: 10),
                            const Text('원하는 6초 구간을 선택하세요', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isExporting)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
  }
}
