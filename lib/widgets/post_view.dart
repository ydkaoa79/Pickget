import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import '../models/post_data.dart';
import '../models/comment_data.dart';
import '../core/app_state.dart';
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
    this.onProfileTap
  });
  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
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

  @override
  void initState() {
    super.initState();
    if (widget.post.isExpired) {
      _remainingSeconds = 0;
    } else {
      _remainingSeconds = widget.post.id == '1' ? 15 : 3600;
    }
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
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

  void _onVote(int side) {
    if (!gIsLoggedIn) {
      gShowLoginPopup?.call();
      return;
    }
    if (_votedSide != 0) return;
    
    if (widget.post.uploaderId == '나의 픽겟') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('본인이 올린 질문에는 참여할 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _votedSide = side;
      
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final sw = constraints.maxWidth;
        final sh = constraints.maxHeight;
        if (_widthA == null && sw > 0) _widthA = sw * 0.5;
        final currentWidthA = _widthA ?? (sw > 0 ? sw * 0.5 : 0.0);
        const double descWidth = 175.0;
        bool isExpired = _remainingSeconds <= 0;

        return GestureDetector(
          onTapUp: (d) => _handleTap(d, sw),
          onPanUpdate: (d) => _onPanUpdate(d, sw),
          onPanEnd: (d) => _onPanEnd(d, sw),
          child: Stack(
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: currentWidthA, 
                    height: sh, 
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: widget.post.imageA.startsWith('http')
                              ? Image.network(widget.post.imageA, fit: BoxFit.cover)
                              : Image.asset(widget.post.imageA, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: (sw - currentWidthA).clamp(0.0, sw), 
                    height: sh, 
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: widget.post.imageB.startsWith('http')
                              ? Image.network(widget.post.imageB, fit: BoxFit.cover)
                              : Image.asset(widget.post.imageB, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, -25),
                  child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: sh * 0.7), 
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            AnimatedContainer(
                              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                              curve: Curves.easeOutCubic, 
                              width: currentWidthA, 
                              child: ClipRect(
                                child: UnconstrainedBox(
                                  clipBehavior: Clip.hardEdge,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: sw * 0.8,
                                    child: widget.post.imageA.startsWith('http')
                                      ? Image.network(widget.post.imageA, fit: BoxFit.fitWidth, alignment: Alignment.topCenter)
                                      : Image.asset(widget.post.imageA, fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
                                  ),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                              curve: Curves.easeOutCubic, 
                              width: (sw - currentWidthA).clamp(0.0, sw), 
                              child: ClipRect(
                                child: UnconstrainedBox(
                                  clipBehavior: Clip.hardEdge,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: sw * 0.8,
                                    child: widget.post.imageB.startsWith('http')
                                      ? Image.network(widget.post.imageB, fit: BoxFit.fitWidth, alignment: Alignment.topCenter)
                                      : Image.asset(widget.post.imageB, fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                        curve: Curves.easeOutCubic, 
                        left: (currentWidthA - 24).clamp(-24.0, sw - 24.0), 
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
                    ],
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
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                            ],
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
                                        widget.post.uploaderId, 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: widget.onFollow,
                                      child: _followBtn(widget.post.isFollowing),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(widget.post.timeLocation, style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
                          widget.post.isLiked ? Icons.favorite : Icons.favorite_border, 
                          formatCount(widget.post.likesCount),
                          color: widget.post.isLiked ? Colors.redAccent : Colors.white,
                          onTap: widget.onLike,
                        ),
                        const SizedBox(width: 20),
                        _statIcon(Icons.chat_bubble_outline, formatCount(widget.post.commentsCount), onTap: () => _showCommentsSheet(context)),
                        const SizedBox(width: 20),
                        _statIcon(
                          widget.post.isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
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
              if (_showAlreadySelectedToast)
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

  void _showCommentsSheet(BuildContext context) {
    // 본인 게시글('me')이 아니면서 투표도 안 한 경우만 팝업 표시
    if (_votedSide == 0 && !isExpired && widget.post.uploaderId != 'me') {
      showDialog(
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
    } else {
      final TextEditingController commentController = TextEditingController();
      showModalBottomSheet(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.post.comments.length,
                      itemBuilder: (context, idx) {
                        final c = widget.post.comments[idx];
                        return _commentItem(c.user, c.text, c.side, c.image, widget.post.isExpired);
                      },
                    ),
                  ),
                  _commentInput(commentController, setSheetState),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _commentInput(TextEditingController controller, StateSetter setSheetState) {
    return Container(
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
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setSheetState(() {
                      widget.post.comments.add(CommentData(
                        user: '나 (본인)', 
                        text: val, 
                        side: _votedSide, 
                        image: 'assets/profiles/profile_11.jpg',
                      ));
                      controller.clear();
                    });
                    FocusScope.of(context).unfocus(); // 엔터 시 키보드 닫기
                  }
                },
                decoration: const InputDecoration(
                  hintText: '의견을 나눠보세요...', 
                  hintStyle: TextStyle(color: Colors.white38), 
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (controller.text.trim().isNotEmpty) {
                setSheetState(() {
                  widget.post.comments.add(CommentData(
                    user: '나 (본인)', 
                    text: controller.text, 
                    side: _votedSide, 
                    image: 'assets/profiles/profile_11.jpg',
                  ));
                  controller.clear();
                });
                FocusScope.of(context).unfocus(); // 전송 후 키보드 닫기
              }
            },
            child: const Icon(Icons.send_rounded, color: Colors.cyanAccent),
          ),
        ],
      ),
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
          Text(isFollowing ? '팔로잉' : '팔로우', style: TextStyle(color: isFollowing ? Colors.white70 : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
          Icon(icon, color: color, size: 30), 
          const SizedBox(height: 5), 
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
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
        width: 120, height: 90,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_shadowText(post.percentA, color: Colors.cyanAccent, size: 13, weight: FontWeight.w900), _shadowText(post.voteCountA, color: Colors.white70, size: 9, weight: FontWeight.bold)]),
                  const SizedBox(width: 35),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_shadowText(post.percentB, color: Colors.redAccent, size: 13, weight: FontWeight.w900), _shadowText(post.voteCountB, color: Colors.white70, size: 9, weight: FontWeight.bold)]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shadowText(String text, {required Color color, required double size, required FontWeight weight}) {
    return Text(text, style: TextStyle(color: color, fontSize: size, fontWeight: weight, letterSpacing: -0.5, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6, offset: const Offset(0, 1))]));
  }

  Widget _commentItem(String name, String text, int votedSide, String imageUrl, bool isPostExpired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2), // 테두리 두께
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: votedSide == 1 ? Colors.cyanAccent : (votedSide == 2 ? Colors.redAccent : Colors.transparent),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 18, 
              backgroundImage: imageUrl.startsWith('http') 
                ? NetworkImage(imageUrl) 
                : AssetImage(imageUrl) as ImageProvider
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3))])),
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
