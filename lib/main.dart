import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'dart:async';

// New Imports
import 'models/post_data.dart';
import 'models/comment_data.dart';
import 'core/app_state.dart';
import 'widgets/social_login_button.dart';
import 'widgets/post_view.dart';
import 'screens/upload_screen.dart';
import 'screens/channel_screen.dart';
import 'screens/activity_analysis_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/channel_feed_screen.dart';
import 'screens/point_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_setup_screen.dart';

void main() {
  runApp(const PickGetApp());
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          primary: Colors.cyanAccent,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.cyanAccent,
          selectionColor: Colors.cyanAccent,
          selectionHandleColor: Colors.cyanAccent,
        ),
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
  int _selectedIndex = 0;
  Timer? _loginTimer;
  late List<PostData> _posts;
  List<PostData> _recommendedPosts = [];
  final Set<String> _forcedVisibleIds = {}; // To show expired posts clicked from ranking
  final PageController _pageController = PageController();
  int _userPoints = 0;
  int _selectedTopTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _posts = [
      PostData(id: '1', title: '오늘의 데이트 룩, 뭐가 더 심쿵해?', uploaderId: '@style_guru', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '서울 강남구 ? 2시간 전', imageA: 'assets/images/post1_a.jpg', imageB: 'assets/images/post1_b.jpg', descriptionA: '트렌디한 오버사이즈 핏과 미니멀한 블랙 코디의 정석', descriptionB: '화려한 패턴과 유니크한 액세서리로 완성된 힙스터 룩', likesCount: 1200, commentsCount: 342, voteCountA: '1.2k', voteCountB: '800', percentA: '60%', percentB: '40%', isFollowing: true, fullDescription: '오늘은 홍대에서 데이트하기 좋은 룩 두 가지를 준비해봤어요! 여러분의 선택은 무엇인가요?', tags: ['데이트', '코디', '홍대']),
      PostData(id: '2', title: '출근룩 이거 어떰?', uploaderId: '@office_worker', uploaderImage: 'assets/profiles/profile_32.jpg', timeLocation: '판교 ? 5시간 전', imageA: 'assets/images/post2_a.jpg', imageB: 'assets/images/post2_b.jpg', descriptionA: '깔끔한 셔츠와 슬랙스 조합, 신뢰감을 주는 비즈니스 캐주얼', descriptionB: '편안한 니트와 베이지 면바지, 다정하고 부드러운 오피스 룩', likesCount: 850, commentsCount: 120, voteCountA: '450', voteCountB: '400', percentA: '53%', percentB: '47%', fullDescription: '월요병을 이겨낼 수 있는 상큼한 출근룩 제안입니다. 투표 부탁드려요!', tags: ['출근룩', '오피스', '비즈니스']),
      PostData(id: '3', title: '휴양지 패션 추천좀!', uploaderId: '@traveler_j', uploaderImage: 'assets/profiles/profile_44.jpg', timeLocation: '제주도 ? 1일 전', imageA: 'assets/images/post3_a.jpg', imageB: 'assets/images/post3_b.jpg', descriptionA: '시원한 리넨 셔츠와 반바지, 휴양지의 여유가 느껴지는 스타일', descriptionB: '에스닉한 무드와 로브로 인생샷을 부르는 화려한 바캉스 룩', likesCount: 2500, commentsCount: 890, voteCountA: '1.8k', voteCountB: '700', percentA: '72%', percentB: '28%', isFollowing: true, fullDescription: '다음 주에 발리로 떠나는데 어떤 옷이 더 잘 어울릴까요? 현지 분위기에 맞춰서 골라주세요.', isExpired: true, tags: ['휴양지', '여행', '발리']),
      PostData(id: '4', title: '운동복 뭐가 나을까?', uploaderId: '@gym_rat', uploaderImage: 'assets/profiles/profile_12.jpg', timeLocation: '부산 ? 3시간 전', imageA: 'assets/images/post4_a.jpg', imageB: 'assets/images/post4_b.jpg', descriptionA: '기능성에 집중한 컴프레션 웨어, 운동 효율을 높여주는 복장', descriptionB: '트렌디한 디자인의 조거 팬츠와 후드, 짐웨어로도 일상복으로도 만점', likesCount: 500, commentsCount: 40, voteCountA: '300', voteCountB: '200', percentA: '60%', percentB: '40%', fullDescription: '오운완! 오늘 새로 산 운동복인데 둘 중에 뭐가 더 핏이 좋아 보이나요?', isExpired: true, tags: ['운동', '헬스', '짐웨어']),
      PostData(id: '5', title: '오늘 저녁 뭐 먹지?', uploaderId: '@foodie_kim', uploaderImage: 'assets/profiles/profile_60.jpg', timeLocation: '홍대 ? 10분 전', imageA: 'assets/images/post5_a.jpg', imageB: 'assets/images/post5_b.jpg', descriptionA: '매콤한 감칠맛이 일품인 전통 한식 메뉴, 한국인의 소울 푸드', descriptionB: '치즈가 듬뿍 들어간 정통 이탈리안 파스타, 특별한 날에 어울리는 맛', likesCount: 3000, commentsCount: 1200, voteCountA: '2k', voteCountB: '1k', percentA: '67%', percentB: '33%', isFollowing: true, fullDescription: '결정장애 왔어요... 한식 vs 양식! 여러분의 픽으로 오늘 저녁 메뉴를 정하겠습니다.', tags: ['맛집', '저녁', '메뉴추천']),
      PostData(id: '6', title: '지난주 베스트 코디', uploaderId: '@style_guru', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '서울 ? 1주일 전', imageA: 'assets/images/post1_a.jpg', imageB: 'assets/images/post1_b.jpg', descriptionA: 'A', descriptionB: 'B', likesCount: 5000, commentsCount: 1500, voteCountA: '3k', voteCountB: '2k', percentA: '60%', percentB: '40%', isExpired: true, tags: ['베스트', '코디', '결산']),
      PostData(id: 'my_1', title: '내가 올린 첫 번째 투표! 어떤가요?', uploaderId: '나의 픽겟', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '방금 전', imageA: 'assets/images/post2_a.jpg', imageB: 'assets/images/post2_b.jpg', descriptionA: '깔끔한 화이트', descriptionB: '포근한 웜톤', likesCount: 45, commentsCount: 12, voteCountA: '28', voteCountB: '17', percentA: '62%', percentB: '38%', tags: ['내꺼', '첫투표']),
      PostData(id: 'my_2', title: '오늘 점심 메뉴 골라줘요!', uploaderId: '나의 픽겟', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '1시간 전', imageA: 'assets/images/post5_a.jpg', imageB: 'assets/images/post5_b.jpg', descriptionA: '매콤한 제육', descriptionB: '담백한 돈까스', likesCount: 120, commentsCount: 45, voteCountA: '65', voteCountB: '55', percentA: '54%', percentB: '46%', tags: ['점심', '메뉴']),
    ];
    _refreshRecommended();
    
    gShowLoginPopup = _showLoginPopup;

    _startLoginTimer();
  }

  void _startLoginTimer() {
    _loginTimer?.cancel();
    _loginTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _showLoginPopup();
      }
    });
  }

  @override
  void dispose() {
    _loginTimer?.cancel();
    super.dispose();
  }

  void _refreshRecommended() {
    List<PostData> nonExpired = _posts.where((p) => !p.isExpired && !p.isHidden).toList();
    if (nonExpired.isEmpty) {
      _recommendedPosts = [];
      return;
    }
    
    // Mix 50% Popular, 50% Others
    List<PostData> popular = nonExpired.where((p) => (p.likesCount + p.commentsCount) >= 1000).toList();
    List<PostData> others = nonExpired.where((p) => (p.likesCount + p.commentsCount) < 1000).toList();
    
    popular.shuffle();
    others.shuffle();
    
    int half = (nonExpired.length / 2).ceil();
    List<PostData> mixed = [
      ...popular.take(half),
      ...others.take(nonExpired.length - popular.take(half).length)
    ];
    mixed.shuffle();
    
    setState(() {
      _recommendedPosts = mixed;
    });
  }

  List<PostData> get _filteredPosts {
    // 공통 규칙: 투표 종료된 컨텐츠는 메인 피드에서 제외 (Pick 탭 제외), 숨김 처리된 컨텐츠도 제외
    List<PostData> filtered = _posts.where((p) => !p.isExpired && !p.isHidden).toList();

    switch (_selectedTopTabIndex) {
      case 0: // Recommended: Mixed & Shuffled
        return _recommendedPosts.where((p) => !p.isExpired || _forcedVisibleIds.contains(p.id)).toList();
      case 1: // 팔로우: 내가 팔로우한 채널만
        filtered = filtered.where((p) => p.isFollowing).toList();
        break;
      case 2: // 즐겨찾기: 내가 즐겨찾기한 컨텐츠만
        filtered = filtered.where((p) => p.isBookmarked).toList();
        break;
      case 3: // Pick: 내가 투표한 진행중인 컨텐츠만
        filtered = filtered.where((p) => p.userVotedSide != 0).toList();
        break;
    }
    if (!gIsLoggedIn && _selectedTopTabIndex != 0) return [];
    return filtered;
  }

  void _showLoginSuccessSnackBar(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$platform 로그인 완료!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.cyanAccent, 
        duration: const Duration(seconds: 1)
      ),
    );
  }

  void _showLoginPopup() {
    _loginTimer?.cancel(); // Cancel automatic timer if popup is shown manually or automatically
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.8), // 뒷화면 어둡게
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/simbol.svg',
                    width: 60,
                    height: 60,
                    // Note: Removed color filter if the SVG is multi-colored, 
                    // or use colorFilter if it should be themed.
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PickGet 시작하기',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 40),
                  SocialLoginButton(
                    svgAsset: 'assets/kakao_logo.svg',
                    label: '카카오 로그인',
                    backgroundColor: const Color(0xFFFEE500),
                    textColor: const Color(0xFF191919).withValues(alpha: 0.85),
                    iconSize: 28, 
                    onTap: () async {
                      setState(() { gIsLoggedIn = true; });
                      Navigator.pop(context);
                      
                      // Show Profile Setup after login
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                      );
                      
                      if (result != null) {
                        setState(() { _userPoints += 100; }); // Balanced Welcome Bonus
                        _showLoginSuccessSnackBar('카카오');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SocialLoginButton(
                    svgAsset: 'assets/naver_logo.svg',
                    label: '네이버 로그인',
                    backgroundColor: const Color(0xFF03C75A),
                    textColor: Colors.white,
                    iconSize: 18.7, 
                    fontWeight: FontWeight.bold,
                    onTap: () async {
                      setState(() { gIsLoggedIn = true; });
                      Navigator.pop(context);
                      
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                      );
                      
                      if (result != null) {
                        setState(() { _userPoints += 100; }); // Balanced Welcome Bonus
                        _showLoginSuccessSnackBar('네이버');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SocialLoginButton(
                    svgAsset: 'assets/google_logo.svg',
                    label: 'Google 로그인',
                    backgroundColor: Colors.white,
                    textColor: const Color(0xFF191919),
                    hasBorder: true,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    onTap: () async {
                      setState(() { gIsLoggedIn = true; });
                      Navigator.pop(context);
                      
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                      );
                      
                      if (result != null) {
                        setState(() { _userPoints += 100; }); // Balanced Welcome Bonus
                        _showLoginSuccessSnackBar('Google');
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '나중에 할게요',
                      style: TextStyle(color: Colors.white38, fontSize: 14, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredPosts;
    return Scaffold(
      body: Stack(
        children: [
          if (!gIsLoggedIn && _selectedTopTabIndex != 0)
            _buildLoginRequiredView()
          else
            PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final post = filteredList[index];
              return PostView(
                key: ValueKey(post.id),
                post: post,
                onLike: () { 
                  if (!gIsLoggedIn) {
                    _showLoginPopup();
                    return;
                  }
                  setState(() { 
                    post.isLiked = !post.isLiked; 
                    if (post.isLiked) {
                      post.likesCount++;
                    } else {
                      post.likesCount--;
                    }
                    HapticFeedback.lightImpact();
                  }); 
                },
                onFollow: () { 
                  if (!gIsLoggedIn) {
                    _showLoginPopup();
                    return;
                  }
                  setState(() { 
                    // 동일한 업로더의 모든 포스트 팔로우 상태 업데이트
                    for (var p in _posts) {
                      if (p.uploaderId == post.uploaderId) {
                        p.isFollowing = !post.isFollowing;
                      }
                    }
                    HapticFeedback.mediumImpact();
                  }); 
                },
                onBookmark: () { 
                  if (!gIsLoggedIn) {
                    _showLoginPopup();
                    return;
                  }
                  setState(() { 
                    post.isBookmarked = !post.isBookmarked; 
                    HapticFeedback.selectionClick();
                  }); 
                },
                onNotInterested: () {
                  setState(() {
                    _posts.removeWhere((p) => p.id == post.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('관심없음으로 설정되어 이 포스트가 제외되었습니다.'), duration: Duration(seconds: 1))
                  );
                },
                onDontRecommendChannel: () {
                  String uploaderId = post.uploaderId;
                  setState(() {
                    _posts.removeWhere((p) => p.uploaderId == uploaderId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$uploaderId 채널의 추천을 중단합니다.'), duration: const Duration(seconds: 1))
                  );
                },
                onReport: (reason) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('신고가 접수되었습니다: $reason'), duration: const Duration(seconds: 1))
                  );
                },
                onVote: (side) {
                  if (!gIsLoggedIn) {
                    _showLoginPopup();
                    return;
                  }
                  setState(() {
                    post.userVotedSide = side;
                  });
                },
                onProfileTap: () {
                  if (!gIsLoggedIn) {
                    _showLoginPopup();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelScreen(
                        uploaderId: post.uploaderId,
                        allPosts: _posts,
                        initialPost: post,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
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

  Widget _buildLoginRequiredView() {
    String tabName = ['', '팔로우한 채널', '즐겨찾기한 픽겟', '투표한 픽겟'][_selectedTopTabIndex];
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Colors.cyanAccent, size: 60),
            ),
            const SizedBox(height: 32),
            Text(
              '로그인이 필요한 기능입니다',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '$tabName 확인을 위해\n로그인을 진행해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _showLoginPopup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('로그인하고 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
                    GestureDetector(
                      onTap: () {
                        if (!gIsLoggedIn) {
                          _showLoginPopup();
                          return;
                        }
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PointScreen(currentPoints: _userPoints)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(22)),
                        child: Row(
                          children: [
                            const Text('P ', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                            Text(
                              _userPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () {
                        if (!gIsLoggedIn) {
                          _showLoginPopup();
                          return;
                        }
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchScreen(allPosts: _posts)),
                        );
                      },
                      child: const Icon(Icons.search, color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
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
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedTopTabIndex = index; }); 
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 글자 두께 변화에 따른 흔들림 방지를 위해 Stack 활용
          Stack(
            alignment: Alignment.center,
            children: [
              // 보이지 않는 가장 두꺼운 글자를 배경에 깔아 너비 확보
              Text(
                label,
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              // 실제 보이는 글자
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
                child: Text(label),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 아래 포인트 바도 흔들림 없도록 투명도만 조절
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 20 + bottomPadding, left: 20, right: 20,
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 25)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                
                // Small delay to simulate loading
                await Future.delayed(const Duration(milliseconds: 200));
                
                _refreshRecommended(); 
                
                if (_pageController.hasClients) {
                  _pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                }
              },
              child: const Icon(Icons.home_filled, color: Colors.white, size: 22),
            ),
            GestureDetector(
              onTap: () {
                if (!gIsLoggedIn) {
                  _showLoginPopup();
                  return;
                }
                HapticFeedback.mediumImpact();
                _showRankingSheet(context);
              },
              child: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 20),
            ),
            GestureDetector(
              onTap: () {
                if (!gIsLoggedIn) {
                  _showLoginPopup();
                  return;
                }
                HapticFeedback.heavyImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadScreen()),
                );
              },
              child: Container(
                width: 36, height: 36, 
                decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle), 
                child: const Icon(Icons.add, color: Colors.cyanAccent, size: 26)
              ),
            ),
            GestureDetector(
              onTap: () {
                if (!gIsLoggedIn) {
                  _showLoginPopup();
                  return;
                }
                HapticFeedback.mediumImpact();
                _showNotificationSheet(context);
              },
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
            ),
            GestureDetector(
              onTap: () { 
                if (!gIsLoggedIn) {
                  _showLoginPopup();
                  return;
                }
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => ChannelScreen(uploaderId: '나의 픽겟', allPosts: _posts, initialPost: _posts.first))
                ).then((_) {
                  if (mounted) setState(() {});
                });
              }, 
              child: gIsLoggedIn 
                ? CircleAvatar(radius: 12, backgroundImage: gProfileImage.startsWith('http') ? NetworkImage(gProfileImage) : AssetImage(gProfileImage) as ImageProvider)
                : const Icon(Icons.account_circle_outlined, color: Colors.white54, size: 24),
            ),
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
      builder: (context) => SafeArea(
        child: Container(
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
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
  void _showRankingSheet(BuildContext context) {
    // Simulate Top 10 from master posts list
    List<PostData> topPosts = List.from(_posts);
    topPosts.sort((a, b) => (b.likesCount + b.commentsCount).compareTo(a.likesCount + a.commentsCount));
    topPosts = topPosts.take(10).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
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
              const Text('어제 인기 Pick (TOP 10)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('지난 24시간 동안 가장 뜨거웠던 투표', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const Divider(color: Colors.white10, height: 30),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topPosts.length,
                  itemBuilder: (context, index) {
                    final post = topPosts[index];
                    return _rankingItem(index + 1, post, () {
                      Navigator.pop(context);
                      _navigateToPost(post);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPost(PostData post) {
    setState(() {
      // Switch to Recommended tab
      _selectedTopTabIndex = 0;
      // Force this post to be visible even if it's expired
      _forcedVisibleIds.add(post.id);
      
      // If it's not in the recommended list at all (e.g. was filtered out during shuffle), add it
      if (!_recommendedPosts.any((p) => p.id == post.id)) {
        _recommendedPosts.insert(0, post);
      }
    });
    
    // Give a small delay for state update and PageView rebuild
    Future.microtask(() {
      final filtered = _filteredPosts;
      final index = filtered.indexWhere((p) => p.id == post.id);
      if (index != -1 && _pageController.hasClients) {
        _pageController.jumpToPage(index);
        HapticFeedback.mediumImpact();
      }
    });
  }

  Widget _rankingItem(int rank, PostData post, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank <= 3 ? Colors.cyanAccent : Colors.white24,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontStyle: rank <= 3 ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (post.isExpired ? '[종료] ' : '') + post.title,
                    style: TextStyle(color: post.isExpired ? Colors.white38 : Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCount(post.likesCount + post.commentsCount), // Simple mock for votes/engagement
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const Text(
                  '픽',
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
