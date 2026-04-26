import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';

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
  bool isFollowing;
  bool isBookmarked;
  bool isLiked;
  final String fullDescription;
  bool isExpired;
  int userVotedSide; // 0: none, 1: A, 2: B
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
    this.fullDescription = "이 포스트에 대한 상세 설명이 여기에 표시됩니다. 업로드 시 입력한 기타 설명글이 나타나는 공간입니다.",
    this.isExpired = false,
    this.userVotedSide = 0,
    List<CommentData>? comments,
  }) : this.comments = comments ?? [
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
  Set<String> _forcedVisibleIds = {}; // To show expired posts clicked from ranking
  final PageController _pageController = PageController();
  int _selectedTopTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _posts = [
      PostData(id: '1', title: '오늘의 데이트 룩, 뭐가 더 심쿵해?', uploaderId: '@style_guru', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '서울 강남구 • 2시간 전', imageA: 'assets/images/post1_a.jpg', imageB: 'assets/images/post1_b.jpg', descriptionA: '트렌디한 오버사이즈 핏과 미니멀한 블랙 코디의 정석', descriptionB: '화려한 패턴과 유니크한 액세서리로 완성된 힙스터 룩', likesCount: 1200, commentsCount: 342, voteCountA: '1.2k', voteCountB: '800', percentA: '60%', percentB: '40%', isFollowing: true, fullDescription: '오늘은 홍대에서 데이트하기 좋은 룩 두 가지를 준비해봤어요! 여러분의 선택은 무엇인가요?'),
      PostData(id: '2', title: '출근룩 이거 어떰?', uploaderId: '@office_worker', uploaderImage: 'assets/profiles/profile_32.jpg', timeLocation: '판교 • 5시간 전', imageA: 'assets/images/post2_a.jpg', imageB: 'assets/images/post2_b.jpg', descriptionA: '깔끔한 셔츠와 슬랙스 조합, 신뢰감을 주는 비즈니스 캐주얼', descriptionB: '편안한 니트와 베이지 면바지, 다정하고 부드러운 오피스 룩', likesCount: 850, commentsCount: 120, voteCountA: '450', voteCountB: '400', percentA: '53%', percentB: '47%', fullDescription: '월요병을 이겨낼 수 있는 상큼한 출근룩 제안입니다. 투표 부탁드려요!'),
      PostData(id: '3', title: '휴양지 패션 추천좀!', uploaderId: '@traveler_j', uploaderImage: 'assets/profiles/profile_44.jpg', timeLocation: '제주도 • 1일 전', imageA: 'assets/images/post3_a.jpg', imageB: 'assets/images/post3_b.jpg', descriptionA: '시원한 리넨 셔츠와 반바지, 휴양지의 여유가 느껴지는 스타일', descriptionB: '에스닉한 무드와 로브로 인생샷을 부르는 화려한 바캉스 룩', likesCount: 2500, commentsCount: 890, voteCountA: '1.8k', voteCountB: '700', percentA: '72%', percentB: '28%', isFollowing: true, fullDescription: '다음 주에 발리로 떠나는데 어떤 옷이 더 잘 어울릴까요? 현지 분위기에 맞춰서 골라주세요.'),
      PostData(id: '4', title: '운동복 뭐가 나을까?', uploaderId: '@gym_rat', uploaderImage: 'assets/profiles/profile_12.jpg', timeLocation: '부산 • 3시간 전', imageA: 'assets/images/post4_a.jpg', imageB: 'assets/images/post4_b.jpg', descriptionA: '기능성에 집중한 컴프레션 웨어, 운동 효율을 높여주는 복장', descriptionB: '트렌디한 디자인의 조거 팬츠와 후드, 짐웨어로도 일상복으로도 만점', likesCount: 500, commentsCount: 40, voteCountA: '300', voteCountB: '200', percentA: '60%', percentB: '40%', fullDescription: '오운완! 오늘 새로 산 운동복인데 둘 중에 뭐가 더 핏이 좋아 보이나요?'),
      PostData(id: '5', title: '오늘 저녁 뭐 먹지?', uploaderId: '@foodie_kim', uploaderImage: 'assets/profiles/profile_60.jpg', timeLocation: '홍대 • 10분 전', imageA: 'assets/images/post5_a.jpg', imageB: 'assets/images/post5_b.jpg', descriptionA: '매콤한 감칠맛이 일품인 전통 한식 메뉴, 한국인의 소울 푸드', descriptionB: '치즈가 듬뿍 들어간 정통 이탈리안 파스타, 특별한 날에 어울리는 맛', likesCount: 3000, commentsCount: 1200, voteCountA: '2k', voteCountB: '1k', percentA: '67%', percentB: '33%', isFollowing: true, fullDescription: '결정장애 왔어요... 한식 vs 양식! 여러분의 픽으로 오늘 저녁 메뉴를 정하겠습니다.'),
      PostData(id: '6', title: '지난주 베스트 코디', uploaderId: '@style_guru', uploaderImage: 'assets/profiles/profile_11.jpg', timeLocation: '서울 • 1주일 전', imageA: 'assets/images/post1_a.jpg', imageB: 'assets/images/post1_b.jpg', descriptionA: 'A', descriptionB: 'B', likesCount: 5000, commentsCount: 1500, voteCountA: '3k', voteCountB: '2k', percentA: '60%', percentB: '40%', isExpired: true),
    ];
    _refreshRecommended();
  }

  void _refreshRecommended() {
    List<PostData> nonExpired = _posts.where((p) => !p.isExpired).toList();
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
    // 공통 규칙: 투표 종료된 컨텐츠는 메인 피드에서 제외 (Pick 탭 제외)
    List<PostData> filtered = _posts.where((p) => !p.isExpired).toList();

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
                    if (post.isLiked) post.likesCount++;
                    else post.likesCount--;
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
      bottom: 55, left: 20, right: 20,
      child: Container(
        height: 74,
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(37), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 25)]),
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
              child: const Icon(Icons.home_filled, color: Colors.white, size: 32),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showRankingSheet(context);
              },
              child: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 30),
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
                width: 54, height: 54, 
                decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle), 
                child: const Icon(Icons.add, color: Colors.cyanAccent, size: 38)
              ),
            ),
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
                  '${(post.likesCount + post.commentsCount).toString()}', // Simple mock for votes/engagement
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
      int countA = int.parse(widget.post.voteCountA.replaceAll(',', ''));
      int countB = int.parse(widget.post.voteCountB.replaceAll(',', ''));
      
      if (side == 1) countA++; else countB++;
      
      int total = countA + countB;
      double perA = (countA / total) * 100;
      double perB = (countB / total) * 100;
      
      widget.post.voteCountA = countA.toString();
      widget.post.voteCountB = countB.toString();
      widget.post.percentA = "${perA.toStringAsFixed(0)}%";
      widget.post.percentB = "${perB.toStringAsFixed(0)}%";
      
      // 3. Target Goal Check (Mocked for demo: if target is 1, it expires immediately)
      // In a real app, this would be checked against a 'targetVotes' field in PostData.
      if (total >= 1) { // Assuming user set 1 for testing
        widget.post.isExpired = true;
        _remainingSeconds = 0;
        _countdownTimer?.cancel();
      }
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
                            child: widget.post.imageB.startsWith('http')
                              ? Image.network(widget.post.imageB, fit: BoxFit.cover)
                              : Image.asset(widget.post.imageB, fit: BoxFit.cover),
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
            ),
              IgnorePointer(child: Container(color: Colors.black.withOpacity(0.15))),
              // Background Labels A/B with Small Crown on Winner
              Positioned(
                top: sh * 0.28 - 20, left: 15, 
                child: _bgLabel('A', _votedSide == 1 ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.45), 
                  isWinner: isExpired && (double.parse(widget.post.percentA.replaceAll('%', '')) > double.parse(widget.post.percentB.replaceAll('%', ''))))
              ),
              Positioned(
                top: sh * 0.28 - 20, right: 15, 
                child: _bgLabel('B', _votedSide == 2 ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.45), 
                  isWinner: isExpired && (double.parse(widget.post.percentB.replaceAll('%', '')) > double.parse(widget.post.percentA.replaceAll('%', ''))))
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
                                    shadows: [Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 2))]
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
                                                      color: Colors.white.withOpacity(0.05),
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
              AnimatedPositioned(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                curve: Curves.easeOutCubic, 
                bottom: 290, 
                left: (currentWidthA / 2) - (descWidth / 2), 
                child: _descBox(widget.post.descriptionA, _isDescAExpanded, () => setState(() => _isDescAExpanded = !_isDescAExpanded)),
              ),
              AnimatedPositioned(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                curve: Curves.easeOutCubic, 
                bottom: 290, 
                left: currentWidthA + ((sw - currentWidthA) / 2) - (descWidth / 2), 
                child: _descBox(widget.post.descriptionB, _isDescBExpanded, () => setState(() => _isDescBExpanded = !_isDescBExpanded)),
              ),
              Positioned(
                bottom: 140, left: 18, right: 130,
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
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        _statIcon(
                          widget.post.isLiked ? Icons.favorite : Icons.favorite_border, 
                          widget.post.likesCount.toString(),
                          color: widget.post.isLiked ? Colors.redAccent : Colors.white,
                          onTap: widget.onLike,
                        ),
                        const SizedBox(width: 20),
                        _statIcon(Icons.chat_bubble_outline, widget.post.commentsCount.toString(), onTap: () {
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
                                                    color: Colors.white.withOpacity(0.05),
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
              color: Colors.black.withOpacity(0.2), 
              borderRadius: BorderRadius.circular(15), 
              border: Border.all(color: Colors.white.withOpacity(0.15))
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
      bottom: 127, // Raised to avoid system bar interference
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
              boxShadow: showBorder ? [BoxShadow(color: teamColor.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)] : [],
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
                  backgroundColor: Colors.cyanAccent.withOpacity(0.9),
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
                  _sectionHeader('투표 기간 설정', trailing: '${_selectedHours}시간 ${_selectedMinutes}분'),
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
                        activeColor: Colors.cyanAccent,
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
                        fillColor: Colors.black.withOpacity(0.2),
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
                      fillColor: Colors.black.withOpacity(0.2),
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
                  _guideText('• 직접 촬영하거나 사용 권한이 있는 이미지만 업로드해 주세요.'),
                  _guideText('• 욕설, 혐오 표현, 부적절한 비하 내용 포함 시 삭제될 수 있습니다.'),
                  _guideText('• 성인 컨텐츠 및 AI 생성물은 반드시 해당 항목을 체크해야 합니다.'),
                  _guideText('• 허위 정보로 혼란을 야기하는 투표는 서비스 이용이 제한됩니다.'),
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
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
            color: Colors.white.withOpacity(0.05),
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
                        if (isA) _imagePathA = null; else _imagePathB = null;
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
                      color: Colors.white.withOpacity(0.03),
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
      tileColor: Colors.white.withOpacity(0.03),
    );
  }
}

class ChannelScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Filter posts by this uploader
    final channelPosts = allPosts.where((p) => p.uploaderId == uploaderId).toList();
    
    // Ensure the initialPost is at the top or handled correctly
    if (!channelPosts.contains(initialPost)) {
      channelPosts.insert(0, initialPost);
    } else {
      // Move initialPost to front if needed, or keep order
      channelPosts.remove(initialPost);
      channelPosts.insert(0, initialPost);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: channelPosts.length,
            itemBuilder: (context, index) {
              final post = channelPosts[index];
              return Stack(
                children: [
                  PostView(
                    post: post,
                    onLike: () {},
                    onFollow: () {},
                    onBookmark: () {},
                    onNotInterested: () {},
                    onDontRecommendChannel: () {},
                    onReport: (reason) {},
                    onVote: (side) {},
                  ),
                  // Overlay Profile Header
                  if (index == 0) Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: post.uploaderImage.startsWith('http')
                              ? NetworkImage(post.uploaderImage)
                              : AssetImage(post.uploaderImage) as ImageProvider,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.uploaderId,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '세상의 모든 선택지를 픽겟하다. #데일리룩 #맛집탐방',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              );
            },
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