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

  @override
  void initState() {
    super.initState();
    _posts = [];
    fetchPosts();

    gShowLoginPopup = _showLoginPopup;
    gOnLogout = () {
      print(
        'DEBUG [LOGOUT]: Logout triggered, clearing points and notifications...',
      );
      if (mounted) {
        setState(() {
          gUserPoints = 0;
          gIsLoggedIn = false;
          gUserInternalId = null; // ← 추가
          gIdText = '테스트용'; // ← 추가
          gNameText = '테스트용'; // ← 추가
          gProfileImage = 'assets/profiles/profile_11.jpg'; // ← 추가
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
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('DEBUG [AUTH]: Event occurred -> $event');

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
        if (session != null) {
          print('DEBUG [AUTH]: Login success detected via listener!');
          _loginTimer?.cancel(); // ✅ 로그인 확인되는 즉시 타이머 종료!
          _handleLoginSuccess(session);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print('DEBUG [AUTH]: Logout detected.');
        setState(() {
          gIsLoggedIn = false;
          gUserPoints = 0;
        });
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
      if (session != null && !gIsLoggedIn) {
        print('DEBUG [AUTH]: Initial session found!');
        _handleLoginSuccess(session);
      }
    });
  }

  void _handleLoginSuccess(Session session) async {
    print('DEBUG [AUTH]: Handling login success for ${session.user.id}');

    // 💡 카카오 프로필 정보 추출 (metadata에서 가져옴)
    final metadata = session.user.userMetadata ?? {};
    final String kakaoName =
        metadata['full_name'] ?? metadata['name'] ?? '픽겟 유저';
    final String kakaoImage =
        metadata['avatar_url'] ??
        metadata['picture'] ??
        'assets/profiles/profile_11.jpg';

    setState(() {
      gIsLoggedIn = true;
      gUserInternalId = session.user.id; // ✅ 진짜 고유 ID 저장!
      gNameText = kakaoName;
      gProfileImage = kakaoImage;
      gIdText =
          session.user.email?.split('@').first ??
          session.user.id.substring(0, 8);
    });

    // DB 프로필 업데이트 (이미 있으면 업데이트, 없으면 생성)
    try {
      await SupabaseService.client.from('user_profiles').upsert({
        'id': gUserInternalId,
        'user_id': gIdText,
        'nickname': gNameText,
        'profile_image': gProfileImage,
      }, onConflict: 'id', ignoreDuplicates: true);
    } catch (e) {
      print('DEBUG [AUTH]: Profile sync error: $e');
    }

    await fetchPosts();

    // 💡 추가 정보(나이, 성별 등)가 없으면 설정 화면으로 이동
    if (mounted && !_isProfileSetupOpen) {
      // ✅ 이미 떠있으면 패스!
      try {
        final profile = await SupabaseService.client
            .from('user_profiles')
            .select('age, gender')
            .eq('id', gUserInternalId!)
            .maybeSingle();

        if (profile != null &&
            (profile['age'] == null || profile['gender'] == null)) {
          print(
            'DEBUG [AUTH]: Missing info detected, showing ProfileSetupScreen',
          );

          _isProfileSetupOpen = true; // ✅ 깃발 올리기!

          if (mounted) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSetupScreen(),
              ),
            );

            _isProfileSetupOpen = false; // ✅ 팝업 닫히면 깃발 내리기

            if (result != null && result is Map) {
              await SupabaseService.client
                  .from('user_profiles')
                  .update({
                    'age': result['age'],
                    'gender': result['gender'],
                    'region': result['region'],
                  })
                  .eq('id', gUserInternalId!);

              setState(() {
                gUserPoints += 100;
              });
              _showLoginSuccessSnackBar('카카오');

              // 정보가 업데이트되었으니 다시 fetchPosts 해서 동기화
              await fetchPosts();
            }
          }
        }
      } catch (e) {
        _isProfileSetupOpen = false; // 에러 나도 깃발은 내려야 함
        print('DEBUG [AUTH]: Profile check/update error: $e');
      }
    }

    if (_isLoginPopupOpen) {
      print('DEBUG [AUTH]: Attempting to close popup safely...');
      if (mounted && _isLoginPopupOpen) {
        if (_loginDialogContext != null) {
          // 컨텍스트가 유효한지 한 번 더 확인하고 pop
          try {
            Navigator.of(_loginDialogContext!).pop();
            print('DEBUG [AUTH]: Popup closed via context.');
          } catch (e) {
            print('DEBUG [AUTH]: Pop error (already closed?): $e');
          }
        }
        _isLoginPopupOpen = false;
        _loginDialogContext = null;
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

  Future<void> fetchPosts() async {
    try {
      Set<String> likedPostIds = {};
      Set<String> bookmarkedPostIds = {};
      Set<String> followedUserIds = {};

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
            setState(() {
              // gUserInternalId는 이미 Auth 세션에서 설정되었으므로 덮어쓰지 않음
              gUserPoints = profileData!['points'] ?? 0;
              gIdText = profileData['user_id'] ?? gIdText;
              gNameText = profileData['nickname'] ?? gNameText;
              gProfileImage = profileData['profile_image'] ?? gProfileImage;
              gBioText = profileData['bio'] ?? gBioText;
            });
          } else {
            // 프로필이 없으면 현재 Auth UUID를 사용하여 새로 생성
            print(
              'DEBUG [PROFILE]: No profile found, creating new one for $gUserInternalId',
            );
            final newProfile = await SupabaseService.client
                .from('user_profiles')
                .insert({
                  'id': gUserInternalId, // ✅ Auth UUID를 프로필 ID로 사용!
                  'user_id': gIdText,
                  'points': 5000,
                  'nickname': gNameText,
                  'profile_image': gProfileImage,
                })
                .select()
                .single();
            setState(() {
              gUserPoints = 5000;
            });
          }

          // 2. ID가 완벽히 준비된 지금, 하트/즐겨찾기/팔로우 소환
          if (gUserInternalId != null) {
            // DEBUG: Check likes columns
            try {
              final debugLike = await SupabaseService.client
                  .from('likes')
                  .select()
                  .limit(1)
                  .maybeSingle();
              print('DEBUG [SCHEMA]: likes columns: ${debugLike?.keys}');
            } catch (e) {
              print('DEBUG [SCHEMA]: likes fetch failed: $e');
            }

            final List<dynamic> userLikes = await SupabaseService.client
                .from('likes')
                .select('post_id')
                .eq('user_id', gUserInternalId!);
            likedPostIds = userLikes
                .map((l) => l['post_id'].toString())
                .toSet();

            final List<dynamic> userBookmarks = await SupabaseService.client
                .from('bookmarks')
                .select('post_id')
                .eq('user_id', gUserInternalId!);
            bookmarkedPostIds = userBookmarks
                .map((b) => b['post_id'].toString())
                .toSet();

            final List<dynamic> userFollows = await SupabaseService.client
                .from('follows')
                .select('following_internal_id')
                .eq('follower_internal_id', gUserInternalId!);
            followedUserIds = userFollows
                .map((f) => f['following_internal_id'].toString())
                .toSet();

            print('DEBUG [FETCH]: gUserInternalId=$gUserInternalId');
            print('DEBUG [FETCH]: likedPostIds=$likedPostIds');
            print('DEBUG [FETCH]: bookmarkedPostIds=$bookmarkedPostIds');
            print('DEBUG [FETCH]: followedUserIds=$followedUserIds');

            // 3. 알림 내역 가져오기
            final List<dynamic> notifs = await SupabaseService.client
                .from('notifications')
                .select()
                .eq('user_id', gUserInternalId!)
                .order('created_at', ascending: false);

            setState(() {
              _notifications = List<Map<String, dynamic>>.from(notifs);
              _hasNewNotifications = _notifications.any(
                (n) => n['is_read'] == false,
              );
            });
          }
        } catch (e) {
          print('개인 데이터 가져오기 실패: $e');
        }
      } else {
        setState(() {
          _notifications = [];
          _hasNewNotifications = false;
          gUserPoints = 0;
        });
      }

      // DEBUG: Check posts columns
      try {
        final debugPost = await SupabaseService.client
            .from('posts')
            .select()
            .limit(1)
            .maybeSingle();
        print('DEBUG [SCHEMA]: posts columns: ${debugPost?.keys}');
      } catch (e) {
        print('DEBUG [SCHEMA]: posts fetch failed: $e');
      }

      // 2. Fetch all posts and user profiles for real-time profile merging
      final List<dynamic> postsData = await SupabaseService.client
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> profilesData = await SupabaseService.client
          .from('user_profiles')
          .select('id, user_id, nickname, profile_image');

      // Create maps for quick profile lookup (by ID and by Handle)
      final Map<String, dynamic> profileById = {
        for (var p in profilesData) p['id'].toString(): p,
      };
      final Map<String, dynamic> profileByHandle = {
        for (var p in profilesData) p['user_id'].toString(): p,
      };

      final loadedPosts = postsData.map((json) {
        final String handle = json['uploader_id']?.toString() ?? '';
        final String? internalId = json['uploader_internal_id']?.toString();

        // Priority: Match by Internal ID, then fallback to Handle
        final profile = (internalId != null)
            ? profileById[internalId]
            : profileByHandle[handle];

        final String latestId = (profile != null && profile['user_id'] != null)
            ? profile['user_id'].toString()
            : handle;
        final String nickname = (profile != null && profile['nickname'] != null)
            ? profile['nickname'].toString()
            : (json['uploader_id'] ?? '익명');
        final String profileImg =
            (profile != null && profile['profile_image'] != null)
            ? profile['profile_image'].toString()
            : (json['uploader_image'] ?? 'assets/profiles/profile_11.jpg');

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
          imageA: json['image_a'] ?? '',
          imageB: json['image_b'] ?? '',
          descriptionA: json['description_a'] ?? '선택지 A',
          descriptionB: json['description_b'] ?? '선택지 B',
          fullDescription: json['full_description'] ?? '',
          likesCount: json['likes_count'] ?? 0,
          commentsCount: json['comments_count'] ?? 0,
          voteCountA: (json['vote_count_a'] ?? 0).toString(),
          voteCountB: (json['vote_count_b'] ?? 0).toString(),
          percentA: '50%', // Placeholder
          percentB: '50%', // Placeholder
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
        _refreshRecommended();
      });
    } catch (e) {
      print('Error fetching posts: $e');
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
                                })
                                .eq('id', gUserInternalId!);

                            setState(() {
                              gUserPoints += 100;
                            });
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
                                })
                                .eq('id', gUserInternalId!);

                            setState(() {
                              gUserPoints += 100;
                            });
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
                    ? CircleAvatar(
                        radius: 12,
                        backgroundImage: gProfileImage.startsWith('http')
                            ? NetworkImage(gProfileImage)
                            : AssetImage(gProfileImage) as ImageProvider,
                      )
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

  void _showRankingSheet(BuildContext context) {
    // Simulate Top 10 from master posts list
    List<PostData> topPosts = List.from(_posts);
    topPosts.sort(
      (a, b) => (b.likesCount + b.commentsCount).compareTo(
        a.likesCount + a.commentsCount,
      ),
    );
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
                '어제 인기 Pick (TOP 10)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '지난 24시간 동안 가장 뜨거웠던 Pick',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Divider(color: Colors.white10, height: 30),
              Expanded(
                child: ListView.builder(
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
                            initialIndex: index,
                            channelPosts: topPosts,
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
      ),
    );
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
                  formatCount(
                    post.likesCount + post.commentsCount,
                  ), // Simple mock for votes/engagement
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
