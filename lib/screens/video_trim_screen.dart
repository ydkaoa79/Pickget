import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/media_compressor.dart';

class VideoTrimScreen extends StatefulWidget {
  final File file;
  const VideoTrimScreen({super.key, required this.file});

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isExporting = false;

  double _totalDurationMs = 1000;
  double _startMs = 0;
  double _endMs = 6000;
  static const double _maxDurationMs = 6000; // 6초 최대
  static const double _minDurationMs = 500;  // 0.5초 최소

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.file(widget.file);
    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.setVolume(0);

    final totalMs = _controller.value.duration.inMilliseconds.toDouble();
    setState(() {
      _isInitialized = true;
      _totalDurationMs = totalMs;
      _startMs = 0;
      _endMs = totalMs.clamp(0, _maxDurationMs);
    });

    _controller.play();
    _controller.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!mounted || !_isInitialized) return;
    final posMs = _controller.value.position.inMilliseconds.toDouble();

    // 선택 구간을 벗어나면 시작점으로 되돌리기
    if (posMs >= _endMs || posMs < _startMs) {
      _controller.seekTo(Duration(milliseconds: _startMs.toInt()));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleExport() async {
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final File? trimmedFile = await MediaCompressor.trimAndCompress(
        widget.file,
        _startMs.toInt(),
        (_endMs - _startMs).toInt(),
      );

      if (mounted) {
        setState(() => _isExporting = false);
        if (trimmedFile != null) {
          Navigator.pop(context, trimmedFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('영상 편집에 실패했습니다.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatMs(double ms) {
    final seconds = (ms / 1000).floor();
    final fraction = ((ms % 1000) / 100).floor();
    return '$seconds.${fraction}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '영상 자르기',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          if (_isInitialized && !_isExporting)
            TextButton(
              onPressed: _handleExport,
              child: const Text('완료', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
              ),
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Stack(
              children: [
                Column(
                  children: [
                    // 🎬 영상 미리보기
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.size.width / _controller.value.size.height,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    ),

                    // 🎛️ 하단 컨트롤 패널
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 재생/일시정지 + 시간 정보
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 재생 버튼
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (_controller.value.isPlaying) {
                                      _controller.pause();
                                    } else {
                                      _controller.seekTo(Duration(milliseconds: _startMs.toInt()));
                                      _controller.play();
                                    }
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(
                                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.cyanAccent,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                // 선택 구간 표시
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.content_cut, color: Colors.cyanAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatMs(_endMs - _startMs),
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 최대 6초 안내
                                Text(
                                  '최대 6.0s',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 시작/끝 시간 라벨
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatMs(_startMs),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatMs(_endMs),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 🎚️ 커스텀 Range Slider
                            SliderTheme(
                              data: SliderThemeData(
                                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                                activeTrackColor: Colors.cyanAccent,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                overlayColor: Colors.cyanAccent.withValues(alpha: 0.15),
                                thumbColor: Colors.cyanAccent,
                                trackHeight: 6,
                                rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
                                valueIndicatorColor: Colors.cyanAccent,
                                valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                showValueIndicator: ShowValueIndicator.onDrag,
                              ),
                              child: RangeSlider(
                                values: RangeValues(_startMs, _endMs),
                                min: 0,
                                max: _totalDurationMs,
                                divisions: (_totalDurationMs / 100).floor().clamp(1, 1000),
                                labels: RangeLabels(_formatMs(_startMs), _formatMs(_endMs)),
                                onChanged: (values) {
                                  double newStart = values.start;
                                  double newEnd = values.end;
                                  double selectionDuration = newEnd - newStart;

                                  // 최대 6초 제한
                                  if (selectionDuration > _maxDurationMs) {
                                    // 어느 쪽을 움직였는지 판단
                                    if ((newStart - _startMs).abs() > (newEnd - _endMs).abs()) {
                                      newEnd = newStart + _maxDurationMs;
                                      if (newEnd > _totalDurationMs) {
                                        newEnd = _totalDurationMs;
                                        newStart = newEnd - _maxDurationMs;
                                      }
                                    } else {
                                      newStart = newEnd - _maxDurationMs;
                                      if (newStart < 0) {
                                        newStart = 0;
                                        newEnd = _maxDurationMs;
                                      }
                                    }
                                  }

                                  // 최소 0.5초 제한
                                  if (newEnd - newStart < _minDurationMs) return;

                                  setState(() {
                                    _startMs = newStart;
                                    _endMs = newEnd;
                                  });

                                  // 슬라이더 조정 시 시작점으로 이동
                                  _controller.seekTo(Duration(milliseconds: newStart.toInt()));
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 프로그레스 바 (현재 재생 위치)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _endMs > _startMs
                                      ? ((_controller.value.position.inMilliseconds - _startMs) / (_endMs - _startMs)).clamp(0, 1)
                                      : 0,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation(Colors.cyanAccent.withValues(alpha: 0.5)),
                                  minHeight: 3,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 하단 안내 텍스트
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) => Opacity(
                                opacity: 0.3 + (_pulseController.value * 0.4),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swipe, color: Colors.white38, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      '양쪽 핸들을 드래그하여 구간을 선택하세요',
                                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 🔄 내보내기 중 오버레이
                if (_isExporting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
                          const SizedBox(height: 20),
                          const Text(
                            '영상을 다듬고 있어요...',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '소리 제거 · 압축 · 자르기',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
