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
import 'package:share_plus/share_plus.dart';
import '../models/post_data.dart';
import '../models/comment_data.dart';
import '../core/app_state.dart';
import '../services/supabase_service.dart';
import '../services/post_service.dart';
import '../screens/channel_screen.dart';

class PostView extends StatefulWidget {
  final PostData post;
  final VoidCallback? onLike;
  final VoidCallback? onFollow;
  final VoidCallback? onBookmark;
  final VoidCallback? onNotInterested;
  final VoidCallback? onDontRecommendChannel;
  final Function(String reason)? onReport;
  final Function(int side)? onVote;
  final Function(String postId)? onDelete;
  final Function(String postId)? onToggleHide;
  final VoidCallback? onProfileTap;

  const PostView({
    super.key, 
    required this.post, 
    this.onLike, 
    this.onFollow, 
    this.onBookmark, 
    this.onNotInterested, 
    this.onDontRecommendChannel, 
    this.onReport, 
    this.onVote, 
    this.onDelete,
    this.onToggleHide,
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
  DateTime? _viewStartTime; // ⏱️ [신규] 6초 정독 체크를 위한 입성 시간 기록
  DateTime? _lastSwitchTime; // ⏱️ [신규] 드래그 시 급격한 영상 전환 방지용 쿨타임

  @override
  bool get wantKeepAlive => true;

  bool get _isOwnPost {
    return widget.post.uploaderInternalId != null &&
        gUserInternalId != null &&
        widget.post.uploaderInternalId!.trim().toLowerCase() ==
            gUserInternalId!.trim().toLowerCase();
  }

  bool get _canViewDiscussionResults {
    return _votedSide != 0 || _isOwnPost || (isExpired && gIsLoggedIn);
  }

  Future<int> _syncCommentsCount() async {
    try {
      final dynamic syncedCount = await SupabaseService.client.rpc(
        'sync_comments_count',
        params: {'target_post_id': widget.post.id},
      );

      if (syncedCount is int) return syncedCount;
      if (syncedCount is num) return syncedCount.toInt();
    } catch (_) {
    }

    final List<dynamic> comments = await SupabaseService.client
        .from('comments')
        .select('id')
        .eq('post_id', widget.post.id);

    final int serverCommentsCount = comments.length;

    await SupabaseService.client
        .from('posts')
        .update({'comments_count': serverCommentsCount})
        .eq('id', widget.post.id);

    return serverCommentsCount;
  }

  @override
  void didUpdateWidget(PostView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.isFollowing != widget.post.isFollowing || oldWidget.post.id != widget.post.id) {
      setState(() {});
    }
  }

  double _dragDistance = 0; 
  Timer? _initTimer; 
  
  @override
  void initState() {
    super.initState();
    _votedSide = gUserVotes[widget.post.id] ?? 0;
    _updateRemainingTime();
    _startTimer();
  }

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

  Future<void> _initVideo(String url, int side) async {
    if (!_isVideo(url)) return;
    if (side == 1 && (_isInitializedA || _isInitializingA)) return;
    if (side == 2 && (_isInitializedB || _isInitializingB)) return;

    if (side == 1) _isInitializingA = true;
    else _isInitializingB = true;

    try {
      VideoPlayerController controller;
      if (!kIsWeb && url.startsWith('http')) {
        try {
          final file = await DefaultCacheManager().getSingleFile(url);
          controller = VideoPlayerController.file(file);
        } catch (e) {
          controller = VideoPlayerController.networkUrl(Uri.parse(url));
        }
      } else if (url.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        controller = VideoPlayerController.file(File(url));
      }

      await controller.initialize();
      await controller.setLooping(false); 
      await controller.setVolume(0); 
      
      void listener() {
        if (!mounted) return;
        if (side == 1 && _controllerA != controller) return;
        if (side == 2 && _controllerB != controller) return;
        final pos = controller.value.position;
        final dur = controller.value.duration;
        if (dur > Duration.zero && pos >= dur) {
          _onVideoFinished(side);
        }
      }
      controller.addListener(listener);

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

      if (side == 1 && _playingSide == 0) {
        _switchToSide(1);
      }
    } catch (e) {
      if (side == 1) _isInitializingA = false;
      else _isInitializingB = false;
    }
  }

  void _onVideoFinished(int side) {
    if (!mounted) return;
    if (side == 1 && _videoAFinished) return;
    if (side == 2 && _videoBFinished) return;
    if (side == 1) _videoAFinished = true;
    if (side == 2) _videoBFinished = true;
    
    double ratioA = (_widthA ?? (MediaQuery.of(context).size.width * 0.5)) / MediaQuery.of(context).size.width;

    if (side == 1) {
      _controllerA?.pause();
      _controllerA?.seekTo(Duration.zero);
      if (ratioA >= 0.55) {
        _switchToSide(1);
      } else if (ratioA <= 0.45) {
      } else {
        _switchToSide(2);
      }
    } else if (side == 2) {
      _controllerB?.pause();
      _controllerB?.seekTo(Duration.zero);
      if (ratioA <= 0.45) {
        _switchToSide(2);
      } else if (ratioA >= 0.55) {
      } else {
        _switchToSide(1);
      }
    }
  }

  void _switchToSide(int side) {
    if (!mounted) return;
    
    if (side == 1 && _isInitializedA && _controllerA != null) {
      _controllerB?.pause();
      _videoAFinished = false;
      _controllerA!.play();
      setState(() => _playingSide = 1);
    } else if (side == 2 && _isInitializedB && _controllerB != null) {
      _controllerA?.pause();
      _videoBFinished = false;
      _controllerB!.play();
      setState(() => _playingSide = 2);
    }
  }

  void _onBecomeVisible() {
    _viewStartTime = DateTime.now(); 
    if (_isVideo(widget.post.imageA)) {
      _initVideo(widget.post.imageA, 1);
    }
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || !_isVisible) return;
      if (_isVideo(widget.post.imageB)) {
        _initVideo(widget.post.imageB, 2);
      }
    });
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
    _controllerA?.dispose(); 
    _controllerB?.dispose();
    super.dispose();
  }

  bool get isMe {
    String nId(String? s) => (s ?? '').trim().toLowerCase();
    if (widget.post.uploaderInternalId != null && gUserInternalId != null) {
      if (nId(widget.post.uploaderInternalId) == nId(gUserInternalId)) return true;
    }
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
        final String postId = widget.post.id; 
        await Future.wait([
          SupabaseService.client.from('votes').delete().eq('post_id', postId),
          SupabaseService.client.from('comments').delete().eq('post_id', postId),
          SupabaseService.client.from('likes').delete().eq('post_id', postId),
          SupabaseService.client.from('bookmarks').delete().eq('post_id', postId),
        ]);
        await SupabaseService.client.from('posts').delete().eq('id', postId);
        widget.onDelete?.call(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물이 삭제되었습니다.')));
        }
      } catch (e) {
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
    Future.delayed(const Duration(milliseconds: 1000), () { 
      if (mounted) setState(() => _showAlreadySelectedToast = false);
    });
  }

  void _showIsMeMessage() {
    if (_showIsMeToast) return;
    setState(() => _showIsMeToast = true);
    Future.delayed(const Duration(milliseconds: 1000), () { 
      if (mounted) setState(() => _showIsMeToast = false);
    });
  }

  bool _isValidDescription(String? text) {
    if (text == null) return false;
    final clean = text.trim();
    if (clean.isEmpty) return false;
    final blackList = [
      "내용을 입력하세요", "내용 없음", "내용이 없습니다", "설명을 입력하세요",
      "선택지A", "선택지B", "선택지 A", "선택지 B"
    ];
    if (blackList.contains(clean)) return false;
    return clean.length > 1; 
  }

  void _onVote(int side) async {
    if (!gIsLoggedIn) {
      gShowLoginPopup?.call();
      return;
    }
    if (_votedSide != 0) return;
    
    String normalized(String? s) => (s ?? '').trim().toLowerCase();
    bool isMe = (widget.post.uploaderInternalId != null && gUserInternalId != null && 
                 normalized(widget.post.uploaderInternalId) == normalized(gUserInternalId));
    
    if (isMe) {
      _showIsMeMessage(); 
      HapticFeedback.vibrate(); 
      return;
    }

    try {
      await SupabaseService.client.from('votes').insert({
        'post_id': widget.post.id,
        'user_internal_id': gUserInternalId,
        'side': side,
      });

      final elapsed = _viewStartTime != null 
          ? DateTime.now().difference(_viewStartTime!).inSeconds 
          : 0;

      if (elapsed >= 6) {
        if (widget.post.uploaderInternalId != null) {
          await SupabaseService.client.from('points_history').insert({
            'user_internal_id': widget.post.uploaderInternalId,
            'amount': 1,
            'description': '내 게시글 투표 받음 보너스',
          });
          try {
            await SupabaseService.client.rpc('increment_points', params: {
              'target_id': widget.post.uploaderInternalId,
              'amount': 1
            });
          } catch(e) {}
        }

        final voteCountRes = await SupabaseService.client
            .from('votes')
            .select('id')
            .eq('user_internal_id', gUserInternalId!);
        
        final int totalVotes = (voteCountRes as List).length;
        if (totalVotes > 0 && totalVotes % 10 == 0) {
          await SupabaseService.client.from('points_history').insert({
            'user_internal_id': gUserInternalId,
            'amount': 1,
            'description': '투표 10회 달성 보너스',
          });
          try {
            await SupabaseService.client.rpc('increment_points', params: {
              'target_id': gUserInternalId,
              'amount': 1
            });
          } catch(e) {}

          if (mounted) {
            setState(() => gUserPoints += 1);
            _triggerPointToast(); 
          }
        }
      }
    } catch (e) {
    }

    setState(() {
      _votedSide = side;
      gUserVotes[widget.post.id] = side; 
      
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

    widget.onVote?.call(side);
    HapticFeedback.heavyImpact();
  }

  bool get isExpired => _remainingSeconds <= 0 || widget.post.isExpired;

  void _onPanUpdate(DragUpdateDetails details, double sw) {
    setState(() { 
      _isDragging = true; 
      _widthA = ((_widthA ?? (sw * 0.5)) + details.delta.dx).clamp(sw * 0.2, sw * 0.8); 
      
      double ratioA = _widthA! / sw;
      final now = DateTime.now();
      if (_lastSwitchTime == null || now.difference(_lastSwitchTime!) > const Duration(milliseconds: 300)) {
        if (ratioA >= 0.55 && _playingSide != 1) {
          _lastSwitchTime = now;
          _switchToSide(1);
        } else if (ratioA <= 0.45 && _playingSide != 2) {
          _lastSwitchTime = now;
          _switchToSide(2);
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details, double sw) {
    if (!_isDragging) return; 

    setState(() {
      _isDragging = false;
      _dragDistance = 0; 
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

  void _onPanCancel(double sw) {
    if (!_isDragging) return; 

    setState(() {
      _isDragging = false;
      _dragDistance = 0; 
      _widthA = sw * 0.5;
      _expandedSide = 0;
    });
  }

  void _handleTap(TapDownDetails details, double sw) {
    _dragDistance = 0; 
    double tapX = details.localPosition.dx;
    double currentWidthA = _widthA ?? (sw * 0.5);

    setState(() {
      if (_expandedSide != 0) {
        _expandedSide = 0;
        _widthA = sw * 0.5;
      } else {
        if (tapX < currentWidthA) {
          _expandedSide = 1;
          _widthA = sw * 0.8;
        } else {
          _expandedSide = 2;
          _widthA = sw * 0.2;
        }
      }
    });
    
    HapticFeedback.lightImpact();
    
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

  void _syncWithGlobalState() {
    final String postId = widget.post.id;
    final String? uploaderId = widget.post.uploaderInternalId;

    widget.post.isLiked = gLikedPostIds.contains(postId);
    widget.post.isBookmarked = gBookmarkedPostIds.contains(postId);
    if (uploaderId != null) {
      widget.post.isFollowing = gFollowedUserIds.contains(uploaderId);
    }
    
    if (gUserVotes.containsKey(postId)) {
      _votedSide = gUserVotes[postId]!;
      widget.post.userVotedSide = _votedSide;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _syncWithGlobalState(); 
    return VisibilityDetector(
      key: ValueKey('vd_${widget.key ?? widget.post.id}'),
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

        return GestureDetector(
          onTapDown: (d) => _handleTap(d, sw),
          onPanUpdate: (d) => _onPanUpdate(d, sw),
          onPanEnd: (d) => _onPanEnd(d, sw),
          onPanCancel: () => _onPanCancel(sw),
          child: Stack(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: currentWidthA, 
                    height: sh,
                    clipBehavior: Clip.hardEdge, 
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: _buildMedia(1, widget.post.imageA, sw, thumbUrl: widget.post.thumbA, forceThumb: true),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        Center(
                          child: OverflowBox(
                            maxWidth: sw, 
                            minWidth: sw,
                            child: _buildMedia(1, widget.post.imageA, sw, thumbUrl: widget.post.thumbA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: (sw - currentWidthA).clamp(0.0, sw), 
                    height: sh,
                    clipBehavior: Clip.hardEdge, 
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: _buildMedia(2, widget.post.imageB, sw, thumbUrl: widget.post.thumbB, forceThumb: true),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        Center(
                          child: OverflowBox(
                            maxWidth: sw, 
                            minWidth: sw,
                            child: _buildMedia(2, widget.post.imageB, sw, thumbUrl: widget.post.thumbB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                      padding: const EdgeInsets.only(left: 20, right: 0), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const SizedBox(width: 20), 
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
                          const SizedBox(width: 20), 
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
                                        onTap: () {
                                          if (!gIsLoggedIn) {
                                            gShowLoginPopup?.call();
                                            return;
                                          }
                                          if (widget.onFollow != null) {
                                            widget.onFollow!();
                                          } else {
                                            PostService.toggleFollow(widget.post);
                                            setState(() {});
                                          }
                                        },
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
                          onTap: () {
                            if (!gIsLoggedIn) {
                              gShowLoginPopup?.call();
                              return;
                            }
                            if (widget.onLike != null) {
                              widget.onLike!();
                            } else {
                              PostService.toggleLike(widget.post);
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 20),
                        _statIcon(
                          Icons.chat_bubble, 
                          _canViewDiscussionResults
                              ? formatCount(widget.post.commentsCount)
                              : 'Pick',
                          onTap: () {
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
                          onTap: () {
                            if (!gIsLoggedIn) {
                              gShowLoginPopup?.call();
                              return;
                            }
                            if (widget.onBookmark != null) {
                              widget.onBookmark!();
                            } else {
                              PostService.toggleBookmark(widget.post);
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 20),
                        _statIcon(Icons.share, '', onTap: () {
                          final String shareUrl = 'https://pickget.net/?id=${widget.post.id}';
                          Share.share(
                            '지금 PickGet에서 이 게시물을 확인해보세요!\n$shareUrl',
                            subject: 'PickGet 게시물 공유',
                          );
                          Clipboard.setData(ClipboardData(text: shareUrl));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              _buildChart(widget.post),
              Positioned(
                bottom: 125 + MediaQuery.of(context).padding.bottom, 
                right: 8, 
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
                      widget.onNotInterested?.call();
                    } else if (value == '채널 추천 안함') {
                      widget.onDontRecommendChannel?.call();
                    } else if (value == '신고') {
                      _showReportSheet(context);
                    } else if (value == '삭제') {
                      _deletePost();
                    } else if (value == '숨기기' || value == '보이기') {
                      if (widget.onToggleHide != null) {
                        widget.onToggleHide!(widget.post.id);
                      } else {
                        PostService.toggleHide(widget.post);
                        setState(() {});
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
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
                            '+1P', 
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
        height: MediaQuery.of(context).size.height * 0.85, 
        decoration: const BoxDecoration(
          color: Color(0xFF121212), 
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
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

    if (!_canViewDiscussionResults) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Pick 후 참여 가능',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '댓글과 진행 상황은 먼저 Pick 한 뒤 확인할 수 있어요.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      _isSheetOpening = false;
      return;
    }

    try {
      final List<dynamic> data = await SupabaseService.client
          .from('comments')
          .select()
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);
      
      final List<dynamic> commentersProfiles = await SupabaseService.client
          .from('user_profiles')
          .select('id, user_id, nickname, profile_image');
      
      final Map<String, dynamic> profileById = {
        for (var p in commentersProfiles) p['id'].toString(): p
      };
      final Map<String, dynamic> profileByHandle = {
        for (var p in commentersProfiles) p['user_id'].toString(): p
      };

      final allComments = data.map((json) {
        final String? internalId = json['user_internal_id']?.toString();
        final String handle = json['user_id'] ?? '';
        final profile = (internalId != null) ? profileById[internalId] : profileByHandle[handle];
        
        return CommentData(
          id: json['id'],
          parentId: json['parent_id'],
          user: (profile != null) ? (profile['nickname'] ?? '익명') : (json['user_name'] ?? '익명'),
          userId: json['user_id'] ?? '',
          userInternalId: json['user_internal_id']?.toString(), 
          text: json['text'] ?? '',
          side: json['side'] ?? 0,
          image: (profile != null) ? (profile['profile_image'] ?? '') : (json['user_image'] ?? ''),
          isPinned: json['is_pinned'] ?? false,
          isHidden: json['is_hidden'] ?? false,
        );
      }).toList();

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
            rootComments.add(c);
          }
        }
      }

      widget.post.comments = rootComments;
      
      int countAll(List<CommentData> list) {
        int total = list.length;
        for (var c in list) {
          total += countAll(c.replies);
        }
        return total;
      }
      
      int totalCount = countAll(rootComments);
      widget.post.commentsCount = totalCount;

      try {
        widget.post.commentsCount = await _syncCommentsCount();
      } catch (e) {
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _isSheetOpening = false;
      return;
    }

    bool isMe = (widget.post.uploaderInternalId != null && gUserInternalId != null && 
                 widget.post.uploaderInternalId!.trim().toLowerCase() == gUserInternalId!.trim().toLowerCase());
    
    if (_votedSide == 0 && !isExpired && !isMe) {
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
                        const SizedBox(width: 48), 
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
                        
                        bool isMe = (widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId);
                        if (_votedSide == 0 && !isMe && !isExpired) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표를 먼저 해주세요!')));
                          return;
                        }

                        final newComment = CommentData(
                          user: gNameText, 
                          userId: gIdText,
                          userInternalId: gUserInternalId, 
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
                          widget.post.commentsCount = await _syncCommentsCount();
                        } catch (e) {
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
                      userInternalId: gUserInternalId, 
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
                      widget.post.commentsCount = await _syncCommentsCount();
                    } catch (e) {
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
    return IgnorePointer(
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
        if (kIsWeb) {
          content = isPlaying
              ? ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, VideoPlayerValue value, child) {
                    final bool videoReady = value.position > const Duration(milliseconds: 500) && 
                                            value.size.width > 0 && 
                                            value.isPlaying;
                    if (!videoReady) {
                      return (thumbUrl != null && thumbUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: thumbUrl.trim(),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                            )
                          : const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2));
                    }
                    return FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: value.size.width,
                        height: value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    );
                  },
                )
              : (thumbUrl != null && thumbUrl.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: thumbUrl.trim(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2));
        } else {
          content = FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          );
        }
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
    bool hasVoted = _canViewDiscussionResults;
    return Positioned(
      bottom: 67 + MediaQuery.of(context).padding.bottom, right: 35,
      child: SizedBox(
        width: 120, height: 110,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none, 
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
              top: 66, 
              left: 5, right: 5, 
              child: Center(
                child: FittedBox( 
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
      margin: const EdgeInsets.only(bottom: 5), 
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
    if (c.isHidden && !isPostAuthor) return const SizedBox.shrink();

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
                              try {
                                await SupabaseService.client
                                  .from('comments')
                                  .update({'is_pinned': newPinned})
                                  .eq('id', c.id!);
                              } catch (e) {}
                            } else if (value == '삭제') {
                              final String? commentId = c.id;
                              setSheetState(() {
                                widget.post.comments.removeAt(index);
                                widget.post.commentsCount--;
                              });
                              if (mounted) setState(() {});
                              try {
                                if (commentId != null) {
                                  await SupabaseService.client
                                    .from('comments')
                                    .delete()
                                    .eq('id', commentId);
                                }
                                widget.post.commentsCount = await _syncCommentsCount();
                              } catch (e) {}
                            } else if (value == '숨기기' || value == '숨김해제') {
                              final bool newHidden = !c.isHidden;
                              setSheetState(() => c.isHidden = newHidden);
                              try {
                                await SupabaseService.client
                                  .from('comments')
                                  .update({'is_hidden': newHidden})
                                  .eq('id', c.id!);
                              } catch (e) {}
                            } else if (value == '신고') {
                              _showReportSheet(context);
                            } else if (value == '수정') {
                              _showEditCommentDialog(c, setSheetState);
                            }
                          },
                          itemBuilder: (context) {
                            List<PopupMenuEntry<String>> items = [];
                            if (isPostAuthor) {
                              items.add(PopupMenuItem(value: c.isPinned ? '고정해제' : '고정', child: Text(c.isPinned ? '고정 해제' : '고정', style: const TextStyle(color: Colors.white, fontSize: 13))));
                            }
                            if (isCommentAuthor) {
                              items.add(const PopupMenuItem(value: '수정', child: Text('수정', style: TextStyle(color: Colors.white, fontSize: 13))));
                            }
                            if (isCommentAuthor || isPostAuthor) {
                              items.add(PopupMenuItem(value: '삭제', child: Text('삭제', style: TextStyle(color: isCommentAuthor ? Colors.redAccent : Colors.white, fontSize: 13))));
                            }
                            if (isPostAuthor && !isCommentAuthor) {
                              items.add(PopupMenuItem(value: c.isHidden ? '숨김해제' : '숨기기', child: Text(c.isHidden ? '숨김 해제' : '숨기기', style: const TextStyle(color: Colors.white, fontSize: 13))));
                            }
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
              setSheetState(() => c.text = newText);
              Navigator.pop(context);
              try {
                await SupabaseService.client
                    .from('comments')
                    .update({'text': newText})
                    .eq('id', c.id!);
              } catch (e) {}
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
        if (widget.onReport != null) widget.onReport!(title);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$title" 사유로 신고가 접수되었습니다.'), backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9)));
      },
    );
  }
}

class DonutPainter extends CustomPainter {
  final double percentA;
  final bool isPreVote;
  DonutPainter({required this.percentA, this.isPreVote = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.25;

    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (isPreVote) return;

    final paintA = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    final paintB = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;

    double sweepA = 2 * 3.141592 * percentA;
    double sweepB = 2 * 3.141592 * (1.0 - percentA);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), -3.141592 / 2, sweepA, false, paintA);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), -3.141592 / 2 + sweepA, sweepB, false, paintB);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
