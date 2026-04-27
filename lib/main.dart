import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
// Global Profile State
String gProfileImage = 'assets/profiles/profile_11.jpg';
String gNameText = '나의 픽겟';
String gIdText = '@나의_픽겟';
String gBioText = '세상의 모든 선택지를 픽겟하다. 하고 싶은 거 다 해요 ✨ 매일 새로운 투표로 여러분의 선택을 기다립니다!';

String formatCount(int count) {
  if (count >= 1000000) {
    double m = count / 1000000;
    return m == m.toInt().toDouble() ? "${m.toInt()}M" : "${m.toStringAsFixed(1)}M";
  } else if (count >= 1000) {
    double k = count / 1000;
    return k == k.toInt().toDouble() ? "${k.toInt()}k" : "${k.toStringAsFixed(1)}k";
  }
  return count.toString();
}

String getEmpathyLevel(int percent) {
  if (percent <= 20) return '매우 낮음';
  if (percent <= 40) return '낮음';
  if (percent <= 60) return '보통';
  if (percent <= 80) return '높음';
  return '매우 높음';
}

void main() {
  runApp(const PickGetApp());
}

class CommentData {
  final String user;
  final String text;
  final int side;
  final String image;

  CommentData({required this.user, required this.text, required this.side, required this.image});
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
  bool isFollowing = false;
  bool isBookmarked = false;
  bool isLiked = false;
  bool isHidden = false;
  final String fullDescription;
  bool isExpired = false;
  int userVotedSide = 0; // 0: none, 1: A, 2: B
  List<CommentData> comments;
  final String? shortDescA;
  final String? shortDescB;
  final List<String>? tags;

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
    this.shortDescA,
    this.shortDescB,
    this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.voteCountA,
    required this.voteCountB,
    required this.percentA,
    required this.percentB,
    this.isFollowing = false,
    this.isBookmarked = false,
    this.isLiked = false,
    this.isHidden = false,
    this.fullDescription = "이 포스트에 대한 상세 설명이 여기에 표시됩니다. 업로드 시 입력한 기타 설명글이 나타나는 공간입니다.",
    this.isExpired = false,
    this.userVotedSide = 0,
    List<CommentData>? comments,
  }) : comments = comments ?? [
    CommentData(user: '멋진 여행자', text: '와! 저는 A가 훨씬 세련되어 보여요. 스타일이 딱 제 취향!', side: 1, image: 'assets/profiles/profile_15.jpg'),
    CommentData(user: '패션매니아', text: '에이, 그래도 겨울엔 레드 포인트가 있는 B가 진리죠!', side: 2, image: 'assets/profiles/profile_20.jpg'),
    CommentData(user: '깔끔쟁이', text: 'A의 사이언 컬러가 사진의 전체적인 무드랑 너무 잘 어울리네요.', side: 1, image: 'assets/profiles/profile_35.jpg'),
    CommentData(user: '익명러', text: 'B가 더 고급스러워 보여요. 저만 그런가요?', side: 2, image: 'assets/profiles/profile_68.jpg'),
  ];
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
  late List<PostData> _posts;
  List<PostData> _recommendedPosts = [];
  final Set<String> _forcedVisibleIds = {}; // To show expired posts clicked from ranking
  final PageController _pageController = PageController();
  int _userPoints = 1250;
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
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredPosts;
    return Scaffold(
      body: Stack(
        children: [
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
                  setState(() {
                    post.userVotedSide = side;
                  });
                },
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelScreen(
                        uploaderId: post.uploaderId,
                        allPosts: _posts,
                        initialPost: post,
                      ),
                    ),
                  );
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
                    GestureDetector(
                      onTap: () {
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
                HapticFeedback.mediumImpact();
                _showRankingSheet(context);
              },
              child: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 20),
            ),
            GestureDetector(
              onTap: () {
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
                HapticFeedback.mediumImpact();
                _showNotificationSheet(context);
              },
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
            ),
            GestureDetector(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelScreen(uploaderId: '나의 픽겟', allPosts: _posts, initialPost: _posts.first))); }, child: CircleAvatar(radius: 12, backgroundImage: gProfileImage.startsWith('http') ? NetworkImage(gProfileImage) : AssetImage(gProfileImage) as ImageProvider)),
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
  const PostView({super.key, required this.post, required this.onLike, required this.onFollow, required this.onBookmark, required this.onNotInterested, required this.onDontRecommendChannel, required this.onReport, required this.onVote, this.onProfileTap});
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

  @override
  void initState() {
    super.initState();
    // For demo: first post ends in 15 seconds, others in 1 hour
    // Set initial timer based on expiration status
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

  void _onVote(int side) {
    if (_votedSide != 0) return;
    
    // 1. Prevent self-voting
    if (widget.post.uploaderId == '마이픽겟') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('본인이 올린 투표에는 참여할 수 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _votedSide = side;
      
      // 2. Update statistics reactively
      int parseV(String s) {
        s = s.toLowerCase().replaceAll(',', '').trim();
        if (s.isEmpty) return 0;
        if (s.endsWith('k')) {
          return (double.tryParse(s.substring(0, s.length - 1)) ?? 0 * 1000).toInt();
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
      
      // 3. Target Goal Check (Removed buggy test logic)
    });

    widget.onVote(side);
    _triggerPointToast();
    HapticFeedback.heavyImpact();
  }

  bool get isExpired => _remainingSeconds <= 0 || widget.post.isExpired;

  void _onPanUpdate(DragUpdateDetails details, double sw) {
    // Always allow swiping to inspect photos, but limit range to 20%~80%
    setState(() { 
      _isDragging = true; 
      _widthA = ((_widthA ?? (sw * 0.5)) + details.delta.dx).clamp(sw * 0.2, sw * 0.8); 
    });
  }

  void _onPanEnd(DragEndDetails details, double sw) {
    setState(() {
      _isDragging = false;
      double currentWidthA = _widthA ?? (sw * 0.5);
      
      // Vote threshold check
      if (currentWidthA > sw * 0.65) {
        if (!isExpired && _votedSide == 0) {
          _onVote(1);
        } else {
          HapticFeedback.heavyImpact();
        }
      } else if (currentWidthA < sw * 0.35) {
        if (!isExpired && _votedSide == 0) {
          _onVote(2);
        } else {
          HapticFeedback.heavyImpact();
        }
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
              // Sharp Foreground Images: TRUE Center Reveal + STABLE VERTICAL CENTER
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(0, -25),
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
                                    child: widget.post.imageA.startsWith('http')
                                      ? Image.network(widget.post.imageA, fit: BoxFit.fitWidth, alignment: Alignment.topCenter)
                                      : Image.asset(widget.post.imageA, fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
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
                      // VS Badge
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
              // Background Labels A/B with Small Crown on Winner
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
                                  widget.post.title.replaceAll('[종료] ', ''), // Double check to remove tag if any
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
                                                  const SizedBox(width: 48), // Spacer for balance
                                                  const Text(
                                                    '상세 설명',
                                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                                    onPressed: () => Navigator.pop(context),
                                                  ),
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
                                                  Text(
                                                    widget.post.title,
                                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.w900),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Text(
                                                    widget.post.fullDescription,
                                                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.8, fontWeight: FontWeight.w400),
                                                  ),
                                                  const SizedBox(height: 40),
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.05),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(color: Colors.white10),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.tips_and_updates_outlined, color: Colors.amberAccent),
                                                        const SizedBox(width: 12),
                                                        const Expanded(
                                                          child: Text(
                                                            '팁: 투표 후에 댓글을 통해 다른 사용자들과 더 깊은 대화를 나눠보세요!',
                                                            style: TextStyle(color: Colors.white70, fontSize: 13),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
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
                    Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.access_time, color: isExpired ? Colors.white38 : Colors.cyanAccent, size: 18), const SizedBox(width: 6), Text(isExpired ? '투표종료' : _formatTimer(_remainingSeconds), style: TextStyle(color: isExpired ? Colors.white38 : Colors.white, fontWeight: FontWeight.w900, fontSize: 12))]))),
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
                        _statIcon(Icons.chat_bubble_outline, formatCount(widget.post.commentsCount), onTap: () {
                          if (_votedSide == 0 && !isExpired) {
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
                            final TextEditingController commentController = TextEditingController();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setSheetState) => SafeArea(
                                  child: Container(
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
                                          child: ListView.builder(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            itemCount: widget.post.comments.length,
                                            itemBuilder: (context, idx) {
                                              final c = widget.post.comments[idx];
                                              return _commentItem(c.user, c.text, c.side, c.image, widget.post.isExpired);
                                            },
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
                                                    color: Colors.white.withValues(alpha: 0.05),
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                  child: TextField(
                                                    controller: commentController,
                                                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
                                                  if (commentController.text.trim().isNotEmpty) {
                                                    FocusScope.of(context).unfocus(); // Close keyboard
                                                    setSheetState(() {
                                                      widget.post.comments.add(CommentData(
                                                        user: '나 (본인)',
                                                        text: commentController.text,
                                                        side: _votedSide,
                                                        image: 'assets/profiles/profile_11.jpg',
                                                      ));
                                                      commentController.clear();
                                                    });
                                                    // Optionally scroll to bottom
                                                  }
                                                },
                                                child: const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }),
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
                              shadows: [Shadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 15)],
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
      width: 72, 
      height: 28, 
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFollowing ? const Color(0xFF272727) : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isFollowing ? Colors.white10 : Colors.transparent, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, 
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFollowing ? Icons.check : Icons.add, 
            color: isFollowing ? Colors.white70 : Colors.white, 
            size: 12
          ),
          const SizedBox(width: 4),
          Transform.translate(
            offset: const Offset(0, -2), 
            child: Text(
              isFollowing ? '팔로잉' : '팔로우', 
              style: TextStyle(
                color: isFollowing ? Colors.white70 : Colors.white, 
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
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
          ), 
          child: Text(text)
        ),
      ],
    ); 
  }
  Widget _descBox(String text, bool isExpanded, VoidCallback onTap) { 
    // Measurement logic to see if text actually needs expansion
    bool needsExpansion = false;
    if (text.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text, 
          style: const TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w600)
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
      );
      // Fixed width is 175, horizontal padding is 12*2 = 24. Available width = 151
      textPainter.layout(maxWidth: 151); 
      needsExpansion = textPainter.didExceedMaxLines;
    }

    return GestureDetector(
      onTap: needsExpansion ? onTap : null, // Only clickable if it needs expansion
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), 
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 175, 
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2), 
              borderRadius: BorderRadius.circular(15), 
              border: Border.all(color: Colors.white.withValues(alpha: 0.15))
            ), 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        text, 
                        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600), 
                        maxLines: isExpanded ? 10 : 2, 
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis
                      ),
                    ),
                    if (needsExpansion && !isExpanded)
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 2),
                        child: Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 14),
                      ),
                  ],
                ),
                if (needsExpansion && isExpanded)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Center(child: Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 14)),
                  )
              ],
            )
          )
        )
      )
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
          SizedBox(
            height: 14, // Fixed height to ensure icon alignment
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(PostData post) {
    bool isExpired = _remainingSeconds <= 0 || post.isExpired;
    bool hasVoted = _votedSide != 0 || isExpired;
    
    return Positioned(
      bottom: 67 + MediaQuery.of(context).padding.bottom,
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
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 1))],
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
        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6, offset: const Offset(0, 1))],
      ),
    );
  }

  Widget _commentItem(String name, String text, int votedSide, String imageUrl, bool isPostExpired) {
    Color teamColor = votedSide == 1 ? Colors.cyanAccent : Colors.redAccent;
    // Show border if the user has actually voted for a side (votedSide 1 or 2)
    // This remains even after the post is expired to show their 'pick' identity.
    bool showBorder = votedSide != 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: showBorder ? teamColor : Colors.transparent, width: 2),
              boxShadow: showBorder ? [BoxShadow(color: teamColor.withValues(alpha: 0.3), blurRadius: 4, spreadRadius: 1)] : [],
            ),
            child: CircleAvatar(
              radius: 18, 
              backgroundImage: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl)
                : AssetImage(imageUrl) as ImageProvider,
            ),
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

  void _showReportSheet(BuildContext context) {
    String? selectedReason;
    final List<String> reasons = [
      '스팸 또는 홍보',
      '부적절한 콘텐츠',
      '저작권 침해',
      '증오 표현 또는 괴롭힘',
      '허위 정보',
      '기타',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 25),
                const Text('신고 사유 선택', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Column(
                  children: reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: Colors.redAccent,
                    onChanged: (val) => setSheetState(() => selectedReason = val),
                    contentPadding: EdgeInsets.zero,
                  )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: selectedReason == null ? null : () {
                      Navigator.pop(context);
                      widget.onReport(selectedReason!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('신고하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descAController = TextEditingController();
  final TextEditingController _descBController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isAdultContent = false;
  bool _isAIContent = false;

  int _selectedHours = 24;
  int _selectedMinutes = 0;
  bool _useTargetGoal = false;
  final TextEditingController _targetVotesController = TextEditingController(text: '100');

  String? _imagePathA;
  String? _imagePathB;

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
        title: const Text('새 투표 만들기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // 1. Create Real Post Data
              final newPost = PostData(
                id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                uploaderId: '마이픽겟',
                uploaderImage: 'https://i.pravatar.cc/150?u=mypickget',
                title: _titleController.text,
                fullDescription: _descController.text,
                timeLocation: '방금 전 · 서울',
                imageA: _imagePathA ?? 'https://picsum.photos/seed/a/800/1000',
                imageB: _imagePathB ?? 'https://picsum.photos/seed/b/800/1000',
                descriptionA: '선택지 A',
                descriptionB: '선택지 B',
                shortDescA: _descAController.text,
                shortDescB: _descBController.text,
                tags: _tagsController.text.split(RegExp(r'[#,\s]+')).where((t) => t.isNotEmpty).toList(),
                likesCount: 0,
                commentsCount: 0,
                voteCountA: '0',
                voteCountB: '0',
                percentA: '0%',
                percentB: '0%',
              );

              // 2. Navigate to ChannelScreen directly with the new post.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChannelScreen(
                  uploaderId: newPost.uploaderId,
                  allPosts: [newPost], // For demo of newly uploaded post
                  initialPost: newPost,
                )),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${_titleController.text}" 투표가 내 채널에 등록되었습니다!'),
                  backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
                ),
              );
            },
            child: const Text('등록', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Block 1: Title
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('투표 제목', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                      hintText: '무엇을 비교할까요?',
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Block 2: Uploads & Individual Descriptions
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이미지 업로드', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _uploadBox('A'),
                            const SizedBox(height: 12),
                            _shortDescField('A', '선택지 A 설명', _descAController, Colors.cyanAccent),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _uploadBox('B'),
                            const SizedBox(height: 12),
                            _shortDescField('B', '선택지 B 설명', _descBController, Colors.redAccent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Block 3: Detailed Description
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('상세 설명 (선택)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '투표에 대한 상세한 내용을 적어주세요...',
                      hintStyle: TextStyle(color: Colors.white24),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Block 4: Vote Settings (Timer & Goal)
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('투표 기간 설정', trailing: '$_selectedHours시간 $_selectedMinutes분'),
                  const SizedBox(height: 16),
                  _durationSlider('시간', _selectedHours.toDouble(), 72, (val) {
                    setState(() {
                      _selectedHours = val.toInt();
                      if (_selectedHours == 0 && _selectedMinutes == 0) _selectedMinutes = 1;
                    });
                  }),
                  _durationSlider('분', _selectedMinutes.toDouble(), 59, (val) {
                    setState(() {
                      _selectedMinutes = val.toInt();
                      if (_selectedHours == 0 && _selectedMinutes == 0) _selectedMinutes = 1;
                    });
                  }),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('목표 투표수 도달 시 종료', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      Switch(
                        value: _useTargetGoal, 
                        onChanged: (val) => setState(() => _useTargetGoal = val),
                        activeThumbColor: Colors.cyanAccent,
                      ),
                    ],
                  ),
                  if (_useTargetGoal) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _targetVotesController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '예: 1000',
                        hintStyle: const TextStyle(color: Colors.white24),
                        suffixText: '표',
                        suffixStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Block 5: Tags & Policies
            _contentBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('검색 태그 및 정책', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tagsController,
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '#패션 #코디 (검색용 키워드)',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      prefixIcon: const Icon(Icons.tag, color: Colors.cyanAccent, size: 18),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _settingTile(
                    '19금 성인 컨텐츠', 
                    _isAdultContent, 
                    (val) => setState(() => _isAdultContent = val!)
                  ),
                  _settingTile(
                    'AI 생성 컨텐츠', 
                    _isAIContent, 
                    (val) => setState(() => _isAIContent = val!)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer: Guidelines
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('픽겟 업로드 가이드라인', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _guideText('? 직접 촬영하거나 사용 권한이 있는 이미지만 업로드해 주세요.'),
                  _guideText('? 욕설, 혐오 표현, 부적절한 비하 내용 포함 시 삭제될 수 있습니다.'),
                  _guideText('? 성인 컨텐츠 및 AI 생성물은 반드시 해당 항목을 체크해야 합니다.'),
                  _guideText('? 허위 정보로 혼란을 야기하는 투표는 서비스 이용이 제한됩니다.'),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _guideText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white24, fontSize: 11, height: 1.5),
      ),
    );
  }

  Widget _contentBlock({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _durationSlider(String label, double value, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.cyanAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            divisions: max.toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        if (trailing != null)
          Text(trailing, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _settingTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      activeColor: Colors.cyanAccent,
      checkColor: Colors.black,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
      side: const BorderSide(color: Colors.white24, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _shortDescField(String label, String hint, TextEditingController controller, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              const Text('설명', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox(String label) {
    final isA = label == 'A';
    final currentPath = isA ? _imagePathA : _imagePathB;

    return GestureDetector(
      onTap: () => _showPickerOptions(label),
      child: AspectRatio(
        aspectRatio: 0.8,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: currentPath != null 
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(currentPath, fit: BoxFit.cover),
                  Container(color: Colors.black26),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isA) {
                          _imagePathA = null;
                        } else {
                          _imagePathB = null;
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.03),
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Colors.white38, size: 40),
                      const SizedBox(height: 12),
                      Text('선택지 $label', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
        ),
      ),
    );
  }

  void _showPickerOptions(String side) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _pickerTile(Icons.camera_alt_outlined, '직접 촬영하기', () => Navigator.pop(context)),
            const SizedBox(height: 12),
            _pickerTile(Icons.photo_library_outlined, '갤러리에서 선택', () {
              setState(() {
                if (side == 'A') {
                  _imagePathA = 'https://picsum.photos/seed/${side}1/800/1000';
                } else {
                  _imagePathB = 'https://picsum.photos/seed/${side}2/800/1000';
                }
              });
              Navigator.pop(context);
            }),
            const SizedBox(height: 12),
            _pickerTile(Icons.videocam_outlined, '동영상 업로드', () => Navigator.pop(context)),
            const SizedBox(height: 12),
            _pickerTile(Icons.close, '취소', () => Navigator.pop(context), isCancel: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(IconData icon, String title, VoidCallback onTap, {bool isCancel = false}) {
    return ListTile(
      leading: Icon(icon, color: isCancel ? Colors.redAccent : Colors.white70),
      title: Text(title, style: TextStyle(color: isCancel ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.white.withValues(alpha: 0.03),
    );
  }
}

class ChannelScreen extends StatefulWidget {
  final String uploaderId;
  final List<PostData> allPosts;
  final PostData initialPost;

  const ChannelScreen({
    super.key, 
    required this.uploaderId, 
    required this.allPosts,
    required this.initialPost,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> with SingleTickerProviderStateMixin {
  String _dName = ''; String _dId = ''; String _dImg = 'assets/profiles/profile_11.jpg'; String _dBio = '';
  bool _isFollowing = false;
  late TabController _tabController;
  late List<PostData> _channelPosts;
  bool _isBioExpanded = false;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.uploaderId == '나의 픽겟') { _dName = gNameText; _dId = gIdText; _dImg = gProfileImage; _dBio = gBioText; }
    else { _dName = widget.uploaderId; _dId = "@${widget.uploaderId.toLowerCase().replaceAll(' ', '_')}"; _dImg = widget.initialPost.uploaderImage; _dBio = '안녕하세요! ${widget.uploaderId}의 픽겟 공간입니다. ✨'; _isFollowing = widget.initialPost.isFollowing; }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      _channelPosts = widget.allPosts.where((p) {
        bool isUploader = p.uploaderId == widget.uploaderId;
        if (widget.uploaderId == '나의 픽겟') {
          return isUploader; // Show all (including hidden) for self
        } else {
          return isUploader && !p.isHidden; // Hide hidden posts for others
        }
      }).toList();
      
      if (!_channelPosts.any((p) => p.id == widget.initialPost.id) && widget.initialPost.uploaderId == widget.uploaderId) {
        if (widget.uploaderId == '나의 픽겟' || !widget.initialPost.isHidden) {
          _channelPosts.insert(0, widget.initialPost);
        }
      }
    });
  }

  void _handleTabSelection() {
    setState(() {});
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _menuItem(Icons.select_all, '전체 선택', () {
                Navigator.pop(context);
                setState(() {
                  _selectedPostIds.addAll(_channelPosts.map((p) => p.id));
                  _isSelectionMode = true;
                });
              }),
              _menuItem(Icons.deselect, '전체 해제', () {
                Navigator.pop(context);
                setState(() {
                  _selectedPostIds.clear();
                  _isSelectionMode = false;
                });
              }),
              _menuItem(Icons.share, '공유하기', () {
                Navigator.pop(context);
                if (_selectedPostIds.length != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유는 한 개의 포스트를 선택했을 때만 가능합니다.')));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물 링크가 복사되었습니다.')));
              }, color: _selectedPostIds.length == 1 ? Colors.white : Colors.white24),
              _menuItem(Icons.visibility_off, '숨기기 / 보이기', () {
                Navigator.pop(context);
                if (_selectedPostIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('편집할 포스트를 선택해주세요.')));
                  return;
                }
                _toggleHide();
              }, color: _selectedPostIds.isNotEmpty ? Colors.white : Colors.white24),
              _menuItem(Icons.delete_outline, '삭제하기', () {
                Navigator.pop(context);
                if (_selectedPostIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제할 포스트를 선택해주세요.')));
                  return;
                }
                _confirmDelete();
              }, color: _selectedPostIds.isNotEmpty ? Colors.redAccent : Colors.redAccent.withValues(alpha: 0.3)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  void _toggleHide() {
    if (_selectedPostIds.isEmpty) return;
    setState(() {
      for (var p in widget.allPosts) {
        if (_selectedPostIds.contains(p.id)) {
          p.isHidden = !p.isHidden;
        }
      }
      _isSelectionMode = false;
      _selectedPostIds.clear();
      _loadPosts(); // Refresh view
    });
  }

  void _confirmDelete() {
    if (_selectedPostIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('삭제하시겠습니까?', style: TextStyle(color: Colors.white)),
        content: const Text('삭제된 포스트는 복구할 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelected();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    setState(() {
      widget.allPosts.removeWhere((p) => _selectedPostIds.contains(p.id));
      _isSelectionMode = false;
      _selectedPostIds.clear();
      _loadPosts(); // Refresh view
    });
  }

  Widget _uploadButton() {
    return Container(
      width: 65, height: 65,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.cyanAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadScreen()));
          },
          borderRadius: BorderRadius.circular(35),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stacked effect
                Transform.translate(
                  offset: const Offset(-4, -4),
                  child: Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(2, 2),
                  child: Transform.rotate(
                    angle: 0.1,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.add, color: Colors.cyanAccent, size: 22, weight: 900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          _buildMenuTile(Icons.share, '공유하기', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('채널 링크가 복사되었습니다.'), duration: Duration(seconds: 1))
            );
          }),
          _buildMenuTile(Icons.block, '이 채널 추천 안 함', () => Navigator.pop(context)),
          _buildMenuTile(Icons.visibility_off, '관심 없음', () => Navigator.pop(context)),
          _buildMenuTile(Icons.report_problem_outlined, '신고하기', () => Navigator.pop(context), isDestructive: true),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }

  int _parseTotalVotes(PostData post) {
    int parseV(String s) {
      s = s.toLowerCase().replaceAll(',', '').trim();
      if (s.isEmpty) return 0;
      if (s.endsWith('k')) {
        return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
      }
      return int.tryParse(s) ?? 0;
    }
    return parseV(post.voteCountA) + parseV(post.voteCountB);
  }

  String _formatVotes(int count) {
    return formatCount(count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 0,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.uploaderId != '나의 픽겟')
                IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: _showMoreMenu),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: _dImg.startsWith('http')
                          ? NetworkImage(_dImg)
                          : AssetImage(_dImg) as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _dName,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                if (widget.uploaderId == '나의 픽겟') ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(
                                            currentName: gNameText,
                                            currentId: gIdText,
                                            currentBio: gBioText,
                                            currentImage: gProfileImage,
                                          ),
                                        ),
                                      ).then((res) {
                                        if (res != null) {
                                          setState(() {
                                            gNameText = res['name'];
                                            gIdText = res['id'];
                                            gBioText = res['bio'];
                                            gProfileImage = res['image'];
                                            _dName = gNameText;
                                            _dId = gIdText;
                                            _dBio = gBioText;
                                            _dImg = gProfileImage;
                                          });
                                        }
                                      });
                                    },
                                    child: const Icon(Icons.edit_note, color: Colors.cyanAccent, size: 24),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "@${_dName.toLowerCase().replaceAll(' ', '_')}",
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "팔로워 58.8k · 콘텐츠 ${formatCount(_channelPosts.length)}",
                              style: const TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bio with Expand Arrow
                  GestureDetector(
                    onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _dBio,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            maxLines: _isBioExpanded ? 10 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isBioExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons (Follow & Sympathy Rate Detail)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.uploaderId == '나의 픽겟') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityAnalysisScreen()));
                            } else {
                              setState(() {
                                _isFollowing = !_isFollowing;
                                // 동일 업로더의 모든 포스트 팔로우 상태 동기화
                                for (var p in widget.allPosts) {
                                  if (p.uploaderId == widget.uploaderId) {
                                    p.isFollowing = _isFollowing;
                                  }
                                }
                              });
                              HapticFeedback.mediumImpact();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (widget.uploaderId != '나의 픽겟' && _isFollowing) 
                              ? const Color(0xFF272727) 
                              : Colors.white,
                            foregroundColor: (widget.uploaderId != '나의 픽겟' && _isFollowing) 
                              ? Colors.white70 
                              : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.uploaderId != '나의 픽겟' && _isFollowing) ...[
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                widget.uploaderId == '나의 픽겟' 
                                  ? '활동분석' 
                                  : (_isFollowing ? '팔로잉' : '팔로우'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '공감도 82%',
                                style: TextStyle(
                                  color: Colors.cyanAccent, 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: Colors.black,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _profileTab('최신순', 0),
                              const SizedBox(width: 30),
                              _profileTab('픽순', 1),
                              const SizedBox(width: 30),
                              _profileTab('시간순', 2),
                            ],
                          ),
                          if (widget.uploaderId == '나의 픽겟')
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                                onPressed: _showSettingsMenu,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostGrid(),
            _buildPostGrid(),
            _buildPostGrid(),
          ],
        ),
      ),
      floatingActionButton: widget.uploaderId == '나의 픽겟' ? _uploadButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _profileTab(String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _tabController.animateTo(index); }); 
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.transparent, fontSize: 15, fontWeight: FontWeight.w900),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 14,
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

  Widget _buildPostGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _channelPosts.length,
      itemBuilder: (context, index) {
        final post = _channelPosts[index];
        final totalVotes = _parseTotalVotes(post);
        bool isSelected = _selectedPostIds.contains(post.id);
        return GestureDetector(
          onLongPress: () {
            if (widget.uploaderId == '나의 픽겟') {
              setState(() {
                _isSelectionMode = true;
                _selectedPostIds.add(post.id);
              });
              HapticFeedback.heavyImpact();
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedPostIds.remove(post.id);
                  if (_selectedPostIds.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedPostIds.add(post.id);
                }
              });
              HapticFeedback.selectionClick();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChannelFeedScreen(initialIndex: index, channelPosts: _channelPosts, allPosts: widget.allPosts,)),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(post.imageA, fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null),
              if (post.isHidden)
                const Center(child: Icon(Icons.visibility_off, color: Colors.white54, size: 30)),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatVotes(totalVotes),
                        style: const TextStyle(
                          color: Colors.white60, 
                          fontSize: 10, 
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent : Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: isSelected ? Colors.black : Colors.transparent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final PreferredSizeWidget _widget;
  _SliverAppBarDelegate(this._widget);

  @override
  double get minExtent => _widget.preferredSize.height;
  @override
  double get maxExtent => _widget.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _widget;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}

class DonutPainter extends CustomPainter {
  final double percentA; final bool isPreVote;
  DonutPainter({required this.percentA, this.isPreVote = false});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); final radius = size.width / 2 - 4; final strokeWidth = 7.0;
    final paintBg = Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);
    if (isPreVote) {
      final paintWhite = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
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

// --- 포인트 관련 클래스 추가 ---

class PointHistoryItem {
  final String title;
  final int amount;
  final String date;
  final bool isEarned;

  PointHistoryItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.isEarned,
  });
}

class PointScreen extends StatefulWidget {
  final int currentPoints;
  const PointScreen({super.key, required this.currentPoints});

  @override
  State<PointScreen> createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  late int _userPoints;
  final List<PointHistoryItem> _history = [
    PointHistoryItem(title: '친구 초대 보상', amount: 500, date: '2026.04.27', isEarned: true),
    PointHistoryItem(title: '출석 체크 보상', amount: 100, date: '2026.04.27', isEarned: true),
    PointHistoryItem(title: '게시물 좋아요 보상', amount: 50, date: '2026.04.26', isEarned: true),
    PointHistoryItem(title: '현금 인출 신청', amount: 10000, date: '2026.04.25', isEarned: false),
    PointHistoryItem(title: '상품권 교환', amount: 5000, date: '2026.04.24', isEarned: false),
    PointHistoryItem(title: '투표 참여 보상', amount: 10, date: '2026.04.23', isEarned: true),
    PointHistoryItem(title: '이벤트 당첨 보너스', amount: 2000, date: '2026.04.20', isEarned: true),
    PointHistoryItem(title: '친구 초대 보상', amount: 500, date: '2026.04.18', isEarned: true),
    PointHistoryItem(title: '베스트 코디 선정', amount: 1000, date: '2026.04.15', isEarned: true),
    PointHistoryItem(title: '광고 시청 보상', amount: 50, date: '2026.04.10', isEarned: true),
    PointHistoryItem(title: '출석 체크 보상', amount: 100, date: '2026.04.05', isEarned: true),
    PointHistoryItem(title: '상품권 교환', amount: 3000, date: '2026.04.01', isEarned: false),
    PointHistoryItem(title: '게시물 좋아요 보상', amount: 50, date: '2026.03.25', isEarned: true),
    PointHistoryItem(title: '친구 초대 보상', amount: 500, date: '2026.03.20', isEarned: true),
  ];

  @override
  void initState() {
    super.initState();
    _userPoints = widget.currentPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('나의 포인트', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C2C), Color(0xFF1C1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('나의 보유 포인트', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('P', style: TextStyle(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Text(
                            _userPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StoreScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('포인트 사용', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.05)),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('30일 이내 소멸 예정', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Text('150 P', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('포인트 내역', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('최근 3개월', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '* 앱에서는 최근 3개월 내역만 표시되며, 전체 내역은 고객센터를 통해 확인하실 수 있습니다. (관련 법령에 의거 5년간 보관)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              itemBuilder: (context, index) {
                final item = _history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item.isEarned ? Colors.cyanAccent : Colors.orangeAccent).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isEarned ? Icons.add : Icons.remove,
                          color: item.isEarned ? Colors.cyanAccent : Colors.orangeAccent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(item.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        "${item.isEarned ? '+' : '-'}${item.amount} P",
                        style: TextStyle(
                          color: item.isEarned ? Colors.cyanAccent : Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showPointPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('포인트 유효기간 및 자동 소멸 정책 안내', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕하세요. 서비스를 이용해 주시는 회원님께 감사의 말씀을 드립니다.\n\n' 
                '회원님의 소중한 포인트 관리 및 원활한 서비스 제공을 위해 포인트 유효기간 정책을 아래와 같이 안내드립니다.\n\n' 
                '? 유효기간: 각 포인트 적립일로부터 1년 (365일)\n\n' 
                '? 소멸 방식: 유효기간이 경과한 포인트는 해당 일자 자정에 자동으로 소멸됩니다.\n\n' 
                '? 사용 원칙: 먼저 적립된 포인트가 먼저 사용되는 \'선입선출\' 방식으로 차감됩니다.\n\n' 
                '? 사전 안내: 포인트 소멸 30일 전과 7일 전에 앱 알림을 통해 소멸 예정 포인트를 미리 안내해 드립니다.\n\n' 
                '소멸된 포인트는 복구가 불가능하오니, 유효기간 내에 현금전환이나 상품 구매 등으로 알뜰하게 사용하시길 바랍니다.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  String _selectedCategory = '커피';
  
  bool _isWithdrawalPending = false;
  int _pendingAmount = 0;

  final Map<String, List<Map<String, String>>> _categoryProducts = {
    '커피': [
      {'title': '[스타벅스] 아메리카노 T', 'price': '4,500 P', 'brand': '스타벅스'},
      {'title': '[투썸플레이스] 카페라떼 R', 'price': '5,000 P', 'brand': '투썸플레이스'},
      {'title': '[메가커피] 아메리카노(HOT)', 'price': '1,500 P', 'brand': '메가커피'},
    ],
    '편의점': [
      {'title': '[GS25] 모바일 상품권 5,000원', 'price': '5,000 P', 'brand': 'GS25'},
      {'title': '[CU] 모바일 상품권 3,000원', 'price': '3,000 P', 'brand': 'CU'},
      {'title': '[7-Eleven] 바나나우유', 'price': '1,700 P', 'brand': '7-Eleven'},
    ],
    '상품권': [
      {'title': '문화상품권 5,000원권', 'price': '5,000 P', 'brand': '컬쳐랜드'},
      {'title': '구글 기프트카드 1만원', 'price': '10,000 P', 'brand': 'Google'},
    ],
    '외식': [
      {'title': '[아웃백] 5만원권', 'price': '50,000 P', 'brand': '아웃백'},
      {'title': '[VIPS] 평일 런치 1인', 'price': '32,000 P', 'brand': 'VIPS'},
    ],
  };

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('포인트 스토어', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 섹션: 묵직한 덩어리감을 위한 배경 처리
            Container(
              width: double.infinity,
              color: const Color(0xFF0F0F0F), // 미세하게 밝은 배경으로 섹션 구분
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
                  // 인출 신청 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isWithdrawalPending ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.cyanAccent.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isWithdrawalPending ? Icons.sync : Icons.stars, color: Colors.cyanAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isWithdrawalPending ? '인출 신청 진행 중' : '현금 인출하기', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isWithdrawalPending ? '신청금액: ${_pendingAmount}P (승인 대기)' : '보유 포인트를 현금으로 전환', 
                                style: TextStyle(color: _isWithdrawalPending ? Colors.cyanAccent : Colors.white38, fontSize: 12)
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isWithdrawalPending ? null : _showWithdrawalDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWithdrawalPending ? Colors.grey[800] : Colors.cyanAccent,
                            foregroundColor: _isWithdrawalPending ? Colors.white24 : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(
                            _isWithdrawalPending ? '처리중' : '인출신청', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 내 쿠폰함 카드
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCouponsScreen()));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, color: Colors.amberAccent, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('내 쿠폰함', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  SizedBox(height: 4),
                                  Text('보유 중인 상품권 확인', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 하단 섹션: 가볍고 탁 트인 덩어리감
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('카테고리', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 10,
                    children: [
                      _buildCategoryItem(Icons.coffee, '커피'),
                      _buildCategoryItem(Icons.fastfood, '편의점'),
                      _buildCategoryItem(Icons.card_giftcard, '상품권'),
                      _buildCategoryItem(Icons.restaurant, '외식'),
                      _buildCategoryItem(Icons.shopping_bag, '백화점'),
                      _buildCategoryItem(Icons.movie, '영화'),
                      _buildCategoryItem(Icons.cake, '베이커리'),
                      _buildCategoryItem(Icons.more_horiz, '기타'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_selectedCategory 상품', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const Text('전체보기', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProductList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    final bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1) : const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(15),
              border: isSelected ? Border.all(color: Colors.cyanAccent, width: 1.5) : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.cyanAccent : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final products = _categoryProducts[_selectedCategory] ?? _categoryProducts['커피']!;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(product['brand']!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Text(product['price']!, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawalDialog() {
    _amountController.clear();
    _accountController.clear();
    _bankController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isFormValid = _amountController.text.isNotEmpty && 
                            _accountController.text.isNotEmpty && 
                            _bankController.text.isNotEmpty;

          return AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현금 인출 신청', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('1일 1회 최대 30,000P', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStoreTextField(
                    '인출할 포인트 (5,000 P 단위)', 
                    controller: _amountController,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildStoreTextField(
                    '입금받으실 계좌번호', 
                    controller: _accountController,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildStoreTextField(
                    '은행명 및 예금주', 
                    controller: _bankController,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '계좌번호 및 예금주 잘못 기입 시 입금이 불가능하며, 이에 따른 책임은 본인에게 있습니다.',
                            style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                onPressed: isFormValid ? () {
                  int? amount = int.tryParse(_amountController.text.replaceAll(',', ''));
                  if (amount == null || amount <= 0 || amount % 5000 != 0) {
                    _showErrorPopup('인출 신청은 5,000P 단위로만 가능합니다.');
                  } else if (amount > 30000) {
                    _showErrorPopup('1회 최대 인출 가능 금액은 30,000P입니다.');
                  } else {
                    Navigator.pop(context);
                    setState(() {
                      _isWithdrawalPending = true;
                      _pendingAmount = amount;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${amount}P 인출 신청이 완료되었습니다.'), duration: const Duration(seconds: 2)),
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFormValid ? Colors.cyanAccent : Colors.grey[800],
                  foregroundColor: isFormValid ? Colors.black : Colors.white24,
                ),
                child: const Text('신청하기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('안내', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreTextField(String label, {TextEditingController? controller, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      keyboardType: label.contains('포인트') ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
      ),
    );
  }
}

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  final List<Map<String, dynamic>> _coupons = [
    {'title': '[GS25] 모바일 상품권 5,000원', 'date': '2026.12.31까지', 'brand': 'GS25', 'isUsed': false, 'type': 'barcode'},
    {'title': '[CU] 모바일 상품권 3,000원', 'date': '2026.11.15까지', 'brand': 'CU', 'isUsed': false, 'type': 'qr'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('내 쿠폰함', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _coupons.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          final bool isUsed = coupon['isUsed'];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: isUsed ? 0.3 : 1.0,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      coupon['type'] == 'barcode' ? Icons.barcode_reader : Icons.qr_code_2,
                      color: Colors.cyanAccent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon['title']!,
                          style: TextStyle(
                            color: isUsed ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: isUsed ? TextDecoration.lineThrough : null,
                          )),
                      const SizedBox(height: 6),
                      Text('유효기간: ${coupon['date']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: isUsed ? 0.2 : 0.4), fontSize: 12)),
                    ],
                  ),
                ),
                if (isUsed)
                  const Text('사용완료', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold))
                else
                  ElevatedButton(
                    onPressed: () => _showBarcodeDialog(context, index, coupon['title']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('사용하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBarcodeDialog(BuildContext context, int index, String title) {
    final coupon = _coupons[index];
    final String type = coupon['type'] ?? 'barcode';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
              ),
              child: type == 'barcode' 
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(20, (index) => Container(
                          width: index % 3 == 0 ? 4 : 2,
                          height: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: Colors.black,
                        )),
                      ),
                      const SizedBox(height: 10),
                      const Text('1234 - 5678 - 9012', style: TextStyle(color: Colors.black, letterSpacing: 2, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 100, color: Colors.black),
                      const SizedBox(height: 10),
                      const Text('QR-9876-5432-10', style: TextStyle(color: Colors.black, letterSpacing: 1, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              type == 'barcode' ? '매장 점원에게 바코드를 보여주세요.' : '매장 스캐너에 QR코드를 스캔해주세요.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.black.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showConfirmUsedDialog(context, index);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('사용 완료 처리하기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmUsedDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('사용 완료 처리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('정말로 사용 완료 처리하시겠습니까?\n한 번 완료하면 되돌릴 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              setState(() {
                _coupons[index]['isUsed'] = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용 완료 처리되었습니다.'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('확인', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final List<PostData> allPosts;
  const SearchScreen({super.key, required this.allPosts});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = ['스타벅스', 'CU', '커피', '편의점', '에어팟'];
  List<PostData> _searchResults = [];
  bool _isSearching = false;
  late TabController _tabController;
  
  // 디테일 뷰 모드를 위한 상태 변수
  bool _isDetailView = false;
  int _detailPageIndex = 0;
  late PageController _detailPageController;
  
  // 이전 상태를 기억하기 위한 변수
  String _lastSearchQuery = '';
  bool _wasInDetailView = false;

  final List<Map<String, dynamic>> _trendingKeywords = [
    {'rank': 1, 'keyword': '데이트 룩', 'change': 'up'},
    {'rank': 2, 'keyword': '오늘 점심', 'change': 'new'},
    {'rank': 3, 'keyword': '운동복 추천', 'change': 'down'},
    {'rank': 4, 'keyword': '선물 고르기', 'change': 'same'},
    {'rank': 5, 'keyword': '가습기 비교', 'change': 'up'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // PageController는 초기화된 경우에만 해제
    if (_isDetailView) {
      _detailPageController.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearching = true;
        _searchResults = widget.allPosts.where((post) {
          final q = query.toLowerCase();
          final titleMatch = post.title.toLowerCase().contains(q);
          final uploaderMatch = post.uploaderId.toLowerCase().contains(q);
          final tagMatch = post.tags?.any((tag) => tag.toLowerCase().contains(q)) ?? false;
          return titleMatch || uploaderMatch || tagMatch;
        }).toList();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (_isDetailView) {
              setState(() => _isDetailView = false);
            } else if (_isSearching) {
              // 검색 결과 목록에서 뒤로가기를 누르면 검색 대시보드로 복구
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _wasInDetailView = false; // 검색을 새로 시작했으므로 이전 기억 초기화
              });
            } else if (_wasInDetailView && !_isSearching) {
              // 대시보드 상태에서 '뒤로가기'를 누르면 이전 피드로 복구
              setState(() {
                _searchController.text = _lastSearchQuery;
                _isSearching = true;
                _isDetailView = true;
                _wasInDetailView = false;
                _detailPageController = PageController(initialPage: _detailPageIndex);
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
            },
            onTap: () {
              if (_isDetailView) {
                setState(() {
                  _lastSearchQuery = _searchController.text;
                  _wasInDetailView = true;
                  _isDetailView = false;
                  _isSearching = false;
                  _searchController.clear();
                });
              }
            },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '궁금한 투표를 검색해보세요',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white24, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        bottom: (_isSearching && !_isDetailView)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: Colors.black,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _searchTab('상위', 0),
                        const SizedBox(width: 30),
                        _searchTab('투표', 1),
                        const SizedBox(width: 30),
                        _searchTab('사용자', 2),
                        const SizedBox(width: 30),
                        _searchTab('태그', 3),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            )
          : null,
      ),
      body: _isSearching 
        ? (_isDetailView ? _buildImmersiveDetailFeed() : _buildSearchResults()) 
        : _buildSearchDashboard(),
    );
  }

  Widget _searchTab(String label, int index) {
    // ... (rest of _searchTab is identical)
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _tabController.animateTo(index); }); 
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.transparent, fontSize: 15, fontWeight: FontWeight.w900),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 14,
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

  Widget _buildImmersiveDetailFeed() {
    // ... (rest of _buildImmersiveDetailFeed remains same)
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _detailPageController,
      itemCount: _searchResults.length,
      onPageChanged: (index) {
        setState(() => _detailPageIndex = index);
      },
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return PostView(
          key: ValueKey('search_${post.id}'),
          post: post,
          onLike: () {
            setState(() {
              post.isLiked = !post.isLiked;
              if (post.isLiked) {
                post.likesCount++;
              } else {
                post.likesCount--;
              }
            });
            HapticFeedback.lightImpact();
          },
          onFollow: () {
            setState(() {
              for (var p in widget.allPosts) {
                if (p.uploaderId == post.uploaderId) {
                  p.isFollowing = !post.isFollowing;
                }
              }
            });
            HapticFeedback.mediumImpact();
          },
          onBookmark: () {
            setState(() {
              post.isBookmarked = !post.isBookmarked;
            });
            HapticFeedback.selectionClick();
          },
          onNotInterested: () {
            setState(() {
              _searchResults.removeAt(index);
              if (_searchResults.isEmpty) _isDetailView = false;
            });
          },
          onDontRecommendChannel: () {
            setState(() {
              String uid = post.uploaderId;
              _searchResults.removeWhere((p) => p.uploaderId == uid);
              if (_searchResults.isEmpty) _isDetailView = false;
            });
          },
          onReport: (reason) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('신고가 접수되었습니다: $reason'), duration: const Duration(seconds: 1))
            );
          },
          onVote: (side) {
            setState(() {
              post.userVotedSide = side;
            });
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white24, size: 60),
            SizedBox(height: 16),
            Text('일치하는 투표가 없습니다', style: TextStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildVoteGrid(), // 상위
        _buildVoteGrid(), // 투표
        const Center(child: Text('검색된 사용자가 없습니다', style: TextStyle(color: Colors.white38))), // 사용자
        const Center(child: Text('검색된 태그가 없습니다', style: TextStyle(color: Colors.white38))), // 태그
      ],
    );
  }

  Widget _buildVoteGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // 세로로 긴 쇼츠 형태
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _detailPageIndex = index;
              _isDetailView = true;
              _detailPageController = PageController(initialPage: index);
            });
            HapticFeedback.lightImpact();
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(post.imageA, fit: BoxFit.cover),
                      // 하단 그라데이션 오버레이
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 투표수 또는 종료 배지 표시
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: post.isExpired 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.black, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    (double.tryParse(post.percentA.replaceAll('%', '')) ?? 0) >= (double.tryParse(post.percentB.replaceAll('%', '')) ?? 0) ? 'A 픽' : 'B 픽',
                                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              children: [
                                const Icon(Icons.how_to_vote, color: Colors.cyanAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  post.voteCountA.contains('k') || post.voteCountB.contains('k') 
                                    ? '${post.voteCountA} / ${post.voteCountB}' // k가 포함된 경우 각각 표시하거나 별도 계산 필요
                                    : '${(int.tryParse(post.voteCountA.replaceAll(',', '')) ?? 0) + (int.tryParse(post.voteCountB.replaceAll(',', '')) ?? 0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                  ),
                                ),
                              ],
                            ),
                      ),
                      // 종료된 경우 살짝 어둡게 처리하는 오버레이
                      if (post.isExpired)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white10,
                            backgroundImage: AssetImage(post.imageA), // 유저 프로필 대체
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              post.uploaderId,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
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
      },
    );
  }

  Widget _buildSearchDashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('최근 검색어', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: const Text('모두 삭제', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _recentSearches.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ActionChip(
                  label: Text(_recentSearches[index]),
                  onPressed: () {
                    _searchController.text = _recentSearches[index];
                    FocusScope.of(context).unfocus();
                  },
                  backgroundColor: const Color(0xFF1C1C1C),
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('지금 인기 있는 투표 키워드', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _trendingKeywords.length,
            itemBuilder: (context, index) {
              final item = _trendingKeywords[index];
              return ListTile(
                onTap: () {
                  _searchController.text = item['keyword'];
                  FocusScope.of(context).unfocus();
                },
                leading: Text(
                  item['rank'].toString(),
                  style: TextStyle(color: item['rank'] <= 3 ? Colors.cyanAccent : Colors.white38, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                title: Text(item['keyword'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: _buildTrendingIcon(item['change']),
              );
            },
          ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('추천 카테고리', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildCategoryChip('?? 패션/뷰티', Colors.purpleAccent),
                _buildCategoryChip('?? 오늘 뭐먹지?', Colors.orangeAccent),
                _buildCategoryChip('?? IT/디지털', Colors.blueAccent),
                _buildCategoryChip('?? 게임/취미', Colors.cyanAccent),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTrendingIcon(String change) {
    switch (change) {
      case 'up': return const Icon(Icons.arrow_drop_up, color: Colors.redAccent, size: 24);
      case 'down': return const Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 24);
      case 'new': return const Text('NEW', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold));
      default: return const Text('-', style: TextStyle(color: Colors.white24));
    }
  }

  Widget _buildCategoryChip(String label, Color color) {
    return GestureDetector(
      onTap: () {
        // 이모지 제외한 텍스트만 추출 (예: '?? 패션/뷰티' -> '패션/뷰티')
        final query = label.split(' ').last;
        _searchController.text = query;
        FocusScope.of(context).unfocus();
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class CategoryProductScreen extends StatelessWidget {
  final String categoryName;
  const CategoryProductScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(categoryName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Text('$categoryName 상품 목록이 곧 업데이트됩니다!', style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  final PostData post;
  const PostDetailScreen({super.key, required this.post});
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(child: Column(children: [
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          CircleAvatar(radius: 18, backgroundImage: AssetImage(post.uploaderImage)),
          const SizedBox(width: 12),
          Text(post.uploaderId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ])),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(post.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(post.fullDescription, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(post.imageA, fit: BoxFit.cover))),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(post.imageB, fit: BoxFit.cover))),
        ])),
        const SizedBox(height: 40),
        const Text('투표에 참여해 보세요!', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 100),
      ])),
    );
  }
}
class EditProfileScreen extends StatefulWidget {
  final String currentName; final String currentId; final String currentBio; final String currentImage;
  const EditProfileScreen({super.key, required this.currentName, required this.currentId, required this.currentBio, required this.currentImage});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name; late TextEditingController _id; late TextEditingController _bio; late String _img;
  @override void initState() { super.initState(); _name = TextEditingController(text: widget.currentName); _id = TextEditingController(text: widget.currentId); _bio = TextEditingController(text: widget.currentBio); _img = widget.currentImage; }
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, elevation: 0, title: const Text('프로필 편집', style: TextStyle(color: Colors.white))),
      body: SingleChildScrollView(child: Column(children: [
        const SizedBox(height: 30),
        GestureDetector(onTap: () => setState(() { int n = int.tryParse(_img.replaceAll(RegExp(r'[^0-9]'), '')) ?? 11; _img = 'assets/profiles/profile_${(n % 11) + 1}.jpg'; }), 
          child: Center(child: Stack(alignment: Alignment.center, children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage(_img), fit: BoxFit.cover, opacity: 0.6))),
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 30),
          ]))),
        const SizedBox(height: 40),
        _field('이름', _name), const SizedBox(height: 20), _field('아이디', _id), const SizedBox(height: 20), _field('자기소개', _bio, lines: 5),
        const SizedBox(height: 60),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(context, {'name': _name.text, 'id': _id.text, 'bio': _bio.text, 'image': _img}),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text('저장하기'),
        ))),
      ])),
    );
  }
  Widget _field(String l, TextEditingController c, {int lines = 1}) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(color: Colors.white54, fontSize: 13)),
    TextField(controller: c, maxLines: lines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: const Color(0xFF151515))),
  ]));
}


class ChannelFeedScreen extends StatefulWidget {
  final int initialIndex;
  final List<PostData> channelPosts;
  final List<PostData> allPosts;

  const ChannelFeedScreen({
    super.key,
    required this.initialIndex,
    required this.channelPosts,
    required this.allPosts,
  });

  @override
  State<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends State<ChannelFeedScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: widget.channelPosts.length,
        itemBuilder: (context, index) {
          final post = widget.channelPosts[index];
          return PostView(
            key: ValueKey('channel_feed_${post.id}'),
            post: post,
            onLike: () {
              setState(() {
                post.isLiked = !post.isLiked;
                if (post.isLiked) {
                  post.likesCount++;
                } else {
                  post.likesCount--;
                }
              });
              HapticFeedback.lightImpact();
            },
            onFollow: () {
              setState(() {
                bool newStatus = !post.isFollowing;
                for (var p in widget.allPosts) {
                  if (p.uploaderId == post.uploaderId) {
                    p.isFollowing = newStatus;
                  }
                }
              });
              HapticFeedback.mediumImpact();
            },
            onBookmark: () {
              setState(() {
                post.isBookmarked = !post.isBookmarked;
              });
              HapticFeedback.selectionClick();
            },
            onNotInterested: () {
              setState(() {
                widget.channelPosts.removeAt(index);
                if (widget.channelPosts.isEmpty) Navigator.pop(context);
              });
            },
            onDontRecommendChannel: () {
              Navigator.pop(context);
            },
            onReport: (reason) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('신고가 접수되었습니다: $reason'), duration: const Duration(seconds: 1))
              );
            },
            onVote: (side) {
              setState(() {
                post.userVotedSide = side;
              });
            },
          );
        },
      ),
    );
  }
}

class ActivityAnalysisScreen extends StatelessWidget {
  const ActivityAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('활동분석', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(),
            const SizedBox(height: 30),
            _buildStatsGrid(context),
            const SizedBox(height: 30),
            _buildSympathyRateCard(),
            const SizedBox(height: 30),
            _buildCategoryPreference(),
            const SizedBox(height: 30),
            _buildTrendSection('주간 참여 Pick 트렌드', [12, 24, 8, 32, 18, 45, 28]),
            const SizedBox(height: 20),
            _buildTrendSection('주간 받은 Pick 트렌드', [150, 220, 110, 310, 180, 420, 290]),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: AssetImage('assets/profiles/profile_11.jpg'), fit: BoxFit.cover),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('나의 픽겟', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('@pickget_official', style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        )
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('참여한 Pick', '152', Icons.touch_app_outlined),
        _statCard('받은 Pick', '3.4k', Icons.front_hand_outlined),
        _statCard('받은 공감', '842', Icons.favorite_border),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PointScreen(currentPoints: 1250))),
          child: _statCard('활동 포인트', '1,250', Icons.stars_outlined, isLink: true),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, {bool isLink = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLink ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: isLink ? Colors.cyanAccent : Colors.white38),
              if (isLink) const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.cyanAccent),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: isLink ? Colors.cyanAccent : Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSympathyRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('대중과의 공감도', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(width: 6),
              Icon(Icons.info_outline, color: Colors.white30, size: 16),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              // 그래프 (왼쪽)
              Expanded(
                flex: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120, height: 120,
                      child: CircularProgressIndicator(
                        value: 0.82,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('82%', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        Text('공감도', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // 수치 정보 (오른쪽)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSympathyStatItem('총 Pick', '152', Colors.white54),
                    const SizedBox(height: 16),
                    _buildSympathyStatItem('선택받은 Pick', '125', Colors.cyanAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          const Text('공감도 단계 안내', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildEmpathyManual(),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Text(
              '당신의 취향은 유저들의 선택과 82% 일치합니다!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSympathyStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildCategoryPreference() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('관심 카테고리 분석', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _categoryBar('패션/뷰티', 0.65, Colors.cyanAccent),
        const SizedBox(height: 16),
        _categoryBar('음식/맛집', 0.45, Colors.white70),
        const SizedBox(height: 16),
        _categoryBar('라이프스타일', 0.30, Colors.white30),
      ],
    );
  }

  Widget _categoryBar(String name, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Text(name, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)), 
            Text('${(percent * 100).toInt()}%', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))
          ]
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3))),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendSection(String title, List<int> counts) {
    int maxVal = counts.reduce((a, b) => a > b ? a : b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text('최근 7일', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _trendBar('월', counts[0] / maxVal, counts[0]),
              _trendBar('화', counts[1] / maxVal, counts[1]),
              _trendBar('수', counts[2] / maxVal, counts[2]),
              _trendBar('목', counts[3] / maxVal, counts[3]),
              _trendBar('금', counts[4] / maxVal, counts[4]),
              _trendBar('토', counts[5] / maxVal, counts[5]),
              _trendBar('일', counts[6] / maxVal, counts[6]),
            ],
          )
        ],
      ),
    );
  }

  Widget _trendBar(String day, double heightFactor, int pickCount) {
    bool isToday = day == '토';
    return Column(
      children: [
        Text(
          pickCount > 999 ? '${(pickCount / 1000).toStringAsFixed(1)}k' : '$pickCount',
          style: TextStyle(color: isToday ? Colors.cyanAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 14,
          height: 100 * heightFactor.clamp(0.1, 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isToday ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: 0.4),
                isToday ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.cyanAccent.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [if (isToday) BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10)],
          ),
        ),
        const SizedBox(height: 10),
        Text(day, style: TextStyle(color: isToday ? Colors.cyanAccent : Colors.white30, fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildEmpathyManual() {
    return Column(
      children: [
        _manualRow('81~100%', '공감왕'),
        _manualRow('61~80%', '공감 마스터'),
        _manualRow('41~60%', '소통 전문가'),
        _manualRow('21~40%', '취향 탐험가'),
        _manualRow('0~20%', '개성파'),
      ],
    );
  }

  Widget _manualRow(String range, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(range, style: const TextStyle(color: Colors.white30, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
