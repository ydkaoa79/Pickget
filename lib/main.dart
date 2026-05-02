import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:app_links/app_links.dart';

// New Imports
import 'models/post_data.dart';
import 'core/app_state.dart';
import 'widgets/social_login_button.dart';
import 'widgets/post_view.dart';
import 'screens/upload_screen.dart';
import 'screens/channel_screen.dart';
import 'screens/point_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/channel_feed_screen.dart';
import 'services/supabase_service.dart';
import 'core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 카카오 SDK 초기화 (네이티브 앱 키 적용)
  KakaoSdk.init(nativeAppKey: 'c4f30c6f5fd4c09548c843ebe0e10074');

  print('DEBUG: App starting with latest comment system code! (Ver. 1.0)');

  // 세로모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SupabaseService.initialize();
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
  Timer? _loginTimer;
  late List<PostData> _posts;
  List<PostData> _recommendedPosts = [];
  final Set<String> _forcedVisibleIds =
      {}; // To show expired posts clicked from ranking
  final PageController _pageController = PageController();
  int _userPoints = 0;
  int _selectedTopTabIndex = 0;
  bool _hasNewNotifications = true;
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoginPopupOpen = false;
  bool _isProfileSetupOpen = false; // ✅ 추가 정보 입력 팝업 중복 방지용
  BuildContext? _loginDialogContext; // 추가
  bool _isInitialLoading = false; // 🛡️ 중복 로딩 방어막 추가!
  bool _isDataLoading = true; // 🔄 데이터 로딩 중인지 (로딩 화면 표시용)

  @override
  void initState() {
    super.initState();
    _posts = [];
    // fetchPosts(); // 🚀 [최적화] 여기서 부르지 않고 아래 리스너/콜백에서 한 번만 부릅니다!

    gShowLoginPopup = _showLoginPopup;
    gOnLogout = () async {
      print('DEBUG [LOGOUT]: Logout triggered, clearing points and notifications...');

      try {
        // 🚀 [핵심] 수파베이스 세션 로그아웃 (기기 저장소 비우기)
        await Supabase.instance.client.auth.signOut(); 
        
        // 🚀 카카오 SDK 로그아웃 (이미 되어있다면 넘어가도록 try-catch)
        await UserApi.instance.logout();
      } catch (e) {
        print('로그아웃 과정 중 알림: $e');
      }

      if (mounted) {
        setState(() {
          gUserPoints = 0;
          gIsLoggedIn = false;
          gUserInternalId = null; 
          gIdText = '테스트용';
          gNameText = '테스트용';
          gProfileImage = '';

          gUserVotes.clear(); // 🗳️ 투표 내역 초기화 (로그아웃 시 VS 마크 복구용!)
          _hasNewNotifications = false;
          _notifications = [];
        });
      }
      fetchPosts();
    };
    gRefreshFeed = fetchPosts;
    _startLoginTimer();

    // [보강] 시스템 레벨 딥링크 탐지기
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      print('DEBUG [SYSTEM_LINK]: Received link: $uri');

      // 딥링크가 들어오면 수파베이스가 세션을 파싱할 시간을 주고 체크
      Future.delayed(const Duration(seconds: 1), () async {
        final session = SupabaseService.client.auth.currentSession;
        if (session != null) {
          print('DEBUG [SYSTEM_LINK]: Session found after deep link!');
          _handleLoginSuccess(session);
        } else {
          print('DEBUG [SYSTEM_LINK]: Session still null. Waiting more...');
          // 1초 더 기다려보고 체크
          Future.delayed(const Duration(seconds: 1), () {
            final session2 = SupabaseService.client.auth.currentSession;
            if (session2 != null) _handleLoginSuccess(session2);
          });
        }
      });
    });

    // 앱이 켜져 있을 때 resume 상태에서도 체크하도록 추가
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.resumed.toString()) {
        print('DEBUG [LIFECYCLE]: App resumed, checking session...');
        final session = SupabaseService.client.auth.currentSession;
        if (session != null && !gIsLoggedIn) {
          _handleLoginSuccess(session);
        }
      }
      return null;
    });

    // 인증 상태 감시자 설치
    print('DEBUG [INIT]: Setting up AuthStateChange listener...');
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // 1. 로그를 찍어서 지금 무슨 일이 일어나는지 확인 (디버깅용)
      print('DEBUG [AUTH]: 이벤트 발생 -> $event, 세션 존재여부 -> ${session != null}');

      // 2. 핵심 로직: 진짜로 '세션'이 들어왔을 때만 성공 처리를 해야 합니다.
      if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) && session != null) {
        // 만약 이미 로그인 처리(gIsLoggedIn)가 끝났다면 또 실행하지 않게 막아야 함
        if (!gIsLoggedIn) {
          print('DEBUG [AUTH]: 진짜 로그인 성공! 이제 팝업 닫고 데이터 세팅함.');
          _loginTimer?.cancel(); // ✅ 로그인 확인되는 즉시 타이머 종료!
          _handleLoginSuccess(session); 
        }
      } 
      // 만약 로그아웃 이벤트가 오면 상태 초기화
      else if (event == AuthChangeEvent.signedOut) {
        print('DEBUG [AUTH]: 로그아웃 됨');
        if (mounted) {
          setState(() {
            gIsLoggedIn = false;
            gUserPoints = 0;
          });
        }
      }
    });

    // 초기 세션 즉시 체크
    print('DEBUG [INIT]: Preparing initial session check...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('DEBUG [INIT]: Inside postFrameCallback');
      // 앱이 딥링크로 열렸을 때의 초기 주소 확인
      try {
        final initialUri = await appLinks.getInitialLink();
        if (initialUri != null) {
          print('DEBUG [SYSTEM_LINK]: Initial link on cold start: $initialUri');
        }
      } catch (e) {
        print('DEBUG [SYSTEM_LINK]: Error getting initial link: $e');
      }

      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        if (!gIsLoggedIn) {
          print('DEBUG [AUTH]: Initial session found in callback!');
          _handleLoginSuccess(session);
        }
      } else {
        if (!gIsLoggedIn && !_isInitialLoading) {
          print('DEBUG [INIT]: No session, fetching guest data...');
          _isInitialLoading = true;
          fetchPosts();
        }
      }
    });
  }

  void _handleLoginSuccess(Session session) async {
    final user = session.user;

    print('DEBUG [AUTH]: Handling login success for ${user.id}');

    // 1. 앱의 전역 상태를 '로그인 됨'으로만 변경 (프로필은 DB에서 가져올 때까지 기본값 유지!)
    setState(() {
      gIsLoggedIn = true;
      gUserInternalId = user.id; // 수파베이스의 유니크 ID 저장
      
      // 이름/아이디는 아직 없을 때만 임시값 세팅 (DB값이 우선)
      if (gNameText.isEmpty || gNameText == '테스트용') {
        gNameText = user.userMetadata?['full_name'] ??
                    user.userMetadata?['name'] ?? '픽겟 유저';
      }
      if (gIdText.isEmpty || gIdText == '테스트용') {
        gIdText = user.email?.split('@').first ?? user.id.substring(0, 8);
      }
      // ⚠️ 프로필 이미지: 카카오 avatar_url 바로 쓰지 않고 빈 문자열 유지
      // → fetchPosts()가 DB에서 커스텀 프로필 가져와서 덮어씀 (깜빡임 방지!)
      gProfileImage = '';
    });

    print('✅ [STATE UPDATE]: 전역 변수 업데이트 완료! (ID: ${user.id})');

    // 2. 띄워져 있는 로그인 팝업 닫기
    if (_isLoginPopupOpen) {
      if (mounted) {
        try {
          if (_loginDialogContext != null) {
            Navigator.of(_loginDialogContext!).pop();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (e) {
          print('DEBUG [AUTH]: Pop error: $e');
        }
      }
      _isLoginPopupOpen = false;
      _loginDialogContext = null;
    }

    // 3. 로그인된 유저의 투표 내역이나 포인트 등을 새로고침
    await fetchPosts(); 

    // 4. 프로필 정보가 비어있으면(신규 유저) 추가 정보 입력 팝업 띄우기
    if (gIsLoggedIn && gUserInternalId != null) {
      final profile = await SupabaseService.client
          .from('user_profiles')
          .select('age, gender, region')
          .eq('id', gUserInternalId!)
          .maybeSingle();

      if (profile == null || profile['age'] == null) {
        if (!_isProfileSetupOpen && mounted) {
          _isProfileSetupOpen = true;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          );
          _isProfileSetupOpen = false;

          if (result != null && result is Map) {
            try {
              await SupabaseService.client
                  .from('user_profiles')
                  .update({
                    'age': result['age'],
                    'gender': result['gender'],
                    'region': result['region'],
                    'agreed_tos': result['agreed_tos'],
                    'agreed_privacy': result['agreed_privacy'],
                    'agreed_third_party': result['agreed_third_party'],
                    'agreed_marketing': result['agreed_marketing'],
                  })
                  .eq('id', gUserInternalId!);

              // 포인트 지급 로직 (예: 필수 동의 1000 + 선택 동의 500)
              int earnedPoints = 1000;
              if (result['agreed_marketing'] == true) {
                earnedPoints += 500;
              }

              setState(() {
                gUserPoints = earnedPoints;
              });

              // 포인트 정보 서버 반영
              await SupabaseService.client
                  .from('user_profiles')
                  .update({'points': gUserPoints})
                  .eq('id', gUserInternalId!);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('가입 축하 포인트가 지급되었습니다! 🎁')),
              );
            } catch (e) {
              print('DEBUG [AUTH]: Profile update error: $e');
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loginTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 🌐 [CDN 무적 연동] 모든 저장소 주소를 최종 CDN 주소로 단축 및 통합
  String toCdnUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('assets/')) return url; // 로컬 에셋은 통과

    final cdnBase = CloudflareConfig.cdnUrl;

    // 1. 이미 CDN 주소면 그대로 반환
    if (url.contains('cdn.pickget.net')) {
      return url;
    }

    // 2. Worker, Supabase, R2 직항 주소 등 모든 케이스를 CDN으로 통합
    if (url.contains('workers.dev') || 
        url.contains('supabase.co') || 
        url.contains('r2.cloudflarestorage.com')) {
      
      // 파일명만 추출 (마지막 / 이후의 문자열)
      final fileName = url.split('/').last;
      // 쿼리 스트링(?...)이 붙어있을 경우 제거하여 깔끔한 파일명만 추출
      final cleanFileName = fileName.split('?').first;
      
      return '$cdnBase$cleanFileName';
    }

    return url;
  }

  Future<void> fetchPosts() async {
    // 🔄 로딩 시작 표시
    if (mounted && _isDataLoading == false) {
      setState(() => _isDataLoading = true);
    }

    try {
      Set<String> likedPostIds = {};
      Set<String> bookmarkedPostIds = {};
      Set<String> followedUserIds = {};
      List<Map<String, dynamic>> loadedNotifications = [];
      bool hasNewNotifs = false;

      if (gIsLoggedIn) {
        try {
          // 1. 프로필 정보 확정 (Auth UUID 기반)
          Map<String, dynamic>? profileData;
          if (gUserInternalId != null) {
            profileData = await SupabaseService.client
                .from('user_profiles')
                .select(
                  'id, points, user_id, nickname, profile_image, bio, age, gender, region',
                )
                .eq('id', gUserInternalId!)
                .maybeSingle();
          }

          if (profileData != null) {
            // setState 안 쓰고 변수만 세팅 (나중에 한 번에 갱신)
            gUserPoints = profileData['points'] ?? 0;
            gIdText = profileData['user_id'] ?? gIdText;
            gNameText = profileData['nickname'] ?? gNameText;
            gProfileImage = profileData['profile_image'] ?? gProfileImage;
            gBioText = profileData['bio'] ?? gBioText;
          } else {
            // 프로필이 없으면 현재 Auth UUID를 사용하여 새로 생성
            print(
              'DEBUG [PROFILE]: No profile found, creating new one for $gUserInternalId',
            );
            await SupabaseService.client
                .from('user_profiles')
                .insert({
                  'id': gUserInternalId, // ✅ Auth UUID를 프로필 ID로 사용!
                  'user_id': gIdText,
                  'points': 0, // 초기 포인트 0 (약관 동의 후 지급)
                  'nickname': gNameText,
                  'profile_image': gProfileImage,
                })
                .select()
                .single();
            gUserPoints = 0;
          }

          // 2. 🚀 [성능 최적화] 개인 데이터 5종을 동시에 가져오기 (병렬 실행!)
          if (gUserInternalId != null) {
            final results = await Future.wait([
              // [0] 좋아요
              SupabaseService.client
                  .from('likes')
                  .select('post_id')
                  .eq('user_id', gUserInternalId!),
              // [1] 북마크
              SupabaseService.client
                  .from('bookmarks')
                  .select('post_id')
                  .eq('user_id', gUserInternalId!),
              // [2] 팔로우
              SupabaseService.client
                  .from('follows')
                  .select('following_internal_id')
                  .eq('follower_internal_id', gUserInternalId!),
              // [3] 투표
              SupabaseService.client
                  .from('votes')
                  .select('post_id, side')
                  .eq('user_internal_id', gUserInternalId!),
              // [4] 알림
              SupabaseService.client
                  .from('notifications')
                  .select()
                  .eq('user_id', gUserInternalId!)
                  .order('created_at', ascending: false),
            ]);

            final List<dynamic> userLikes = results[0];
            final List<dynamic> userBookmarks = results[1];
            final List<dynamic> userFollows = results[2];
            final List<dynamic> userVotes = results[3];
            final List<dynamic> notifs = results[4];

            likedPostIds = userLikes.map((l) => l['post_id'].toString()).toSet();
            bookmarkedPostIds = userBookmarks.map((b) => b['post_id'].toString()).toSet();
            followedUserIds = userFollows.map((f) => f['following_internal_id'].toString()).toSet();
            gUserVotes = {
              for (var v in userVotes) v['post_id'].toString(): v['side'] as int
            };
            loadedNotifications = List<Map<String, dynamic>>.from(notifs);
            hasNewNotifs = loadedNotifications.any((n) => n['is_read'] == false);

            print('DEBUG [FETCH]: gUserInternalId=$gUserInternalId');
            print('DEBUG [FETCH]: likedPostIds=${likedPostIds.length}개, bookmarks=${bookmarkedPostIds.length}개, follows=${followedUserIds.length}개');
          }
        } catch (e) {
          print('개인 데이터 가져오기 실패: $e');
        }
      } else {
        loadedNotifications = [];
        hasNewNotifs = false;
        gUserPoints = 0;
      }

      // 2. [최적화] 게시물을 가져올 때 작성자의 최신 프로필 정보를 '조인(Join)'해서 한 번에 가져옵니다.
      // uploader_internal_id를 기준으로 user_profiles 테이블의 정보를 함께 긁어옵니다.
      final List<dynamic> postsData = await SupabaseService.client
          .from('posts')
          .select('*, profiles:user_profiles!uploader_internal_id(id, user_id, nickname, profile_image)')
          .order('created_at', ascending: false);

      final loadedPosts = postsData.map((json) {
        final profile = json['profiles']; // 조인된 프로필 데이터
        final String handle = json['uploader_id']?.toString() ?? '';
        final String? internalId = json['uploader_internal_id']?.toString();

        // 최신 프로필 정보가 있으면 그것을 쓰고, 없으면 게시물의 기본 정보를 사용합니다 (방어 로직)
        final String latestId = (profile != null && profile['user_id'] != null)
            ? profile['user_id'].toString()
            : handle;
        final String nickname = (profile != null && profile['nickname'] != null)
            ? profile['nickname'].toString()
            : (json['uploader_name'] ?? json['uploader_id'] ?? '익명');
        final String profileImg = toCdnUrl(
            (profile != null && profile['profile_image'] != null)
            ? profile['profile_image'].toString()
            : (json['uploader_image'] ?? 'assets/profiles/profile_11.jpg'));

        final String? finalInternalId =
            internalId ?? profile?['id']?.toString();

        final post = PostData(
          id: json['id'].toString(),
          title: json['title'] ?? '제목 없음',
          uploaderId: latestId, // Use the latest handle!
          uploaderInternalId: finalInternalId, // 🆔 비어있으면 프로필에서 가져온 진짜 주민번호 이식!
          uploaderName: nickname,
          uploaderImage: profileImg,
          timeLocation: '방금 전',
          imageA: toCdnUrl(json['image_a'] ?? ''),
          imageB: toCdnUrl(json['image_b'] ?? ''),
          thumbA: json['thumb_a'] != null ? toCdnUrl(json['thumb_a']) : null,
          thumbB: json['thumb_b'] != null ? toCdnUrl(json['thumb_b']) : null,
          descriptionA: json['description_a'] ?? '선택지 A',
          descriptionB: json['description_b'] ?? '선택지 B',
          fullDescription: json['full_description'] ?? '',
          likesCount: json['likes_count'] ?? 0,
          commentsCount: json['comments_count'] ?? 0,
          voteCountA: (json['vote_count_a'] ?? 0).toString(),
          voteCountB: (json['vote_count_b'] ?? 0).toString(),
          totalVotesCount: json['total_votes'] ?? 0,
          percentA: (() {
            int a = json['vote_count_a'] ?? 0;
            int b = json['vote_count_b'] ?? 0;
            if (a + b == 0) return '50%';
            return '${(a / (a + b) * 100).round()}%';
          })(),
          percentB: (() {
            int a = json['vote_count_a'] ?? 0;
            int b = json['vote_count_b'] ?? 0;
            if (a + b == 0) return '50%';
            return '${(b / (a + b) * 100).round()}%';
          })(),
          isLiked: gIsLoggedIn && likedPostIds.contains(json['id'].toString()),
          isBookmarked:
              gIsLoggedIn && bookmarkedPostIds.contains(json['id'].toString()),
          isFollowing:
              gIsLoggedIn &&
              followedUserIds.contains(
                json['uploader_internal_id']?.toString() ?? '',
              ),
          tags:
              (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
          isExpired: () {
            bool exp = json['is_expired'] ?? false;
            if (exp) return true;
            final tags =
                (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
                [];
            final createdAtStr = json['created_at'];
            if (createdAtStr != null) {
              final createdAt = DateTime.tryParse(createdAtStr);
              if (createdAt != null) {
                for (var tag in tags) {
                  if (tag.startsWith('duration:')) {
                    final mins = int.tryParse(tag.split(':')[1]);
                    if (mins != null &&
                        DateTime.now().isAfter(
                          createdAt.add(Duration(minutes: mins)),
                        )) {
                      return true;
                    }
                  }
                }
              }
            }
            return false;
          }(),
          durationMinutes: () {
            int? dm = json['duration_minutes'];
            if (dm != null) return dm;
            final tags =
                (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
                [];
            for (var tag in tags) {
              if (tag.startsWith('duration:'))
                return int.tryParse(tag.split(':')[1]);
            }
            return null;
          }(),
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
          isHidden: (json['tags'] as List?)?.contains('#hidden#') ?? false,
        );

        if (post.id == '5ffdae62-7072-4ee9-9476-c18aa8afc733') {
          print(
            'DEBUG [MAIN]: Post 5ffdae62 comments_count: ${post.commentsCount}, isLiked: ${post.isLiked}',
          );
        }
        return post;
      }).toList();

      setState(() {
        _posts = loadedPosts.where((p) {
          // 🆔 진짜 고유 번호(UUID)로 내 글인지 확인!
          bool isMine =
              gIsLoggedIn &&
              p.uploaderInternalId != null &&
              p.uploaderInternalId == gUserInternalId;
          return isMine || !p.isHidden;
        }).toList();
        _notifications = loadedNotifications;
        _hasNewNotifications = hasNewNotifs;
        _isDataLoading = false; // 🔄 로딩 완료!
        _refreshRecommended();
      });
    } catch (e) {
      print('Error fetching posts: $e');
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

  void _startLoginTimer() {
    _loginTimer?.cancel();
    _loginTimer = Timer(const Duration(seconds: 4), () async {
      // 타이머가 끝났을 때 세션을 한 번 더 직접 확인 (가장 확실한 방법)
      final session = SupabaseService.client.auth.currentSession;
      if (mounted && !gIsLoggedIn && session == null && !_isLoginPopupOpen) {
        _showLoginPopup();
      }
    });
  }

  void _refreshRecommended() {
    List<PostData> nonExpired = _posts
        .where((p) => !p.isExpired && !p.isHidden)
        .toList();
    if (nonExpired.isEmpty) {
      _recommendedPosts = [];
      return;
    }

    // 1. 내 글 분리 (우선 노출용)
    List<PostData> myPosts = nonExpired
        .where((p) => p.uploaderInternalId == gUserInternalId)
        .toList();
    List<PostData> otherPosts = nonExpired
        .where((p) => p.uploaderInternalId != gUserInternalId)
        .toList();

    // 2. 남의 글은 인기글/일반글로 섞기
    List<PostData> popular = otherPosts
        .where((p) => (p.likesCount + p.commentsCount) >= 1000)
        .toList();
    List<PostData> others = otherPosts
        .where((p) => (p.likesCount + p.commentsCount) < 1000)
        .toList();

    popular.shuffle();
    others.shuffle();

    List<PostData> mixedOthers = [...popular, ...others];

    // 🎯 정석 로직: [내 글] + [섞인 남의 글] 순서로 배치
    setState(() {
      _recommendedPosts = [...myPosts, ...mixedOthers];
    });
  }

  List<PostData> get _filteredPosts {
    // 기본 필터: 숨김 처리되지 않은 게시물
    List<PostData> visiblePosts = _posts.where((p) => !p.isHidden).toList();

    switch (_selectedTopTabIndex) {
      case 0: // 추천
        return _recommendedPosts
            .where((p) => !p.isExpired || _forcedVisibleIds.contains(p.id))
            .toList();
      case 1: // 팔로우
        return visiblePosts
            .where((p) => p.isFollowing && !p.isExpired)
            .toList();
      case 2: // 즐겨찾기
        return visiblePosts
            .where((p) => p.isBookmarked && !p.isExpired)
            .toList();
      case 3: // Pick: 내가 선택한 게시물 (정렬: 진행중 짧은시간순 -> 마감됨)
        List<PostData> picked = visiblePosts
            .where((p) => p.userVotedSide != 0)
            .toList();

        // 정렬 로직
        List<PostData> ongoing = picked.where((p) => !p.isExpired).toList();
        List<PostData> expired = picked.where((p) => p.isExpired).toList();

        // 진행 중인 건 시간이 짧게 남은 순 (remainingSeconds 기준은 아니지만, prototype용으로 durationMinutes 등 활용 가능)
        // 여기서는 durationMinutes나 생성 시간 등을 고려하여 정렬할 수 있습니다.
        // PostData에 구체적인 마감 시각 필드가 있다면 더 정확합니다.
        ongoing.sort(
          (a, b) => (a.durationMinutes ?? 0).compareTo(b.durationMinutes ?? 0),
        );

        return [...ongoing, ...expired];
      default:
        return [];
    }
  }

  void _showLoginSuccessSnackBar(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$platform 로그인 완료!',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.cyanAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLoginPopup() {
    if (_isLoginPopupOpen) return;
    _isLoginPopupOpen = true;
    _loginTimer?.cancel();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.8), // 뒷화면 어둡게
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, anim1, anim2) {
        _loginDialogContext = dialogContext; // 저장!
        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _isLoginPopupOpen = false;
              _loginDialogContext = null;
            }
          },
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 40),
                    SocialLoginButton(
                      svgAsset: 'assets/kakao_logo.svg',
                      label: '카카오 로그인',
                      backgroundColor: const Color(0xFFFEE500),
                      textColor: const Color(
                        0xFF191919,
                      ).withValues(alpha: 0.85),
                      iconSize: 28,
                      onTap: () async {
                        // 💡 안전하게 팝업 닫기 (중복 pop 방지)
                        if (_isLoginPopupOpen && _loginDialogContext != null) {
                          final targetCtx = _loginDialogContext;
                          _isLoginPopupOpen = false;
                          _loginDialogContext = null;
                          try {
                            Navigator.of(targetCtx!).pop();
                          } catch (e) {
                            print('DEBUG [AUTH]: Tap pop error: $e');
                          }
                        }

                        try {
                          // 1. 수파베이스 카카오 로그인 실행
                          await SupabaseService.client.auth.signInWithOAuth(
                            OAuthProvider.kakao,
                            redirectTo: 'pickget://login-callback',
                            authScreenLaunchMode: LaunchMode.inAppBrowserView,
                          );
                        } catch (e) {
                          // 💡 참고: 로그인이 완료되면 딥링크를 통해 앱으로 돌아오고,
                          // supabase_flutter 패키지가 자동으로 세션을 인식합니다.
                        } catch (e) {
                          print('카카오 로그인 에러: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('로그인 중 오류가 발생했습니다: $e')),
                          );
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
                        setState(() {
                          gIsLoggedIn = true;
                        });
                        await fetchPosts(); // Identity check!
                        Navigator.pop(context);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSetupScreen(),
                          ),
                        );

                        if (result != null && result is Map) {
                          try {
                            await SupabaseService.client
                                .from('user_profiles')
                                .update({
                                  'age': result['age'],
                                  'gender': result['gender'],
                                  'region': result['region'],
                                  'agreed_tos': result['agreed_tos'],
                                  'agreed_privacy': result['agreed_privacy'],
                                  'agreed_third_party': result['agreed_third_party'],
                                  'agreed_marketing': result['agreed_marketing'],
                                })
                                .eq('id', gUserInternalId!);

                            // 포인트 지급 로직 (예: 필수 동의 1000 + 선택 동의 500)
                            int earnedPoints = 1000;
                            if (result['agreed_marketing'] == true) {
                              earnedPoints += 500;
                            }

                            setState(() {
                              gUserPoints += earnedPoints;
                            });

                            // 포인트 정보도 서버에 반영
                            await SupabaseService.client
                                .from('user_profiles')
                                .update({'points': gUserPoints})
                                .eq('id', gUserInternalId!);

                            _showLoginSuccessSnackBar('네이버');
                          } catch (e) {
                            print(
                              'DEBUG [AUTH]: Naver profile update error: $e',
                            );
                          }
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
                        setState(() {
                          gIsLoggedIn = true;
                        });
                        await fetchPosts(); // Identity check!
                        Navigator.pop(context);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSetupScreen(),
                          ),
                        );

                        if (result != null && result is Map) {
                          try {
                            await SupabaseService.client
                                .from('user_profiles')
                                .update({
                                  'age': result['age'],
                                  'gender': result['gender'],
                                  'region': result['region'],
                                  'agreed_tos': result['agreed_tos'],
                                  'agreed_privacy': result['agreed_privacy'],
                                  'agreed_third_party': result['agreed_third_party'],
                                  'agreed_marketing': result['agreed_marketing'],
                                })
                                .eq('id', gUserInternalId!);

                            // 포인트 지급 로직
                            int earnedPoints = 1000;
                            if (result['agreed_marketing'] == true) {
                              earnedPoints += 500;
                            }

                            setState(() {
                              gUserPoints += earnedPoints;
                            });

                            // 포인트 정보도 서버에 반영
                            await SupabaseService.client
                                .from('user_profiles')
                                .update({'points': gUserPoints})
                                .eq('id', gUserInternalId!);

                            _showLoginSuccessSnackBar('Google');
                          } catch (e) {
                            print(
                              'DEBUG [AUTH]: Google profile update error: $e',
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () {
                        _isLoginPopupOpen = false;
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '나중에 할게요',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
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
          // 🔄 데이터 로딩 중일 때 로딩 화면 표시 (프리징 방지!)
          if (_isDataLoading && _posts.isEmpty)
            _buildLoadingView()
          else if (!gIsLoggedIn && _selectedTopTabIndex != 0)
            _buildLoginRequiredView()
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final post = filteredList[index];
                return PostView(
                  key: ValueKey(
                    '${post.id}_$gIsLoggedIn',
                  ), // Force rebuild on login/logout!
                  post: post,
                  onLike: () async {
                    if (!gIsLoggedIn) {
                      _showLoginPopup();
                      return;
                    }
                    final bool nowLiked = !post.isLiked;

                    // 1. UI 즉시 반영 (선체감)
                    setState(() {
                      post.isLiked = nowLiked;
                      if (nowLiked) {
                        post.likesCount++;
                        gUserPoints += 1; // 포인트 UI 즉시 반영
                      } else {
                        post.likesCount--;
                      }
                      HapticFeedback.lightImpact();
                    });

                    // 2. 서버 연동 (주민번호 기준!)
                    try {
                      print(
                        'DEBUG [LIKE]: Attempting to sync heart. user_internal_id=$gUserInternalId, post_id=${post.id}, nowLiked=$nowLiked',
                      );
                      if (nowLiked) {
                        // 하트 기록
                        final res = await SupabaseService.client
                            .from('likes')
                            .insert({
                              'user_id': gUserInternalId, // 🆔 진짜 컬럼명으로 교체!
                              'post_id': post.id,
                            });
                        print('DEBUG [LIKE]: Insert success!');

                        // 포인트 내역 기록 (+1P)
                        await SupabaseService.client
                            .from('points_history')
                            .insert({
                              'user_id': gUserInternalId,
                              'amount': 1,
                              'description': '게시물 좋아요 보너스',
                            });
                      } else {
                        // 하트 취소
                        await SupabaseService.client
                            .from('likes')
                            .delete()
                            .match({
                              'user_id': gUserInternalId!,
                              'post_id': post.id,
                            });
                        print('DEBUG [LIKE]: Delete success!');
                      }

                      // 3. 게시물 테이블의 하트 수 실시간 동기화
                      await SupabaseService.client
                          .from('posts')
                          .update({'likes_count': post.likesCount})
                          .eq('id', post.id);

                      setState(() {}); // UI 갱신만 수행
                    } catch (e) {
                      print('DEBUG [LIKE]: ERROR 상세 -> $e');
                    }
                  },
                  onFollow: () async {
                    if (!gIsLoggedIn) {
                      _showLoginPopup();
                      return;
                    }
                    final bool nowFollowing = !post.isFollowing;
                    String normalized(String s) => s.replaceAll(' ', '').trim();
                    final String targetUploader = normalized(post.uploaderId);

                    setState(() {
                      for (var p in _posts) {
                        if (normalized(p.uploaderId) == targetUploader) {
                          p.isFollowing = nowFollowing;
                        }
                      }
                      HapticFeedback.mediumImpact();
                    });

                    try {
                      if (nowFollowing) {
                        await SupabaseService.client.from('follows').insert({
                          'follower_internal_id': gUserInternalId!,
                          'following_internal_id': post.uploaderInternalId!,
                        });
                      } else {
                        await SupabaseService.client
                            .from('follows')
                            .delete()
                            .match({
                              'follower_internal_id': gUserInternalId!,
                              'following_internal_id': post.uploaderInternalId!,
                            });
                      }
                    } catch (e) {
                      print('팔로우 서버 동기화 에러: $e');
                    }
                  },
                  onBookmark: () async {
                    if (!gIsLoggedIn) {
                      _showLoginPopup();
                      return;
                    }
                    final bool nowBookmarked = !post.isBookmarked;
                    setState(() {
                      post.isBookmarked = nowBookmarked;
                      HapticFeedback.selectionClick();
                    });

                    try {
                      if (nowBookmarked) {
                        await SupabaseService.client.from('bookmarks').insert({
                          'user_id': gUserInternalId!,
                          'post_id': post.id,
                        });
                      } else {
                        await SupabaseService.client
                            .from('bookmarks')
                            .delete()
                            .match({
                              'user_id': gUserInternalId!,
                              'post_id': post.id,
                            });
                      }
                    } catch (e) {
                      print('즐겨찾기 동기화 에러: $e');
                    }
                  },
                  onNotInterested: () {
                    setState(() {
                      _posts.removeWhere((p) => p.id == post.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('관심없음으로 설정되어 이 포스트가 제외되었습니다.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onDontRecommendChannel: () {
                    String uploaderId = post.uploaderId;
                    setState(() {
                      _posts.removeWhere((p) => p.uploaderId == uploaderId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$uploaderId 채널의 추천을 중단합니다.'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onReport: (reason) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('신고가 접수되었습니다: $reason'),
                        duration: const Duration(seconds: 1),
                      ),
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
                  onDelete: (postId) {
                    setState(() {
                      _posts.removeWhere((p) => p.id == postId);
                      _refreshRecommended();
                    });
                  },
                  onToggleHide: (postId) async {
                    setState(() {
                      post.isHidden = !post.isHidden;
                      _refreshRecommended();
                    });
                    try {
                      await SupabaseService.client
                          .from('posts')
                          .update({
                            'tags': post.isHidden
                                ? [...(post.tags ?? []), '#hidden#']
                                : (post.tags ?? [])
                                      .where((t) => t != '#hidden#')
                                      .toList(),
                          })
                          .eq('id', postId);
                    } catch (e) {
                      print('숨기기 동기화 에러: $e');
                    }
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
                      if (mounted) {
                        setState(() {
                          // 채널 화면에서 게시물이 삭제되었을 수 있으므로 추천 목록 등을 동기화
                          _refreshRecommended();
                        });
                      }
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

  // 🔄 데이터 로딩 중 표시 화면 (첫 실행 프리징 방지!)
  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PickGet 로고
            SvgPicture.asset(
              'assets/simbol.svg',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 32),
            // 로딩 인디케이터
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.cyanAccent,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '콘텐츠를 불러오는 중...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequiredView() {
    String tabName = [
      '',
      '팔로우한 채널',
      '즐겨찾기한 픽겟',
      '선택한 픽겟',
    ][_selectedTopTabIndex];
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
              child: const Icon(
                Icons.lock_outline,
                color: Colors.cyanAccent,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '로그인이 필요한 기능입니다',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$tabName 확인을 위해\n로그인을 진행해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.5,
              ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '로그인하고 시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 30,
                      fit: BoxFit.contain,
                    ),
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
                              MaterialPageRoute(
                                builder: (context) =>
                                    PointScreen(currentPoints: gUserPoints),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'P ',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  gUserPoints.toString().replaceAllMapped(
                                    RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
                                    (Match m) => "${m[1]},",
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
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
                              MaterialPageRoute(
                                builder: (context) =>
                                    SearchScreen(allPosts: _posts),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topTab(String label, int index) {
    final isSelected = _selectedTopTabIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTopTabIndex = index;
        });
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
      bottom: 20 + bottomPadding,
      left: 20,
      right: 20,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
            ),
          ],
        ),
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
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: const Icon(
                Icons.home_filled,
                color: Colors.white,
                size: 22,
              ),
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
              child: const Icon(
                Icons.emoji_events_outlined,
                color: Colors.white,
                size: 20,
              ),
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
                ).then((_) async {
                  // 1. 서버에서 최신 데이터 가져오기
                  await fetchPosts();

                  // 2. 자동으로 첫 번째 페이지(새 글)로 이동!
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.cyanAccent,
                  size: 26,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (!gIsLoggedIn) {
                  _showLoginPopup();
                  return;
                }
                HapticFeedback.mediumImpact();
                setState(() {
                  _hasNewNotifications = false;
                }); // 알림 확인 시 점 제거
                _showNotificationSheet(context);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 20,
                  ),
                  if (gIsLoggedIn && _hasNewNotifications)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.cyanAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (!gIsLoggedIn) {
                  _showLoginPopup();
                  return;
                }
                // 게시물이 없을 경우를 대비한 안전한 이동 로직
                PostData? firstPost = _posts.isNotEmpty ? _posts.first : null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelScreen(
                      uploaderId: '나의픽겟',
                      allPosts: _posts,
                      initialPost:
                          firstPost ??
                          PostData(
                            id: 'dummy',
                            uploaderId: '나의픽겟',
                            uploaderName: gNameText,
                            uploaderImage: gProfileImage,
                            title: '첫 포스트를 올려보세요!',
                            timeLocation: '방금 전',
                            imageA: 'assets/images/placeholder.png',
                            imageB: 'assets/images/placeholder.png',
                            descriptionA: '',
                            descriptionB: '',
                            likesCount: 0,
                            commentsCount: 0,
                            voteCountA: '0',
                            voteCountB: '0',
                            percentA: '50%',
                            percentB: '50%',
                            fullDescription: '',
                            comments: [],
                          ),
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      _refreshRecommended();
                    });
                  }
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(10), // 터치 마스크 영역 넉넉하게 확장
                child: gIsLoggedIn
                    ? (gProfileImage.isEmpty
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black,
                        child: const Icon(Icons.person, color: Colors.white54, size: 16),
                      )
                    : CircleAvatar(
                        radius: 12,
                        backgroundImage: gProfileImage.startsWith('http')
                            ? NetworkImage(gProfileImage)
                            : AssetImage(gProfileImage) as ImageProvider,
                        backgroundColor: Colors.black,
                      ))
                    : const Icon(
                        Icons.account_circle_outlined,
                        color: Colors.white54,
                        size: 24,
                      ),
              ),
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '알림',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Divider(color: Colors.white10, height: 30),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(
                        child: Text(
                          '새로운 알림이 없습니다.',
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          IconData icon;
                          Color color;
                          switch (n['type']) {
                            case 'info':
                              icon = Icons.campaign;
                              color = Colors.cyanAccent;
                              break;
                            case 'win':
                              icon = Icons.check_circle;
                              color = Colors.amberAccent;
                              break;
                            case 'comment':
                              icon = Icons.chat_bubble;
                              color = Colors.blueAccent;
                              break;
                            case 'like':
                              icon = Icons.favorite;
                              color = Colors.redAccent;
                              break;
                            default:
                              icon = Icons.notifications;
                              color = Colors.white54;
                          }

                          return _notificationItem(
                            icon,
                            color,
                            n['message'] ?? n['title'] ?? '',
                            '방금 전', // In real app, format n['created_at']
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationItem(
    IconData icon,
    Color color,
    String message,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRankingSheet(BuildContext context) async {
    // 1. 로딩 창 먼저 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<List<PostData>>(
            future: _fetchTopRankings(),
            builder: (context, snapshot) {
              bool isLoading = snapshot.connectionState == ConnectionState.waiting;
              List<PostData> topPosts = snapshot.data ?? [];

              return SafeArea(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF121212),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '실시간 인기 Pick (TOP 10)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '지금 가장 뜨거운 실시간 랭킹',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const Divider(color: Colors.white10, height: 30),
                      Expanded(
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyanAccent,
                                  strokeWidth: 2,
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: topPosts.length,
                                itemBuilder: (context, index) {
                                  final post = topPosts[index];
                                  return _rankingItem(index + 1, post, () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChannelFeedScreen(
                                          initialIndex: 0, // 랭킹에서 누르면 해당 포스트가 첫번째
                                          channelPosts: [post],
                                          allPosts: _posts,
                                        ),
                                      ),
                                    );
                                  });
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<PostData>> _fetchTopRankings() async {
    try {
      // 서버에서 직접 최신 투표 데이터가 포함된 게시물 조회
      final List<dynamic> data = await SupabaseService.client
          .from('posts')
          .select('*, total_votes') // 필요한 필드를 모두 포함하되 누락 방지
          .order('total_votes', ascending: false)
          .limit(50);

      List<PostData> loadedPosts = data.map((json) {
        // [수정] 데이터 타입을 명확히 하고, null 처리를 더 견고하게 함
        String vA = (json['vote_count_a'] ?? '0').toString();
        String vB = (json['vote_count_b'] ?? '0').toString();

        return PostData(
          id: json['id'].toString(),
          title: json['title'] ?? '제목 없음',
          uploaderId: json['uploader_id']?.toString() ?? '익명',
          uploaderName: json['uploader_name'] ?? json['uploader_id']?.toString() ?? '익명',
          uploaderImage: toCdnUrl(json['uploader_image'] ?? 'assets/profiles/profile_11.jpg'),
          timeLocation: '실시간',
          imageA: json['image_a'] ?? '',
          imageB: json['image_b'] ?? '',
          descriptionA: json['description_a'] ?? '',
          descriptionB: json['description_b'] ?? '',
          likesCount: json['likes_count'] ?? 0,
          commentsCount: json['comments_count'] ?? 0,
          voteCountA: vA,
          voteCountB: vB,
          totalVotesCount: json['total_votes'] ?? 0,
          percentA: (() {
            int a = int.tryParse(vA) ?? 0;
            int b = int.tryParse(vB) ?? 0;
            if (a + b == 0) return '50%';
            return '${(a / (a + b) * 100).round()}%';
          })(),
          percentB: (() {
            int a = int.tryParse(vA) ?? 0;
            int b = int.tryParse(vB) ?? 0;
            if (a + b == 0) return '50%';
            return '${(b / (a + b) * 100).round()}%';
          })(),
          tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
          isExpired: () {
            // 종료 여부 계산 로직 (메인과 동일)
            final String? createdAtStr = json['created_at'];
            final List<dynamic> tags = json['tags'] as List? ?? [];
            if (createdAtStr != null) {
              final createdAt = DateTime.tryParse(createdAtStr);
              if (createdAt != null) {
                for (var tag in tags) {
                  String t = tag.toString();
                  if (t.startsWith('duration:')) {
                    final mins = int.tryParse(t.split(':')[1]);
                    if (mins != null && DateTime.now().isAfter(createdAt.add(Duration(minutes: mins)))) {
                      return true;
                    }
                  }
                }
              }
            }
            return false;
          }(),
        );
      }).toList();

      // 투표 합계 순으로 정밀 정렬
      loadedPosts.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
      return loadedPosts.take(10).toList();
    } catch (e) {
      print('랭킹 데이터 로드 실패: $e');
      return [];
    }
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
                    style: TextStyle(
                      color: post.isExpired ? Colors.white38 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                  formatCount(post.totalVotes), // 진짜 투표수(A+B) 표시!
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  '픽',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
