import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';

void main() {
  runApp(const PickGetApp());
}

class PostData {
  final String id;
  final String title;
  final String uploaderId;
  final String uploaderImage;
  final String timeLocation;
  final String imageA;
  final String imageB;
  final String descriptionA;
  final String descriptionB;
  int likesCount;
  int commentsCount;
  String voteCountA;
  String voteCountB;
  String percentA;
  String percentB;
  bool isFollowing;
  bool isBookmarked;
  bool isLiked;

  PostData({
    required this.id,
    required this.title,
    required this.uploaderId,
    required this.uploaderImage,
    required this.timeLocation,
    required this.imageA,
    required this.imageB,
    required this.descriptionA,
    required this.descriptionB,
    required this.likesCount,
    required this.commentsCount,
    required this.voteCountA,
    required this.voteCountB,
    required this.percentA,
    required this.percentB,
    this.isFollowing = false,
    this.isBookmarked = false,
    this.isLiked = false,
  });
}

class PickGetApp extends StatelessWidget {
  const PickGetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PickGet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Pretendard',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late List<PostData> _posts;
  final PageController _pageController = PageController();
  int _selectedTopTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _posts = [
      PostData(id: '1', title: '오늘의 데이트 룩, 뭐가 더 심쿵해?', uploaderId: '@style_guru', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '서울 강남구 • 2시간 전', imageA: 'assets/images/post1_a.jpg', imageB: 'assets/images/post1_b.jpg', descriptionA: '트렌디한 오버사이즈 핏과 미니멀한 블랙 코디의 정석', descriptionB: '화려한 패턴과 유니크한 액세서리로 완성된 힙스터 룩', likesCount: 1200, commentsCount: 342, voteCountA: '1.2k', voteCountB: '800', percentA: '60%', percentB: '40%', isFollowing: true),
      PostData(id: '2', title: '출근룩 이거 어떰?', uploaderId: '@office_worker', uploaderImage: 'assets/profiles/profile_32.jpg', timeLocation: '판교 • 5시간 전', imageA: 'assets/images/post2_a.jpg', imageB: 'assets/images/post2_b.jpg', descriptionA: '깔끔한 셔츠와 슬랙스 조합, 신뢰감을 주는 비즈니스 캐주얼', descriptionB: '편안한 니트와 베이지 면바지, 다정하고 부드러운 오피스 룩', likesCount: 850, commentsCount: 120, voteCountA: '450', voteCountB: '400', percentA: '53%', percentB: '47%'),
      PostData(id: '3', title: '휴양지 패션 추천좀!', uploaderId: '@traveler_j', uploaderImage: 'assets/profiles/profile_44.jpg', timeLocation: '제주도 • 1일 전', imageA: 'assets/images/post3_a.jpg', imageB: 'assets/images/post3_b.jpg', descriptionA: '시원한 리넨 셔츠와 반바지, 휴양지의 여유가 느껴지는 스타일', descriptionB: '에스닉한 무드와 로브로 인생샷을 부르는 화려한 바캉스 룩', likesCount: 2500, commentsCount: 890, voteCountA: '1.8k', voteCountB: '700', percentA: '72%', percentB: '28%', isFollowing: true),
      PostData(id: '4', title: '운동복 뭐가 나을까?', uploaderId: '@gym_rat', uploaderImage: 'assets/profiles/profile_12.jpg', timeLocation: '부산 • 3시간 전', imageA: 'assets/images/post4_a.jpg', imageB: 'assets/images/post4_b.jpg', descriptionA: '기능성에 집중한 컴프레션 웨어, 운동 효율을 높여주는 복장', descriptionB: '트렌디한 디자인의 조거 팬츠와 후드, 짐웨어로도 일상복으로도 만점', likesCount: 500, commentsCount: 40, voteCountA: '300', voteCountB: '200', percentA: '60%', percentB: '40%'),
      PostData(id: '5', title: '오늘 저녁 뭐 먹지?', uploaderId: '@foodie_kim', uploaderImage: 'assets/profiles/profile_60.jpg', timeLocation: '홍대 • 10분 전', imageA: 'assets/images/post5_a.jpg', imageB: 'assets/images/post5_b.jpg', descriptionA: '매콤한 감칠맛이 일품인 전통 한식 메뉴, 한국인의 소울 푸드', descriptionB: '치즈가 듬뿍 들어간 정통 이탈리안 파스타, 특별한 날에 어울리는 맛', likesCount: 3000, commentsCount: 1200, voteCountA: '2k', voteCountB: '1k', percentA: '67%', percentB: '33%', isFollowing: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return PostView(
                post: _posts[index],
                onLike: () { 
                  setState(() { 
                    _posts[index].isLiked = !_posts[index].isLiked; 
                    if (_posts[index].isLiked) _posts[index].likesCount++;
                    else _posts[index].likesCount--;
                    HapticFeedback.lightImpact();
                  }); 
                },
                onFollow: () { 
                  setState(() { 
                    _posts[index].isFollowing = !_posts[index].isFollowing; 
                    HapticFeedback.mediumImpact();
                  }); 
                },
                onBookmark: () { 
                  setState(() { 
                    _posts[index].isBookmarked = !_posts[index].isBookmarked; 
                    HapticFeedback.selectionClick();
                  }); 
                },
              );
            },
          ),
          _buildTopBar(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/logo.png', height: 30, fit: BoxFit.contain),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(22)),
                      child: const Row(
                        children: [
                          Text('P ', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                          Text('12,323', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Icon(Icons.search, color: Colors.white, size: 32),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _topTab('추천', 0),
              const SizedBox(width: 25),
              _topTab('팔로우', 1),
              const SizedBox(width: 25),
              _topTab('즐겨찾기', 2),
              const SizedBox(width: 25),
              _topTab('Pick', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topTab(String label, int index) {
    final isSelected = _selectedTopTabIndex == index;
    return GestureDetector(
      onTap: () { setState(() { _selectedTopTabIndex = index; }); },
      child: Column(
        children: [
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 16, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500)),
          if (isSelected) Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 30, left: 20, right: 20,
      child: Container(
        height: 74,
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(37), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 25)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.home_filled, color: Colors.white, size: 32),
            const Icon(Icons.emoji_events_outlined, color: Colors.white54, size: 30),
            Container(width: 54, height: 54, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.cyanAccent, size: 38)),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showNotificationSheet(context);
              },
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 30),
            ),
            const CircleAvatar(radius: 18, backgroundImage: AssetImage('assets/profiles/profile_5.jpg')),
          ],
        ),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('알림', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const Divider(color: Colors.white10, height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _notificationItem(Icons.favorite, Colors.redAccent, '내 포스트에 좋아요가 달렸습니다.', '3분 전'),
                  _notificationItem(Icons.chat_bubble, Colors.cyanAccent, '새로운 댓글이 추가되었습니다: "와 저도 A!"', '12분 전'),
                  _notificationItem(Icons.monetization_on, Colors.amberAccent, '투표 참여로 10P를 획득했습니다.', '1시간 전'),
                  _notificationItem(Icons.person_add, Colors.purpleAccent, 'traveler_j님이 회원님을 팔로우하기 시작했습니다.', '3시간 전'),
                  _notificationItem(Icons.star, Colors.orangeAccent, '이번 주의 인기 Pick으로 선정되었습니다!', '어제'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem(IconData icon, Color color, String message, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostView extends StatefulWidget {
  final PostData post;
  final VoidCallback onLike;
  final VoidCallback onFollow;
  final VoidCallback onBookmark;
  const PostView({super.key, required this.post, required this.onLike, required this.onFollow, required this.onBookmark});
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

  @override
  void initState() {
    super.initState();
    // For demo: first post ends in 15 seconds, others in 1 hour
    _remainingSeconds = widget.post.id == '1' ? 15 : 3600;
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

  void _onPanUpdate(DragUpdateDetails details, double sw) {
    // Always allow swiping to inspect photos, but limit range to 20%~80%
    setState(() { 
      _isDragging = true; 
      _widthA = ((_widthA ?? (sw * 0.5)) + details.delta.dx).clamp(sw * 0.2, sw * 0.8); 
    });
  }

  void _onPanEnd(DragEndDetails details, double sw) {
    bool isExpired = _remainingSeconds <= 0;
    setState(() {
      _isDragging = false;
      double currentWidthA = _widthA ?? (sw * 0.5);
      
      // Vote threshold check
      if (currentWidthA > sw * 0.65) {
        if (!isExpired && _votedSide == 0) {
          _votedSide = 1;
          _triggerPointToast();
        }
        HapticFeedback.heavyImpact();
      } else if (currentWidthA < sw * 0.35) {
        if (!isExpired && _votedSide == 0) {
          _votedSide = 2;
          _triggerPointToast();
        }
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }

      // ALWAYS return to 50:50 after swiping
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
              // Full Screen Blur Backgrounds
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
                            child: Image.asset(widget.post.imageA, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),
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
                            child: Image.asset(widget.post.imageB, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ],
              ),
              // Sharp Foreground Images: TRUE Center Reveal + STABLE VERTICAL CENTER
              Positioned.fill(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // The Image Pair
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: sh * 0.7), 
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            // Side A Window
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
                                    child: Image.asset(
                                      widget.post.imageA, 
                                      fit: BoxFit.fitWidth,
                                      alignment: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Side B Window
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
                                    child: Image.asset(
                                      widget.post.imageB, 
                                      fit: BoxFit.fitWidth,
                                      alignment: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // VS Badge
                      AnimatedPositioned(
                        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                        curve: Curves.easeOutCubic, 
                        left: (currentWidthA - 24).clamp(-24.0, sw - 24.0), 
                        child: IgnorePointer(
                          child: Container(
                            width: 48, height: 48, 
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18)), 
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
              IgnorePointer(child: Container(color: Colors.black.withOpacity(0.15))),
              // Background Labels A/B with Small Crown on Winner
              Positioned(
                top: sh * 0.28, left: 15, 
                child: _bgLabel('A', _votedSide == 1 ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.45), isWinner: isExpired && (widget.post.percentA.compareTo(widget.post.percentB) > 0))
              ),
              Positioned(
                top: sh * 0.28, right: 15, 
                child: _bgLabel('B', _votedSide == 2 ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.45), isWinner: isExpired && (widget.post.percentB.compareTo(widget.post.percentA) > 0))
              ),
              Positioned(
                top: 180, left: 0, right: 0,
                child: Column(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 40), Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.post.title, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1.5, shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 2))]), maxLines: 1)))), const Icon(Icons.more_vert, color: Colors.white70, size: 28)])),
                    const SizedBox(height: 12),
                    Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1), width: 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.access_time, color: isExpired ? Colors.white38 : Colors.cyanAccent, size: 18), const SizedBox(width: 6), Text(isExpired ? '투표종료' : _formatTimer(_remainingSeconds), style: TextStyle(color: isExpired ? Colors.white38 : Colors.white, fontWeight: FontWeight.w900, fontSize: 12))]))),
                    // Voting Guide Text
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
              AnimatedPositioned(duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), curve: Curves.easeOutCubic, bottom: 265, left: (currentWidthA / 2) - (descWidth / 2), child: _descBox(widget.post.descriptionA)),
              AnimatedPositioned(duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), curve: Curves.easeOutCubic, bottom: 265, left: currentWidthA + ((sw - currentWidthA) / 2) - (descWidth / 2), child: _descBox(widget.post.descriptionB)),
              Positioned(
                bottom: 115, left: 18, right: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 28, backgroundImage: AssetImage(widget.post.uploaderImage)),
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
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _statIcon(
                          widget.post.isLiked ? Icons.favorite : Icons.favorite_border, 
                          widget.post.likesCount.toString(),
                          color: widget.post.isLiked ? Colors.redAccent : Colors.white,
                          onTap: widget.onLike,
                        ),
                        const SizedBox(width: 35),
                        _statIcon(Icons.chat_bubble_outline, widget.post.commentsCount.toString(), onTap: () {
                          if (_votedSide == 0) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('투표 후 참여 가능', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                content: const Text('댓글을 확인하고 의견을 나누려면\n먼저 어느 쪽이든 Pick 해주세요!', style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('확인', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setSheetState) => Container(
                                  height: MediaQuery.of(context).size.height * 0.75, 
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF121212),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 12),
                                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                                      const SizedBox(height: 20),
                                      const Text('댓글', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                      const Divider(color: Colors.white10, height: 30),
                                      Expanded(
                                        child: ListView(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          children: [
                                            _commentItem('멋진 여행자', '와! 저는 A가 훨씬 세련되어 보여요. 스타일이 딱 제 취향!', 1, 'assets/profiles/profile_15.jpg'),
                                            _commentItem('패션매니아', '에이, 그래도 겨울엔 레드 포인트가 있는 B가 진리죠!', 2, 'assets/profiles/profile_20.jpg'),
                                            _commentItem('깔끔쟁이', 'A의 사이언 컬러가 사진의 전체적인 무드랑 너무 잘 어울리네요.', 1, 'assets/profiles/profile_35.jpg'),
                                            _commentItem('익명러', 'B가 더 고급스러워 보여요. 저만 그런가요?', 2, 'assets/profiles/profile_68.jpg'),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.only(
                                          left: 16, right: 16, top: 12, 
                                          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E1E),
                                          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                child: const TextField(
                                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                                  decoration: InputDecoration(
                                                    hintText: '의견을 나눠보세요...',
                                                    hintStyle: TextStyle(color: Colors.white38),
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        }),
                        const SizedBox(width: 35),
                        _statIcon(
                          widget.post.isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                          '',
                          color: widget.post.isBookmarked ? Colors.amberAccent : Colors.white,
                          onTap: widget.onBookmark,
                        ),
                        const SizedBox(width: 35),
                        _statIcon(Icons.share, '', onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유 링크가 복사되었습니다!'), duration: Duration(seconds: 1)));
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              _buildChart(widget.post),
              // POINT TOAST (+10P): Simple, Clean, Cyan, Slow & Smooth
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
                              shadows: [Shadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 15)],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _followBtn(bool isFollowing) {
    return Container(
      width: 72, // Fixed width to prevent layout shift
      height: 28, // Fixed height
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFollowing ? Colors.cyanAccent.withOpacity(0.1) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isFollowing ? Colors.cyanAccent.withOpacity(0.4) : Colors.transparent, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center icons and text
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFollowing ? Icons.check : Icons.add, color: isFollowing ? Colors.cyanAccent : Colors.white, size: 12),
          const SizedBox(width: 4),
          Transform.translate(
            offset: const Offset(0, -2), // Shift text up by 2px
            child: Text(
              isFollowing ? '팔로잉' : '팔로우', 
              style: TextStyle(
                color: isFollowing ? Colors.cyanAccent : Colors.white, 
                fontSize: 10, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _bgLabel(String text, Color color, {bool isWinner = false}) { 
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        if (isWinner)
          Positioned(
            top: -18,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 24),
                );
              },
            ),
          ),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300), 
          style: TextStyle(
            color: color, 
            fontSize: 45, 
            fontFamily: 'Pretendard', 
            fontWeight: FontWeight.w900, 
            letterSpacing: -4, 
            shadows: [Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
          ), 
          child: Text(text)
        ),
      ],
    ); 
  }
  Widget _descBox(String text) { return ClipRRect(borderRadius: BorderRadius.circular(15), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(width: 175, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.15))), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)))); }
  Widget _statIcon(IconData icon, String value, {Color color = Colors.white, VoidCallback? onTap}) { 
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30), 
          const SizedBox(height: 5), 
          SizedBox(
            height: 14, // Fixed height to ensure icon alignment
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(PostData post) {
    bool hasVoted = _votedSide != 0;
    
    return Positioned(
      bottom: 102, // Lowered to be closer to nav bar
      right: 35,   // Aligns donut center with profile icon's left edge
      child: SizedBox(
        width: 120, 
        height: 90, // More compact height
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Donut (Fixed Top)
            SizedBox(
              width: 58, height: 58,
              child: CustomPaint(
                painter: DonutPainter(
                  percentA: hasVoted ? (double.tryParse(post.percentA.replaceAll('%', '')) ?? 50) / 100 : 1.0,
                  isPreVote: !hasVoted,
                ),
                child: Center(
                  child: Text(
                    hasVoted ? 'VS' : 'Pick\nView', 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: hasVoted ? 13 : 10,
                      height: 1.1,
                      shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                  ),
                ),
              ),
            ),
            // Stats (Overlapping slightly with the donut)
            if (hasVoted) Positioned(
              top: 48, // Overlaps with the bottom part of the 58px donut
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end, // Align towards the donut
                  children: [
                    _shadowText(post.percentA, color: Colors.cyanAccent, size: 13, weight: FontWeight.w900),
                    _shadowText(post.voteCountA, color: Colors.white70, size: 9, weight: FontWeight.bold),
                  ],
                ),
                const SizedBox(width: 35), // Increased gap (+3px each side)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, // Align towards the donut
                  children: [
                    _shadowText(post.percentB, color: Colors.redAccent, size: 13, weight: FontWeight.w900),
                    _shadowText(post.voteCountB, color: Colors.white70, size: 9, weight: FontWeight.bold),
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

  Widget _shadowText(String text, {required Color color, required double size, required FontWeight weight}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.5,
        shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 6, offset: const Offset(0, 1))],
      ),
    );
  }

  Widget _commentItem(String name, String text, int votedSide, String imageUrl) {
    Color teamColor = votedSide == 1 ? Colors.cyanAccent : Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: teamColor, width: 2),
              boxShadow: [BoxShadow(color: teamColor.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)],
            ),
            child: CircleAvatar(radius: 18, backgroundImage: AssetImage(imageUrl)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
                const SizedBox(height: 4),
                const Text('5분 전', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final double percentA; final bool isPreVote;
  DonutPainter({required this.percentA, this.isPreVote = false});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); final radius = size.width / 2 - 4; final strokeWidth = 7.0;
    final paintBg = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);
    if (isPreVote) {
      final paintWhite = Paint()..color = Colors.white.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, paintWhite);
    } else {
      final paintA = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      final paintB = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      
      // Draw Side A (Cyan) on the LEFT (Counter-clockwise from top)
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, -2 * 3.14159 * percentA, false, paintA);
      // Draw Side B (Red) on the RIGHT (Clockwise from top)
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, 2 * 3.14159 * (1 - percentA), false, paintB);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}