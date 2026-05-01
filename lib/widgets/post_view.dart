import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
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
  bool _isSheetOpening = false;

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
    return normalized(widget.post.uploaderId) == normalized('나의 픽겟') || 
           widget.post.uploaderId == 'me' || 
           normalized(widget.post.uploaderId) == normalized(gIdText);
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
        final dynamic targetId = int.tryParse(widget.post.id) ?? widget.post.id;
        await SupabaseService.client.from('posts').delete().eq('id', targetId);
        widget.onDelete(widget.post.id);
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
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showAlreadySelectedToast = false);
    });
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('본인이 올린 질문에는 참여할 수 없습니다.')));
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
        if (_expandedSide == 1) { _expandedSide = 0; _widthA = sw * 0.5; }
        else { _expandedSide = 1; _widthA = sw * 0.8; }
      } else {
        if (_expandedSide == 2) { _expandedSide = 0; _widthA = sw * 0.5; }
        else { _expandedSide = 2; _widthA = sw * 0.2; }
      }
    });
    HapticFeedback.lightImpact();
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
    return LayoutBuilder(
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
                            child: widget.post.imageA.trim().contains('http')
                              ? Image.network(widget.post.imageA.trim(), fit: BoxFit.cover)
                              : Image.asset(widget.post.imageA.trim(), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        // 전경 이미지 (창문 너비에 상관없이 80% 크기로 고정되어 있음)
                        Center(
                          child: OverflowBox(
                            maxWidth: sw * 0.8, // 이미지는 항상 화면의 80% 크기!
                            minWidth: sw * 0.8,
                            child: widget.post.imageA.trim().contains('http')
                              ? Image.network(widget.post.imageA.trim(), fit: BoxFit.cover)
                              : Image.asset(widget.post.imageA.trim(), fit: BoxFit.cover),
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
                            child: widget.post.imageB.trim().contains('http')
                              ? Image.network(widget.post.imageB.trim(), fit: BoxFit.cover)
                              : Image.asset(widget.post.imageB.trim(), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        // 전경 이미지 (80% 크기로 고정)
                        Center(
                          child: OverflowBox(
                            maxWidth: sw * 0.8, // 이미지는 항상 화면의 80% 크기!
                            minWidth: sw * 0.8,
                            child: widget.post.imageB.trim().contains('http')
                              ? Image.network(widget.post.imageB.trim(), fit: BoxFit.cover)
                              : Image.asset(widget.post.imageB.trim(), fit: BoxFit.cover),
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
                top: sh / 2 - 24,
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
                top: sh * 0.28 - 20, left: 15, 
                child: _bgLabel('A', _votedSide == 1 ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.45), 
                  isWinner: isExpired && ((double.tryParse(widget.post.percentA.replaceAll('%', '')) ?? 0) > (double.tryParse(widget.post.percentB.replaceAll('%', '')) ?? 0)))
              ),
              Positioned(
                top: sh * 0.28 - 20, right: 15, 
                child: _bgLabel('B', _votedSide == 2 ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.45), 
                  isWinner: isExpired && ((double.tryParse(widget.post.percentB.replaceAll('%', '')) ?? 0) > (double.tryParse(widget.post.percentA.replaceAll('%', '')) ?? 0)))
              ),
              Positioned(
                top: 160, left: 0, right: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const SizedBox(width: 40), 
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
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 28),
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
                              if (isMe) {
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: '설명',
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.white70, size: 20),
                                        SizedBox(width: 12),
                                        Text('설명', style: TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: widget.post.isHidden ? '보이기' : '숨기기',
                                    child: Row(
                                      children: [
                                        Icon(widget.post.isHidden ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 20),
                                        SizedBox(width: 12),
                                        Text(widget.post.isHidden ? '보이기' : '숨기기', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: '삭제',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                        SizedBox(width: 12),
                                        Text('삭제', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ];
                              } else {
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: '설명',
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.white70, size: 20),
                                        SizedBox(width: 12),
                                        Text('설명', style: TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: '관심없음',
                                    child: Row(
                                      children: [
                                        Icon(Icons.block, color: Colors.white70, size: 20),
                                        SizedBox(width: 12),
                                        Text('관심없음', style: TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: '채널 추천 안함',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_off_outlined, color: Colors.white70, size: 20),
                                        SizedBox(width: 12),
                                        Text('채널 추천 안함', style: TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: '신고',
                                    child: Row(
                                      children: [
                                        Icon(Icons.report_gmailerrorred, color: Colors.redAccent, size: 20),
                                        SizedBox(width: 12),
                                        Text('신고', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ];
                              }
                            },
                          ),
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
                  opacity: _expandedSide == 1 ? 1.0 : 0.0,
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
                  opacity: _expandedSide == 2 ? 1.0 : 0.0,
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
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28, 
                            backgroundImage: widget.post.uploaderImage.startsWith('http')
                              ? NetworkImage(widget.post.uploaderImage)
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
                  top: 260, 
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '이미 선택한 콘텐츠입니다',
                        style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDescriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      const Text('상세 설명', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
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
                  const SizedBox(height: 20),
                  const Text('댓글', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const Divider(color: Colors.white10, height: 30),
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
    return Stack(
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
    ); 
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
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600), maxLines: isExpanded ? 10 : 2, overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis)),
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
    bool hasVoted = _votedSide != 0 || isExpired;
    return Positioned(
      bottom: 67 + MediaQuery.of(context).padding.bottom, right: 35,
      child: SizedBox(
        width: 120, height: 110, // Increased height to accommodate label
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SizedBox(
              width: 58, height: 58,
              child: CustomPaint(
                painter: DonutPainter(percentA: hasVoted ? (double.tryParse(post.percentA.replaceAll('%', '')) ?? 50) / 100 : 1.0, isPreVote: !hasVoted),
                child: Center(child: Text(hasVoted ? 'VS' : 'Pick\nView', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: hasVoted ? 13 : 10, height: 1.1))),
              ),
            ),
            if (hasVoted) Positioned(
              top: 48, left: 0, right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          if (_votedSide == 1) _myPickLabel(),
                          _shadowText(post.percentA, color: Colors.cyanAccent, size: 13, weight: FontWeight.w900), 
                          _shadowText(post.voteCountA, color: Colors.white70, size: 9, weight: FontWeight.bold)
                        ]
                      ),
                      const SizedBox(width: 35),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          if (_votedSide == 2) _myPickLabel(),
                          _shadowText(post.percentB, color: Colors.redAccent, size: 13, weight: FontWeight.w900), 
                          _shadowText(post.voteCountB, color: Colors.white70, size: 9, weight: FontWeight.bold)
                        ]
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myPickLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      margin: const EdgeInsets.only(bottom: 2),
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
                child: CircleAvatar(
                  radius: depth > 0 ? 14 : 18, 
                  backgroundImage: c.image.startsWith('http') 
                    ? NetworkImage(c.image) 
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
                              String displayName = isMe ? '나의 픽겟' : widget.post.uploaderId;
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
                          onSelected: (value) {
                            if (value == '고정' || value == '고정해제') {
                              setSheetState(() {
                                c.isPinned = !c.isPinned;
                                if (c.isPinned) {
                                  widget.post.comments.removeAt(index);
                                  widget.post.comments.insert(0, c);
                                }
                              });
                            } else if (value == '삭제') {
                              setSheetState(() {
                                widget.post.comments.removeAt(index);
                                widget.post.commentsCount--;
                              });
                              if (mounted) {
                                setState(() {});
                              }
                              try {
                                SupabaseService.client
                                  .from('posts')
                                  .update({'comments_count': widget.post.commentsCount})
                                  .eq('id', widget.post.id);
                              } catch (e) {
                                print('댓글삭제 에러: $e');
                              }
                            } else if (value == '숨기기' || value == '숨김해제') {
                              setSheetState(() {
                                c.isHidden = !c.isHidden;
                              });
                            } else if (value == '신고') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
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
            onPressed: () {
              setSheetState(() {
                c.text = controller.text;
              });
              Navigator.pop(context);
            }, 
            child: const Text('수정', style: TextStyle(color: Colors.cyanAccent))
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    String? selectedReason;
    final List<String> reasons = ['스팸 또는 홍보', '부적절한 콘텐츠', '저작권 침해', '증오 표현 또는 괴롭힘', '허위 정보', '기타'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(color: Color(0xFF121212), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 25),
                const Text('신고 사유 선택', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                // ignore: deprecated_member_use
                Column(children: reasons.map((reason) => RadioListTile<String>(title: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 15)), value: reason, groupValue: selectedReason, activeColor: Colors.redAccent, 
                  // ignore: deprecated_member_use
                  onChanged: (val) => setSheetState(() => selectedReason = val), contentPadding: EdgeInsets.zero)).toList()),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: selectedReason == null ? null : () { Navigator.pop(context); widget.onReport(selectedReason!); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text('신고하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
