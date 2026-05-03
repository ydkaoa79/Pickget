import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:io'; // 🚀 파일 처리를 위해 추가!
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/post_data.dart';
import '../models/comment_data.dart';
import '../core/app_state.dart';
import '../services/supabase_service.dart';
import '../screens/channel_screen.dart';

class PostView extends StatefulWidget {
  final PostData post;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onBookmark;
  final VoidCallback onNotInterested;
  final VoidCallback onDontRecommendChannel;
  final Function(String reason) onReport;
  final Function(int side) onVote;
  final Function(String postId) onDelete;
  final Function(String postId) onToggleHide;
  final VoidCallback? onProfileTap;

  const PostView({
    super.key, 
    required this.post, 
    required this.onLike, 
    required this.onFollow, 
    required this.onBookmark, 
    required this.onNotInterested, 
    required this.onDontRecommendChannel, 
    required this.onReport, 
    required this.onVote, 
    required this.onDelete,
    required this.onToggleHide,
    this.onProfileTap
  });
  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> with AutomaticKeepAliveClientMixin {
  double? _widthA; 
  int _votedSide = 0; 
  bool _isDragging = false;
  int _expandedSide = 0; 
  bool _showPointToast = false;
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _isDescAExpanded = false;
  bool _isDescBExpanded = false;
  bool _showAlreadySelectedToast = false;
  bool _showIsMeToast = false; // 🚫 본인 게시물 알림용 추가!
  bool _isSheetOpening = false;
  
  // 🎬 영상 재생 시스템 (v2.0 - 깔끔 재구축)
  VideoPlayerController? _controllerA;
  VideoPlayerController? _controllerB;
  bool _isInitializedA = false;
  bool _isInitializedB = false;
  bool _isInitializingA = false;
  bool _isInitializingB = false;
  int _playingSide = 0; // 0: 없음, 1: A재생중, 2: B재생중
  bool _isVisible = false;
  bool _videoAFinished = false;
  bool _videoBFinished = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(PostView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the post data reference changed or follows were updated, we need to refresh
    if (oldWidget.post.isFollowing != widget.post.isFollowing || oldWidget.post.id != widget.post.id) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    print('DEBUG: PostView State initialized for post_id: ${widget.post.id} (Ver. 1.0)');
    
    // 이전 투표 내역 불러오기
    _votedSide = gUserVotes[widget.post.id] ?? 0;
    
    _updateRemainingTime();
    _startTimer();

    // 🎬 영상 초기화는 화면에 보일 때(VisibilityDetector)에서 자동 처리!
  }

  // 🎬 모든 영상 리소스 해제
  void _releaseAllVideos() {
    _controllerA?.dispose();
    _controllerA = null;
    _isInitializedA = false;
    _isInitializingA = false;
    
    _controllerB?.dispose();
    _controllerB = null;
    _isInitializedB = false;
    _isInitializingB = false;
    
    _playingSide = 0;
    _videoAFinished = false;
    _videoBFinished = false;
  }

  // 🎬 영상 초기화 (네트워크 URL 직접 사용, 6초 영상이라 빠름)
  Future<void> _initVideo(String url, int side) async {
    if (!_isVideo(url)) return;
    if (side == 1 && (_isInitializedA || _isInitializingA)) return;
    if (side == 2 && (_isInitializedB || _isInitializingB)) return;

    if (side == 1) _isInitializingA = true;
    else _isInitializingB = true;

    try {
      print('DEBUG [VIDEO v2]: Side $side 초기화 시작 - $url');
      
      // 🚀 주소가 http로 시작하면 웹/모바일 상관없이 네트워크 재생 방식을 사용 (웹 에러 방지)
      VideoPlayerController controller;
      if (url.startsWith('http')) {
        print('DEBUG [VIDEO v2]: 네트워크 URL 감지 - networkUrl 사용: $url');
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        print('DEBUG [VIDEO v2]: 로컬 파일 감지 - file 사용');
        final file = File(url);
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0); // 🔇 음소거 (소리는 업로드 시 이미 삭제됨)
      
      // 🎬 영상 끝 감지 리스너
      controller.addListener(() {
        if (!mounted) return;
        final pos = controller.value.position;
        final dur = controller.value.duration;
        if (dur > Duration.zero && pos >= dur) {
          _onVideoFinished(side);
        }
      });

      if (!mounted || !_isVisible) {
        controller.dispose();
        if (side == 1) _isInitializingA = false;
        else _isInitializingB = false;
        return;
      }

      setState(() {
        if (side == 1) {
          _controllerA = controller;
          _isInitializedA = true;
          _isInitializingA = false;
        } else {
          _controllerB = controller;
          _isInitializedB = true;
          _isInitializingB = false;
        }
      });

      // 🎬 A가 준비되면 자동 재생 시작!
      if (side == 1 && _playingSide == 0) {
        _switchToSide(1);
      }
      
      print('DEBUG [VIDEO v2]: Side $side 초기화 완료!');
    } catch (e) {
      if (side == 1) _isInitializingA = false;
      else _isInitializingB = false;
      print('DEBUG [VIDEO v2]: Side $side 초기화 실패 - $e');
    }
  }

  // 🎬 영상 재생 완료 시 처리 (무한 루프 로직)
  void _onVideoFinished(int side) {
    if (!mounted) return;
    
    // 🎬 현재 어떤 사이드가 확장되어 있는지 체크
    double ratioA = (_widthA ?? (MediaQuery.of(context).size.width * 0.5)) / MediaQuery.of(context).size.width;

    if (side == 1) {
      print('DEBUG [VIDEO v2]: A 영상 종료');
      _controllerA?.pause();
      _controllerA?.seekTo(Duration.zero);
      
      if (ratioA >= 0.55) {
        // A가 확장된 상태라면 A 무한 반복
        _switchToSide(1);
      } else if (ratioA <= 0.45) {
        // B가 확장된 상태인데 A가 끝난 건 무시 (이미 B 재생 중일 것)
      } else {
        // 중앙 상태라면 B로 전환 (순차 루프)
        _switchToSide(2);
      }
    } else if (side == 2) {
      print('DEBUG [VIDEO v2]: B 영상 종료');
      _controllerB?.pause();
      _controllerB?.seekTo(Duration.zero);

      if (ratioA <= 0.45) {
        // B가 확장된 상태라면 B 무한 반복
        _switchToSide(2);
      } else if (ratioA >= 0.55) {
        // A가 확장된 상태인데 B가 끝난 건 무시
      } else {
        // 중앙 상태라면 다시 A로 전환 (순차 루프 A->B->A...)
        _switchToSide(1);
      }
    }
  }

  // 🎬 특정 사이드로 즉시 전환 (터치/슬라이드 시 호출)
  void _switchToSide(int side) {
    if (!mounted) return;
    
    if (side == 1 && _isInitializedA && _controllerA != null) {
      _controllerB?.pause(); // B는 보던 위치에서 일시정지
      // 🚀 보던 위치에서 Resume! (완전히 끝났을 때만 위에서 0초로 감)
      _controllerA!.play();
      setState(() => _playingSide = 1);
    } else if (side == 2 && _isInitializedB && _controllerB != null) {
      _controllerA?.pause(); // A는 보던 위치에서 일시정지
      // 🚀 보던 위치에서 Resume!
      _controllerB!.play();
      setState(() => _playingSide = 2);
    }
  }

  // 🎬 화면 진입 시 영상 시작
  void _onBecomeVisible() {
    if (_isVideo(widget.post.imageA)) {
      _initVideo(widget.post.imageA, 1);
    }
    if (_isVideo(widget.post.imageB)) {
      _initVideo(widget.post.imageB, 2);
    }
  }

  bool _isVideo(String url) {
    final path = url.toLowerCase();
    return path.endsWith('.mp4') || 
           path.endsWith('.mov') || 
           path.endsWith('.m4v') || 
           path.endsWith('.avi') || 
           path.endsWith('.wmv') || 
           path.endsWith('.mkv') || 
           path.endsWith('.3gp');
  }

  void _updateRemainingTime() {
    if (widget.post.isExpired) {
      _remainingSeconds = 0;
    } else {
      // Calculate remaining seconds based on absolute end time
      _remainingSeconds = widget.post.endTime.difference(DateTime.now()).inSeconds;
      if (_remainingSeconds < 0) _remainingSeconds = 0;
    }
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _updateRemainingTime();
        if (_remainingSeconds <= 0) {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controllerA?.dispose(); // 🎬 영상 리소스 해제 필수!
    _controllerB?.dispose();
    super.dispose();
  }

  bool get isMe {
    // 🆔 오직 주민번호(UUID) 하나로만 판단 (진짜 정석!)
    String nId(String? s) => (s ?? '').trim().toLowerCase();
    if (widget.post.uploaderInternalId != null && gUserInternalId != null) {
      if (nId(widget.post.uploaderInternalId) == nId(gUserInternalId)) return true;
    }
    // 예외/안전장치 (아이디 기반)
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    return normalized(widget.post.uploaderId) == normalized(gIdText) || 
           widget.post.uploaderId == 'me';
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('게시물 삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('이 게시물을 정말 삭제하시겠습니까? 삭제 후에는 복구할 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final String postId = widget.post.id; // UUID 문자열 그대로 사용

        // 🔥 [핵심] 외래 키 제약 때문에 연관 데이터 먼저 삭제 후 게시물 삭제!
        await Future.wait([
          SupabaseService.client.from('votes').delete().eq('post_id', postId),
          SupabaseService.client.from('comments').delete().eq('post_id', postId),
          SupabaseService.client.from('likes').delete().eq('post_id', postId),
          SupabaseService.client.from('bookmarks').delete().eq('post_id', postId),
        ]);

        // 연관 데이터 삭제 완료 후 게시물 삭제
        await SupabaseService.client.from('posts').delete().eq('id', postId);

        widget.onDelete(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 삭제되었습니다.')));
        }
      } catch (e) {
        debugPrint('Delete error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')));
        }
      }
    }
  }

  void _triggerPointToast() {
    setState(() => _showPointToast = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showPointToast = false);
    });
  }

  void _showAlreadySelectedMessage() {
    if (_showAlreadySelectedToast) return;
    setState(() => _showAlreadySelectedToast = true);
    Future.delayed(const Duration(milliseconds: 1000), () { // ⏱️ 시간 1초로 단축!
      if (mounted) setState(() => _showAlreadySelectedToast = false);
    });
  }

  void _showIsMeMessage() {
    if (_showIsMeToast) return;
    setState(() => _showIsMeToast = true);
    Future.delayed(const Duration(milliseconds: 1000), () { // ⏱️ 1초만 잔류!
      if (mounted) setState(() => _showIsMeToast = false);
    });
  }

  // 🛡️ 진짜 유효한 설명글인지 확인하는 판별기
  bool _isValidDescription(String? text) {
    if (text == null) return false;
    final clean = text.trim();
    if (clean.isEmpty) return false;
    // 의미 없는 기본값들이나 공백만 있는 경우 차단!
    final blackList = [
      "내용을 입력하세요", "내용 없음", "내용이 없습니다", "설명을 입력하세요",
      "선택지A", "선택지B", "선택지 A", "선택지 B"
    ];
    if (blackList.contains(clean)) return false;
    return clean.length > 1; // 최소 2글자는 되어야 함
  }

  void _onVote(int side) async {
    if (!gIsLoggedIn) {
      gShowLoginPopup?.call();
      return;
    }
    if (_votedSide != 0) return;
    
    // 🆔 오직 주민번호(UUID) 하나로만 판단 (진짜 정석!)
    String normalized(String? s) => (s ?? '').trim().toLowerCase();
    bool isMe = (widget.post.uploaderInternalId != null && gUserInternalId != null && 
                 normalized(widget.post.uploaderInternalId) == normalized(gUserInternalId));
    
    print('DEBUG [VOTE]: gUserInternalId=$gUserInternalId, postUploaderInternalId=${widget.post.uploaderInternalId}, isMe=$isMe');

    if (isMe) {
      _showIsMeMessage(); // 🚀 SnackBar 대신 전용 토스트 호출!
      HapticFeedback.vibrate(); // 진동으로 피드백!
      return;
    }

    // 💾 진짜 투표 및 포인트 적립 로직 (정석!)
    try {
      // 1. 투표 기록 저장
      await SupabaseService.client.from('votes').insert({
        'post_id': widget.post.id,
        'user_internal_id': gUserInternalId, // 🆔 주민번호 기록!
        'side': side,
      });

      // 2. 포인트 적립 (+10P)
      await SupabaseService.client.from('points_history').insert({
        'user_internal_id': gUserInternalId, // 🆔 주민번호 기록!
        'amount': 10,
        'description': '질문 참여 보너스',
      });

      // 3. 앱 내 점수 즉시 반영
      if (mounted) {
        setState(() {
          gUserPoints += 10;
        });
      }
      print('DEBUG [VOTE]: Real vote and 10P recorded. DB trigger will handle counts.');
    } catch (e) {
      print('DEBUG [VOTE]: Error recording vote: $e');
    }

    setState(() {
      _votedSide = side;
      gUserVotes[widget.post.id] = side; // 전역 상태에 즉시 반영
      
      int parseV(String s) {
        s = s.toLowerCase().replaceAll(',', '').trim();
        if (s.isEmpty) return 0;
        if (s.endsWith('k')) {
          return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
        }
        return int.tryParse(s) ?? 0;
      }
      int countA = parseV(widget.post.voteCountA);
      int countB = parseV(widget.post.voteCountB);
      
      if (side == 1) {
        countA++;
      } else {
        countB++;
      }
      
      int total = countA + countB;
      double perA = (countA / total) * 100;
      double perB = (countB / total) * 100;
      
      widget.post.voteCountA = countA.toString();
      widget.post.voteCountB = countB.toString();
      widget.post.percentA = "${perA.toStringAsFixed(0)}%";
      widget.post.percentB = "${perB.toStringAsFixed(0)}%";
    });

    widget.onVote(side);
    _triggerPointToast();
    HapticFeedback.heavyImpact();
  }

  bool get isExpired => _remainingSeconds <= 0 || widget.post.isExpired;

  void _onPanUpdate(DragUpdateDetails details, double sw) {
    setState(() { 
      _isDragging = true; 
      _widthA = ((_widthA ?? (sw * 0.5)) + details.delta.dx).clamp(sw * 0.2, sw * 0.8); 
      
      // 🎬 실시간 영상 전환 체크 (55% 이상 열리면 즉시 재생)
      double ratioA = _widthA! / sw;
      if (ratioA >= 0.55 && _playingSide != 1) {
        _switchToSide(1);
      } else if (ratioA <= 0.45 && _playingSide != 2) {
        _switchToSide(2);
      }
    });
  }

  void _onPanEnd(DragEndDetails details, double sw) {
    setState(() {
      _isDragging = false;
      double currentWidthA = _widthA ?? (sw * 0.5);
      
      if (currentWidthA > sw * 0.65) {
        if (!isExpired && _votedSide == 0) {
          _onVote(1);
        } else if (_votedSide != 0) {
          _showAlreadySelectedMessage();
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      } else if (currentWidthA < sw * 0.35) {
        if (!isExpired && _votedSide == 0) {
          _onVote(2);
        } else if (_votedSide != 0) {
          _showAlreadySelectedMessage();
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      } else {
        HapticFeedback.selectionClick();
      }

      _widthA = sw * 0.5; 
      _expandedSide = 0; 
    });
  }

  void _handleTap(TapUpDetails details, double sw) {
    if (_isDragging) return;
    double tapX = details.localPosition.dx;
    double currentWidthA = _widthA ?? (sw * 0.5);
    


    setState(() {
      if (tapX < currentWidthA) {
        // 왼쪽(A) 영역 클릭
        if (_expandedSide == 1) { 
          _expandedSide = 0; 
          _widthA = sw * 0.5; 
        } else { 
          _expandedSide = 1; 
          _widthA = sw * 0.8; // 🔙 0.85에서 0.8로 원복
        }
      } else {
        // 오른쪽(B) 영역 클릭
        if (_expandedSide == 2) { 
          _expandedSide = 0; 
          _widthA = sw * 0.5; 
        } else { 
          _expandedSide = 2; 
          _widthA = sw * 0.2; // 🔙 0.15에서 0.2로 원복
        }
      }
    });
    
    HapticFeedback.lightImpact();
    
    // 🎬 터치 시에도 즉시 전환 체크
    double ratioA = (_widthA ?? (sw * 0.5)) / sw;
    if (ratioA >= 0.55) {
      _switchToSide(1);
    } else if (ratioA <= 0.45) {
      _switchToSide(2);
    } else {
      if (_playingSide == 0) _switchToSide(1);
    }
  }



  String _formatTimer(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key('post_view_${widget.post.id}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final visible = info.visibleFraction > 0.5;
        if (_isVisible != visible) {
          _isVisible = visible;
          if (visible) {
            _onBecomeVisible();
          } else {
            _releaseAllVideos();
          }
        }
      },
      child: LayoutBuilder(
      builder: (context, constraints) {
        final sw = constraints.maxWidth;
        final sh = constraints.maxHeight;
        if (_widthA == null && sw > 0) _widthA = sw * 0.5;
        final currentWidthA = _widthA ?? (sw > 0 ? sw * 0.5 : 0.0);
        const double descWidth = 175.0;
        bool isExpired = _remainingSeconds <= 0;
        // UI update for remaining time

        return GestureDetector(
          onTapUp: (d) => _handleTap(d, sw),
          onPanUpdate: (d) => _onPanUpdate(d, sw),
          onPanEnd: (d) => _onPanEnd(d, sw),
          child: Stack(
            children: [
              Row(
                children: [
                  // 왼쪽 A 구역 (창문 역할)
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: currentWidthA, 
                    height: sh,
                    clipBehavior: Clip.hardEdge, // 창문 밖으로 나가는 건 자름
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      children: [
                        // 배경 블러 (창문 뒤에 꽉 참)
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: _buildMedia(1, widget.post.imageA, sw, thumbUrl: widget.post.thumbA, forceThumb: true),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        // 전경 이미지 (창문 너비에 상관없이 80% 크기로 고정되어 있음)
                        Center(
                          child: OverflowBox(
                            maxWidth: sw, // 🚀 80%에서 100%로 키워서 여백 없앰!
                            minWidth: sw,
                            child: _buildMedia(1, widget.post.imageA, sw, thumbUrl: widget.post.thumbA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽 B 구역 (창문 역할)
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: (sw - currentWidthA).clamp(0.0, sw), 
                    height: sh,
                    clipBehavior: Clip.hardEdge, // 창문 밖으로 나가는 건 자름
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      children: [
                        // 배경 블러
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: _buildMedia(2, widget.post.imageB, sw, thumbUrl: widget.post.thumbB, forceThumb: true),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        // 전경 이미지 (80% 크기로 고정)
                        Center(
                          child: OverflowBox(
                            maxWidth: sw, // 🚀 80%에서 100%로 키워서 여백 없앰!
                            minWidth: sw,
                            child: _buildMedia(2, widget.post.imageB, sw, thumbUrl: widget.post.thumbB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 2. 중앙 VS 아이콘
              AnimatedPositioned(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                curve: Curves.easeOutCubic, 
                left: (currentWidthA - 24).clamp(-24.0, sw - 24.0), 
                top: (sh / 2 - 24) - 20,
                child: IgnorePointer(
                  child: Container(
                    width: 48, height: 48, 
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.18)), 
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
                        child: const Center(child: Text('VS', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -1))),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(child: Container(color: Colors.black.withValues(alpha: 0.15))),
              Positioned(
                top: sh * 0.28 - 40, left: 15, 
                child: _bgLabel('A', _votedSide == 1 ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.45), 
                  isWinner: isExpired && ((double.tryParse(widget.post.percentA.replaceAll('%', '')) ?? 0) > (double.tryParse(widget.post.percentB.replaceAll('%', '')) ?? 0)))
              ),
              Positioned(
                top: sh * 0.28 - 40, right: 15, 
                child: _bgLabel('B', _votedSide == 2 ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.45), 
                  isWinner: isExpired && ((double.tryParse(widget.post.percentB.replaceAll('%', '')) ?? 0) > (double.tryParse(widget.post.percentA.replaceAll('%', '')) ?? 0)))
              ),
              Positioned(
                top: 140, left: 0, right: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 0), // 우측 여백을 0으로 하고 버튼 내부에서 처리
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const SizedBox(width: 20), // 좌측 여백 (대칭용)
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown, 
                                child: Text(
                                  widget.post.title.replaceAll('[종료] ', ''),
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: 26, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: -1.5, 
                                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 10, offset: const Offset(0, 2))]
                                  ), 
                                  maxLines: 1
                                )
                              )
                            )
                          ), 
                          const SizedBox(width: 20), // 우측 여백 (대칭용)
                        ]
                      )
                    ),
                    const SizedBox(height: 12),
                    Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.access_time, color: isExpired ? Colors.white38 : Colors.cyanAccent, size: 18), const SizedBox(width: 6), Text(isExpired ? '선택종료' : _formatTimer(_remainingSeconds), style: TextStyle(color: isExpired ? Colors.white38 : Colors.white, fontWeight: FontWeight.w900, fontSize: 12))]))),
                    if (_isDragging && _votedSide == 0 && !isExpired)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: val,
                              child: const Text(
                                '선택 후에는 변경할 수 없습니다',
                                style: TextStyle(
                                  color: Colors.cyanAccent, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                curve: Curves.easeOutCubic, 
                bottom: 210 + MediaQuery.of(context).padding.bottom, 
                left: (currentWidthA / 2) - (descWidth / 2), 
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  // 🚀 판별기를 통과한 '진짜 내용'이 있을 때만 드래그/클릭 시 노출!
                  opacity: ((_expandedSide == 1 || (_isDragging && currentWidthA > sw * 0.55)) && _isValidDescription(widget.post.descriptionA)) ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: _expandedSide != 1,
                    child: _descBox(widget.post.descriptionA, _isDescAExpanded, () => setState(() => _isDescAExpanded = !_isDescAExpanded)),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                curve: Curves.easeOutCubic, 
                bottom: 210 + MediaQuery.of(context).padding.bottom, 
                left: currentWidthA + ((sw - currentWidthA) / 2) - (descWidth / 2), 
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  // 🚀 판별기를 통과한 '진짜 내용'이 있을 때만 드래그/클릭 시 노출!
                  opacity: ((_expandedSide == 2 || (_isDragging && currentWidthA < sw * 0.45)) && _isValidDescription(widget.post.descriptionB)) ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: _expandedSide != 2,
                    child: _descBox(widget.post.descriptionB, _isDescBExpanded, () => setState(() => _isDescBExpanded = !_isDescBExpanded)),
                  ),
                ),
              ),
              Positioned(
                bottom: 80 + MediaQuery.of(context).padding.bottom, left: 18, right: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypeTags(),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Row(
                        children: [
                          widget.post.uploaderImage.isEmpty
                            ? const CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.person, color: Colors.white54, size: 30),
                              )
                            : CircleAvatar(
                                radius: 28, 
                                backgroundColor: Colors.black,
                                backgroundImage: widget.post.uploaderImage.startsWith('http')
                                  ? CachedNetworkImageProvider(widget.post.uploaderImage)
                                  : AssetImage(widget.post.uploaderImage) as ImageProvider,
                              ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.post.uploaderName, 
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8, offset: const Offset(0, 1))]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isMe) 
                                      GestureDetector(
                                        onTap: widget.onFollow,
                                        child: _followBtn(widget.post.isFollowing),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(widget.post.timeLocation, style: TextStyle(color: Colors.white54, fontSize: 11, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8, offset: const Offset(0, 1))])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        _statIcon(
                          Icons.favorite, 
                          formatCount(widget.post.likesCount),
                          color: widget.post.isLiked ? Colors.redAccent : Colors.white,
                          onTap: widget.onLike,
                        ),
                        const SizedBox(width: 20),
                        _statIcon(
                          Icons.chat_bubble, 
                          formatCount(widget.post.commentsCount),
                          onTap: () {
                            print('DEBUG: Comment icon tapped for post_id: ${widget.post.id}');
                            if (!gIsLoggedIn) {
                              gShowLoginPopup?.call();
                              return;
                            }
                            _showCommentsSheet(context);
                          },
                        ),
                        const SizedBox(width: 20),
                        _statIcon(
                          Icons.bookmark, 
                          '',
                          color: widget.post.isBookmarked ? Colors.amberAccent : Colors.white,
                          onTap: widget.onBookmark,
                        ),
                        const SizedBox(width: 20),
                        _statIcon(Icons.share, '', onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 링크가 복사되었습니다!'), duration: Duration(seconds: 1)));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              _buildChart(widget.post),
              // 🚀 [신규 위치] 점 세 개 메뉴 버튼을 그래프 옆 벽면으로 이동
              Positioned(
                bottom: 125 + MediaQuery.of(context).padding.bottom, 
                right: 8, // 벽에 더 바짝 붙임
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 44, height: 44,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: const Icon(Icons.more_vert, color: Colors.white54, size: 26),
                  ),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  onSelected: (value) {
                    if (value == '설명') {
                      _showDescriptionSheet(context);
                    } else if (value == '관심없음') {
                      widget.onNotInterested();
                    } else if (value == '채널 추천 안함') {
                      widget.onDontRecommendChannel();
                    } else if (value == '신고') {
                      _showReportSheet(context);
                    } else if (value == '삭제') {
                      _deletePost();
                    } else if (value == '숨기기' || value == '보이기') {
                      widget.onToggleHide(widget.post.id);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    // 🔒 [추가] 비로그인 상태면 '설명'만 노출
                    if (!gIsLoggedIn) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: '설명', child: Row(children: [Icon(Icons.info_outline, color: Colors.white70, size: 20), SizedBox(width: 12), Text('설명', style: TextStyle(color: Colors.white, fontSize: 14))])),
                      ];
                    }

                    bool isMe = (widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId);
                    if (isMe) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: '설명', child: Row(children: [Icon(Icons.info_outline, color: Colors.white70, size: 20), SizedBox(width: 12), Text('설명', style: TextStyle(color: Colors.white, fontSize: 14))])),
                        PopupMenuItem<String>(value: widget.post.isHidden ? '보이기' : '숨기기', child: Row(children: [Icon(widget.post.isHidden ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 20), SizedBox(width: 12), Text(widget.post.isHidden ? '보이기' : '숨기기', style: const TextStyle(color: Colors.white, fontSize: 14))])),
                        const PopupMenuItem<String>(value: '삭제', child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('삭제', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold))])),
                      ];
                    } else {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: '설명', child: Row(children: [Icon(Icons.info_outline, color: Colors.white70, size: 20), SizedBox(width: 12), Text('설명', style: TextStyle(color: Colors.white, fontSize: 14))])),
                        const PopupMenuItem<String>(value: '관심없음', child: Row(children: [Icon(Icons.block, color: Colors.white70, size: 20), SizedBox(width: 12), Text('관심없음', style: TextStyle(color: Colors.white, fontSize: 14))])),
                        const PopupMenuItem<String>(value: '채널 추천 안함', child: Row(children: [Icon(Icons.person_off_outlined, color: Colors.white70, size: 20), SizedBox(width: 12), Text('채널 추천 안함', style: TextStyle(color: Colors.white, fontSize: 14))])),
                        const PopupMenuItem<String>(value: '신고', child: Row(children: [Icon(Icons.report_gmailerrorred, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('신고', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold))])),
                      ];
                    }
                  },
                ),
              ),
              if (_showPointToast)
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Transform.translate(
                        offset: Offset(0, -150 * val),
                        child: Opacity(
                          opacity: (1.0 - val).clamp(0.0, 1.0),
                          child: Text(
                            '+10P', 
                            style: TextStyle(
                              color: Colors.cyanAccent, 
                              fontSize: 36, 
                              fontWeight: FontWeight.w900,
                              shadows: [Shadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 15)],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              if (_showAlreadySelectedToast && !isExpired)
                Positioned(
                  top: sh * 0.45, 
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '이미 선택한 콘텐츠입니다',
                        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                ),

              if (_showIsMeToast)
                Positioned(
                  top: sh * 0.45, 
                  left: 0, right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, val, child) => Transform.scale(
                        scale: 0.8 + (0.2 * val),
                        child: Opacity(
                          opacity: val,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, color: Colors.redAccent, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  '본인 질문에는 투표할 수 없어요!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
    );
  }

  void _showDescriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // 🚀 100%에서 85%로 줄여서 상단 여백 확보!
        decoration: const BoxDecoration(
          color: Color(0xFF121212), // 조금 더 깊이감 있는 블랙
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // 🎩 상단 핸들 바 (드래그 유도 및 디자인 포인트)
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text('상세 설명', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 28), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    Text(widget.post.fullDescription, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.8, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context) async {
    if (_isSheetOpening) return;
    _isSheetOpening = true;

    // 1. Fetch ALL comments for this post
    try {
      print('DEBUG: Fetching comments for post_id: ${widget.post.id}');
      final List<dynamic> data = await SupabaseService.client
          .from('comments')
          .select()
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);
      
      print('DEBUG: Fetched ${data.length} comments from server.');
      
      // 1-b. Fetch user profiles for commenters to enable real-time sync
      final List<dynamic> commentersProfiles = await SupabaseService.client
          .from('user_profiles')
          .select('id, user_id, nickname, profile_image');
      
      final Map<String, dynamic> profileById = {
        for (var p in commentersProfiles) p['id'].toString(): p
      };
      final Map<String, dynamic> profileByHandle = {
        for (var p in commentersProfiles) p['user_id'].toString(): p
      };

      // First, create all CommentData objects with merged profile info
      final allComments = data.map((json) {
        final String? internalId = json['user_internal_id']?.toString();
        final String handle = json['user_id'] ?? '';
        
        // Propagation Magic: Match by Internal ID (String/UUID), fallback to handle snapshot
        final profile = (internalId != null) ? profileById[internalId] : profileByHandle[handle];
        
        return CommentData(
          id: json['id'],
          parentId: json['parent_id'],
          user: (profile != null) ? (profile['nickname'] ?? '익명') : (json['user_name'] ?? '익명'),
          userId: json['user_id'] ?? '',
          userInternalId: json['user_internal_id']?.toString(), // 🆔 주민번호 불러오기
          text: json['text'] ?? '',
          side: json['side'] ?? 0,
          image: (profile != null) ? (profile['profile_image'] ?? 'assets/profiles/profile_11.jpg') : (json['user_image'] ?? 'assets/profiles/profile_11.jpg'),
          isPinned: json['is_pinned'] ?? false,
          isHidden: json['is_hidden'] ?? false,
        );
      }).toList();

      // Second, rebuild the tree
      final List<CommentData> rootComments = [];
      final Map<String, CommentData> commentMap = {for (var c in allComments) c.id!: c};

      for (var c in allComments) {
        if (c.parentId == null) {
          rootComments.add(c);
        } else {
          final parent = commentMap[c.parentId];
          if (parent != null) {
            parent.replies.add(c);
          } else {
            // Parent not found (maybe deleted?), treat as root
            rootComments.add(c);
          }
        }
      }

      widget.post.comments = rootComments;
      
      // Third, recursive count for the icon
      int countAll(List<CommentData> list) {
        int total = list.length;
        for (var c in list) {
          total += countAll(c.replies);
        }
        return total;
      }
      
      int totalCount = countAll(rootComments);
      widget.post.commentsCount = totalCount;
      print('DEBUG: Total recursive comment count: $totalCount');

      // Sync correctly calculated count back to posts table
      try {
        print('DEBUG: Syncing comments_count ($totalCount) to Supabase posts table for post_id: ${widget.post.id}');
        await SupabaseService.client
          .from('posts')
          .update({'comments_count': totalCount})
          .eq('id', widget.post.id);
        print('DEBUG: Sync SUCCESS!');
      } catch (e) {
        print('DEBUG: Sync FAILED! Error: $e');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('DEBUG: Fetch comments FAILED! Error: $e');
      _isSheetOpening = false;
      return;
    }

    // 🆔 주민번호 기반 주인 확인 (진짜 정석!)
    bool isMe = (widget.post.uploaderInternalId != null && gUserInternalId != null && 
                 widget.post.uploaderInternalId!.trim().toLowerCase() == gUserInternalId!.trim().toLowerCase());
    
    print('DEBUG [COMMENT]: gUserInternalId=$gUserInternalId, postUploaderInternalId=${widget.post.uploaderInternalId}, isMe=$isMe, _votedSide=$_votedSide, isExpired=$isExpired');
    if (_votedSide == 0 && !isExpired && !isMe) {
      print('DEBUG [COMMENT]: BLOCKED! Showing AlertDialog.');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('선택 후 참여 가능', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: const Text('댓글을 확인하고 의견을 나누려면\n먼저 어느 쪽이든 Pick 해주세요!', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
          ],
        ),
      );
      _isSheetOpening = false;
    } else {
      final TextEditingController commentController = TextEditingController();
      final ScrollController scrollController = ScrollController();
      CommentData? replyingTo;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75, 
              decoration: const BoxDecoration(
                color: Color(0xFF121212), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // 좌측 균형용
                        const Text('댓글', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.post.comments.length,
                      itemBuilder: (context, idx) {
                        final c = widget.post.comments[idx];
                        return _commentItem(c, idx, setSheetState, (target) {
                          setSheetState(() {
                            replyingTo = target;
                          });
                        });
                      },
                    ),
                  ),
                  _commentInput(commentController, setSheetState, replyingTo, scrollController, (val) {
                    setSheetState(() {
                      replyingTo = val;
                    });
                  }),
                ],
              ),
            ),
          ),
        ),
      );
      _isSheetOpening = false;
    }
  }

  Widget _commentInput(TextEditingController controller, StateSetter setSheetState, CommentData? replyingTo, ScrollController scrollController, Function(CommentData?) setReplyTarget) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(Icons.reply, color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 8),
                Text('${replyingTo.user}님에게 답글 남기는 중...', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setReplyTarget(null),
                  child: const Icon(Icons.close, color: Colors.white54, size: 16),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.only(
            left: 16, 
            right: 16, 
            top: 12, 
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), 
            border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05), 
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: false,
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onSubmitted: (val) async {
                      final text = val.trim();
                      if (text.isNotEmpty) {
                        if (!gIsLoggedIn) {
                          gShowLoginPopup?.call();
                          return;
                        }
                        
                        // 🆔 진짜 주인 확인 (정석!)
                        bool isMe = (widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId);
                        
                        // 일반 유저는 투표 필수! 단, 주인님이거나 투표 종료된 글은 프리패스!
                        if (_votedSide == 0 && !isMe && !isExpired) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표를 먼저 해주세요!')));
                          return;
                        }

                        final newComment = CommentData(
                          user: gNameText, 
                          userId: gIdText,
                          userInternalId: gUserInternalId, // 🆔 주민번호 장착!
                          text: text, 
                          side: _votedSide, 
                          image: gProfileImage,
                          parentId: replyingTo?.id,
                        );

                        setSheetState(() {
                          if (replyingTo != null) {
                            replyingTo.replies.add(newComment);
                            setReplyTarget(null);
                          } else {
                            widget.post.comments.add(newComment);
                          }
                          widget.post.commentsCount++;
                          controller.clear();
                        });
                        if (mounted) setState(() {}); 

                        try {
                          await SupabaseService.client.from('comments').insert({
                            'post_id': widget.post.id,
                            'parent_id': newComment.parentId,
                            'user_name': gNameText,
                            'user_id': gIdText,
                            'user_internal_id': gUserInternalId,
                            'text': text,
                            'user_image': gProfileImage,
                            'side': _votedSide,
                          });

                          // ★ [제미나이 프로 X 정석 로봇] 게시물 테이블의 댓글 숫자도 실시간 업데이트!
                          await SupabaseService.client
                            .from('posts')
                            .update({'comments_count': widget.post.commentsCount})
                            .eq('id', widget.post.id);

                        } catch (e) {
                          print('댓글 저장 및 숫자 업데이트 실패: $e');
                        }
                      }
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: (_votedSide == 0 && !((widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId) || 
                                 (widget.post.uploaderId.replaceAll(RegExp(r'[@\s_]'), '').trim() == gIdText.replaceAll(RegExp(r'[@\s_]'), '').trim()))) 
                                 ? '투표 후 댓글을 남겨주세요' 
                                 : '댓글을 입력하세요...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    if (!gIsLoggedIn) {
                      gShowLoginPopup?.call();
                      return;
                    }

                    bool isMe = (widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId);
                    
                    if (_votedSide == 0 && !isMe && !isExpired) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표를 먼저 해주세요!')));
                      return;
                    }

                    final newComment = CommentData(
                      user: gNameText, 
                      userId: gIdText,
                      userInternalId: gUserInternalId, // 🆔 주민번호 장착!
                      text: text, 
                      side: _votedSide, 
                      image: gProfileImage,
                      parentId: replyingTo?.id,
                    );

                    setSheetState(() {
                      if (replyingTo != null) {
                        replyingTo.replies.add(newComment);
                        setReplyTarget(null);
                      } else {
                        widget.post.comments.add(newComment);
                      }
                      widget.post.commentsCount++;
                      controller.clear();
                    });
                    if (mounted) setState(() {}); 

                    try {
                      await SupabaseService.client.from('comments').insert({
                        'post_id': widget.post.id,
                        'parent_id': newComment.parentId,
                        'user_name': gNameText,
                        'user_id': gIdText,
                        'user_internal_id': gUserInternalId,
                        'text': text,
                        'user_image': gProfileImage,
                        'side': _votedSide,
                      });

                      // ★ [제미나이 프로 X 정석 로봇] 게시물 테이블의 댓글 숫자도 실시간 업데이트!
                      await SupabaseService.client
                        .from('posts')
                        .update({'comments_count': widget.post.commentsCount})
                        .eq('id', widget.post.id);

                    } catch (e) {
                      print('댓글 저장 및 숫자 업데이트 실패: $e');
                    }
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: const Icon(Icons.send_rounded, color: Colors.cyanAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _followBtn(bool isFollowing) {
    return Container(
      width: 72, height: 28, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFollowing ? const Color(0xFF272727) : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isFollowing ? Colors.white10 : Colors.transparent, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, 
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFollowing ? Icons.check : Icons.add, color: isFollowing ? Colors.white70 : Colors.white, size: 12),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(isFollowing ? '팔로잉' : '팔로우', style: TextStyle(color: isFollowing ? Colors.white70 : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _bgLabel(String text, Color color, {bool isWinner = false}) { 
    return IgnorePointer( // 배경 글자가 터치 이벤트를 가로막지 않도록 설정 (중요!)
      child: Stack(
        clipBehavior: Clip.none, alignment: Alignment.topCenter,
        children: [
          if (isWinner)
            Positioned(
              top: -18,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, val, child) => Transform.scale(scale: val, child: const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 24)),
              ),
            ),
          Text(text, style: TextStyle(color: color, fontSize: 45, fontWeight: FontWeight.w900, letterSpacing: -4)),
        ],
      ),
    ); 
  }

  Widget _buildMedia(int side, String url, double sw, {String? thumbUrl, bool forceThumb = false}) {
    if (_isVideo(url)) {
      final controller = (side == 1) ? _controllerA : _controllerB;
      final isInitialized = (side == 1) ? _isInitializedA : _isInitializedB;
      final isPlaying = (_playingSide == side);

      Widget content;
      if (!forceThumb && isInitialized && controller != null) {
        // 🎬 초기화만 되었다면 재생 여부와 상관없이 영상 화면 유지 (일시정지 포함)
        content = FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        );
      } else {
        if (thumbUrl != null && thumbUrl.isNotEmpty) {
          content = CachedNetworkImage(
            imageUrl: thumbUrl.trim(),
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
          );
        } else {
          content = const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2));
        }
      }

      return content;
    } else {
      if (url.trim().isEmpty) {
        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2));
      }
      // 🖼️ 이미지일 때 (기존 로직 그대로 캐싱 적용!)
      // 블러 배경용(forceThumb)이라면 썸네일을 우선 사용해서 성능 최적화!
      final String effectiveUrl = (forceThumb && thumbUrl != null && thumbUrl.isNotEmpty) 
          ? thumbUrl.trim() 
          : url.trim();

      return effectiveUrl.contains('http')
          ? CachedNetworkImage(
              imageUrl: effectiveUrl,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
            )
          : Image.asset(effectiveUrl, fit: BoxFit.cover);
    }
  }

  Widget _descBox(String text, bool isExpanded, VoidCallback onTap) { 
    bool needsExpansion = false;
    if (text.isNotEmpty) {
      final textPainter = TextPainter(text: TextSpan(text: text, style: const TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w600)), maxLines: 2, textDirection: TextDirection.ltr);
      textPainter.layout(maxWidth: 151); 
      needsExpansion = textPainter.didExceedMaxLines;
    }
    return GestureDetector(
      onTap: needsExpansion ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 175, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.15))), 
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600), maxLines: isExpanded ? 10 : 2, overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis)),
                  if (needsExpansion && !isExpanded) const Padding(padding: EdgeInsets.only(left: 4, bottom: 2), child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 14)),
                ]),
                if (needsExpansion && isExpanded) const Padding(padding: EdgeInsets.only(top: 4), child: Center(child: Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 14))),
              ],
            ),
          ),
        ),
      ),
    ); 
  }

  Widget _statIcon(IconData icon, String value, {Color color = Colors.white, VoidCallback? onTap}) { 
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8, offset: const Offset(0, 1))]), 
          const SizedBox(height: 5), 
          Text(value, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 8, offset: const Offset(0, 1))])),
        ],
      ),
    );
  }

  Widget _buildChart(PostData post) {
    bool isExpired = _remainingSeconds <= 0 || post.isExpired;
    bool hasVoted = _votedSide != 0 || isExpired || isMe;
    return Positioned(
      bottom: 67 + MediaQuery.of(context).padding.bottom, right: 35,
      child: SizedBox(
        width: 120, height: 110,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none, // 에러 방지용! 박스를 벗어나도 보이게 설정
          children: [
            SizedBox(
              width: 58, height: 58,
              child: CustomPaint(
                painter: DonutPainter(percentA: hasVoted ? (double.tryParse(post.percentA.replaceAll('%', '')) ?? 50) / 100 : 1.0, isPreVote: !hasVoted),
                child: Center(child: Text(hasVoted ? 'VS' : 'Pick\nView', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: hasVoted ? 13 : 10, height: 1.1))),
              ),
            ),
            if (hasVoted) Positioned(
              top: 58, left: 0, right: 0, 
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 왼쪽 A 통계 (시안색 - 우측 정렬)
                      SizedBox(
                        width: 45,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerRight,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _shadowText(post.percentA, color: Colors.cyanAccent, size: 14, weight: FontWeight.w900),
                                _shadowText(post.voteCountA, color: Colors.white70, size: 9, weight: FontWeight.bold),
                              ],
                            ),
                            if (_votedSide == 1) Positioned(
                              top: -18, right: 0,
                              child: _myPickLabel(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // 오른쪽 B 통계 (빨간색 - 좌측 정렬)
                      SizedBox(
                        width: 50,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _shadowText(post.percentB, color: Colors.redAccent, size: 14, weight: FontWeight.w900),
                                  _shadowText(post.voteCountB, color: Colors.white70, size: 9, weight: FontWeight.bold),
                                ],
                              ),
                              if (_votedSide == 2) Positioned(
                                top: -18, left: 0,
                                child: _myPickLabel(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ) else Positioned(
              top: 66, // ⚪ 조금 더 여유 있게 아래로 배치
              left: 5, right: 5, // 🚀 양옆 여백을 줘서 중앙 정렬 유도
              child: Center(
                child: FittedBox( // 💥 [대응] 작은 폰에서도 글자가 안 깨지게 자동 축소!
                  fit: BoxFit.scaleDown,
                  child: _shadowText(
                    '투표 후 확인 가능', 
                    color: Colors.white.withValues(alpha: 0.85), 
                    size: 11,
                    weight: FontWeight.w900
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTags() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.post.isAd) _tagChip('Sponsor', Colors.amber),
        if (widget.post.isAdult) _tagChip('19+', Colors.redAccent),
        if (widget.post.isAi) _tagChip('AI컨텐츠', Colors.cyanAccent),
      ],
    );
  }

  Widget _tagChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _myPickLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      margin: const EdgeInsets.only(bottom: 5), // 간격을 2에서 5로 대폭 확대
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
      child: const Text('My Pick', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.w900)),
    );
  }

  Widget _shadowText(String text, {required Color color, required double size, required FontWeight weight}) {
    return Text(text, style: TextStyle(color: color, fontSize: size, fontWeight: weight, letterSpacing: -0.5, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6, offset: const Offset(0, 1))]));
  }

  Widget _commentItem(CommentData c, int index, StateSetter setSheetState, Function(CommentData) onReplyTap, {double depth = 0}) {
    bool isPostAuthor = (widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId);
    bool isCommentAuthor = (c.userInternalId != null && c.userInternalId == gUserInternalId);
    
    if (c.isHidden && !isPostAuthor) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 20, left: depth * 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.side == 1 ? Colors.cyanAccent : (c.side == 2 ? Colors.redAccent : Colors.transparent),
                    width: 2,
                  ),
                ),
                child: c.image.isEmpty 
                  ? CircleAvatar(
                      radius: depth > 0 ? 14 : 18,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.person, color: Colors.white54, size: depth > 0 ? 16 : 20),
                    )
                  : CircleAvatar(
                      radius: depth > 0 ? 14 : 18, 
                      backgroundColor: Colors.black,
                      backgroundImage: c.image.startsWith('http') 
                        ? CachedNetworkImageProvider(c.image) 
                        : AssetImage(c.image) as ImageProvider
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) {
                            // 주민번호(internal_id)를 우선으로 작성자/본인 판별 (정석!)
                            bool isMe = (c.userInternalId != null && c.userInternalId == gUserInternalId);
                            bool isPostAuthorTag = (c.userInternalId != null && widget.post.uploaderInternalId != null && c.userInternalId == widget.post.uploaderInternalId);
                            
                            if (isPostAuthorTag) {
                              String displayName = isMe ? gNameText : widget.post.uploaderName;
                              String badge = isMe ? '(본인)' : '(작성자)';
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24, width: 0.5),
                                ),
                                child: Text(
                                  "$displayName $badge", 
                                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)
                                ),
                              );
                            }
                            return Text(c.user, style: TextStyle(color: Colors.white, fontSize: depth > 0 ? 12 : 13, fontWeight: FontWeight.bold));
                          }
                        ),
                        if (c.isPinned) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.push_pin, color: Colors.cyanAccent, size: 12),
                          const Text(' 고정됨', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) async {
                            if (value == '고정' || value == '고정해제') {
                              final bool newPinned = !c.isPinned;
                              setSheetState(() {
                                c.isPinned = newPinned;
                                if (c.isPinned) {
                                  widget.post.comments.removeAt(index);
                                  widget.post.comments.insert(0, c);
                                }
                              });
                              // DB 고정 상태 업데이트
                              try {
                                await SupabaseService.client
                                  .from('comments')
                                  .update({'is_pinned': newPinned})
                                  .eq('id', c.id!);
                              } catch (e) {
                                print('댓글 고정 에러: $e');
                              }
                            } else if (value == '삭제') {
                              final String? commentId = c.id;
                              setSheetState(() {
                                widget.post.comments.removeAt(index);
                                widget.post.commentsCount--;
                              });
                              if (mounted) {
                                setState(() {});
                              }
                              try {
                                // 1. DB에서 실제 삭제
                                if (commentId != null) {
                                  await SupabaseService.client
                                    .from('comments')
                                    .delete()
                                    .eq('id', commentId);
                                }
                                // 2. 게시물 댓글 수 업데이트
                                await SupabaseService.client
                                  .from('posts')
                                  .update({'comments_count': widget.post.commentsCount})
                                  .eq('id', widget.post.id);
                              } catch (e) {
                                print('댓글삭제 에러: $e');
                              }
                            } else if (value == '숨기기' || value == '숨김해제') {
                              final bool newHidden = !c.isHidden;
                              setSheetState(() {
                                c.isHidden = newHidden;
                              });
                              // DB 숨김 상태 업데이트
                              try {
                                await SupabaseService.client
                                  .from('comments')
                                  .update({'is_hidden': newHidden})
                                  .eq('id', c.id!);
                              } catch (e) {
                                print('댓글숨김 에러: $e');
                              }
                            } else if (value == '신고') {
                              _showReportSheet(context);
                            } else if (value == '수정') {
                              _showEditCommentDialog(c, setSheetState);
                            }
                          },
                          itemBuilder: (context) {
                            List<PopupMenuEntry<String>> items = [];
                            
                            // 1. Pin/Unpin (Only for Post Owner)
                            if (isPostAuthor) {
                              items.add(PopupMenuItem(
                                value: c.isPinned ? '고정해제' : '고정',
                                child: Text(c.isPinned ? '고정 해제' : '고정', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ));
                            }
                            
                            // 2. Edit (Only for Comment Author)
                            if (isCommentAuthor) {
                              items.add(const PopupMenuItem(value: '수정', child: Text('수정', style: TextStyle(color: Colors.white, fontSize: 13))));
                            }
                            
                            // 3. Delete (Author OR Post Owner)
                            if (isCommentAuthor || isPostAuthor) {
                              items.add(PopupMenuItem(
                                value: '삭제', 
                                child: Text('삭제', style: TextStyle(color: isCommentAuthor ? Colors.redAccent : Colors.white, fontSize: 13))
                              ));
                            }
                            
                            // 4. Hide (Only for Post Owner on OTHERS' comments)
                            if (isPostAuthor && !isCommentAuthor) {
                              items.add(PopupMenuItem(
                                value: c.isHidden ? '숨김해제' : '숨기기', 
                                child: Text(c.isHidden ? '숨김 해제' : '숨기기', style: const TextStyle(color: Colors.white, fontSize: 13))
                              ));
                            }
                            
                            // 5. Report (Everyone except on their OWN comment)
                            if (!isCommentAuthor) {
                              items.add(const PopupMenuItem(value: '신고', child: Text('신고', style: TextStyle(color: Colors.redAccent, fontSize: 13))));
                            }
                            
                            return items;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), 
                    Text(
                      c.isHidden ? '숨겨진 댓글입니다.' : c.text, 
                      style: TextStyle(
                        color: c.isHidden ? Colors.white24 : Colors.white70, 
                        fontSize: depth > 0 ? 12 : 13, 
                        height: 1.3,
                        fontStyle: c.isHidden ? FontStyle.italic : FontStyle.normal,
                      )
                    ),
                    if (!c.isHidden)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => onReplyTap(c),
                          child: const Text('답글 달기', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ]
                )
              ),
            ],
          ),
        ),
        // 대댓글(답글)들을 재귀적으로 렌더링
        if (c.replies.isNotEmpty)
          ...c.replies.asMap().entries.map((entry) {
            return _commentItem(entry.value, entry.key, setSheetState, onReplyTap, depth: depth + 1);
          }),
      ],
    );
  }

  void _showEditCommentDialog(CommentData c, StateSetter setSheetState) {
    final controller = TextEditingController(text: c.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('댓글 수정', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: '내용을 입력하세요', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              setSheetState(() {
                c.text = newText;
              });
              Navigator.pop(context);
              // DB에 댓글 수정 내용 저장
              try {
                await SupabaseService.client
                    .from('comments')
                    .update({'text': newText})
                    .eq('id', c.id!);
              } catch (e) {
                print('댓글 수정 DB 저장 오류: $e');
              }
            }, 
            child: const Text('수정', style: TextStyle(color: Colors.cyanAccent))
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎩 상단 바 및 닫기 버튼
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text('게시물 신고', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('신고 사유를 선택해주세요. 검토 후 신속히 조치하겠습니다.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 25),

              // 📋 신고 항목 리스트 (아이콘 탑재!)
              _reportItem(context, Icons.copyright, '저작권 침해', Colors.amberAccent),
              _reportItem(context, Icons.explicit_outlined, '부적절한 콘텐츠', Colors.redAccent),
              _reportItem(context, Icons.campaign_outlined, '스팸 또는 홍보', Colors.blueAccent),
              _reportItem(context, Icons.psychology_alt_outlined, '허위 정보 유포', Colors.purpleAccent),
              _reportItem(context, Icons.sentiment_very_dissatisfied, '증오 표현 또는 괴롭힘', Colors.orangeAccent),
              _reportItem(context, Icons.more_horiz, '기타', Colors.white54),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportItem(BuildContext context, IconData icon, String title, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white10, size: 18),
      onTap: () {
        Navigator.pop(context);
        widget.onReport(title); // 🚀 사유 전달!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" 사유로 신고가 접수되었습니다.'),
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }
}
