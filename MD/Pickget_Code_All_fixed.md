# Pickget Project Code Export

## File: pubspec.yaml
``yaml
name: pickget
description: "A new Flutter project."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.11.5

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.2.4
  supabase_flutter: ^2.12.4
  http: ^1.6.0
  path_provider: ^2.1.5
  image_picker: ^1.2.2
  video_player: ^2.11.1
  dio: ^5.9.2
  intl: ^0.20.2
  shared_preferences: ^2.5.5
  image_cropper: ^12.2.1
  kakao_flutter_sdk_user: ^2.0.0+1
  flutter_image_compress: ^2.4.0
  video_compress: ^3.1.4
  cached_network_image: ^3.4.1
  flutter_cache_manager: ^3.4.1
  visibility_detector: ^0.4.0+2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: "^0.13.1"

flutter_launcher_icons:
  android: "ic_launcher"
  image_path: "AppIcons/playstore.png"
  min_sdk_android: 21 # android min sdk min:16, default 21

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  assets:
    - assets/
    - assets/images/
    - assets/profiles/
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package

``

## File: lib\core\app_constants.dart
``dart
// 앱 전체에서 사용하는 상수 값 모음
class AppConstants {
  // 포인트 관련 상수
  static const int signupBasePoints = 1000;
  static const int marketingConsentPoints = 500;
  static const int likePoints = 1;
  static const int votePoints = 5;
  static const int uploadPoints = 100;

  // 인기 게시물 기준 (좋아요 + 댓글 합산)
  static const int popularPostThreshold = 1000;

  // 로그인 팝업 딜레이 (초)
  static const int loginPopupDelaySecs = 4;

  AppConstants._();
}
``

## File: lib\main.dart
``dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:app_links/app_links.dart';

// New Imports
import 'models/post_data.dart';
import 'core/app_state.dart';
import 'core/app_constants.dart';
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

  // ??移댁뭅??SDK 珥덇린??(?ㅼ씠?곕툕 ?????곸슜)
  KakaoSdk.init(nativeAppKey: 'c4f30c6f5fd4c09548c843ebe0e10074');

  if (kDebugMode) debugPrint('DEBUG: App starting with latest comment system code! (Ver. 1.0)');

  // ?몃줈紐⑤뱶 怨좎젙
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
  Timer? _expiryRefreshTimer;
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
  bool _isProfileSetupOpen = false; // ??異붽? ?뺣낫 ?낅젰 ?앹뾽 以묐났 諛⑹???
  BuildContext? _loginDialogContext; // 異붽?
  bool _isInitialLoading = false; // ?썳截?以묐났 濡쒕뵫 諛⑹뼱留?異붽?!
  bool _isDataLoading = true; // ?봽 ?곗씠??濡쒕뵫 以묒씤吏 (濡쒕뵫 ?붾㈃ ?쒖떆??

  @override
  void initState() {
    super.initState();
    _posts = [];
    // fetchPosts(); // ?? [理쒖쟻?? ?ш린??遺瑜댁? ?딄퀬 ?꾨옒 由ъ뒪??肄쒕갚?먯꽌 ??踰덈쭔 遺由낅땲??

    gShowLoginPopup = _showLoginPopup;
    gOnLogout = () async {
      if (kDebugMode) debugPrint('DEBUG [LOGOUT]: Logout triggered, clearing points and notifications...');

      try {
        // ?? [?듭떖] ?섑뙆踰좎씠???몄뀡 濡쒓렇?꾩썐 (湲곌린 ??μ냼 鍮꾩슦湲?
        await Supabase.instance.client.auth.signOut(); 
        
        // ?? 移댁뭅??SDK 濡쒓렇?꾩썐 (?대? ?섏뼱?덈떎硫??섏뼱媛?꾨줉 try-catch)
        await UserApi.instance.logout();
      } catch (e) {
        if (kDebugMode) debugPrint('濡쒓렇?꾩썐 怨쇱젙 以??뚮┝: $e');
      }

      if (mounted) {
        setState(() {
          gUserPoints = 0;
          gIsLoggedIn = false;
          gUserInternalId = null; 
          gIdText = '?뚯뒪?몄슜';
          gNameText = '?뚯뒪?몄슜';
          gProfileImage = '';

          gUserVotes.clear(); // ?뿳截??ы몴 ?댁뿭 珥덇린??(濡쒓렇?꾩썐 ??VS 留덊겕 蹂듦뎄??)
          _hasNewNotifications = false;
          _notifications = [];
        });
      }
      fetchPosts();
    };
    gRefreshFeed = fetchPosts;
    _startLoginTimer();
    _startExpiryRefreshTimer();

    // [蹂닿컯] ?쒖뒪???덈꺼 ?λ쭅???먯?湲?
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      if (kDebugMode) debugPrint('DEBUG [SYSTEM_LINK]: Received link: $uri');

      // ?λ쭅?ш? ?ㅼ뼱?ㅻ㈃ ?섑뙆踰좎씠?ㅺ? ?몄뀡???뚯떛???쒓컙??二쇨퀬 泥댄겕
      Future.delayed(const Duration(seconds: 1), () async {
        final session = SupabaseService.client.auth.currentSession;
        if (session != null) {
          if (kDebugMode) debugPrint('DEBUG [SYSTEM_LINK]: Session found after deep link!');
          _handleLoginSuccess(session);
        } else {
          if (kDebugMode) debugPrint('DEBUG [SYSTEM_LINK]: Session still null. Waiting more...');
          // 1珥???湲곕떎?ㅻ낫怨?泥댄겕
          Future.delayed(const Duration(seconds: 1), () {
            final session2 = SupabaseService.client.auth.currentSession;
            if (session2 != null) _handleLoginSuccess(session2);
          });
        }
      });
    });

    // ?깆씠 耳쒖졇 ?덉쓣 ??resume ?곹깭?먯꽌??泥댄겕?섎룄濡?異붽?
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.resumed.toString()) {
        if (kDebugMode) debugPrint('DEBUG [LIFECYCLE]: App resumed, checking session...');
        final session = SupabaseService.client.auth.currentSession;
        if (session != null && !gIsLoggedIn) {
          _handleLoginSuccess(session);
        }
      }
      return null;
    });

    // ?몄쬆 ?곹깭 媛먯떆???ㅼ튂
    if (kDebugMode) debugPrint('DEBUG [INIT]: Setting up AuthStateChange listener...');
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // 1. 濡쒓렇瑜?李띿뼱??吏湲?臾댁뒯 ?쇱씠 ?쇱뼱?섎뒗吏 ?뺤씤 (?붾쾭源낆슜)
      if (kDebugMode) debugPrint('DEBUG [AUTH]: ?대깽??諛쒖깮 -> $event, ?몄뀡 議댁옱?щ? -> ${session != null}');

      // 2. ?듭떖 濡쒖쭅: 吏꾩쭨濡?'?몄뀡'???ㅼ뼱?붿쓣 ?뚮쭔 ?깃났 泥섎━瑜??댁빞 ?⑸땲??
      if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) && session != null) {
        // 留뚯빟 ?대? 濡쒓렇??泥섎━(gIsLoggedIn)媛 ?앸궗?ㅻ㈃ ???ㅽ뻾?섏? ?딄쾶 留됱븘????
        if (!gIsLoggedIn) {
          if (kDebugMode) debugPrint('DEBUG [AUTH]: 吏꾩쭨 濡쒓렇???깃났! ?댁젣 ?앹뾽 ?リ퀬 ?곗씠???명똿??');
          _loginTimer?.cancel(); // ??濡쒓렇???뺤씤?섎뒗 利됱떆 ??대㉧ 醫낅즺!
          _handleLoginSuccess(session); 
        }
      } 
      // 留뚯빟 濡쒓렇?꾩썐 ?대깽?멸? ?ㅻ㈃ ?곹깭 珥덇린??
      else if (event == AuthChangeEvent.signedOut) {
        if (kDebugMode) debugPrint('DEBUG [AUTH]: 濡쒓렇?꾩썐 ??);
        if (mounted) {
          setState(() {
            gIsLoggedIn = false;
            gUserPoints = 0;
          });
        }
      }
    });

    // 珥덇린 ?몄뀡 利됱떆 泥댄겕
    if (kDebugMode) debugPrint('DEBUG [INIT]: Preparing initial session check...');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kDebugMode) debugPrint('DEBUG [INIT]: Inside postFrameCallback');
      // ?깆씠 ?λ쭅?щ줈 ?대졇???뚯쓽 珥덇린 二쇱냼 ?뺤씤
      try {
        final initialUri = await appLinks.getInitialLink();
        if (initialUri != null) {
          if (kDebugMode) debugPrint('DEBUG [SYSTEM_LINK]: Initial link on cold start: $initialUri');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('DEBUG [SYSTEM_LINK]: Error getting initial link: $e');
      }

      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        if (!gIsLoggedIn) {
          if (kDebugMode) debugPrint('DEBUG [AUTH]: Initial session found in callback!');
          _handleLoginSuccess(session);
        }
      } else {
        if (!gIsLoggedIn && !_isInitialLoading) {
          if (kDebugMode) debugPrint('DEBUG [INIT]: No session, fetching guest data...');
          _isInitialLoading = true;
          fetchPosts();
        }
      }
    });
  }

  void _handleLoginSuccess(Session session) async {
    final user = session.user;

    if (kDebugMode) debugPrint('DEBUG [AUTH]: Handling login success for ${user.id}');

    // 1. ?깆쓽 ?꾩뿭 ?곹깭瑜?'濡쒓렇?????쇰줈留?蹂寃?(?꾨줈?꾩? DB?먯꽌 媛?몄삱 ?뚭퉴吏 湲곕낯媛??좎?!)
    setState(() {
      gIsLoggedIn = true;
      gUserInternalId = user.id; // ?섑뙆踰좎씠?ㅼ쓽 ?좊땲??ID ???
      
      // ?대쫫/?꾩씠?붾뒗 ?꾩쭅 ?놁쓣 ?뚮쭔 ?꾩떆媛??명똿 (DB媛믪씠 ?곗꽑)
      if (gNameText.isEmpty || gNameText == '?뚯뒪?몄슜') {
        gNameText = user.userMetadata?['full_name'] ??
                    user.userMetadata?['name'] ?? '?쎄쿊 ?좎?';
      }
      if (gIdText.isEmpty || gIdText == '?뚯뒪?몄슜') {
        gIdText = user.email?.split('@').first ?? user.id.substring(0, 8);
      }
      // ?좑툘 ?꾨줈???대?吏: 移댁뭅??avatar_url 諛붾줈 ?곗? ?딄퀬 鍮?臾몄옄???좎?
      // ??fetchPosts()媛 DB?먯꽌 而ㅼ뒪? ?꾨줈??媛?몄?????뼱? (源쒕묀??諛⑹?!)
      gProfileImage = '';
    });

    if (kDebugMode) debugPrint('??[STATE UPDATE]: ?꾩뿭 蹂???낅뜲?댄듃 ?꾨즺! (ID: ${user.id})');

    // 2. ?꾩썙???덈뒗 濡쒓렇???앹뾽 ?リ린
    if (_isLoginPopupOpen) {
      if (mounted) {
        try {
          if (_loginDialogContext != null) {
            Navigator.of(_loginDialogContext!).pop();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('DEBUG [AUTH]: Pop error: $e');
        }
      }
      _isLoginPopupOpen = false;
      _loginDialogContext = null;
    }

    // 3. 濡쒓렇?몃맂 ?좎????ы몴 ?댁뿭?대굹 ?ъ씤???깆쓣 ?덈줈怨좎묠
    await fetchPosts(); 

    // 4. ?꾨줈???뺣낫媛 鍮꾩뼱?덉쑝硫??좉퇋 ?좎?) 異붽? ?뺣낫 ?낅젰 ?앹뾽 ?꾩슦湲?
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

              // ?ъ씤??吏湲?濡쒖쭅 (?? ?꾩닔 ?숈쓽 1000 + ?좏깮 ?숈쓽 500)
              int earnedPoints = AppConstants.signupBasePoints;
              if (result['agreed_marketing'] == true) {
                earnedPoints += AppConstants.marketingConsentPoints;
              }

              setState(() {
                gUserPoints = earnedPoints;
              });

              // ?ъ씤???뺣낫 ?쒕쾭 諛섏쁺
              await SupabaseService.client
                  .from('user_profiles')
                  .update({'points': gUserPoints})
                  .eq('id', gUserInternalId!);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('媛??異뺥븯 ?ъ씤?멸? 吏湲됰릺?덉뒿?덈떎! ?럞')),
              );
            } catch (e) {
              if (kDebugMode) debugPrint('DEBUG [AUTH]: Profile update error: $e');
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
    _expiryRefreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ?뙋 [CDN 臾댁쟻 ?곕룞] 紐⑤뱺 ??μ냼 二쇱냼瑜?理쒖쥌 CDN 二쇱냼濡??⑥텞 諛??듯빀
  String toCdnUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('assets/')) return url; // 濡쒖뺄 ?먯뀑? ?듦낵

    final cdnBase = CloudflareConfig.cdnUrl;

    // 1. ?대? CDN 二쇱냼硫?洹몃?濡?諛섑솚
    if (url.contains('cdn.pickget.net')) {
      return url;
    }

    // 2. Worker, Supabase, R2 吏곹빆 二쇱냼 ??紐⑤뱺 耳?댁뒪瑜?CDN?쇰줈 ?듯빀
    if (url.contains('workers.dev') || 
        url.contains('supabase.co') || 
        url.contains('r2.cloudflarestorage.com')) {
      
      // ?뚯씪紐낅쭔 異붿텧 (留덉?留?/ ?댄썑??臾몄옄??
      final fileName = url.split('/').last;
      // 荑쇰━ ?ㅽ듃留??...)??遺숈뼱?덉쓣 寃쎌슦 ?쒓굅?섏뿬 源붾걫???뚯씪紐낅쭔 異붿텧
      final cleanFileName = fileName.split('?').first;
      
      return '$cdnBase$cleanFileName';
    }

    return url;
  }

  /// A와 B의 투표 수를 받아 퍼센트 문자열을 반환합니다.
  String _calcPercent(int a, int b, {required bool isA}) {
    if (a + b == 0) return '50%';
    final ratio = isA ? a / (a + b) : b / (a + b);
    return '${(ratio * 100).round()}%';
  }

  Future<void> fetchPosts() async {
    // ?봽 濡쒕뵫 ?쒖옉 ?쒖떆
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
          // 1. ?꾨줈???뺣낫 ?뺤젙 (Auth UUID 湲곕컲)
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
            // setState ???곌퀬 蹂?섎쭔 ?명똿 (?섏쨷????踰덉뿉 媛깆떊)
            gUserPoints = profileData['points'] ?? 0;
            gIdText = profileData['user_id'] ?? gIdText;
            gNameText = profileData['nickname'] ?? gNameText;
            gProfileImage = profileData['profile_image'] ?? gProfileImage;
            gBioText = profileData['bio'] ?? gBioText;
          } else {
            // ?꾨줈?꾩씠 ?놁쑝硫??꾩옱 Auth UUID瑜??ъ슜?섏뿬 ?덈줈 ?앹꽦
            if (kDebugMode) debugPrint(
              'DEBUG [PROFILE]: No profile found, creating new one for $gUserInternalId',
            );
            await SupabaseService.client
                .from('user_profiles')
                .insert({
                  'id': gUserInternalId, // ??Auth UUID瑜??꾨줈??ID濡??ъ슜!
                  'user_id': gIdText,
                  'points': 0, // 珥덇린 ?ъ씤??0 (?쎄? ?숈쓽 ??吏湲?
                  'nickname': gNameText,
                  'profile_image': gProfileImage,
                })
                .select()
                .single();
            gUserPoints = 0;
          }

          // 2. ?? [?깅뒫 理쒖쟻?? 媛쒖씤 ?곗씠??5醫낆쓣 ?숈떆??媛?몄삤湲?(蹂묐젹 ?ㅽ뻾!)
          if (gUserInternalId != null) {
            final results = await Future.wait([
              // [0] 醫뗭븘??
              SupabaseService.client
                  .from('likes')
                  .select('post_id')
                  .eq('user_id', gUserInternalId!),
              // [1] 遺곷쭏??
              SupabaseService.client
                  .from('bookmarks')
                  .select('post_id')
                  .eq('user_id', gUserInternalId!),
              // [2] ?붾줈??
              SupabaseService.client
                  .from('follows')
                  .select('following_internal_id')
                  .eq('follower_internal_id', gUserInternalId!),
              // [3] ?ы몴
              SupabaseService.client
                  .from('votes')
                  .select('post_id, side')
                  .eq('user_internal_id', gUserInternalId!),
              // [4] ?뚮┝
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

            if (kDebugMode) debugPrint('DEBUG [FETCH]: gUserInternalId=$gUserInternalId');
            if (kDebugMode) debugPrint('DEBUG [FETCH]: likedPostIds=${likedPostIds.length}媛? bookmarks=${bookmarkedPostIds.length}媛? follows=${followedUserIds.length}媛?);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('媛쒖씤 ?곗씠??媛?몄삤湲??ㅽ뙣: $e');
        }
      } else {
        loadedNotifications = [];
        hasNewNotifs = false;
        gUserPoints = 0;
      }

      // 2. [理쒖쟻?? 寃뚯떆臾쇱쓣 媛?몄삱 ???묒꽦?먯쓽 理쒖떊 ?꾨줈???뺣낫瑜?'議곗씤(Join)'?댁꽌 ??踰덉뿉 媛?몄샃?덈떎.
      // uploader_internal_id瑜?湲곗??쇰줈 user_profiles ?뚯씠釉붿쓽 ?뺣낫瑜??④퍡 湲곸뼱?듬땲??
      final List<dynamic> postsData = await SupabaseService.client
          .from('posts')
          .select('*, profiles:user_profiles!uploader_internal_id(id, user_id, nickname, profile_image)')
          .order('created_at', ascending: false);

      final loadedPosts = postsData.map((json) {
        final profile = json['profiles']; // 議곗씤???꾨줈???곗씠??
        final String handle = json['uploader_id']?.toString() ?? '';
        final String? internalId = json['uploader_internal_id']?.toString();

        // 理쒖떊 ?꾨줈???뺣낫媛 ?덉쑝硫?洹멸쾬???곌퀬, ?놁쑝硫?寃뚯떆臾쇱쓽 湲곕낯 ?뺣낫瑜??ъ슜?⑸땲??(諛⑹뼱 濡쒖쭅)
        final String latestId = (profile != null && profile['user_id'] != null)
            ? profile['user_id'].toString()
            : handle;
        final String nickname = (profile != null && profile['nickname'] != null)
            ? profile['nickname'].toString()
            : (json['uploader_name'] ?? json['uploader_id'] ?? '?듬챸');
        final String profileImg = toCdnUrl(
            (profile != null && profile['profile_image'] != null)
            ? profile['profile_image'].toString()
            : (json['uploader_image'] ?? 'assets/profiles/profile_11.jpg'));

        final String? finalInternalId =
            internalId ?? profile?['id']?.toString();

        final post = PostData(
          id: json['id'].toString(),
          title: json['title'] ?? '?쒕ぉ ?놁쓬',
          uploaderId: latestId, // Use the latest handle!
          uploaderInternalId: finalInternalId, // ?넄 鍮꾩뼱?덉쑝硫??꾨줈?꾩뿉??媛?몄삩 吏꾩쭨 二쇰?踰덊샇 ?댁떇!
          uploaderName: nickname,
          uploaderImage: profileImg,
          timeLocation: '諛⑷툑 ??,
          imageA: toCdnUrl(json['image_a'] ?? ''),
          imageB: toCdnUrl(json['image_b'] ?? ''),
          thumbA: json['thumb_a'] != null ? toCdnUrl(json['thumb_a']) : null,
          thumbB: json['thumb_b'] != null ? toCdnUrl(json['thumb_b']) : null,
          descriptionA: json['description_a'] ?? '?좏깮吏 A',
          descriptionB: json['description_b'] ?? '?좏깮吏 B',
          fullDescription: json['full_description'] ?? '',
          likesCount: json['likes_count'] ?? 0,
          commentsCount: json['comments_count'] ?? 0,
          voteCountA: (json['vote_count_a'] ?? 0).toString(),
          voteCountB: (json['vote_count_b'] ?? 0).toString(),
          totalVotesCount: json['total_votes'] ?? 0,
          percentA: _calcPercent(json['vote_count_a'] ?? 0, json['vote_count_b'] ?? 0, isA: true),
          percentB: _calcPercent(json['vote_count_a'] ?? 0, json['vote_count_b'] ?? 0, isA: false),
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
          if (kDebugMode) debugPrint(
            'DEBUG [MAIN]: Post 5ffdae62 comments_count: ${post.commentsCount}, isLiked: ${post.isLiked}',
          );
        }
        return post;
      }).toList();

      setState(() {
        _posts = loadedPosts.where((p) {
          // ?넄 吏꾩쭨 怨좎쑀 踰덊샇(UUID)濡???湲?몄? ?뺤씤!
          bool isMine =
              gIsLoggedIn &&
              p.uploaderInternalId != null &&
              p.uploaderInternalId == gUserInternalId;
          return isMine || !p.isHidden;
        }).toList();
        _notifications = loadedNotifications;
        _hasNewNotifications = hasNewNotifs;
        _isDataLoading = false; // ?봽 濡쒕뵫 ?꾨즺!
        _refreshRecommended();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching posts: $e');
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

  void _startLoginTimer() {
    _loginTimer?.cancel();
    _loginTimer = Timer(const Duration(seconds: 4), () async {
      // ??대㉧媛 ?앸궗?????몄뀡????踰???吏곸젒 ?뺤씤 (媛???뺤떎??諛⑸쾿)
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

    // 1. ??湲 遺꾨━ (?곗꽑 ?몄텧??
    List<PostData> myPosts = nonExpired
        .where((p) => p.uploaderInternalId == gUserInternalId)
        .toList();
    List<PostData> otherPosts = nonExpired
        .where((p) => p.uploaderInternalId != gUserInternalId)
        .toList();

    // 2. ?⑥쓽 湲? ?멸린湲/?쇰컲湲濡??욊린
    List<PostData> popular = otherPosts
        .where((p) => (p.likesCount + p.commentsCount) >= AppConstants.popularPostThreshold)
        .toList();
    List<PostData> others = otherPosts
        .where((p) => (p.likesCount + p.commentsCount) < AppConstants.popularPostThreshold)
        .toList();

    popular.shuffle();
    others.shuffle();

    List<PostData> mixedOthers = [...popular, ...others];

    // ?렞 ?뺤꽍 濡쒖쭅: [??湲] + [?욎씤 ?⑥쓽 湲] ?쒖꽌濡?諛곗튂
    setState(() {
      _recommendedPosts = [...myPosts, ...mixedOthers];
    });
  }

  List<PostData> get _filteredPosts {
    // 湲곕낯 ?꾪꽣: ?④? 泥섎━?섏? ?딆? 寃뚯떆臾?
    List<PostData> visiblePosts = _posts.where((p) => !p.isHidden).toList();

    switch (_selectedTopTabIndex) {
      case 0: // 異붿쿇
        return _recommendedPosts
            .where((p) => !p.isExpired || _forcedVisibleIds.contains(p.id))
            .toList();
      case 1: // ?붾줈??
        return visiblePosts
            .where((p) => p.isFollowing && !p.isExpired)
            .toList();
      case 2: // 利먭꺼李얘린
        return visiblePosts
            .where((p) => p.isBookmarked && !p.isExpired)
            .toList();
      case 3: // Pick: ?닿? ?좏깮??寃뚯떆臾?(?뺣젹: 吏꾪뻾以?吏㏃??쒓컙??-> 留덇컧??
        List<PostData> picked = visiblePosts
            .where((p) => p.userVotedSide != 0)
            .toList();

        // ?뺣젹 濡쒖쭅
        List<PostData> ongoing = picked.where((p) => !p.isExpired).toList();
        List<PostData> expired = picked.where((p) => p.isExpired).toList();

        // 吏꾪뻾 以묒씤 嫄??쒓컙??吏㏐쾶 ?⑥? ??(remainingSeconds 湲곗?? ?꾨땲吏留? prototype?⑹쑝濡?durationMinutes ???쒖슜 媛??
        // ?ш린?쒕뒗 durationMinutes???앹꽦 ?쒓컙 ?깆쓣 怨좊젮?섏뿬 ?뺣젹?????덉뒿?덈떎.
        // PostData??援ъ껜?곸씤 留덇컧 ?쒓컖 ?꾨뱶媛 ?덈떎硫????뺥솗?⑸땲??
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
          '$platform 濡쒓렇???꾨즺!',
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
      barrierColor: Colors.black.withValues(alpha: 0.8), // ?룻솕硫??대몼寃?
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, anim1, anim2) {
        _loginDialogContext = dialogContext; // ???
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
                      'PickGet ?쒖옉?섍린',
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
                      label: '移댁뭅??濡쒓렇??,
                      backgroundColor: const Color(0xFFFEE500),
                      textColor: const Color(
                        0xFF191919,
                      ).withValues(alpha: 0.85),
                      iconSize: 28,
                      onTap: () async {
                        // ?뮕 ?덉쟾?섍쾶 ?앹뾽 ?リ린 (以묐났 pop 諛⑹?)
                        if (_isLoginPopupOpen && _loginDialogContext != null) {
                          final targetCtx = _loginDialogContext;
                          _isLoginPopupOpen = false;
                          _loginDialogContext = null;
                          try {
                            Navigator.of(targetCtx!).pop();
                          } catch (e) {
                            if (kDebugMode) debugPrint('DEBUG [AUTH]: Tap pop error: $e');
                          }
                        }

                        try {
                          // 1. ?섑뙆踰좎씠??移댁뭅??濡쒓렇???ㅽ뻾
                          await SupabaseService.client.auth.signInWithOAuth(
                            OAuthProvider.kakao,
                            redirectTo: 'pickget://login-callback',
                            authScreenLaunchMode: LaunchMode.inAppBrowserView,
                          );
                        } catch (e) {
                          // ?뮕 李멸퀬: 濡쒓렇?몄씠 ?꾨즺?섎㈃ ?λ쭅?щ? ?듯빐 ?깆쑝濡??뚯븘?ㅺ퀬,
                          // supabase_flutter ?⑦궎吏媛 ?먮룞?쇰줈 ?몄뀡???몄떇?⑸땲??
                        } catch (e) {
                          if (kDebugMode) debugPrint('移댁뭅??濡쒓렇???먮윭: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('濡쒓렇??以??ㅻ쪟媛 諛쒖깮?덉뒿?덈떎: $e')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SocialLoginButton(
                      svgAsset: 'assets/naver_logo.svg',
                      label: '?ㅼ씠踰?濡쒓렇??,
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

                            // ?ъ씤??吏湲?濡쒖쭅 (?? ?꾩닔 ?숈쓽 1000 + ?좏깮 ?숈쓽 500)
                            int earnedPoints = AppConstants.signupBasePoints;
                            if (result['agreed_marketing'] == true) {
                              earnedPoints += AppConstants.marketingConsentPoints;
                            }

                            setState(() {
                              gUserPoints += earnedPoints;
                            });

                            // ?ъ씤???뺣낫???쒕쾭??諛섏쁺
                            await SupabaseService.client
                                .from('user_profiles')
                                .update({'points': gUserPoints})
                                .eq('id', gUserInternalId!);

                            _showLoginSuccessSnackBar('?ㅼ씠踰?);
                          } catch (e) {
                            if (kDebugMode) debugPrint(
                              'DEBUG [AUTH]: Naver profile update error: $e',
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SocialLoginButton(
                      svgAsset: 'assets/google_logo.svg',
                      label: 'Google 濡쒓렇??,
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

                            // ?ъ씤??吏湲?濡쒖쭅
                            int earnedPoints = AppConstants.signupBasePoints;
                            if (result['agreed_marketing'] == true) {
                              earnedPoints += AppConstants.marketingConsentPoints;
                            }

                            setState(() {
                              gUserPoints += earnedPoints;
                            });

                            // ?ъ씤???뺣낫???쒕쾭??諛섏쁺
                            await SupabaseService.client
                                .from('user_profiles')
                                .update({'points': gUserPoints})
                                .eq('id', gUserInternalId!);

                            _showLoginSuccessSnackBar('Google');
                          } catch (e) {
                            if (kDebugMode) debugPrint(
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
                        '?섏쨷???좉쾶??,
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
          // ?봽 ?곗씠??濡쒕뵫 以묒씪 ??濡쒕뵫 ?붾㈃ ?쒖떆 (?꾨━吏?諛⑹?!)
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

                    // 1. UI 利됱떆 諛섏쁺 (?좎껜媛?
                    setState(() {
                      post.isLiked = nowLiked;
                      if (nowLiked) {
                        post.likesCount++;
                        gUserPoints += 1; // ?ъ씤??UI 利됱떆 諛섏쁺
                      } else {
                        post.likesCount--;
                      }
                      HapticFeedback.lightImpact();
                    });

                    // 2. ?쒕쾭 ?곕룞 (二쇰?踰덊샇 湲곗?!)
                    try {
                      if (kDebugMode) debugPrint(
                        'DEBUG [LIKE]: Attempting to sync heart. user_internal_id=$gUserInternalId, post_id=${post.id}, nowLiked=$nowLiked',
                      );
                      if (nowLiked) {
                        // ?섑듃 湲곕줉
                        final res = await SupabaseService.client
                            .from('likes')
                            .insert({
                              'user_id': gUserInternalId, // ?넄 吏꾩쭨 而щ읆紐낆쑝濡?援먯껜!
                              'post_id': post.id,
                            });
                        if (kDebugMode) debugPrint('DEBUG [LIKE]: Insert success!');

                        // ?ъ씤???댁뿭 湲곕줉 (+1P)
                        await SupabaseService.client
                            .from('points_history')
                            .insert({
                              'user_id': gUserInternalId,
                              'amount': 1,
                              'description': '寃뚯떆臾?醫뗭븘??蹂대꼫??,
                            });
                      } else {
                        // ?섑듃 痍⑥냼
                        await SupabaseService.client
                            .from('likes')
                            .delete()
                            .match({
                              'user_id': gUserInternalId!,
                              'post_id': post.id,
                            });
                        if (kDebugMode) debugPrint('DEBUG [LIKE]: Delete success!');
                      }

                      // 3. 寃뚯떆臾??뚯씠釉붿쓽 ?섑듃 ???ㅼ떆媛??숆린??
                      await SupabaseService.client
                          .from('posts')
                          .update({'likes_count': post.likesCount})
                          .eq('id', post.id);

                      setState(() {}); // UI 媛깆떊留??섑뻾
                    } catch (e) {
                      if (kDebugMode) debugPrint('DEBUG [LIKE]: ERROR ?곸꽭 -> $e');
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
                      if (kDebugMode) debugPrint('?붾줈???쒕쾭 ?숆린???먮윭: $e');
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
                      if (kDebugMode) debugPrint('利먭꺼李얘린 ?숆린???먮윭: $e');
                    }
                  },
                  onNotInterested: () {
                    setState(() {
                      _posts.removeWhere((p) => p.id == post.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('愿?ъ뾾?뚯쑝濡??ㅼ젙?섏뼱 ???ъ뒪?멸? ?쒖쇅?섏뿀?듬땲??'),
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
                        content: Text('$uploaderId 梨꾨꼸??異붿쿇??以묐떒?⑸땲??'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onReport: (reason) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('?좉퀬媛 ?묒닔?섏뿀?듬땲?? $reason'),
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
                      if (kDebugMode) debugPrint('?④린湲??숆린???먮윭: $e');
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
                          // 梨꾨꼸 ?붾㈃?먯꽌 寃뚯떆臾쇱씠 ??젣?섏뿀?????덉쑝誘濡?異붿쿇 紐⑸줉 ?깆쓣 ?숆린??
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

  // ?봽 ?곗씠??濡쒕뵫 以??쒖떆 ?붾㈃ (泥??ㅽ뻾 ?꾨━吏?諛⑹?!)
  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PickGet 濡쒓퀬
            SvgPicture.asset(
              'assets/simbol.svg',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 32),
            // 濡쒕뵫 ?몃뵒耳?댄꽣
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
              '肄섑뀗痢좊? 遺덈윭?ㅻ뒗 以?..',
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
      '?붾줈?고븳 梨꾨꼸',
      '利먭꺼李얘린???쎄쿊',
      '?좏깮???쎄쿊',
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
              '濡쒓렇?몄씠 ?꾩슂??湲곕뒫?낅땲??,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$tabName ?뺤씤???꾪빐\n濡쒓렇?몄쓣 吏꾪뻾?댁＜?몄슂.',
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
                  '濡쒓렇?명븯怨??쒖옉?섍린',
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
                  _topTab('異붿쿇', 0),
                  const SizedBox(width: 25),
                  _topTab('?붾줈??, 1),
                  const SizedBox(width: 25),
                  _topTab('利먭꺼李얘린', 2),
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
          // 湲???먭퍡 蹂?붿뿉 ?곕Ⅸ ?붾뱾由?諛⑹?瑜??꾪빐 Stack ?쒖슜
          Stack(
            alignment: Alignment.center,
            children: [
              // 蹂댁씠吏 ?딅뒗 媛???먭볼??湲?먮? 諛곌꼍??源붿븘 ?덈퉬 ?뺣낫
              Text(
                label,
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              // ?ㅼ젣 蹂댁씠??湲??
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
          // ?꾨옒 ?ъ씤??諛붾룄 ?붾뱾由??녿룄濡??щ챸?꾨쭔 議곗젅
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
                  // 1. ?쒕쾭?먯꽌 理쒖떊 ?곗씠??媛?몄삤湲?
                  await fetchPosts();

                  // 2. ?먮룞?쇰줈 泥?踰덉㎏ ?섏씠吏(??湲)濡??대룞!
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
                }); // ?뚮┝ ?뺤씤 ?????쒓굅
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
                // 寃뚯떆臾쇱씠 ?놁쓣 寃쎌슦瑜??鍮꾪븳 ?덉쟾???대룞 濡쒖쭅
                PostData? firstPost = _posts.isNotEmpty ? _posts.first : null;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelScreen(
                      uploaderId: '?섏쓽?쎄쿊',
                      allPosts: _posts,
                      initialPost:
                          firstPost ??
                          PostData(
                            id: 'dummy',
                            uploaderId: '?섏쓽?쎄쿊',
                            uploaderName: gNameText,
                            uploaderImage: gProfileImage,
                            title: '泥??ъ뒪?몃? ?щ젮蹂댁꽭??',
                            timeLocation: '諛⑷툑 ??,
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
                padding: const EdgeInsets.all(10), // ?곗튂 留덉뒪???곸뿭 ?됰꼮?섍쾶 ?뺤옣
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
                '?뚮┝',
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
                          '?덈줈???뚮┝???놁뒿?덈떎.',
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
                            '諛⑷툑 ??, // In real app, format n['created_at']
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
    // 1. 濡쒕뵫 李?癒쇱? ?쒖떆
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
                        '?ㅼ떆媛??멸린 Pick (TOP 10)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '吏湲?媛???④굅???ㅼ떆媛???궧',
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
                                          initialIndex: 0, // ??궧?먯꽌 ?꾨Ⅴ硫??대떦 ?ъ뒪?멸? 泥ル쾲吏?
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
      // ?쒕쾭?먯꽌 吏곸젒 理쒖떊 ?ы몴 ?곗씠?곌? ?ы븿??寃뚯떆臾?議고쉶
      final List<dynamic> data = await SupabaseService.client
          .from('posts')
          .select('*, total_votes') // ?꾩슂???꾨뱶瑜?紐⑤몢 ?ы븿?섎릺 ?꾨씫 諛⑹?
          .order('total_votes', ascending: false)
          .limit(50);

      List<PostData> loadedPosts = data.map((json) {
        // [?섏젙] ?곗씠????낆쓣 紐낇솗???섍퀬, null 泥섎━瑜???寃ш퀬?섍쾶 ??
        String vA = (json['vote_count_a'] ?? '0').toString();
        String vB = (json['vote_count_b'] ?? '0').toString();

        return PostData(
          id: json['id'].toString(),
          title: json['title'] ?? '?쒕ぉ ?놁쓬',
          uploaderId: json['uploader_id']?.toString() ?? '?듬챸',
          uploaderName: json['uploader_name'] ?? json['uploader_id']?.toString() ?? '?듬챸',
          uploaderImage: toCdnUrl(json['uploader_image'] ?? 'assets/profiles/profile_11.jpg'),
          timeLocation: '?ㅼ떆媛?,
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
            // 醫낅즺 ?щ? 怨꾩궛 濡쒖쭅 (硫붿씤怨??숈씪)
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

      // ?ы몴 ?⑷퀎 ?쒖쑝濡??뺣? ?뺣젹
      loadedPosts.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
      return loadedPosts.take(10).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('??궧 ?곗씠??濡쒕뱶 ?ㅽ뙣: $e');
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
                    (post.isExpired ? '[醫낅즺] ' : '') + post.title,
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
                  formatCount(post.totalVotes), // 吏꾩쭨 ?ы몴??A+B) ?쒖떆!
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  '??,
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

``

## File: lib\core\app_state.dart
``dart
import 'dart:ui';
import '../services/supabase_service.dart';

String gNameText = '?뚯뒪?몄슜';
String gIdText = '?뚯뒪?몄슜';
// 濡쒓렇?????명똿?섎뒗 吏꾩쭨 怨좎쑀 ID (濡쒓렇?꾩썐 ?쒖뿉??null濡?珥덇린??
String? gUserInternalId; // ???섎뱶肄붾뵫 UUID ?쒓굅!
String gBioText = '?덈뀞?섏꽭?? ???PickGet ?좎??낅땲??';
String gProfileImage = ''; // 濡쒕뵫 以묒뿉??鍮?臾몄옄????寃? 諛곌꼍 person ?꾩씠肄??쒖떆
int gUserPoints = 0;
bool gIsLoggedIn = false;
VoidCallback? gShowLoginPopup;
VoidCallback? gRefreshFeed;
Function()? gOnLogout;
Map<String, int> gUserVotes = {};

String formatCount(dynamic countVal) {
  int count = 0;
  if (countVal is int) {
    count = countVal;
  } else if (countVal is String) {
    count = int.tryParse(countVal) ?? 0;
  }
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}留?;
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}泥?;
  }
  return count.toString();
}

String getEmpathyLevel(int percent) {
  if (percent <= 20) return '留ㅼ슦 ??쓬';
  if (percent <= 40) return '??쓬';
  if (percent <= 60) return '蹂댄넻';
  if (percent <= 80) return '?믪쓬';
  return '留ㅼ슦 ?믪쓬';
}

``

## File: lib\core\supabase_config.dart
``dart
class SupabaseConfig {
  static const String url = 'https://otstiqndmoyzkurrjobb.supabase.co';
  static const String anonKey = 'sb_publishable_Gb0aPbRFQ6uVSM_Lt8uvDw_CF9xKrhm';
  static const String password = 'oS8b0VyeSYc5RJll'; 
}

class CloudflareConfig {
  // ?뵦 accessKey? secretKey瑜??꾩쟾????젣?덈떎! 
  // ?댁젣 ?뚯빱(Worker)媛 蹂댁븞???꾨떞?⑸땲??
  static const String workerUrl = 'https://pickget-uploader.ydkaoa79.workers.dev/';
  static const String cdnUrl = 'https://cdn.pickget.net/';
}

``

## File: lib\models\comment_data.dart
``dart
class CommentData {
  String? id; // Supabase UUID
  String? parentId; // Parent comment UUID for replies
  final String user;
  final String userId; 
  final String? userInternalId; // ?넄 ?볤? ?묒꽦??二쇰?踰덊샇 異붽?!
  String text;
  final int side;
  final String image;
  bool isPinned;
  bool isHidden;
  List<CommentData> replies;

  CommentData({
    this.id,
    this.parentId,
    required this.user, 
    required this.userId,
    this.userInternalId,
    required this.text, 
    required this.side, 
    required this.image,
    this.isPinned = false,
    this.isHidden = false,
    List<CommentData>? replies,
  }) : replies = replies ?? [];
}

``

## File: lib\models\post_data.dart
``dart
import 'comment_data.dart';

class PostData {
  final String id;
  final String title;
  String uploaderId;
  final String? uploaderInternalId; // ?넄 二쇰?踰덊샇 ?꾨뱶 異붽?!
  String uploaderName;
  String uploaderImage;
  final String timeLocation;
  final String imageA;
  final String imageB;
  final String? thumbA;
  final String? thumbB;
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
  bool isHidden;
  final String fullDescription;
  bool isExpired;
  int userVotedSide; // 0: none, 1: A, 2: B
  List<CommentData> comments;
  final String? shortDescA;
  final String? shortDescB;
  final List<String>? tags;
  final int? durationMinutes;
  final int? targetPickCount;
  final DateTime createdAt;
  int totalVotesCount; // ?뿳截??쒕쾭?먯꽌 媛?몄삩 吏꾩쭨 珥??ы몴??異붽?
  
  DateTime get endTime => createdAt.add(Duration(minutes: durationMinutes ?? 1440));
  
  // ?뿳截?吏꾩쭨 ?ы몴???⑷퀎 怨꾩궛 (DB 而щ읆???덉쑝硫??곗꽑 ?ъ슜, ?놁쑝硫?吏곸젒 怨꾩궛)
  int get totalVotes {
    if (totalVotesCount > 0) return totalVotesCount;
    
    int parseV(String s) {
      s = s.toLowerCase().replaceAll(',', '').trim();
      if (s.isEmpty) return 0;
      if (s.endsWith('k')) {
        return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
      }
      return int.tryParse(s) ?? 0;
    }
    return parseV(voteCountA) + parseV(voteCountB);
  }

  PostData({
    required this.id,
    required this.title,
    required this.uploaderId,
    this.uploaderInternalId,
    required this.uploaderName,
    required this.uploaderImage,
    required this.timeLocation,
    required this.imageA,
    required this.imageB,
    this.thumbA,
    this.thumbB,
    required this.descriptionA,
    required this.descriptionB,
    this.shortDescA,
    this.shortDescB,
    this.tags,
    this.durationMinutes,
    this.targetPickCount,
    DateTime? createdAt,
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
    this.fullDescription = "???ъ뒪?몄뿉 ????곸꽭 ?ㅻ챸???ш린???쒖떆?⑸땲??",
    this.isExpired = false,
    this.userVotedSide = 0,
    this.totalVotesCount = 0, // 湲곕낯媛?異붽?
    List<CommentData>? comments,
  }) : createdAt = createdAt ?? DateTime.now(),
       comments = comments ?? [];
}

``

## File: lib\screens\activity_analysis_screen.dart
``dart
import 'package:flutter/material.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'point_screen.dart';
import '../services/supabase_service.dart';

class ActivityAnalysisScreen extends StatefulWidget {
  final List<PostData> userPosts;
  const ActivityAnalysisScreen({super.key, required this.userPosts});

  @override
  State<ActivityAnalysisScreen> createState() => _ActivityAnalysisScreenState();
}

class _ActivityAnalysisScreenState extends State<ActivityAnalysisScreen> {
  int totalPicks = 0;
  int totalLikes = 0;
  int myVotedCount = 0; // [?좉퇋] ?닿? 李몄뿬???ы몴 ??
  int myMatchCount = 0; // [?좉퇋] 怨듦컧 ?깃났 ?잛닔
  double empathyRate = 0.0;
  Map<String, int> categoryCounts = {};
  List<int> weeklyPicks = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    try {
      // 1. ?닿? 諛쏆? ?듦퀎 怨꾩궛 (?쒕쾭?먯꽌 ?ㅼ떆媛?吏곸젒 議고쉶濡??뺥솗???뺣낫)
      final List<dynamic> myPosts = await SupabaseService.client
          .from('posts')
          .select('vote_count_a, vote_count_b, likes_count')
          .eq('uploader_internal_id', gUserInternalId!);

      int picksReceived = 0;
      int likesReceived = 0;
      
      for (var p in myPosts) {
        int countA = _parseVotes(p['vote_count_a']?.toString() ?? '0');
        int countB = _parseVotes(p['vote_count_b']?.toString() ?? '0');
        picksReceived += (countA + countB);
        likesReceived += (p['likes_count'] as int? ?? 0);
      }

      // 2. ?닿? 李몄뿬???ы몴 ?댁뿭 媛?몄삤湲?
      final List<dynamic> myVotes = await SupabaseService.client
          .from('votes')
          .select('post_id, side')
          .eq('user_internal_id', gUserInternalId!);

      int votedCount = 0; // [?섏젙] 0遺???쒖옉?섏뿬 醫낅즺???ы몴留?移댁슫??
      int matchCount = 0;

      if (myVotes.isNotEmpty) {
        // 3. ?ы몴??寃뚯떆臾쇰뱾???ㅼ젣 寃곌낵? 鍮꾧탳?섍린
        for (var vote in myVotes) {
          final postId = vote['post_id'].toString();
          final mySide = vote['side'] as int;

          final postData = await SupabaseService.client
              .from('posts')
              .select('vote_count_a, vote_count_b, created_at, tags')
              .eq('id', postId)
              .maybeSingle();

          if (postData != null) {
            // [?섏젙] DB???녿뒗 is_expired ????쒓컙怨??쒓렇濡?醫낅즺 ?щ? 吏곸젒 怨꾩궛
            bool isExpiredPost = false;
            final String? createdAtStr = postData['created_at'];
            final List<dynamic> tags = postData['tags'] as List? ?? [];
            
            if (createdAtStr != null) {
              final createdAt = DateTime.tryParse(createdAtStr);
              if (createdAt != null) {
                for (var tag in tags) {
                  String tagStr = tag.toString();
                  if (tagStr.startsWith('duration:')) {
                    final mins = int.tryParse(tagStr.split(':')[1]);
                    if (mins != null && DateTime.now().isAfter(createdAt.add(Duration(minutes: mins)))) {
                      isExpiredPost = true;
                    }
                  }
                }
              }
            }

            if (!isExpiredPost) continue; // 醫낅즺?섏? ?딆? ?ы몴??怨꾩궛?먯꽌 ?쒖쇅

            votedCount++; // 醫낅즺???ы몴留?移댁슫??
            
            int countA = _parseVotes(postData['vote_count_a']?.toString() ?? '0');
            int countB = _parseVotes(postData['vote_count_b']?.toString() ?? '0');
            
            int winnerSide = (countA > countB) ? 1 : (countB > countA ? 2 : 0);
            
            // [議곌굔 諛섏쁺] ???좏깮???ㅼ닔寃??뱀옄)怨??쇱튂?섍굅?? 鍮꾧꼈????0) 怨듦컧?쇰줈 ?몄젙
            if (mySide == winnerSide || winnerSide == 0) {
              matchCount++;
            }
          }
        }
      }

      setState(() {
        totalPicks = picksReceived;
        totalLikes = likesReceived;
        myVotedCount = votedCount;
        myMatchCount = matchCount;
        // 怨듦컧???섏떇: (留욎텣 ?잛닔 / 珥?李몄뿬 ?잛닔) * 100
        empathyRate = votedCount > 0 ? (matchCount / votedCount) * 100 : 0.0;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('?쒕룞 遺꾩꽍 ?곗씠??怨꾩궛 ?ㅽ뙣: $e');
    }
  }

  int _parseVotes(String s) {
    s = s.toLowerCase().replaceAll(',', '').trim();
    if (s.isEmpty) return 0;
    if (s.endsWith('k')) {
      return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
    }
    return int.tryParse(s) ?? 0;
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

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
        title: const Text('?쒕룞遺꾩꽍', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            _buildTrendSection('二쇨컙 諛쏆? Pick ?몃젋??, weeklyPicks),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: gProfileImage.startsWith('http') 
                ? NetworkImage(gProfileImage) 
                : AssetImage(gProfileImage) as ImageProvider, 
              fit: BoxFit.cover
            ),
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
            Text(gNameText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('@${gIdText.toLowerCase().replaceAll(' ', '_')}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        )
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // 湲곌린 ?덈퉬???곕씪 移대뱶 鍮꾩쑉???좊룞?곸쑝濡?議곗젙 (?묒? ?붾㈃?먯꽌???믪씠瑜????뺣낫)
    final double dynamicAspectRatio = screenWidth < 360 ? 1.3 : (screenWidth < 400 ? 1.45 : 1.6);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: dynamicAspectRatio,
      children: [
        _statCard('肄섑뀗痢???, _formatNumber(widget.userPosts.length), Icons.article_outlined),
        _statCard('諛쏆? Pick', _formatNumber(totalPicks), Icons.front_hand_outlined),
        _statCard('諛쏆? ?섑듃', _formatNumber(totalLikes), Icons.favorite_border),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PointScreen(currentPoints: gUserPoints))),
          child: _statCard('?쒕룞 ?ъ씤??, gUserPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"), Icons.stars_outlined, isLink: true),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(color: isLink ? Colors.cyanAccent : Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
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
              Text('?以묎낵??怨듦컧??, style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(width: 6),
              Icon(Icons.info_outline, color: Colors.white30, size: 16),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.28, 
                      height: MediaQuery.of(context).size.width * 0.28,
                      child: CircularProgressIndicator(
                        value: empathyRate / 100,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        color: Colors.cyanAccent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${empathyRate.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        const Text('怨듦컧??, style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSympathyStatItem('李몄뿬 ?ы몴', _formatNumber(myVotedCount), Colors.white54),
                    const SizedBox(height: 16),
                    _buildSympathyStatItem('怨듦컧 ?깃났', _formatNumber(myMatchCount), Colors.cyanAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          const Text('怨듦컧???④퀎 ?덈궡', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildEmpathyManual(),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Text(
              '?뱀떊? ?ㅻⅨ ?좎??ㅺ낵 ${empathyRate.toInt()}% 怨듦컧?섍퀬 ?덉뒿?덈떎!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w500),
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
    var sortedEntries = categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var topEntries = sortedEntries.take(3).toList();
    
    if (topEntries.isEmpty) {
      return const SizedBox();
    }

    int maxCount = topEntries[0].value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('愿??移댄뀒怨좊━ 遺꾩꽍', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...topEntries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _categoryBar('#${e.key}', e.value / maxCount, 
              e == topEntries[0] ? Colors.cyanAccent : (e == topEntries[1] ? Colors.white70 : Colors.white30)),
        )),
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
    if (maxVal == 0) maxVal = 1;

    List<String> days = ['??, '??, '??, '紐?, '湲?, '??, '??];
    int todayIdx = DateTime.now().weekday - 1; // 0 (Mon) to 6 (Sun)
    
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
              Text('理쒓렐 7??, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              // Map index to day label (approximate based on today)
              String dayLabel = days[(todayIdx - (6 - i) + 7) % 7];
              return _trendBar(dayLabel, counts[i] / maxVal, counts[i], i == 6);
            }),
          )
        ],
      ),
    );
  }

  Widget _trendBar(String day, double heightFactor, int pickCount, bool isToday) {
    return Column(
      children: [
        Text(
          pickCount > 999 ? '${(pickCount / 1000).toStringAsFixed(1)}k' : '$pickCount',
          style: TextStyle(color: isToday ? Colors.cyanAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          width: 14,
          height: 100 * heightFactor.clamp(0.05, 1.0),
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
        _manualRow('81~100%', '怨듦컧??),
        _manualRow('61~80%', '怨듦컧 留덉뒪??),
        _manualRow('41~60%', '?뚰넻 ?꾨Ц媛'),
        _manualRow('21~40%', '痍⑦뼢 ?먰뿕媛'),
        _manualRow('0~20%', '媛쒖꽦??),
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

``

## File: lib\screens\channel_feed_screen.dart
``dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../widgets/post_view.dart';
import '../core/app_state.dart';
import 'channel_screen.dart';
import '../services/supabase_service.dart';

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
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.channelPosts.length,
            itemBuilder: (context, index) {
              final post = widget.channelPosts[index];
              return PostView(
                key: ValueKey('channel_feed_${post.id}'),
                post: post,
                onLike: () async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  final bool nowLiked = !post.isLiked;
                  setState(() {
                    post.isLiked = nowLiked;
                    if (nowLiked) {
                      post.likesCount++;
                    } else {
                      post.likesCount--;
                    }
                  });
                  HapticFeedback.lightImpact();

                  try {
                    if (nowLiked) {
                      await SupabaseService.client.from('likes').insert({
                        'user_id': gUserInternalId,
                        'post_id': post.id,
                      });
                      // ?ъ씤???곷┰ (+1P)
                      await SupabaseService.client.from('points_history').insert({
                        'user_id': gUserInternalId,
                        'amount': 1,
                        'description': '寃뚯떆臾?醫뗭븘??蹂대꼫??,
                      });
                    } else {
                      await SupabaseService.client.from('likes').delete().match({
                        'user_id': gUserInternalId!,
                        'post_id': post.id,
                      });
                    }
                    // 寃뚯떆臾??뚯씠釉붿쓽 醫뗭븘?????낅뜲?댄듃
                    await SupabaseService.client.from('posts').update({
                      'likes_count': post.likesCount
                    }).eq('id', post.id);
                  } catch (e) {
                    if (kDebugMode) debugPrint('醫뗭븘???숆린???먮윭: $e');
                  }
                },
                onFollow: () async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  final bool nowFollowing = !post.isFollowing;
                  setState(() {
                    for (var p in widget.allPosts) {
                      if (p.uploaderId == post.uploaderId) {
                        p.isFollowing = nowFollowing;
                      }
                    }
                  });
                  HapticFeedback.mediumImpact();

                  try {
                    if (nowFollowing) {
                      await SupabaseService.client.from('follows').insert({
                        'follower_internal_id': gUserInternalId!,
                        'following_internal_id': post.uploaderInternalId!,
                      });
                    } else {
                      await SupabaseService.client.from('follows').delete().match({
                        'follower_internal_id': gUserInternalId!,
                        'following_internal_id': post.uploaderInternalId!,
                      });
                    }
                  } catch (e) {
                    if (kDebugMode) debugPrint('?붾줈???숆린???먮윭: $e');
                  }
                },
                onBookmark: () async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  final bool nowBookmarked = !post.isBookmarked;
                  setState(() {
                    post.isBookmarked = nowBookmarked;
                  });
                  HapticFeedback.selectionClick();

                  try {
                    if (nowBookmarked) {
                      await SupabaseService.client.from('bookmarks').insert({
                        'user_id': gUserInternalId!,
                        'post_id': post.id,
                      });
                    } else {
                      await SupabaseService.client.from('bookmarks').delete().match({
                        'user_id': gUserInternalId!,
                        'post_id': post.id,
                      });
                    }
                  } catch (e) {
                    if (kDebugMode) debugPrint('利먭꺼李얘린 ?숆린???먮윭: $e');
                  }
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
                    SnackBar(content: Text('?좉퀬媛 ?묒닔?섏뿀?듬땲?? $reason'), duration: const Duration(seconds: 1))
                  );
                },
                onVote: (side) {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  setState(() {
                    post.userVotedSide = side;
                  });
                },
                onDelete: (postId) {
                  setState(() {
                    widget.channelPosts.removeWhere((p) => p.id == postId);
                    widget.allPosts.removeWhere((p) => p.id == postId);
                    if (widget.channelPosts.isEmpty) {
                      Navigator.pop(context);
                    }
                  });
                },
                onToggleHide: (postId) async {
                  setState(() {
                    post.isHidden = !post.isHidden;
                  });
                  try {
                    await SupabaseService.client
                        .from('posts')
                        .update({'tags': post.isHidden ? [...(post.tags ?? []), '#hidden#'] : (post.tags ?? []).where((t) => t != '#hidden#').toList()})
                        .eq('id', postId);
                  } catch (e) {
                    if (kDebugMode) debugPrint('?④린湲??숆린???먮윭: $e');
                  }
                },
                onProfileTap: () {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelScreen(
                        uploaderId: post.uploaderId,
                        allPosts: widget.allPosts,
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
          // ?곷떒 ?ㅻ줈媛湲?踰꾪듉 (?뚮줈??
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // ?곷떒 ??踰꾪듉 (?뚮줈??- ??踰덉뿉 硫붿씤?쇰줈)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              ),
              onPressed: () {
                // 泥??붾㈃(硫붿씤)???섏삱 ?뚭퉴吏 紐⑤뱺 ?붾㈃???レ쓬
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }
}

``

## File: lib\screens\channel_screen.dart
``dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'upload_screen.dart';
import 'activity_analysis_screen.dart';
import 'edit_profile_screen.dart';
import 'channel_feed_screen.dart';
import '../services/supabase_service.dart';

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
  String _dName = ''; String _dImg = 'assets/profiles/profile_11.jpg'; String _dBio = '';
  bool _isFollowing = false;
  late TabController _tabController;
  late List<PostData> _channelPosts;
  bool _isBioExpanded = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};
  double _empathyRate = 0.0; // [?좉퇋] 吏꾩쭨 怨듦컧????μ쓣 ?꾪븳 蹂??
  int _followerCount = 0; // [?좉퇋] ?ㅼ젣 ?붾줈????

  bool get isMe {
    // ?넄 ?ㅼ쭅 二쇰?踰덊샇(UUID) ?섎굹濡쒕쭔 ?먮떒 (吏꾩쭨 ?뺤꽍!)
    String nId(String? s) => (s ?? '').trim().toLowerCase();
    
    if (widget.initialPost.uploaderInternalId != null && gUserInternalId != null) {
      if (nId(widget.initialPost.uploaderInternalId) == nId(gUserInternalId)) {
        return true;
      }
    }
    
    // ?덉쇅/?덉쟾?μ튂 (?꾩씠??湲곕컲)
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    return normalized(widget.uploaderId) == normalized('?섏쓽 ?쎄쿊') || 
           widget.uploaderId == 'me' || 
           normalized(widget.uploaderId) == normalized(gIdText);
  }

  @override
  void initState() {
    super.initState();
    // ?룢截??뺤꽍 ?곗씠??珥덇린??
    if (isMe) {
      _dName = gNameText;
      _dImg = gProfileImage;
      _dBio = gBioText;
    } else {
      _dName = widget.initialPost.uploaderName; // 吏꾩쭨 ?대쫫???대쫫 ?먮━??
      _dImg = widget.initialPost.uploaderImage;
      _dBio = '?덈뀞?섏꽭?? ${widget.initialPost.uploaderName}???쎄쿊 怨듦컙?낅땲?? ??;
      _isFollowing = widget.initialPost.isFollowing;
    }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPosts();
    _calculateRealEmpathy(); // [?좉퇋] 吏꾩쭨 怨듦컧??怨꾩궛 ?쒖옉
    _fetchFollowerCount(); // [?좉퇋] ?ㅼ젣 ?붾줈????議고쉶

    // ?룢截??뺤꽍 媛뺤젣 ?덈줈怨좎묠: ?뱀떆 紐⑤? ?몄떇 吏?곗쓣 諛⑹??섍린 ?꾪빐 0.1珥????ㅼ떆 ?뺤씤!
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  // ?룢截?[?쒕룞遺꾩꽍 ?뺤꽍 濡쒖쭅 ?댁떇] 吏꾩쭨 怨듦컧??怨꾩궛 ?⑥닔
  Future<void> _calculateRealEmpathy() async {
    try {
      final String? targetInternalId = isMe ? gUserInternalId : widget.initialPost.uploaderInternalId;
      if (targetInternalId == null) return;

      // 1. ?ы몴 李몄뿬 ?댁뿭 媛?몄삤湲?
      final List<dynamic> myVotes = await SupabaseService.client
          .from('votes')
          .select('post_id, side')
          .eq('user_internal_id', targetInternalId);

      int votedCount = 0;
      int matchCount = 0;

      if (myVotes.isNotEmpty) {
        for (var vote in myVotes) {
          final postId = vote['post_id'].toString();
          final mySide = vote['side'] as int;

          final postData = await SupabaseService.client
              .from('posts')
              .select('vote_count_a, vote_count_b, created_at, tags')
              .eq('id', postId)
              .maybeSingle();

          if (postData != null) {
            // 醫낅즺 ?щ? 吏곸젒 怨꾩궛 (?쒕룞遺꾩꽍 濡쒖쭅怨??숈씪)
            bool isExpiredPost = false;
            final String? createdAtStr = postData['created_at'];
            final List<dynamic> tags = postData['tags'] as List? ?? [];
            
            if (createdAtStr != null) {
              final createdAt = DateTime.tryParse(createdAtStr);
              if (createdAt != null) {
                for (var tag in tags) {
                  String t = tag.toString();
                  if (t.startsWith('duration:')) {
                    final mins = int.tryParse(t.split(':')[1]);
                    if (mins != null && DateTime.now().isAfter(createdAt.add(Duration(minutes: mins)))) {
                      isExpiredPost = true;
                    }
                  }
                }
              }
            }

            if (!isExpiredPost) continue; 

            votedCount++; 
            int countA = _parseTotalVotesRaw(postData['vote_count_a']?.toString() ?? '0');
            int countB = _parseTotalVotesRaw(postData['vote_count_b']?.toString() ?? '0');
            int winnerSide = (countA > countB) ? 1 : (countB > countA ? 2 : 0);
            
            if (mySide == winnerSide || winnerSide == 0) {
              matchCount++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _empathyRate = votedCount > 0 ? (matchCount / votedCount) * 100 : 0.0;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('梨꾨꼸 怨듦컧??怨꾩궛 ?ㅽ뙣: $e');
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

  int _parseTotalVotesRaw(String s) {
    s = s.toLowerCase().replaceAll(',', '').trim();
    if (s.isEmpty) return 0;
    if (s.endsWith('k')) return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
    return int.tryParse(s) ?? 0;
  }

  // ?룢截?[?좉퇋] ?ㅼ젣 ?붾줈????議고쉶 ?⑥닔
  Future<void> _fetchFollowerCount() async {
    try {
      final String? targetInternalId = isMe ? gUserInternalId : widget.initialPost.uploaderInternalId;
      if (targetInternalId == null) return;

      // follows ?뚯씠釉붿뿉???섎? ?붾줈?고븳 ?곗씠?곕? 媛?몄? 媛쒖닔瑜??됰땲?? (?뺥솗??而щ읆紐??곸슜)
      final List<dynamic> response = await SupabaseService.client
          .from('follows')
          .select('id')
          .eq('following_internal_id', targetInternalId);
      
      if (mounted) {
        setState(() {
          _followerCount = response.length;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('?붾줈????議고쉶 ?ㅽ뙣: $e');
    }
  }

  void _loadPosts() {
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    String currentChannelId = normalized(widget.uploaderId);
    String myId = normalized('?섏쓽 ?쎄쿊');

    setState(() {
      _channelPosts = widget.allPosts.where((p) {
        // ?넄 二쇰?踰덊샇(UUID) 湲곕컲 ?뺤꽍 ?꾪꽣留?
        if (isMe) {
          // ??梨꾨꼸???? ??二쇰?踰덊샇? ?쇱튂?섎뒗 寃껊쭔!
          return p.uploaderInternalId == gUserInternalId;
        } else {
          // ????섏씠吏??寃쎌슦: 洹??щ엺??二쇰?踰덊샇? ?쇱튂?섎뒗 寃껊쭔!
          bool isSameOwner = (p.uploaderInternalId != null && p.uploaderInternalId == widget.initialPost.uploaderInternalId);
          return isSameOwner && !p.isHidden;
        }
      }).toList();
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
              _menuItem(Icons.logout, '濡쒓렇?꾩썐', () {
                Navigator.pop(context);
                _showLogoutDialog();
              }, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showPostManagementMenu() {
    if (!isMe) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 15),
                Text(
                  _selectedPostIds.isEmpty ? '寃뚯떆臾?愿由? : '${_selectedPostIds.length}媛??좏깮??,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12),
                _menuItem(Icons.check_box_outlined, _isSelectionMode ? '?좏깮 紐⑤뱶 醫낅즺' : '?좏깮 紐⑤뱶 ?쒖옉', () {
                  Navigator.pop(context);
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) _selectedPostIds.clear();
                  });
                }),
                _menuItem(Icons.select_all, '?꾩껜 ?좏깮', () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedPostIds.addAll(_channelPosts.map((p) => p.id));
                  });
                  setModalState(() {});
                }),
                _menuItem(Icons.deselect, '?꾩껜 ?댁젣', () {
                  setState(() {
                    _selectedPostIds.clear();
                  });
                  setModalState(() {});
                }),
                _menuItem(Icons.visibility_off, '?④린湲?/ 蹂댁씠湲?, () {
                  if (_selectedPostIds.isEmpty) return;
                  Navigator.pop(context);
                  _toggleHide();
                }),
                _menuItem(Icons.delete_outline, '?좏깮 ??젣', () {
                  if (_selectedPostIds.isEmpty) return;
                  Navigator.pop(context);
                  _deletePosts();
                }, color: Colors.redAccent),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deletePosts() {
    if (_selectedPostIds.isEmpty) return;
    
    // Create a copy to avoid modification issues during async loop
    final idsToDelete = _selectedPostIds.toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('${idsToDelete.length}媛쒖쓽 寃뚯떆臾쇱쓣 ??젣?섏떆寃좎뒿?덇퉴?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('??젣??寃뚯떆臾쇱? 蹂듦뎄?????놁뒿?덈떎.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('痍⑥냼', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              List<String> successIds = [];
              for (var id in idsToDelete) {
                try {
                  // ?뵦 [?듭떖] ?몃옒 ???쒖빟 ?뚮Ц???곌? ?곗씠??癒쇱? ??젣 ??寃뚯떆臾???젣!
                  await Future.wait([
                    SupabaseService.client.from('votes').delete().eq('post_id', id),
                    SupabaseService.client.from('comments').delete().eq('post_id', id),
                    SupabaseService.client.from('likes').delete().eq('post_id', id),
                    SupabaseService.client.from('bookmarks').delete().eq('post_id', id),
                  ]);
                  // ?곌? ?곗씠????젣 ?꾨즺 ??寃뚯떆臾???젣
                  await SupabaseService.client.from('posts').delete().eq('id', id);
                  successIds.add(id);
                } catch (e) {
                  if (kDebugMode) debugPrint('Delete error for $id: $e');
                }
              }
              
              setState(() {
                widget.allPosts.removeWhere((p) => successIds.contains(p.id));
                _loadPosts();
                _selectedPostIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${successIds.length}媛쒖쓽 寃뚯떆臾쇱씠 ??젣?섏뿀?듬땲??')));
            },
            child: const Text('??젣', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _toggleHide() async {
    if (_selectedPostIds.isEmpty) return;
    final idsToToggle = _selectedPostIds.toList();
    int count = 0;
    
    for (var id in idsToToggle) {
      try {
        final post = widget.allPosts.firstWhere((p) => p.id == id);
        final dynamic targetId = int.tryParse(id) ?? id;
        
        // Use isHidden property to get the true current state
        bool currentlyHidden = post.isHidden;
        List<String> currentTags = List<String>.from(post.tags ?? []);
        
        if (currentlyHidden) {
          currentTags.remove('#hidden#');
        } else {
          if (!currentTags.contains('#hidden#')) {
            currentTags.add('#hidden#');
          }
        }
        
        await SupabaseService.client.from('posts').update({'tags': currentTags}).eq('id', targetId);
        
        setState(() {
          post.isHidden = !currentlyHidden;
          // Update the internal tags list content directly
          if (post.tags != null) {
            if (currentlyHidden) {
              post.tags!.remove('#hidden#');
            } else {
              if (!post.tags!.contains('#hidden#')) post.tags!.add('#hidden#');
            }
          }
        });
        count++;
      } catch (e) {
        if (kDebugMode) debugPrint('Update error for $id: $e');
      }
    }
    
    setState(() {
      _loadPosts();
      _selectedPostIds.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count媛쒖쓽 寃뚯떆臾??곹깭媛 蹂寃쎈릺?덉뒿?덈떎.')));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('濡쒓렇?꾩썐 ?섏떆寃좎뒿?덇퉴?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('痍⑥냼', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                gIsLoggedIn = false;
                gUserPoints = 0; // 吏媛?利됱떆 ?뺤닔!
              });
              gOnLogout?.call(); // 硫붿씤 ?붾㈃?먮룄 ?뚮┝!
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('濡쒓렇?꾩썐', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
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
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const UploadScreen())
            ).then((newPost) {
              if (newPost != null && newPost is PostData) {
                setState(() {
                  widget.allPosts.insert(0, newPost);
                  _loadPosts();
                });
              }
            });
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
          _buildMenuTile(Icons.share, '怨듭쑀?섍린', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('梨꾨꼸 留곹겕媛 蹂듭궗?섏뿀?듬땲??'), duration: Duration(seconds: 1))
            );
          }),
          _buildMenuTile(Icons.block, '??梨꾨꼸 異붿쿇 ????, () => Navigator.pop(context)),
          _buildMenuTile(Icons.visibility_off, '愿???놁쓬', () => Navigator.pop(context)),
          _buildMenuTile(Icons.report_problem_outlined, '?좉퀬?섍린', () => Navigator.pop(context), isDestructive: true),
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
    return post.totalVotes;
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
              if (isMe)
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _showSettingsMenu),
              if (!isMe)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white), 
                  padding: const EdgeInsets.all(12), // ?곗튂 ?곸뿭 ?뺣?瑜??꾪빐 ?⑤뵫 異붽?
                  onPressed: _showMoreMenu
                ),
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
                      Builder(builder: (_) {
                        final img = (isMe ? gProfileImage : _dImg).trim();
                        return img.isEmpty
                          ? const CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.person, color: Colors.white54, size: 40),
                            )
                          : CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.black,
                              backgroundImage: img.startsWith('http')
                                ? NetworkImage(img)
                                : AssetImage(img) as ImageProvider,
                            );
                      }),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isMe ? gNameText : _dName, // ?룢截?二쇱씤?섏씠硫?理쒖떊 ?대쫫?? ?꾨땲硫??뚰솚???대쫫??
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                if (isMe) ...[
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
                                            _dBio = gBioText;
                                            _dImg = gProfileImage;
                                          });
                                            // ?렞 ??寃뚯떆臾??뺣낫?ㅻ룄 ?ㅼ떆媛꾩쑝濡??숆린??(硫붿씤 ???섍???諛붾줈 蹂댁씠寃?)
                                            for (var p in widget.allPosts) {
                                              if (p.uploaderInternalId == gUserInternalId) {
                                                p.uploaderId = res['id'];
                                                p.uploaderName = res['name'];
                                                p.uploaderImage = res['image'];
                                              }
                                            }
                                            // Global Feed Refresh!
                                            gRefreshFeed?.call();
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
                              "@${isMe ? gIdText : widget.uploaderId}", // ?넄 吏꾩쭨 ?꾩씠??(@...)
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "?붾줈??${formatCount(_followerCount)} 쨌 肄섑뀗痢?${formatCount(_channelPosts.length)}",
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
                            isMe ? gBioText : _dBio,
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
                          onPressed: () async {
                            if (isMe) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityAnalysisScreen(userPosts: _channelPosts)));
                            } else {
                              if (!gIsLoggedIn) {
                                gShowLoginPopup?.call();
                                return;
                              }
                              final bool nowFollowing = !_isFollowing;
                              setState(() {
                                _isFollowing = nowFollowing;
                                // ?숈씪 ?낅줈?붿쓽 紐⑤뱺 ?ъ뒪???붾줈???곹깭 ?숆린??
                                for (var p in widget.allPosts) {
                                  if (p.uploaderId == widget.uploaderId) {
                                    p.isFollowing = nowFollowing;
                                  }
                                }
                              });
                              HapticFeedback.mediumImpact();

                              try {
                                if (nowFollowing) {
                                  await SupabaseService.client
                                    .from('follows')
                                    .insert({
                                      'follower_internal_id': gUserInternalId!, 
                                      'following_internal_id': widget.initialPost.uploaderInternalId!
                                    });
                                } else {
                                  await SupabaseService.client
                                    .from('follows')
                                    .delete()
                                    .match({
                                      'follower_internal_id': gUserInternalId!, 
                                      'following_internal_id': widget.initialPost.uploaderInternalId!
                                    });
                                }
                              } catch (e) {
                                if (kDebugMode) debugPrint('?붾줈???쒕쾭 ?숆린???먮윭: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (!isMe && _isFollowing) 
                              ? const Color(0xFF272727) 
                              : Colors.white,
                            foregroundColor: (!isMe && _isFollowing) 
                              ? Colors.white70 
                              : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe && _isFollowing) ...[
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                isMe 
                                  ? '?쒕룞遺꾩꽍' 
                                  : (_isFollowing ? '?붾줈?? : '?붾줈??),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '怨듦컧??${_empathyRate.toInt()}%',
                                style: const TextStyle(
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
                              _profileTab('理쒖떊??, 0),
                              const SizedBox(width: 30),
                              _profileTab('?쎌닚', 1),
                              const SizedBox(width: 30),
                              _profileTab('?쒓컙??, 2),
                            ],
                          ),
                          if (isMe)
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                                onPressed: _showPostManagementMenu,
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
      floatingActionButton: isMe ? _uploadButton() : null,
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

        // Calculate expired status
        bool isExpired = post.isExpired;
        if (!isExpired && post.tags != null) {
          final now = DateTime.now();
          for (var tag in post.tags!) {
            if (tag.startsWith('duration:')) {
              final mins = int.tryParse(tag.split(':')[1]);
              if (mins != null && now.isAfter(post.createdAt.add(Duration(minutes: mins)))) {
                isExpired = true;
              }
              break;
            }
          }
        }

        return GestureDetector(
          onLongPress: () {
            if (isMe) {
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
                if (_selectedPostIds.contains(post.id)) {
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
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _loadPosts();
                  });
                }
              });
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              (post.thumbA != null && post.thumbA!.isNotEmpty)
                ? Image.network(post.thumbA!.trim(), fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null)
                : (_isVideo(post.imageA)
                   ? Container(color: Colors.black26, child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54)))
                   : (post.imageA.trim().contains('http')
                        ? Image.network(post.imageA.trim(), fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null)
                        : Image.asset(post.imageA.trim(), fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null))),
              
              // Status Badge (Top Left)
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.black.withValues(alpha: 0.6) : Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isExpired ? '?좏깮醫낅즺' : '?좏깮以?,
                    style: TextStyle(
                      color: isExpired ? Colors.white70 : Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

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
                ),
              ),
              Positioned(
                bottom: 6, left: 6, right: 6,
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
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  right: 8, // Moved to right to avoid overlap with status badge
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
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, -2 * 3.14159 * percentA, false, paintA);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, 2 * 3.14159 * (1 - percentA), false, paintB);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

``

## File: lib\screens\edit_profile_screen.dart
``dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../services/cloudflare_service.dart';
import '../core/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentId;
  final String currentBio;
  final String currentImage;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentId,
    required this.currentBio,
    required this.currentImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _id;
  late TextEditingController _bio;
  late String _img;
  final CloudflareService _cloudflareService = CloudflareService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.currentName);
    _id = TextEditingController(text: widget.currentId);
    _bio = TextEditingController(text: widget.currentBio);
    _img = widget.currentImage;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      // 1. Crop Image first
      final String? croppedPath = await _cropImage(pickedFile.path);
      if (croppedPath == null) return; // User cancelled crop

      setState(() => _isUploading = true);
      try {
        final String fileName = 'profile_${gUserInternalId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String? url = await _cloudflareService.uploadFile(File(croppedPath), fileName);
        if (url != null) {
          setState(() {
            _img = url;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('?대?吏 ?낅줈???ㅽ뙣: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<String?> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '?꾨줈???ъ쭊 ?몄쭛',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.cyanAccent,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, 
          activeControlsWidgetColor: Colors.cyanAccent,
        ),
        IOSUiSettings(
          title: '?꾨줈???ъ쭊 ?몄쭛',
          aspectRatioLockEnabled: true,
        ),
      ],
    );
    return croppedFile?.path;
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('?꾨줈???몄쭛', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadImage,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF151515),
                        border: Border.all(color: Colors.white10, width: 2),
                        image: DecorationImage(
                          image: _img.startsWith('http') 
                            ? NetworkImage(_img) 
                            : AssetImage(_img) as ImageProvider, 
                          fit: BoxFit.cover, 
                          opacity: _isUploading ? 0.3 : 0.8
                        ),
                      ),
                    ),
                    if (_isUploading)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _field('?대쫫', _name),
            const SizedBox(height: 20),
            _field('?꾩씠??, _id),
            const SizedBox(height: 20),
            _field('?먭린?뚭컻', _bio, lines: 5),
            const SizedBox(height: 60),
            
            // ?뮶 ??ν븯湲?踰꾪듉 ?뱀뀡
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    
                    // 濡쒕뵫 ?쒖떆
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
                    );

                    try {
                      // 0. ?꾩씠??以묐났 泥댄겕
                      if (_id.text != widget.currentId) {
                        final existing = await SupabaseService.client
                            .from('user_profiles')
                            .select('user_id')
                            .eq('user_id', _id.text)
                            .maybeSingle();
                        
                        if (existing != null) {
                          if (mounted) {
                            Navigator.pop(context); // 濡쒕뵫 ?リ린
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('?대? ?ъ슜 以묒씤 ?꾩씠?붿엯?덈떎. ?ㅻⅨ ?꾩씠?붾? ?낅젰?댁＜?몄슂! ?쁾'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // 二쇰?踰덊샇(User ID) 理쒖쥌 ?뺤씤 (?대? Auth ?몄뀡?먯꽌 ?ㅼ젙?섏뼱 ?덉뼱????
                      if (gUserInternalId == null) {
                        throw Exception('濡쒓렇???몄뀡??留뚮즺?섏뿀?듬땲?? ?ㅼ떆 濡쒓렇?명빐二쇱꽭??');
                      }

                      // 1. ?꾨줈???낅뜲?댄듃 (二쇰?踰덊샇 湲곗?!)
                      await SupabaseService.client
                          .from('user_profiles')
                          .update({
                            'nickname': _name.text,
                            'bio': _bio.text,
                            'profile_image': _img,
                            'user_id': _id.text,
                          })
                          .eq('id', gUserInternalId!);

                      // 2. 湲濡쒕쾶 ?곹깭 蹂??利됱떆 ?숆린??(吏꾩쭨 ?뺤꽍!)
                      gNameText = _name.text;
                      gIdText = _id.text;
                      gProfileImage = _img;

                      // 3. 寃뚯떆臾??볤? ?대쫫???숆린??(二쇰?踰덊샇 湲곕컲?쇰줈 ???뺤떎?섍쾶!)
                      await SupabaseService.client
                          .from('posts')
                          .update({'uploader_id': _id.text})
                          .eq('uploader_internal_id', gUserInternalId!);
                      
                      await SupabaseService.client
                          .from('comments')
                          .update({
                            'user_id': _id.text,
                            'user_name': _name.text,
                            'user_image': _img,
                          })
                          .eq('user_internal_id', gUserInternalId!);

                      // 3. ?쇰뱶 ?덈줈怨좎묠 ?덉빟 (硫붿씤 ?붾㈃ ?깆뿉??利됱떆 諛섏쁺?섎룄濡?
                      gRefreshFeed?.call();

                      if (mounted) {
                        Navigator.pop(context); // 濡쒕뵫 ?リ린
                        Navigator.pop(context, {
                          'name': _name.text,
                          'id': _id.text,
                          'bio': _bio.text,
                          'image': _img
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context); // 濡쒕뵫 ?リ린
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('????ㅽ뙣: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('??ν븯湲?, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: lines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF151515),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}

``

## File: lib\screens\point_screen.dart
``dart
import 'package:flutter/material.dart';
import 'store_screen.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';

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
  final ScrollController _scrollController = ScrollController();
  List<PointHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPolicy() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final List<dynamic> data = await SupabaseService.client
          .from('points_history')
          .select()
          .eq('user_internal_id', gUserInternalId!)
          .order('created_at', ascending: false);
      
      setState(() {
        _history = data.map((item) {
          final createdAt = DateTime.parse(item['created_at']);
          final dateStr = "${createdAt.year}.${createdAt.month.toString().padLeft(2,'0')}.${createdAt.day.toString().padLeft(2,'0')}";
          final amount = item['amount'] as int;
          return PointHistoryItem(
            title: item['description'] ?? '?ъ씤??蹂??,
            amount: amount.abs(),
            date: dateStr,
            isEarned: amount > 0,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('?ъ씤???댁뿭 媛?몄삤湲??ㅽ뙣: $e');
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('?섏쓽 ?ъ씤??, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ?곷떒 ?꾨━誘몄뾼 ?ъ씤??移대뱶 ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.cyanAccent.withValues(alpha: 0.15),
                    const Color(0xFF1A1A1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.05),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('?꾩옱 蹂댁쑀???ъ씤??, style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('P', style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 12),
                             Text(
                            gUserPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"),
                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StoreScreen(userPoints: gUserPoints))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: const Row(
                            children: [
                              Text('?ъ슜?섍린', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, color: Colors.white38, size: 16),
                            SizedBox(width: 8),
                            Text('30???대궡 ?뚮㈇ ?덉젙', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text('0 P', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _scrollToPolicy,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '?ъ씤???댁슜?덈궡 諛??뚮㈇?뺤콉',
                          style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.cyanAccent.withValues(alpha: 0.7), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- ?ъ씤???댁뿭 ?ㅻ뜑 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('?ъ씤???댁뿭', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('理쒓렐 3媛쒖썡', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- ?ъ씤???댁뿭 由ъ뒪??---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              itemBuilder: (context, index) {
                final item = _history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item.isEarned ? Colors.cyanAccent : Colors.white).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.isEarned ? Icons.add_rounded : Icons.remove_rounded,
                          color: item.isEarned ? Colors.cyanAccent : Colors.white60,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(item.date, style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Text(
                        "${item.isEarned ? '+' : '-'}${item.amount} P",
                        style: TextStyle(
                          color: item.isEarned ? Colors.cyanAccent : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // --- 以묒슂: 怨쇨굅 踰꾩쟾??紐⑤뱺 寃쎄퀬臾??뺤콉 ?덈궡 ?뱀뀡 ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 18),
                      SizedBox(width: 10),
                      Text('?ъ씤???댁슜 ?덈궡 諛??뚮㈇ ?뺤콉', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _policyItem('?좏슚湲곌컙', '媛??ъ씤???곷┰?쇰줈遺??1??(365?? ?숈븞 ?좎??⑸땲??'),
                  _policyItem('?뚮㈇ 諛⑹떇', '?좏슚湲곌컙??寃쎄낵???ъ씤?몃뒗 ?대떦 ?쇱옄 ?먯젙???먮룞 ?뚮㈇?⑸땲??'),
                  _policyItem('?ъ슜 ?먯튃', '癒쇱? ?곷┰???ъ씤?멸? 癒쇱? ?ъ슜?섎뒗 \'?좎엯?좎텧\' 諛⑹떇?낅땲??'),
                  _policyItem('?ъ쟾 ?덈궡', '?뚮㈇ 30???꾧낵 7???꾩뿉 ???뚮┝?쇰줈 誘몃━ ?덈궡???쒕┰?덈떎.'),
                  const SizedBox(height: 12),
                  const Text(
                    '* ?뚮㈇???ъ씤?몃뒗 蹂듦뎄媛 遺덇??ν븯?ㅻ땲 湲곌컙 ?댁뿉 ?곹뭹 援щℓ ?깆쑝濡??ъ슜?섏떆湲?諛붾엻?덈떎.\n* 理쒓렐 3媛쒖썡 ?댁뿭留??쒖떆?섎ŉ, ?꾩껜 ?댁뿭? 怨좉컼?쇳꽣瑜??듯빐 ?뺤씤 媛?ν빀?덈떎.',
                    style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _policyItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('??', style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4, fontFamily: 'Pretendard'),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

``

## File: lib\screens\profile_setup_screen.dart
``dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Demo Data
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedRegion;

  // Terms Agreement
  bool _agreeToAll = false;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  bool _agreeToThirdParty = false;
  bool _agreeToMarketing = false;

  final List<String> _ageGroups = ['10?', '20?', '30?', '40?', '50? ?댁긽'];
  final List<String> _regions = [
    '?쒖슱',
    '寃쎄린',
    '?몄쿇',
    '遺??,
    '?援?,
    '愿묒＜',
    '???,
    '?몄궛',
    '?몄쥌',
    '媛뺤썝',
    '異⑸턿',
    '異⑸궓',
    '?꾨턿',
    '?꾨궓',
    '寃쎈턿',
    '寃쎈궓',
    '?쒖＜',
  ];

  final String _tosText = """
??議?(紐⑹쟻)
蹂??쎄?? ?뚯궗媛 ?쒓났?섎뒗 'PickGet(?쎄쿊)' ?쒕퉬?ㅼ쓽 ?댁슜 議곌굔 諛??덉감, ?뚯궗? ?뚯썝 媛꾩쓽 沅뚮━, ?섎Т 諛?梨낆엫 ?ы빆??洹쒖젙?⑸땲??

??議?(?ъ씤???곷┰ 諛??ъ슜)
???뚯썝? ?쒕퉬?????ы몴 李몄뿬, ?대깽??李몄뿬 ???뚯궗媛 ?뺥븳 諛⑸쾿???곕씪 ?ъ씤?몃? ?곷┰?????덉뒿?덈떎.
???곷┰???ъ씤?몃뒗 ?뚯궗媛 ?뺥븳 湲곗????곕씪 ?곹뭹 援먰솚 ?깆뿉 ?ъ슜?????덉뒿?덈떎.
??遺?뺥븳 諛⑸쾿(留ㅽ겕濡? ?ㅼ쨷 怨꾩젙 ???쇰줈 ?ъ씤?몃? ?띾뱷??寃쎌슦, ?뚯궗???ъ쟾 ?듬낫 ?놁씠 ?대떦 ?ъ씤?몃? ?뚯닔?섍퀬 ?뚯썝???쒕퉬???댁슜???쒗븳?????덉뒿?덈떎.

??議?(?뚯썝 寃뚯떆臾?愿由?
???뚯썝???묒꽦???ы몴 肄섑뀗痢???寃뚯떆臾쇱쓽 ??묎텒? ?뚯썝?먭쾶 ?덉쑝硫? ?뚯궗???쒕퉬???댁쁺 諛??띾낫 紐⑹쟻?쇰줈 ?대? ?쒖슜?????덉뒿?덈떎.
???뚯궗????몄쓽 沅뚮━瑜?移⑦빐?섍굅???쒕퉬???댁쁺 紐⑹쟻??遺?⑺븯吏 ?딅뒗 寃뚯떆臾쇱쓣 ?꾩쓽濡???젣?섍굅??釉붾씪?몃뱶 泥섎━?????덉뒿?덈떎.

??議?(?곗씠??蹂닿? 諛??쒖슜)
?뚯궗???뚯썝??以묐났 李몄뿬 諛⑹?, ?ъ씤???뺤궛 諛?遺???ъ슜 ?먯?瑜??꾪빐 ?쒕퉬???댁슜 湲곕줉???섏쭛?섎ŉ, ?대떦 ?뺣낫???뚯썝???덊눜 ?쒓퉴吏 蹂닿??⑸땲??
""";

  final String _privacyText = """
1. ?섏쭛?섎뒗 媛쒖씤?뺣낫 ??ぉ
?뚯궗???쒕퉬???쒓났???꾪빐 ?꾨옒??媛쒖씤?뺣낫瑜??섏쭛?⑸땲??
?꾩닔??ぉ: ?대찓??二쇱냼, 湲곌린 ?앸퀎媛? ?됰꽕?? ?쒕퉬???댁슜 湲곕줉(?ы몴 李몄뿬 ?대젰 ??

2. 媛쒖씤?뺣낫???섏쭛 諛??댁슜 紐⑹쟻
- ?뚯썝 ?앸퀎 諛?媛???섏궗 ?뺤씤
- ?ъ씤???곷┰ 諛??ъ슜 ?댁뿭 愿由?
- 遺???댁슜 諛⑹? 諛?鍮꾩씤媛 ?ъ슜 ?뺤씤
- 留욎땄???쒕퉬???쒓났 諛??듦퀎 遺꾩꽍

3. 媛쒖씤?뺣낫??蹂댁쑀 諛??댁슜 湲곌컙
?먯튃?곸쑝濡??뚯썝??媛쒖씤?뺣낫???뚯썝 ?덊눜 ??吏泥??놁씠 ?뚭린?⑸땲?? ?? 遺???댁슜 諛⑹? 諛?愿??踰뺣졊???섑븳 蹂댁〈???꾩슂??寃쎌슦 ?덉쇅?곸쑝濡??쇱젙 湲곌컙 蹂닿??????덉뒿?덈떎.

4. 媛쒖씤?뺣낫 蹂댄샇梨낆엫??
?뚯궗??媛쒖씤?뺣낫瑜?蹂댄샇?섍퀬 愿??遺덈쭔??泥섎━?섍린 ?꾪빐 ?꾨옒? 媛숈씠 梨낆엫?먮? 吏?뺥븯怨??덉뒿?덈떎.
?대떦遺?? PickGet ?댁쁺?
?곕씫泥? support@pickget.net
""";

  final String _thirdPartyText = """
1. ?쒓났諛쏅뒗 ?? '?ㅽ룿???ы몴'瑜?吏꾪뻾?섎뒗 ?대떦 湲곗뾽 諛?釉뚮옖???뚰듃??
2. ?쒓났 紐⑹쟻: ?ы몴 寃곌낵 遺꾩꽍(?곕졊, ?깅퀎 ???듦퀎 泥섎━), 寃쏀뭹 ?대깽???뱀꺼???좎젙 諛?諛곗넚
3. ?쒓났 ??ぉ: ?깅퀎, ?곕졊?, ?ы몴 ?묐떟 ?곗씠??(寃쏀뭹 諛곗넚 ?쒖뿉 ?쒗븯???앸퀎 ?뺣낫 ?쒗븳???쒓났)
4. 蹂댁쑀 諛??댁슜 湲곌컙: ?대떦 紐⑹쟻 ?ъ꽦 ??利됱떆 ?뚭린
""";

  final String _marketingText = """
1. ?섏쭛 紐⑹쟻: ?좉퇋 ?쒕퉬???덈궡, ?대깽??諛?留욎땄???쒗깮 ?뺣낫 ?쒓났
2. ?섏쭛 ??ぉ: ?대??꾪솕 踰덊샇, ?대찓??二쇱냼, ???몄떆 ?좏겙
3. 蹂댁쑀 諛??댁슜 湲곌컙: ?숈쓽 泥좏쉶 ?먮뒗 ?뚯썝 ?덊눜 ?쒓퉴吏
4. 泥좏쉶 ?덈궡: ?뚯썝? ?몄젣?좎? ?????ㅼ젙?먯꽌 ?섏떊 ?숈쓽瑜?泥좏쉶?????덉뒿?덈떎.
""";

  bool get _canSubmit =>
      _selectedGender != null &&
      _selectedAge != null &&
      _selectedRegion != null &&
      _agreeToTerms &&
      _agreeToPrivacy &&
      _agreeToThirdParty;

  void _updateAllAgreements(bool? value) {
    setState(() {
      _agreeToAll = value ?? false;
      _agreeToTerms = _agreeToAll;
      _agreeToPrivacy = _agreeToAll;
      _agreeToThirdParty = _agreeToAll;
      _agreeToMarketing = _agreeToAll;
    });
  }

  void _showTermsDetail(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('?リ린'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: null,
      body: SafeArea(
        bottom: false, // Bottom button handles safe area
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '?뚯썝媛???꾨즺 ?뢾',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '?꾩닔 ?쎄? 諛?湲곕낯 ?뺣낫瑜??뺤씤?댁＜?몄슂.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Terms Section (Compact)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151515),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTermsRow(
                              '?꾩껜 ?숈쓽',
                              _agreeToAll,
                              (val) => _updateAllAgreements(val),
                              isBold: true,
                            ),
                            const Divider(color: Colors.white10, height: 16),
                            _buildTermsRow(
                              '[?꾩닔] ?쒕퉬???댁슜?쎄?',
                              _agreeToTerms,
                              (val) {
                                setState(() {
                                  _agreeToTerms = val ?? false;
                                  _agreeToAll =
                                      _agreeToTerms &&
                                      _agreeToPrivacy &&
                                      _agreeToThirdParty &&
                                      _agreeToMarketing;
                                });
                              },
                              onTap: () =>
                                  _showTermsDetail('?쒕퉬???댁슜?쎄?', _tosText),
                            ),
                            const SizedBox(height: 8),
                            _buildTermsRow(
                              '[?꾩닔] 媛쒖씤?뺣낫 泥섎━諛⑹묠',
                              _agreeToPrivacy,
                              (val) {
                                setState(() {
                                  _agreeToPrivacy = val ?? false;
                                  _agreeToAll =
                                      _agreeToTerms &&
                                      _agreeToPrivacy &&
                                      _agreeToThirdParty &&
                                      _agreeToMarketing;
                                });
                              },
                              onTap: () =>
                                  _showTermsDetail('媛쒖씤?뺣낫 泥섎━諛⑹묠', _privacyText),
                            ),
                            const SizedBox(height: 8),
                            _buildTermsRow(
                              '[?꾩닔] ?????곗씠???쒓났',
                              _agreeToThirdParty,
                              (val) {
                                setState(() {
                                  _agreeToThirdParty = val ?? false;
                                  _agreeToAll =
                                      _agreeToTerms &&
                                      _agreeToPrivacy &&
                                      _agreeToThirdParty &&
                                      _agreeToMarketing;
                                });
                              },
                              onTap: () => _showTermsDetail(
                                '媛쒖씤?뺣낫 ?????쒓났 ?숈쓽',
                                _thirdPartyText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTermsRow(
                              '[?좏깮] 留덉????뺣낫 ?섏떊',
                              _agreeToMarketing,
                              (val) {
                                setState(() {
                                  _agreeToMarketing = val ?? false;
                                  _agreeToAll =
                                      _agreeToTerms &&
                                      _agreeToPrivacy &&
                                      _agreeToThirdParty &&
                                      _agreeToMarketing;
                                });
                              },
                              onTap: () => _showTermsDetail(
                                '留덉????뺣낫 ?섏떊 ?숈쓽',
                                _marketingText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      // Demographics (Side by Side where possible)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gender Section (Natural width)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('?깅퀎'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildChoiceChip(
                                      '??,
                                      _selectedGender == '?⑥꽦',
                                      () => setState(() => _selectedGender = '?⑥꽦')),
                                  const SizedBox(width: 8),
                                  _buildChoiceChip(
                                      '??,
                                      _selectedGender == '?ъ꽦',
                                      () => setState(() => _selectedGender = '?ъ꽦')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Region Section (Takes remaining space)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('嫄곗＜ 吏??),
                                const SizedBox(height: 12),
                                Container(
                                  height: 50, // Standard height
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151515),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRegion,
                                      hint: const Text(
                                        '吏???좏깮',
                                        style: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 13,
                                        ),
                                      ),
                                      isExpanded: true,
                                      dropdownColor: const Color(0xFF151515),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      items: _regions
                                          .map(
                                            (String value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedRegion = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('?곕졊?'),
                      const SizedBox(height: 12),
                      Row(
                        children: _ageGroups.map((age) {
                          final bool isLast = age == _ageGroups.last;
                          return Expanded(
                            flex: isLast ? 14 : 10, // Give '50? ?댁긽' more space
                            child: Padding(
                              padding: EdgeInsets.only(right: isLast ? 0 : 6),
                              child: _buildChoiceChip(
                                  age,
                                  _selectedAge == age,
                                  () => setState(() => _selectedAge = age)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Bottom Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _canSubmit
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context, {
                                    'gender': _selectedGender,
                                    'age': _selectedAge,
                                    'region': _selectedRegion,
                                    'agreed_tos': _agreeToTerms,
                                    'agreed_privacy': _agreeToPrivacy,
                                    'agreed_third_party': _agreeToThirdParty,
                                    'agreed_marketing': _agreeToMarketing,
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canSubmit
                                ? Colors.cyanAccent
                                : const Color(0xFF2A2A2A),
                            foregroundColor: _canSubmit ? Colors.black : Colors.white24,
                            elevation: _canSubmit ? 8 : 0,
                            shadowColor: Colors.cyanAccent.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(_canSubmit ? '媛???꾨즺?섍퀬 ?쒖옉?섍린' : '??ぉ??紐⑤몢 梨꾩썙二쇱꽭??),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTermsRow(
    String title,
    bool value,
    Function(bool?) onChanged, {
    bool isBold = false,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyanAccent,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: Colors.white24, width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: value ? Colors.white : Colors.white60,
                      fontSize: 14,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (!isBold)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white24,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ), // Smaller padding
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          border: Border.all(
            color: isSelected
                ? Colors.cyanAccent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13, // Smaller font
            ),
          ),
        ),
      ),
    );
  }
}

``

## File: lib\screens\search_screen.dart
``dart
import 'package:flutter/material.dart';
import '../models/post_data.dart';
import 'channel_screen.dart';
import 'channel_feed_screen.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';

class SearchScreen extends StatefulWidget {
  final List<PostData> allPosts;
  const SearchScreen({super.key, required this.allPosts});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PostData> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingPopular = false;

  List<String> _searchHistory = [];
  final List<Map<String, dynamic>> _popularSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadPopularSearches(); // ?멸린 寃?됱뼱 濡쒕뵫 異붽?
  }

  Future<void> _loadHistory() async {
    if (!gIsLoggedIn) return;
    try {
      final List<dynamic> data = await SupabaseService.client
          .from('search_history')
          .select('keyword')
          .eq('user_internal_id', gUserInternalId!)
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _searchHistory = data.map((item) => item['keyword'].toString()).toList();
      });
    } catch (e) {
      if (kDebugMode) debugPrint('寃??湲곕줉 遺덈윭?ㅺ린 ?ㅽ뙣: $e');
    }
  }

  Future<void> _loadPopularSearches() async {
    setState(() => _isLoadingPopular = true);
    try {
      // 1. 理쒓렐 24?쒓컙 ??紐⑤뱺 ?좎???寃???곗씠??議고쉶
      final List<dynamic> data = await SupabaseService.client
          .from('search_history')
          .select('keyword')
          .gte('created_at',
              DateTime.now().subtract(const Duration(hours: 24)).toIso8601String());

      if (data.isEmpty) return;

      // 2. ?ㅼ썙?쒕퀎 寃???잛닔 吏묎퀎
      Map<String, int> counts = {};
      for (var item in data) {
        String keyword = item['keyword']?.toString() ?? '';
        if (keyword.trim().isNotEmpty) {
          counts[keyword] = (counts[keyword] ?? 0) + 1;
        }
      }

      // 3. 寃???잛닔 湲곗? ?대┝李⑥닚 ?뺣젹
      var sortedEntries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // 4. ?곸쐞 10媛쒕쭔 由ъ뒪?몄뿉 諛섏쁺
      if (mounted) {
        setState(() {
          _popularSearches.clear();
          for (var entry in sortedEntries.take(10)) {
            _popularSearches.add({
              'term': entry.key,
              'status': 'NEW',
              'change': 0,
            });
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('?ㅼ떆媛??멸린 寃?됱뼱 濡쒕뱶 ?ㅽ뙣: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPopular = false);
      }
    }
  }

  Future<void> _saveKeyword(String query) async {
    if (!gIsLoggedIn) return;
    try {
      // 以묐났 泥댄겕 諛??낅뜲?댄듃 (Upsert ?먮굦?쇰줈)
      await SupabaseService.client.from('search_history').upsert({
        'user_internal_id': gUserInternalId!,
        'keyword': query,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_internal_id,keyword');
    } catch (e) {
      if (kDebugMode) debugPrint('寃?됱뼱 ????ㅽ뙣: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = widget.allPosts
          .where(
            (p) =>
                p.title.toLowerCase().contains(query.toLowerCase()) ||
                p.uploaderId.toLowerCase().contains(query.toLowerCase()) ||
                p.uploaderName.toLowerCase().contains(query.toLowerCase()) ||
                (p.tags?.any(
                      (t) => t.toLowerCase().contains(query.toLowerCase()),
                    ) ==
                    true),
          )
          .toList();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    // 濡쒖뺄 ?곹깭 ?낅뜲?댄듃 (以묐났 諛⑹? 諛?理쒖떊??
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) _searchHistory.removeLast();
      _isSearching = true;
    });

    // ?ㅼ떆媛??꾪꽣留곷룄 媛숈씠 ?섑뻾
    _filterResults(query);

    // ?쒕쾭?????
    _saveKeyword(query);
  }

  void _deleteHistoryItem(String item) {
    setState(() {
      _searchHistory.remove(item);
    });
    // ?쒕쾭?먯꽌 ??젣
    if (gIsLoggedIn) {
      SupabaseService.client
          .from('search_history')
          .delete()
          .match({'user_internal_id': gUserInternalId!, 'keyword': item})
          .then((_) => if (kDebugMode) debugPrint('寃?됱뼱 ?쒕쾭 ??젣 ?꾨즺'))
          .catchError((e) => if (kDebugMode) debugPrint('寃?됱뼱 ?쒕쾭 ??젣 ?ㅽ뙣: $e'));
    }
  }

  void _clearAllHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // ?쒕쾭?먯꽌 ?꾩껜 ??젣
    if (gIsLoggedIn) {
      SupabaseService.client
          .from('search_history')
          .delete()
          .eq('user_internal_id', gUserInternalId!)
          .then((_) => if (kDebugMode) debugPrint('?꾩껜 寃??湲곕줉 ?쒕쾭 ??젣 ?꾨즺'))
          .catchError((e) => if (kDebugMode) debugPrint('?꾩껜 寃??湲곕줉 ?쒕쾭 ??젣 ?ㅽ뙣: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            // ???移??뚮뒗 寃??寃곌낵留??꾪꽣留?(?쒕쾭 ???X)
                            _filterResults(val);
                          },
                          onSubmitted: (val) {
                            // ?뷀꽣 ?뚮????뚮쭔 吏꾩쭨 寃?됱쑝濡??몄젙?섍퀬 ???
                            _performSearch(val);
                          },
                          decoration: const InputDecoration(
                            hintText: '吏덈Ц ?쒕ぉ, 梨꾨꼸紐? ?쒓렇 寃??,
                            hintStyle: TextStyle(
                              color: Colors.white24,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white38,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isSearching
                    ? _buildSearchResults()
                    : _buildDiscoveryView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '理쒓렐 寃?됱뼱',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_searchHistory.isNotEmpty)
              TextButton(
                onPressed: _clearAllHistory,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '?꾩껜 ??젣',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _searchHistory
              .map(
                (item) => Container(
                  padding: const EdgeInsets.only(
                    left: 14,
                    right: 8,
                    top: 6,
                    bottom: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // ?ㅼ썙???대┃ ???ㅻ낫??利됱떆 ?④?
                          FocusScope.of(context).unfocus();
                          _searchController.text = item;
                          _performSearch(item);
                        },
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _deleteHistoryItem(item),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white38,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 40),
        const Text(
          '?ㅼ떆媛??멸린 寃?됱뼱',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _isLoadingPopular
              ? Column(
                  children: List.generate(10, (index) => _buildSkeletonTile(index + 1)),
                )
              : Column(
                  children: List.generate(_popularSearches.length, (index) {
                    final item = _popularSearches[index];
                    return _popularSearchTile(
                      index + 1,
                      item['term'],
                      item['status'],
                      item['change'],
                    );
                  }),
                ),
        ),
        const SizedBox(height: 40),
        const Text(
          '異붿쿇 移댄뀒怨좊━',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _categoryTile(Icons.shopping_bag_outlined, '?⑥뀡 & ?ㅽ???, '?ㅼ떆媛??몃젋???뺤씤'),
        _categoryTile(Icons.restaurant_outlined, '留쏆쭛 & 移댄럹', '二쇰? ?ロ뵆?덉씠??),
        _categoryTile(Icons.favorite_border, '?곗븷 & 怨좊?', '?듬챸 怨좊? ?곷떞'),
        _categoryTile(Icons.flight_takeoff, '?ы뻾 & ?쇱씠??, '?ы뻾 轅??怨듭쑀'),
      ],
    );
  }

  final Map<String, List<String>> _categoryKeywords = {
    '?⑥뀡 & ?ㅽ???: ['?⑥뀡', '?ㅽ???, '?곗씪由щ）', 'OOTD', '肄붾뵒', '?⑥뀡?쇳뵆', '?룹뒪?洹몃옩', '誘몃땲硫猷?, '?ㅽ듃由욱뙣??, '怨좏봽肄붿뼱', '??댄닾耳??, 'Y2K', '袁몄븞袁?, '?ㅽ뵾?ㅻ）', '?뚰겕?⑥뼱', '?섏씠?붾뱶', '鍮덊떚吏猷?, '?섎??뚮）', '罹먯＜??, '?꾨찓移댁?', '猷⑸턿', '?섍컼猷?, '?곗씠?몃）', '罹좏띁?ㅻ）', '?대룞蹂?, '?좎뒳?덉?猷?, '諛붿틝?ㅻ）', '?먮쭏?쇱썾??, '?뗭뾽肄붾뵒', '?덉씠?대뱶猷?, '??대뱶?ъ툩', '?щ옓??, '?곕떂', '泥?컮吏', '?붿툩', '釉붾씪?곗뒪', '?곗뀛痢?, '?덊듃', '?ы궥', '肄뷀듃', '?⑤뵫', '?ㅻ땲而ㅼ쫰', '?대룞??, '援щ몢', '媛諛?, '紐⑥옄', '?낆꽭?щ━'],
    '留쏆쭛 & 移댄럹': ['留쏆쭛', '留쏆쭛異붿쿇', '移댄럹', '移댄럹異붿쿇', '癒뱀뒪?洹몃옩', '留쏆뒪?洹몃옩', '移댄럹?ъ뼱', '?ロ뵆?덉씠??, '?ロ뵆', '遺꾩쐞湲곕쭧吏?, '酉곕쭧吏?, '釉뚮윴移?, '?ㅼ떆', '珥덈갈', '?꾨쾭嫄?, '?쇱옄', '?뚯뒪?', '?ㅽ뀒?댄겕', '留덈씪??, '?쇨껸??, '怨좉린吏?, '鍮듭??쒕?', '?붿???, '耳?댄겕', '?꾨꽋', '而ㅽ뵾', '?쇰뼹', '?〓낭??, '移섑궓', '?좎쭛', '?댁옄移댁빞', '??몃컮'],
    '?곗븷 & 怨좊?': ['?곗븷', '怨좊?', '?щ옉', '??, '吏앹궗??, '?뚭컻??, '?곗븷?곷떞', '怨좊??곷떞', '?멸컙愿怨?, '?щ━', '留덉쓬嫄닿컯', '?먮쭅', '?꾨줈', '怨듦컧', '?대퀎', '?ы쉶', '寃고샎', '?≪븘', '吏곸옣怨좊?', '吏꾨줈怨좊?', 'MBTI', '?濡?, '?ъ＜', '踰덉븘??, '?ㅽ듃?덉뒪', '媛볦깮', '?듦?', '?먭린怨꾨컻'],
    '?ы뻾 & ?쇱씠??: ['?ы뻾', '?ы뻾異붿쿇', '援?궡?ы뻾', '?댁쇅?ы뻾', '?몄틝??, '罹좏븨', '李⑤컯', '湲?⑦븨', '媛먯꽦?숈냼', '?명뀛', '由ъ“??, '鍮꾪뻾湲?, '?쒖＜?ы뻾', '?쇰낯?ы뻾', '?좊읇?ы뻾', '?쇱긽', '?쇱씠?꾩뒪???, '痍⑤?', '?대룞', '?ㅼ슫??, '?명뀒由ъ뼱', '諛⑷씀誘멸린', '?먯랬', '?ы뀒??, '二쇱떇', '肄붿씤', '肄붾뵫', '諛섎젮?숇Ъ', '媛뺤븘吏', '怨좎뼇??],
  };

  void _filterByCategory(String category) {
    List<String> keywords = _categoryKeywords[category] ?? [];
    if (keywords.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchController.text = category; // 寃?됱갹??移댄뀒怨좊━紐??쒖떆
      _searchResults = widget.allPosts.where((post) {
        final content = (post.title + (post.fullDescription ?? '') + (post.tags?.join(' ') ?? '')).toLowerCase();
        return keywords.any((kw) => content.contains(kw.toLowerCase()));
      }).toList();
    });
  }

  Widget _categoryTile(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () => _filterByCategory(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white70, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white10),
          ],
        ),
      ),
    );
  }

  Widget _popularSearchTile(int rank, String term, String status, int change) {
    return InkWell(
      onTap: () {
        // ?멸린 寃?됱뼱 ?대┃ ???ㅻ낫??利됱떆 ?④?
        FocusScope.of(context).unfocus();
        _searchController.text = term;
        _performSearch(term);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.cyanAccent : Colors.white24,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                term,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusIndicator(status, change),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonTile(int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 30,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status, int change) {
    if (status == 'NEW') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'NEW',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    } else if (status == 'UP') {
      return Row(
        children: [
          const Icon(Icons.arrow_drop_up, color: Colors.redAccent, size: 18),
          Text(
            '$change',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else if (status == 'DOWN') {
      return Row(
        children: [
          const Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 18),
          Text(
            '$change',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    return const Text(
      '-',
      style: TextStyle(color: Colors.white24, fontSize: 12),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            _searchResults.isEmpty ? '寃??寃곌낵 ?놁쓬' : '寃??寃곌낵 (${_searchResults.length})',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, color: Colors.white10, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        '?쇱튂?섎뒗 寃뚯떆臾쇱씠 ?놁뒿?덈떎.\n?ㅻⅨ ?ㅼ썙?쒕줈 寃?됲빐蹂댁꽭??',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white24, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: GridView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final post = _searchResults[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // 1. ?곸긽 ?쇰뱶濡??대룞
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChannelFeedScreen(
                                        initialIndex: index,
                                        channelPosts: _searchResults,
                                        allPosts: widget.allPosts,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: (post.thumbA != null && post.thumbA!.isNotEmpty)
                                        ? Image.network(post.thumbA!.trim(), fit: BoxFit.cover)
                                        : (_isVideo(post.imageA)
                                            ? Container(color: Colors.black26, child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54)))
                                            : (post.imageA.trim().contains('http')
                                                ? Image.network(post.imageA.trim(), fit: BoxFit.cover)
                                                : Image.asset(post.imageA.trim(), fit: BoxFit.cover))),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.3),
                                              Colors.black.withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 2. ?곹깭 諛곗?
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: post.isExpired
                                        ? Colors.black54
                                        : Colors.cyanAccent.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    post.isExpired ? '?좏깮醫낅즺' : '?좏깮以?,
                                    style: TextStyle(
                                      color: post.isExpired
                                          ? Colors.white70
                                          : Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              // 3. ?섎떒 ?뺣낫
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '${post.totalVotes} picks',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            fontSize: 9,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.cyanAccent.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            post.uploaderName,
                                            style: const TextStyle(
                                              color: Colors.cyanAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                  ),
                ),
        ),
      ],
    );
  }
}

``

## File: lib\screens\store_screen.dart
``dart
import 'package:flutter/material.dart';

class StoreScreen extends StatefulWidget {
  final int userPoints;
  const StoreScreen({super.key, required this.userPoints});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  String _selectedCategory = '而ㅽ뵾';
  
  bool _isWithdrawalPending = false;
  int _pendingAmount = 0;

  final Map<String, List<Map<String, String>>> _categoryProducts = {
    '而ㅽ뵾': [
      {'title': '[?ㅽ?踰낆뒪] ?꾨찓由ъ뭅??T', 'price': '4,500 P', 'brand': '?ㅽ?踰낆뒪'},
      {'title': '[?ъ뜽?뚮젅?댁뒪] 移댄럹?쇰뼹 R', 'price': '5,000 P', 'brand': '?ъ뜽?뚮젅?댁뒪'},
      {'title': '[硫붽?而ㅽ뵾] ?꾨찓由ъ뭅??HOT)', 'price': '1,500 P', 'brand': '硫붽?而ㅽ뵾'},
    ],
    '?몄쓽??: [
      {'title': '[GS25] 紐⑤컮???곹뭹沅?5,000??, 'price': '5,000 P', 'brand': 'GS25'},
      {'title': '[CU] 紐⑤컮???곹뭹沅?3,000??, 'price': '3,000 P', 'brand': 'CU'},
      {'title': '[7-Eleven] 諛붾굹?섏슦??, 'price': '1,700 P', 'brand': '7-Eleven'},
    ],
    '?곹뭹沅?: [
      {'title': '臾명솕?곹뭹沅?5,000?먭텒', 'price': '5,000 P', 'brand': '而ъ퀜?쒕뱶'},
      {'title': '援ш? 湲고봽?몄뭅??1留뚯썝', 'price': '10,000 P', 'brand': 'Google'},
    ],
    '臾명솕': [
      {'title': 'CGV 1???곹솕愿?뚭텒', 'price': '13,000 P', 'brand': 'CGV'},
      {'title': '濡?뜲?쒕꽕留??곹솕?덈ℓ沅?, 'price': '12,000 P', 'brand': '濡?뜲?쒕꽕留?},
      {'title': '援먮낫臾멸퀬 湲고봽?몄뭅??1留뚯썝', 'price': '10,000 P', 'brand': '援먮낫臾멸퀬'},
    ],
    '?몄떇': [
      {'title': '[?꾩썐諛? 5留뚯썝沅?, 'price': '50,000 P', 'brand': '?꾩썐諛?},
      {'title': '[VIPS] ?됱씪 ?곗튂 1??, 'price': '32,000 P', 'brand': 'VIPS'},
    ],
    '湲고?': [
      {'title': '?ㅼ씠踰꾪럹???ъ씤??5,000??, 'price': '5,000 P', 'brand': '?ㅼ씠踰?},
      {'title': '移댁뭅?ㅽ넚 ?대え?곗퐯 援щℓ沅?, 'price': '2,500 P', 'brand': '移댁뭅??},
    ],
  };

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _bankController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  void _showWithdrawalDialog() {
    String? localError; // ?앹뾽 ?대????먮윭 硫붿떆吏 蹂??

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('?꾧툑 ?몄텧 ?좎껌', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ?낅젰 ?꾨뱶??(媛꾧꺽 異뺤냼)
                  Row(
                    children: [
                      Expanded(child: _inputFieldCompact('??됰챸', _bankController, '?? 移댁뭅?ㅻ콉??, TextInputType.text)),
                      const SizedBox(width: 12),
                      Expanded(child: _inputFieldCompact('?덇툑二?, _holderController, '?ㅻ챸 ?낅젰', TextInputType.text)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inputFieldCompact('怨꾩쥖踰덊샇', _accountController, '?섏씠??-) ?놁씠 ?낅젰', TextInputType.number),
                  const SizedBox(height: 12),
                  _inputFieldCompact('?몄텧 ?ъ씤??(理쒖냼 10,000P)', _amountController, '5,000P ?⑥쐞濡??낅젰', TextInputType.number),
                  
                  const SizedBox(height: 16),
                  
                  // 二쇱쓽?ы빆 (??而댄뙥?명븯寃?
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '??蹂몄씤 紐낆쓽 怨꾩쥖 ?꾩닔 / ?뱀씤源뚯? 理쒕? 3???뚯슂\n??5,000P ?⑥쐞 ?좎껌 媛??(理쒕? 30,000P)',
                      style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // ?대? ?먮윭 硫붿떆吏 ?쒖떆 ?곸뿭
                  if (localError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Text(
                          localError!, 
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final int? amount = int.tryParse(_amountController.text);
                        String? error;

                        if (_amountController.text.isEmpty || _holderController.text.isEmpty || _accountController.text.isEmpty || _bankController.text.isEmpty) {
                          error = '紐⑤뱺 ?뺣낫瑜??낅젰?댁＜?몄슂.';
                        } else if (amount == null || amount < 10000) {
                          error = '理쒖냼 10,000P遺???몄텧 媛?ν빀?덈떎.';
                        } else if (amount % 5000 != 0) {
                          error = '5,000P ?⑥쐞濡쒕쭔 ?좎껌 媛?ν빀?덈떎.';
                        } else if (amount > widget.userPoints) {
                          error = '蹂댁쑀?섏떊 ?ъ씤?멸? 遺議깊빀?덈떎.';
                        }

                        if (error != null) {
                          setSheetState(() => localError = error);
                          return;
                        }

                        setState(() {
                          _isWithdrawalPending = true;
                          _pendingAmount = amount!;
                        });
                        
                        Navigator.pop(context);

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('?좎껌 ?꾨즺', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            content: const Text('?꾧툑 ?몄텧 ?좎껌???꾨즺?섏뿀?듬땲??\n愿由ъ옄 ?뺤씤 ??理쒕? 3???대궡???낃툑?⑸땲??', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('?뺤씤', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('?좎껌?섍린', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  SizedBox(height: 20 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputFieldCompact(String label, TextEditingController controller, String hint, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('?ъ씤???ㅽ넗??, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF0F0F0F),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                children: [
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
                                _isWithdrawalPending ? '?몄텧 ?좎껌 吏꾪뻾 以? : '?꾧툑 ?몄텧?섍린', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isWithdrawalPending ? '?좎껌湲덉븸: ${_pendingAmount}P (?뱀씤 ?湲?' : '蹂댁쑀 ?ъ씤?몃? ?꾧툑?쇰줈 ?꾪솚', 
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
                            _isWithdrawalPending ? '?좎껌以? : '?몄텧?좎껌', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyCouponsScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(Icons.confirmation_num_outlined, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 12),
                            Expanded(child: Text('??荑좏룿??, style: TextStyle(color: Colors.white70, fontSize: 14))),
                            Row(
                              children: [
                                Text('2', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _categoryProducts.keys.map((cat) => _categoryTab(cat)).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categoryProducts[_selectedCategory]!.length,
                itemBuilder: (context, index) {
                  final product = _categoryProducts[_selectedCategory]![index];
                  return _productCard(product);
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _categoryTab(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label, 
          style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
        ),
      ),
    );
  }

  Widget _productCard(Map<String, String> product) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.redeem, color: Colors.white10, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['brand']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 4),
                Text(product['title']!, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(product['price']!, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
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
    {'title': '[GS25] 紐⑤컮???곹뭹沅?5,000??, 'date': '2026.12.31源뚯?', 'brand': 'GS25', 'isUsed': false, 'type': 'barcode'},
    {'title': '[CU] 紐⑤컮???곹뭹沅?3,000??, 'date': '2026.11.15源뚯?', 'brand': 'CU', 'isUsed': false, 'type': 'qr'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('??荑좏룿??, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      Text('?좏슚湲곌컙: ${coupon['date']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: isUsed ? 0.2 : 0.4), fontSize: 12)),
                    ],
                  ),
                ),
                if (isUsed)
                  const Text('?ъ슜?꾨즺', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold))
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
                    child: const Text('?ъ슜?섍린', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
              type == 'barcode' ? '留ㅼ옣 ?먯썝?먭쾶 諛붿퐫?쒕? 蹂댁뿬二쇱꽭??' : '留ㅼ옣 ?ㅼ틦?덉뿉 QR肄붾뱶瑜??ㅼ틪?댁＜?몄슂.',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.black.withValues(alpha: 0.1)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                child: const Text('?ъ슜 ?꾨즺 泥섎━?섍린', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('?リ린', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
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
        title: const Text('?ъ슜 ?꾨즺 泥섎━', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('?뺣쭚濡??ъ슜 ?꾨즺 泥섎━?섏떆寃좎뒿?덇퉴?\n??踰??꾨즺?섎㈃ ?섎룎由????놁뒿?덈떎.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('痍⑥냼', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              setState(() {
                _coupons[index]['isUsed'] = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('?ъ슜 ?꾨즺 泥섎━?섏뿀?듬땲??'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('?뺤씤', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

``

## File: lib\screens\upload_screen.dart
``dart
import 'package:flutter/material.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'channel_screen.dart';
import 'video_trim_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/cloudflare_service.dart';
import '../services/supabase_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/media_compressor.dart';
import 'package:path/path.dart' as p;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descAController = TextEditingController();
  final TextEditingController _descBController = TextEditingController();
  final TextEditingController _descController = TextEditingController(); // ?곸꽭?ㅻ챸 洹몃?濡??좎?
  final TextEditingController _tagsController = TextEditingController();

  String? _imagePathA;
  String? _imagePathB;
  String? _thumbPathA; // ?렗 ?곸긽 ?몃꽕??寃쎈줈 異붽?!
  String? _thumbPathB;
  int _selectedHours = 24;
  int _selectedMinutes = 0;
  bool _useTargetPick = false;
  final TextEditingController _targetPickController = TextEditingController(text: '100');
  
  bool _isAdult = false; // ?뵞 ?깆씤 肄섑뀗痢??щ?
  bool _isAI = false;    // ?쨼 AI ?앹꽦 ?щ?
  
  final ImagePicker _picker = ImagePicker();
  final CloudflareService _cloudflareService = CloudflareService();
  bool _isUploading = false;

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
        title: const Text('??吏덈Ц ?섍린', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          _isUploading 
            ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))))
            : TextButton(
                onPressed: _handleUpload,
                child: const Text('?깅줉', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 吏덈Ц ?쒕ぉ 釉붾줉
              _cardBlock(
                title: '吏덈Ц ?쒕ぉ',
                child: _inputField(_titleController, '臾댁뾿?????섏?吏 臾쇱뼱蹂댁꽭??),
              ),
              const SizedBox(height: 16),

            // 鍮꾧탳 ???諛??ㅻ챸 釉붾줉
            _cardBlock(
              title: '鍮꾧탳 ????낅줈??,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _abUploadCard('A', _imagePathA, (path) => setState(() => _imagePathA = path))),
                      const SizedBox(width: 12),
                      Expanded(child: _abUploadCard('B', _imagePathB, (path) => setState(() => _imagePathB = path))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _inputField(_descAController, 'A ?ㅻ챸 (?? 鍮④컯)', isSmall: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _inputField(_descBController, 'B ?ㅻ챸 (?? ?뚮옉)', isSmall: true)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ?곸꽭 ?ㅻ챸 釉붾줉
            _cardBlock(
              title: '?곸꽭 ?ㅻ챸 (?좏깮)',
              child: _inputField(_descController, '吏덈Ц????????먯꽭???뚮젮二쇱꽭??..', maxLines: 3),
            ),
            const SizedBox(height: 16),

            // 吏꾪뻾 ?쒓컙 諛?紐⑺몴 Pick 釉붾줉 (以묒슂 ?ㅼ젙 ?⑹뼱由?
            _cardBlock(
              title: '吏꾪뻾 ?ㅼ젙',
              child: Column(
                children: [
                  _durationPicker(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  _targetPickSelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ?쒓렇 釉붾줉
            _cardBlock(
              title: '?쒓렇',
              child: _inputField(_tagsController, '#?곗씪由щ） #?⑥뀡 #異붿쿇 (?대? 寃?됱슜)'),
            ),
            const SizedBox(height: 32),

            // ?뵞 ?깆씤/AI 肄섑뀗痢??ㅼ젙 (二쇱쓽?ы빆 諛붾줈 ??)
            _cardBlock(
              title: '肄섑뀗痢??ㅼ젙',
              child: _safetyOptions(),
            ),
            const SizedBox(height: 16),

            _precautionsBlock(),
            const SizedBox(height: 32),

            // ?섎떒 ????깅줉 踰꾪듉
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('吏덈Ц ?깅줉?섍린', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _cardBlock({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('?쒕ぉ???낅젰?댁＜?몄슂.')));
      return;
    }
    
    if (_imagePathA == null || _imagePathB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('??媛쒖쓽 ?대?吏瑜?紐⑤몢 ?낅줈?쒗빐二쇱꽭??')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // ?? 1. ?대?吏留??뺤텞 (?곸긽? ?몃┝ ?붾㈃?먯꽌 ?대? ?뺤텞+?ㅻ뵒?ㅼ궘???꾨즺!)
      File fileA = File(_imagePathA!);
      File fileB = File(_imagePathB!);

      bool isVideoA = _isVideo(_imagePathA!);
      bool isVideoB = _isVideo(_imagePathB!);

      File? compressedA = isVideoA ? fileA : await MediaCompressor.compressImage(fileA);
      File? compressedB = isVideoB ? fileB : await MediaCompressor.compressImage(fileB);

      // 2. R2 ?낅줈??(?뺤옣???묐삊?섍쾶 梨숆린湲?)
      final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
      final String randomStr = (DateTime.now().millisecond % 1000).toString().padLeft(3, '0');
      
      String extA = p.extension(_imagePathA!).toLowerCase();
      String extB = p.extension(_imagePathB!).toLowerCase();

      String? urlA = await _cloudflareService.uploadFile(
        compressedA ?? fileA, 
        'post_${timestamp}_${randomStr}_A$extA'
      );
      String? urlB = await _cloudflareService.uploadFile(
        compressedB ?? fileB, 
        'post_${timestamp}_${randomStr}_B$extB'
      );

      // ?? ?몃꽕???낅줈??異붽? (議댁옱??寃쎌슦)
      String? thumbUrlA;
      if (_thumbPathA != null) {
        thumbUrlA = await _cloudflareService.uploadFile(File(_thumbPathA!), 'post_${timestamp}_${randomStr}_thumbA.jpg');
      }
      String? thumbUrlB;
      if (_thumbPathB != null) {
        thumbUrlB = await _cloudflareService.uploadFile(File(_thumbPathB!), 'post_${timestamp}_${randomStr}_thumbB.jpg');
      }

      if (urlA == null || urlB == null) {
        throw Exception('?뚯씪 ?낅줈???ㅽ뙣');
      }

      // 2. Insert into Supabase
      final int totalMinutes = (_selectedHours * 60) + _selectedMinutes;
      final int? targetCount = _useTargetPick ? (int.tryParse(_targetPickController.text) ?? 100) : null;
      final List<String> finalTags = _tagsController.text.split(RegExp(r'[#,\s]+')).where((t) => t.isNotEmpty).toList();
      // Trick: Store duration and target count in tags since columns are missing
      finalTags.add('duration:$totalMinutes');
      if (targetCount != null) finalTags.add('target:$targetCount');
      if (_isAdult) finalTags.add('adult:true'); // ?뵞 ?깆씤 ?쒓렇 異붽?
      if (_isAI) finalTags.add('ai:true');       // ?쨼 AI ?쒓렇 異붽?

      final response = await SupabaseService.client.from('posts').insert({
        'title': _titleController.text,
        'uploader_id': gIdText,
        'uploader_internal_id': gUserInternalId, // 二쇰?踰덊샇 ?쒖뒪???꾩엯!
        'image_a': urlA,
        'image_b': urlB,
        if (thumbUrlA != null) 'thumb_a': thumbUrlA,
        if (thumbUrlB != null) 'thumb_b': thumbUrlB,
        'description_a': _descAController.text.isEmpty ? '?좏깮吏 A' : _descAController.text,
        'description_b': _descBController.text.isEmpty ? '?좏깮吏 B' : _descBController.text,
        'tags': finalTags,
      }).select().single();

      final newPost = PostData(
        id: response['id'].toString(),
        uploaderId: gIdText,
        uploaderInternalId: gUserInternalId, // ?넄 ?깅줉 ??二쇰?踰덊샇 湲곕줉!
        uploaderName: gNameText,
        uploaderImage: gProfileImage,
        title: _titleController.text,
        fullDescription: _descController.text,
        timeLocation: '諛⑷툑 ??,
        imageA: urlA,
        imageB: urlB,
        thumbA: thumbUrlA,
        thumbB: thumbUrlB,
        descriptionA: _descAController.text.isEmpty ? '?좏깮吏 A' : _descAController.text,
        descriptionB: _descBController.text.isEmpty ? '?좏깮吏 B' : _descBController.text,
        tags: finalTags,
        durationMinutes: totalMinutes,
        targetPickCount: targetCount,
        likesCount: 0,
        commentsCount: 0,
        voteCountA: '0',
        voteCountB: '0',
        percentA: '0%',
        percentB: '0%',
      );

      if (mounted) {
        // Return the new post to the previous screen (ChannelScreen) so it can be added to the list
        Navigator.pop(context, newPost);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_titleController.text}" 吏덈Ц???깅줉?섏뿀?듬땲??'),
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('?깅줉 ?ㅽ뙣: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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

  void _showImageSourceActionSheet(String label, Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('?낅줈??諛⑹떇 ?좏깮', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.cyanAccent),
              title: const Text('?ъ쭊 李띻린 (移대찓??', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (image != null) _handlePickedMedia(image.path, label, onPick, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.cyanAccent),
              title: const Text('媛ㅻ윭由ъ뿉???ъ쭊 ?좏깮', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (image != null) _handlePickedMedia(image.path, label, onPick, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.redAccent),
              title: const Text('媛ㅻ윭由ъ뿉???곸긽 ?좏깮', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
                if (video != null) _handlePickedMedia(video.path, label, onPick, isVideo: true);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePickedMedia(String path, String label, Function(String) onPick, {required bool isVideo}) async {
    if (isVideo) {
      // ?렗 ?곸긽 ?몃┝ ?붾㈃?쇰줈 ?대룞 (6珥??대궡 議곗젅 + ?뺤텞 + ?ㅻ뵒????젣)
      final File? trimmedFile = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoTrimScreen(file: File(path))),
      );

      if (trimmedFile == null) return; // 痍⑥냼 ??以묐떒

      final String finalPath = trimmedFile.path;

      // ?뼹截??몃┝???곸긽?쇰줈 ?몃꽕???앹꽦
      final thumbFile = await MediaCompressor.generateThumbnail(finalPath);
      
      if (mounted) {
        setState(() {
          if (label == 'A') {
            _imagePathA = finalPath;
            _thumbPathA = thumbFile?.path;
          } else {
            _imagePathB = finalPath;
            _thumbPathB = thumbFile?.path;
          }
        });
        onPick(finalPath);
      }
    } else {
      // ?벝 ?ъ쭊??寃쎌슦 湲곗〈泥섎읆 ?щ∼ 濡쒖쭅 媛??
      setState(() {
        if (label == 'A') _thumbPathA = null;
        else _thumbPathB = null;
      });
      final String? croppedPath = await _cropImage(path);
      if (croppedPath != null) onPick(croppedPath);
    }
  }

  Future<String?> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '?대?吏 ?몄쭛',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.cyanAccent,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false, 
          activeControlsWidgetColor: Colors.cyanAccent,
        ),
        IOSUiSettings(
          title: '?대?吏 ?몄쭛',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    return croppedFile?.path;
  }

  Widget _sectionTitle(String title) {
    return Text(
      title, 
      style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.5)
    );
  }

  Widget _inputField(TextEditingController controller, String hint, {int maxLines = 1, bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isSmall ? 15 : 20),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontSize: isSmall ? 13 : 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _abUploadCard(String label, String? path, Function(String) onPick) {
    String? thumbPath = (label == 'A') ? _thumbPathA : _thumbPathB;
    
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(label, onPick),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            image: (path != null || thumbPath != null)
              ? DecorationImage(
                  image: thumbPath != null 
                    ? FileImage(File(thumbPath)) 
                    : (path!.startsWith('http') 
                        ? NetworkImage(path) 
                        : FileImage(File(path)) as ImageProvider), 
                  fit: BoxFit.cover
                ) 
              : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (path == null && thumbPath == null) ...[
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.03), fontSize: 80, fontWeight: FontWeight.w900)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 32),
                    const SizedBox(height: 8),
                    Text('$label ?낅줈??, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              if (thumbPath != null) // ?곸긽??寃쎌슦 ?뚮젅???꾩씠肄??쒖떆
                const Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
              if (path != null || thumbPath != null)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationPicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('?쒓컙 ?좏깮', style: TextStyle(color: Colors.white38, fontSize: 11)),
              DropdownButton<int>(
                value: _selectedHours,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E1E),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
                items: List.generate(73, (i) => i).map((i) => DropdownMenuItem(
                  value: i,
                  child: Text('$i?쒓컙', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedHours = val ?? 0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('遺??좏깮', style: TextStyle(color: Colors.white38, fontSize: 11)),
              DropdownButton<int>(
                value: _selectedMinutes,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E1E),
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
                items: List.generate(60, (i) => i).map((i) => DropdownMenuItem(
                  value: i,
                  child: Text('$i遺?, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedMinutes = val ?? 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _targetPickSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('紐⑺몴 Pick 議곌린 留덇컧', style: TextStyle(color: Colors.white, fontSize: 14)),
            Switch(
              value: _useTargetPick, 
              onChanged: (v) => setState(() => _useTargetPick = v),
              activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.3),
              activeThumbColor: Colors.cyanAccent,
            ),
          ],
        ),
        if (_useTargetPick)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.ads_click_outlined, color: Colors.white38, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _targetPickController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '紐⑺몴 ?レ옄 ?낅젰',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Text('Pick ?꾨떖 ??留덇컧', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _safetyOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.explicit_outlined, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text('?깆씤 肄섑뀗痢??쒖떆', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            Switch(
              value: _isAdult, 
              onChanged: (v) => setState(() => _isAdult = v),
              activeTrackColor: Colors.redAccent.withValues(alpha: 0.3),
              activeThumbColor: Colors.redAccent,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_outlined, color: Colors.cyanAccent, size: 20),
                SizedBox(width: 8),
                Text('AI ?앹꽦 肄섑뀗痢??쒖떆', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            Switch(
              value: _isAI, 
              onChanged: (v) => setState(() => _isAI = v),
              activeTrackColor: Colors.cyanAccent.withValues(alpha: 0.3),
              activeThumbColor: Colors.cyanAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _precautionsBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white38, size: 16),
              SizedBox(width: 8),
              Text('?낅줈????二쇱쓽?ы빆', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('????몄쓽 ??묎텒??移⑦빐?섍굅??遺덉풄媛먯쓣 二쇰뒗 肄섑뀗痢좊뒗 ?쒖옱?????덉뒿?덈떎.', style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('???덉쐞 ?ъ떎 ?좏룷??遺?곸젅???쒓렇 ?ъ슜 ??寃뚯떆臾쇱씠 ??젣?????덉뒿?덈떎.', style: TextStyle(color: Colors.white24, fontSize: 11)),
          Text('??吏꾪뻾 ?쒓컙? ?깅줉 ???섏젙??遺덇??ν븯???좎쨷???좏깮?댁＜?몄슂.', style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}

``

## File: lib\screens\video_trim_screen.dart
``dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/media_compressor.dart';

class VideoTrimScreen extends StatefulWidget {
  final File file;
  const VideoTrimScreen({super.key, required this.file});

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isExporting = false;

  double _totalDurationMs = 1000;
  double _startMs = 0;
  double _endMs = 6000;
  static const double _maxDurationMs = 6000; // 6珥?理쒕?
  static const double _minDurationMs = 500;  // 0.5珥?理쒖냼

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.file(widget.file);
    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.setVolume(0);

    final totalMs = _controller.value.duration.inMilliseconds.toDouble();
    setState(() {
      _isInitialized = true;
      _totalDurationMs = totalMs;
      _startMs = 0;
      _endMs = totalMs.clamp(0, _maxDurationMs);
    });

    _controller.play();
    _controller.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!mounted || !_isInitialized) return;
    final posMs = _controller.value.position.inMilliseconds.toDouble();

    // ?좏깮 援ш컙??踰쀬뼱?섎㈃ ?쒖옉?먯쑝濡??섎룎由ш린
    if (posMs >= _endMs || posMs < _startMs) {
      _controller.seekTo(Duration(milliseconds: _startMs.toInt()));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleExport() async {
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      // ?렗 ?ㅼ젣濡?援ш컙??議곗젙?덈뒗吏 ?먮떒
      final bool didTrim = (_startMs > 100) || (_endMs < _totalDurationMs - 100);
      
      File? resultFile;
      if (didTrim) {
        // ?귨툘 ?ㅼ젣濡??섎옄???뚮쭔 ?몃┝+?뺤텞
        if (kDebugMode) debugPrint('DEBUG [TRIM]: 援ш컙 ?먮Ⅴ湲?紐⑤뱶 (${_startMs}ms ~ ${_endMs}ms)');
        resultFile = await MediaCompressor.trimAndCompress(
          widget.file,
          _startMs.toInt(),
          (_endMs - _startMs).toInt(),
        );
      } else {
        // ?렗 ???섎옄?쇰㈃ ?⑥닚 ?뺤텞+?ㅻ뵒?ㅼ궘?쒕쭔 (?덉젙??)
        if (kDebugMode) debugPrint('DEBUG [TRIM]: ?꾩껜 ?뺤텞 紐⑤뱶 (?몃┝ ?놁쓬)');
        resultFile = await MediaCompressor.compressVideo(widget.file);
      }

      if (mounted) {
        setState(() => _isExporting = false);
        if (resultFile != null) {
          Navigator.pop(context, resultFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('?곸긽 ?몄쭛???ㅽ뙣?덉뒿?덈떎.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('?ㅻ쪟: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatMs(double ms) {
    final seconds = (ms / 1000).floor();
    final fraction = ((ms % 1000) / 100).floor();
    return '$seconds.${fraction}s';
  }

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
        title: const Text(
          '?곸긽 ?먮Ⅴ湲?,
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          if (_isInitialized && !_isExporting)
            TextButton(
              onPressed: _handleExport,
              child: const Text('?꾨즺', style: TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
              ),
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Stack(
              children: [
                Column(
                  children: [
                    // ?렗 ?곸긽 誘몃━蹂닿린
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller.value.size.width / _controller.value.size.height,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                    ),

                    // ?럾截??섎떒 而⑦듃濡??⑤꼸
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ?ъ깮/?쇱떆?뺤? + ?쒓컙 ?뺣낫
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // ?ъ깮 踰꾪듉
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (_controller.value.isPlaying) {
                                      _controller.pause();
                                    } else {
                                      _controller.seekTo(Duration(milliseconds: _startMs.toInt()));
                                      _controller.play();
                                    }
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(
                                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.cyanAccent,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                // ?좏깮 援ш컙 ?쒖떆
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.content_cut, color: Colors.cyanAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatMs(_endMs - _startMs),
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 理쒕? 6珥??덈궡
                                Text(
                                  '理쒕? 6.0s',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ?쒖옉/???쒓컙 ?쇰꺼
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatMs(_startMs),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatMs(_endMs),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // ?럻截?而ㅼ뒪? Range Slider
                            SliderTheme(
                              data: SliderThemeData(
                                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                                activeTrackColor: Colors.cyanAccent,
                                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                                overlayColor: Colors.cyanAccent.withValues(alpha: 0.15),
                                thumbColor: Colors.cyanAccent,
                                trackHeight: 6,
                                rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
                                valueIndicatorColor: Colors.cyanAccent,
                                valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                showValueIndicator: ShowValueIndicator.onDrag,
                              ),
                              child: RangeSlider(
                                values: RangeValues(_startMs, _endMs),
                                min: 0,
                                max: _totalDurationMs,
                                divisions: (_totalDurationMs / 100).floor().clamp(1, 1000),
                                labels: RangeLabels(_formatMs(_startMs), _formatMs(_endMs)),
                                onChanged: (values) {
                                  double newStart = values.start;
                                  double newEnd = values.end;
                                  double selectionDuration = newEnd - newStart;

                                  // 理쒕? 6珥??쒗븳
                                  if (selectionDuration > _maxDurationMs) {
                                    // ?대뒓 履쎌쓣 ?吏곸??붿? ?먮떒
                                    if ((newStart - _startMs).abs() > (newEnd - _endMs).abs()) {
                                      newEnd = newStart + _maxDurationMs;
                                      if (newEnd > _totalDurationMs) {
                                        newEnd = _totalDurationMs;
                                        newStart = newEnd - _maxDurationMs;
                                      }
                                    } else {
                                      newStart = newEnd - _maxDurationMs;
                                      if (newStart < 0) {
                                        newStart = 0;
                                        newEnd = _maxDurationMs;
                                      }
                                    }
                                  }

                                  // 理쒖냼 0.5珥??쒗븳
                                  if (newEnd - newStart < _minDurationMs) return;

                                  setState(() {
                                    _startMs = newStart;
                                    _endMs = newEnd;
                                  });

                                  // ?щ씪?대뜑 議곗젙 ???쒖옉?먯쑝濡??대룞
                                  _controller.seekTo(Duration(milliseconds: newStart.toInt()));
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ?꾨줈洹몃젅??諛?(?꾩옱 ?ъ깮 ?꾩튂)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _endMs > _startMs
                                      ? ((_controller.value.position.inMilliseconds - _startMs) / (_endMs - _startMs)).clamp(0, 1)
                                      : 0,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation(Colors.cyanAccent.withValues(alpha: 0.5)),
                                  minHeight: 3,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ?섎떒 ?덈궡 ?띿뒪??                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) => Opacity(
                                opacity: 0.3 + (_pulseController.value * 0.4),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swipe, color: Colors.white38, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      '?묒そ ?몃뱾???쒕옒洹명븯??援ш컙???좏깮?섏꽭??,
                                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ?봽 ?대낫?닿린 以??ㅻ쾭?덉씠
                if (_isExporting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
                          const SizedBox(height: 20),
                          const Text(
                            '?곸긽???ㅻ벉怨??덉뼱??..',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '?뚮━ ?쒓굅 쨌 ?뺤텞 쨌 ?먮Ⅴ湲?,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

``

## File: lib\services\cloudflare_service.dart
``dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/supabase_config.dart';

class CloudflareService {
  final Dio _dio = Dio();

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      String uploadUrl = CloudflareConfig.workerUrl;
      
      if (kDebugMode) debugPrint('DEBUG [UPLOAD]: Attempting POST upload to $uploadUrl with filename: $fileName');

      // ?? POST 諛⑹떇 + FormData濡??ъ옣?댁꽌 ?꾩넚!
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        uploadUrl,
        data: formData,
      );

      if (kDebugMode) debugPrint('DEBUG [UPLOAD]: Server response -> ${response.statusCode}');

      if (response.statusCode == 200) {
        // ?렞 ??ν븷 ?뚮뒗 CDN 二쇱냼濡?由ы꽩
        return '${CloudflareConfig.cdnUrl}$fileName';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG [UPLOAD]: ERROR -> $e');
    }
    return null;
  }

  String _getContentType(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}

``

## File: lib\services\media_compressor.dart
``dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaCompressor {
  
  /// ?벝 ?대?吏 ?뺤텞 (?붿쭏? ?대━怨??⑸웾? 1/10 ?좊쭑!)
  static Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
      
    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG [COMPRESS]: ?대?吏 ?뺤텞 ?ㅽ뙣 - $e');
      return file;
    }
  }

  /// ?렗 鍮꾨뵒???뺤텞 + ?ㅻ뵒???꾩쟾 ??젣 (6珥?吏㏃? ?곸긽 ?꾩슜)
  static Future<File?> compressVideo(File file) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: false, // ?뵁 ?뚮━ ?꾩쟾 ??젣!
      );

      if (mediaInfo == null || mediaInfo.file == null) return null;
      return mediaInfo.file;

    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG [COMPRESS]: ?곸긽 ?뺤텞 ?ㅽ뙣 - $e');
      return file; // ?뺤텞 ?ㅽ뙣?대룄 ?먮낯?쇰줈 吏꾪뻾
    }
  }

  /// ?뼹截?鍮꾨뵒???몃꽕???앹꽦 (泥??꾨젅??
  static Future<File?> generateThumbnail(String videoPath) async {
    try {
      final thumbFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 50,
        position: -1, // 泥??꾨젅??      );
      return thumbFile;
    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG [THUMBNAIL]: ?몃꽕???앹꽦 ?ㅽ뙣 - $e');
      return null;
    }
  }

  /// ?귨툘 鍮꾨뵒???몃┝ + ?뺤텞 + ?ㅻ뵒????젣 (?ъ씤??)
  static Future<File?> trimAndCompress(File file, int startMs, int durationMs) async {
    try {
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        startTime: startMs ~/ 1000,     // 珥??⑥쐞濡?蹂??        duration: durationMs ~/ 1000,   // 珥??⑥쐞濡?蹂??        deleteOrigin: false,
        includeAudio: false, // ?뵁 ?뚮━ ?꾩쟾 ??젣!
      );

      if (mediaInfo == null || mediaInfo.file == null) return null;
      return mediaInfo.file;

    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG [TRIM]: ?곸긽 ?몃┝+?뺤텞 ?ㅽ뙣 - $e');
      return file; // ?ㅽ뙣 ???먮낯 諛섑솚
    }
  }
}

``

## File: lib\services\supabase_service.dart
``dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

``

## File: lib\widgets\post_view.dart
``dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:io'; // ?? ?뚯씪 泥섎━瑜??꾪빐 異붽?!
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
  bool _showIsMeToast = false; // ?슟 蹂몄씤 寃뚯떆臾??뚮┝??異붽?!
  bool _isSheetOpening = false;
  
  // ?렗 ?곸긽 ?ъ깮 ?쒖뒪??(v2.0 - 源붾걫 ?ш뎄異?
  VideoPlayerController? _controllerA;
  VideoPlayerController? _controllerB;
  bool _isInitializedA = false;
  bool _isInitializedB = false;
  bool _isInitializingA = false;
  bool _isInitializingB = false;
  int _playingSide = 0; // 0: ?놁쓬, 1: A?ъ깮以? 2: B?ъ깮以?
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
    if (kDebugMode) debugPrint('DEBUG: PostView State initialized for post_id: ${widget.post.id} (Ver. 1.0)');
    
    // ?댁쟾 ?ы몴 ?댁뿭 遺덈윭?ㅺ린
    _votedSide = gUserVotes[widget.post.id] ?? 0;
    
    _updateRemainingTime();
    _startTimer();

    // ?렗 ?곸긽 珥덇린?붾뒗 ?붾㈃??蹂댁씪 ??VisibilityDetector)?먯꽌 ?먮룞 泥섎━!
  }

  // ?렗 紐⑤뱺 ?곸긽 由ъ냼???댁젣
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

  // ?렗 ?곸긽 珥덇린??(?ㅽ듃?뚰겕 URL 吏곸젒 ?ъ슜, 6珥??곸긽?대씪 鍮좊쫫)
  Future<void> _initVideo(String url, int side) async {
    if (!_isVideo(url)) return;
    if (side == 1 && (_isInitializedA || _isInitializingA)) return;
    if (side == 2 && (_isInitializedB || _isInitializingB)) return;

    if (side == 1) _isInitializingA = true;
    else _isInitializingB = true;

    try {
      if (kDebugMode) debugPrint('DEBUG [VIDEO v2]: Side $side 珥덇린???쒖옉 - $url');
      
      // ?? 罹먯떆 留ㅻ땲?濡?癒쇱? ?ㅼ슫濡쒕뱶 ??濡쒖뺄 ?뚯씪濡??ъ깮 (?덉젙??UP)
      final file = await DefaultCacheManager().getSingleFile(url);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0); // ?뵁 ?뚯냼嫄?(?뚮━???낅줈?????대? ??젣??
      
      // ?렗 ?곸긽 ??媛먯? 由ъ뒪??
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

      // ?렗 A媛 以鍮꾨릺硫??먮룞 ?ъ깮 ?쒖옉!
      if (side == 1 && _playingSide == 0) {
        _switchToSide(1);
      }
      
      if (kDebugMode) debugPrint('DEBUG [VIDEO v2]: Side $side 珥덇린???꾨즺!');
    } catch (e) {
      if (side == 1) _isInitializingA = false;
      else _isInitializingB = false;
      if (kDebugMode) debugPrint('DEBUG [VIDEO v2]: Side $side 珥덇린???ㅽ뙣 - $e');
    }
  }

  // ?렗 ?곸긽 ?ъ깮 ?꾨즺 ??泥섎━ (臾댄븳 猷⑦봽 濡쒖쭅)
  void _onVideoFinished(int side) {
    if (!mounted) return;
    
    // ?렗 ?꾩옱 ?대뼡 ?ъ씠?쒓? ?뺤옣?섏뼱 ?덈뒗吏 泥댄겕
    double ratioA = (_widthA ?? (MediaQuery.of(context).size.width * 0.5)) / MediaQuery.of(context).size.width;

    if (side == 1) {
      if (kDebugMode) debugPrint('DEBUG [VIDEO v2]: A ?곸긽 醫낅즺');
      _controllerA?.pause();
      _controllerA?.seekTo(Duration.zero);
      
      if (ratioA >= 0.55) {
        // A媛 ?뺤옣???곹깭?쇰㈃ A 臾댄븳 諛섎났
        _switchToSide(1);
      } else if (ratioA <= 0.45) {
        // B媛 ?뺤옣???곹깭?몃뜲 A媛 ?앸궃 嫄?臾댁떆 (?대? B ?ъ깮 以묒씪 寃?
      } else {
        // 以묒븰 ?곹깭?쇰㈃ B濡??꾪솚 (?쒖감 猷⑦봽)
        _switchToSide(2);
      }
    } else if (side == 2) {
      if (kDebugMode) debugPrint('DEBUG [VIDEO v2]: B ?곸긽 醫낅즺');
      _controllerB?.pause();
      _controllerB?.seekTo(Duration.zero);

      if (ratioA <= 0.45) {
        // B媛 ?뺤옣???곹깭?쇰㈃ B 臾댄븳 諛섎났
        _switchToSide(2);
      } else if (ratioA >= 0.55) {
        // A媛 ?뺤옣???곹깭?몃뜲 B媛 ?앸궃 嫄?臾댁떆
      } else {
        // 以묒븰 ?곹깭?쇰㈃ ?ㅼ떆 A濡??꾪솚 (?쒖감 猷⑦봽 A->B->A...)
        _switchToSide(1);
      }
    }
  }

  // ?렗 ?뱀젙 ?ъ씠?쒕줈 利됱떆 ?꾪솚 (?곗튂/?щ씪?대뱶 ???몄텧)
  void _switchToSide(int side) {
    if (!mounted) return;
    
    if (side == 1 && _isInitializedA && _controllerA != null) {
      _controllerB?.pause(); // B??蹂대뜕 ?꾩튂?먯꽌 ?쇱떆?뺤?
      // ?? 蹂대뜕 ?꾩튂?먯꽌 Resume! (?꾩쟾???앸궗???뚮쭔 ?꾩뿉??0珥덈줈 媛?
      _controllerA!.play();
      setState(() => _playingSide = 1);
    } else if (side == 2 && _isInitializedB && _controllerB != null) {
      _controllerA?.pause(); // A??蹂대뜕 ?꾩튂?먯꽌 ?쇱떆?뺤?
      // ?? 蹂대뜕 ?꾩튂?먯꽌 Resume!
      _controllerB!.play();
      setState(() => _playingSide = 2);
    }
  }

  // ?렗 ?붾㈃ 吏꾩엯 ???곸긽 ?쒖옉
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
    _controllerA?.dispose(); // ?렗 ?곸긽 由ъ냼???댁젣 ?꾩닔!
    _controllerB?.dispose();
    super.dispose();
  }

  bool get isMe {
    // ?넄 ?ㅼ쭅 二쇰?踰덊샇(UUID) ?섎굹濡쒕쭔 ?먮떒 (吏꾩쭨 ?뺤꽍!)
    String nId(String? s) => (s ?? '').trim().toLowerCase();
    if (widget.post.uploaderInternalId != null && gUserInternalId != null) {
      if (nId(widget.post.uploaderInternalId) == nId(gUserInternalId)) return true;
    }
    // ?덉쇅/?덉쟾?μ튂 (?꾩씠??湲곕컲)
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    return normalized(widget.post.uploaderId) == normalized('?섏쓽 ?쎄쿊') || 
           widget.post.uploaderId == 'me' || 
           normalized(widget.post.uploaderId) == normalized(gIdText);
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('寃뚯떆臾???젣', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('??寃뚯떆臾쇱쓣 ?뺣쭚 ??젣?섏떆寃좎뒿?덇퉴? ??젣 ?꾩뿉??蹂듦뎄?????놁뒿?덈떎.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('痍⑥냼', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('??젣', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final String postId = widget.post.id; // UUID 臾몄옄??洹몃?濡??ъ슜

        // ?뵦 [?듭떖] ?몃옒 ???쒖빟 ?뚮Ц???곌? ?곗씠??癒쇱? ??젣 ??寃뚯떆臾???젣!
        await Future.wait([
          SupabaseService.client.from('votes').delete().eq('post_id', postId),
          SupabaseService.client.from('comments').delete().eq('post_id', postId),
          SupabaseService.client.from('likes').delete().eq('post_id', postId),
          SupabaseService.client.from('bookmarks').delete().eq('post_id', postId),
        ]);

        // ?곌? ?곗씠????젣 ?꾨즺 ??寃뚯떆臾???젣
        await SupabaseService.client.from('posts').delete().eq('id', postId);

        widget.onDelete(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('寃뚯떆臾쇱씠 ??젣?섏뿀?듬땲??')));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Delete error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('??젣 以??ㅻ쪟媛 諛쒖깮?덉뒿?덈떎.')));
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
    Future.delayed(const Duration(milliseconds: 1000), () { // ?깍툘 ?쒓컙 1珥덈줈 ?⑥텞!
      if (mounted) setState(() => _showAlreadySelectedToast = false);
    });
  }

  void _showIsMeMessage() {
    if (_showIsMeToast) return;
    setState(() => _showIsMeToast = true);
    Future.delayed(const Duration(milliseconds: 1000), () { // ?깍툘 1珥덈쭔 ?붾쪟!
      if (mounted) setState(() => _showIsMeToast = false);
    });
  }

  // ?썳截?吏꾩쭨 ?좏슚???ㅻ챸湲?몄? ?뺤씤?섎뒗 ?먮퀎湲?
  bool _isValidDescription(String? text) {
    if (text == null) return false;
    final clean = text.trim();
    if (clean.isEmpty) return false;
    // ?섎? ?녿뒗 湲곕낯媛믩뱾?대굹 怨듬갚留??덈뒗 寃쎌슦 李⑤떒!
    final blackList = [
      "?댁슜???낅젰?섏꽭??, "?댁슜 ?놁쓬", "?댁슜???놁뒿?덈떎", "?ㅻ챸???낅젰?섏꽭??,
      "?좏깮吏A", "?좏깮吏B", "?좏깮吏 A", "?좏깮吏 B"
    ];
    if (blackList.contains(clean)) return false;
    return clean.length > 1; // 理쒖냼 2湲?먮뒗 ?섏뼱????
  }

  void _onVote(int side) async {
    if (!gIsLoggedIn) {
      gShowLoginPopup?.call();
      return;
    }
    if (_votedSide != 0) return;
    
    // ?넄 ?ㅼ쭅 二쇰?踰덊샇(UUID) ?섎굹濡쒕쭔 ?먮떒 (吏꾩쭨 ?뺤꽍!)
    String normalized(String? s) => (s ?? '').trim().toLowerCase();
    bool isMe = (widget.post.uploaderInternalId != null && gUserInternalId != null && 
                 normalized(widget.post.uploaderInternalId) == normalized(gUserInternalId));
    
    if (kDebugMode) debugPrint('DEBUG [VOTE]: gUserInternalId=$gUserInternalId, postUploaderInternalId=${widget.post.uploaderInternalId}, isMe=$isMe');

    if (isMe) {
      _showIsMeMessage(); // ?? SnackBar ????꾩슜 ?좎뒪???몄텧!
      HapticFeedback.vibrate(); // 吏꾨룞?쇰줈 ?쇰뱶諛?
      return;
    }

    // ?뮶 吏꾩쭨 ?ы몴 諛??ъ씤???곷┰ 濡쒖쭅 (?뺤꽍!)
    try {
      // 1. ?ы몴 湲곕줉 ???
      await SupabaseService.client.from('votes').insert({
        'post_id': widget.post.id,
        'user_internal_id': gUserInternalId, // ?넄 二쇰?踰덊샇 湲곕줉!
        'side': side,
      });

      // 2. ?ъ씤???곷┰ (+10P)
      await SupabaseService.client.from('points_history').insert({
        'user_internal_id': gUserInternalId, // ?넄 二쇰?踰덊샇 湲곕줉!
        'amount': 10,
        'description': '吏덈Ц 李몄뿬 蹂대꼫??,
      });

      // 3. ?????먯닔 利됱떆 諛섏쁺
      if (mounted) {
        setState(() {
          gUserPoints += 10;
        });
      }
      if (kDebugMode) debugPrint('DEBUG [VOTE]: Real vote and 10P recorded. DB trigger will handle counts.');
    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG [VOTE]: Error recording vote: $e');
    }

    setState(() {
      _votedSide = side;
      gUserVotes[widget.post.id] = side; // ?꾩뿭 ?곹깭??利됱떆 諛섏쁺
      
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
      
      // ?렗 ?ㅼ떆媛??곸긽 ?꾪솚 泥댄겕 (55% ?댁긽 ?대━硫?利됱떆 ?ъ깮)
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
        if (_expandedSide == 1) { _expandedSide = 0; _widthA = sw * 0.5; }
        else { _expandedSide = 1; _widthA = sw * 0.8; }
      } else {
        if (_expandedSide == 2) { _expandedSide = 0; _widthA = sw * 0.5; }
        else { _expandedSide = 2; _widthA = sw * 0.2; }
      }
    });
    HapticFeedback.lightImpact();
    
    // ?렗 ?곗튂 ?쒖뿉??利됱떆 ?꾪솚 泥댄겕 (55% 湲곗? ?곸슜)
    double ratioA = (_widthA ?? (sw * 0.5)) / sw;
    if (ratioA >= 0.55) {
      _switchToSide(1);
    } else if (ratioA <= 0.45) {
      _switchToSide(2);
    } else {
      // 以묒븰 ?곹깭(0.5)???뚮뒗 A?묪 ?쒖감 ?ъ깮 ?먮쫫???곕쫫 (?대? ?ъ깮 以묒씠硫??좎?)
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
                  // ?쇱そ A 援ъ뿭 (李쎈Ц ??븷)
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: currentWidthA, 
                    height: sh,
                    clipBehavior: Clip.hardEdge, // 李쎈Ц 諛뽰쑝濡??섍???嫄??먮쫫
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      children: [
                        // 諛곌꼍 釉붾윭 (李쎈Ц ?ㅼ뿉 苑?李?
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: _buildMedia(1, widget.post.imageA, sw, thumbUrl: widget.post.thumbA, forceThumb: true),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        // ?꾧꼍 ?대?吏 (李쎈Ц ?덈퉬???곴??놁씠 80% ?ш린濡?怨좎젙?섏뼱 ?덉쓬)
                        Center(
                          child: OverflowBox(
                            maxWidth: sw * 0.8, // ?대?吏????긽 ?붾㈃??80% ?ш린!
                            minWidth: sw * 0.8,
                            child: _buildMedia(1, widget.post.imageA, sw, thumbUrl: widget.post.thumbA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ?ㅻⅨ履?B 援ъ뿭 (李쎈Ц ??븷)
                  AnimatedContainer(
                    duration: _isDragging ? Duration.zero : const Duration(milliseconds: 400), 
                    curve: Curves.easeOutCubic, 
                    width: (sw - currentWidthA).clamp(0.0, sw), 
                    height: sh,
                    clipBehavior: Clip.hardEdge, // 李쎈Ц 諛뽰쑝濡??섍???嫄??먮쫫
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      children: [
                        // 諛곌꼍 釉붾윭
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: _buildMedia(2, widget.post.imageB, sw, thumbUrl: widget.post.thumbB, forceThumb: true),
                          ),
                        ),
                        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),
                        // ?꾧꼍 ?대?吏 (80% ?ш린濡?怨좎젙)
                        Center(
                          child: OverflowBox(
                            maxWidth: sw * 0.8, // ?대?吏????긽 ?붾㈃??80% ?ш린!
                            minWidth: sw * 0.8,
                            child: _buildMedia(2, widget.post.imageB, sw, thumbUrl: widget.post.thumbB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 2. 以묒븰 VS ?꾩씠肄?
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
                      padding: const EdgeInsets.only(left: 20, right: 0), // ?곗륫 ?щ갚??0?쇰줈 ?섍퀬 踰꾪듉 ?대??먯꽌 泥섎━
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const SizedBox(width: 40), // 醫뚯슦 諛몃윴?ㅻ? 留욎떠 ?쒕ぉ 以묒븰 ?뺣젹 ?좎? (20+40=60)
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown, 
                                child: Text(
                                  widget.post.title.replaceAll('[醫낅즺] ', ''),
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
                            padding: EdgeInsets.zero,
                            child: Container(
                              width: 60, height: 60, // ?곗튂 ?곸뿭??60x60?쇰줈 ????뺤옣
                              color: Colors.transparent, // ?щ챸??二쇰? ?곸뿭 ?대뵒瑜??뚮윭???곗튂?섍쾶 ??
                              alignment: Alignment.center,
                              child: const Icon(Icons.more_vert, color: Colors.white70, size: 30),
                            ),
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            onSelected: (value) {
                              if (value == '?ㅻ챸') {
                                _showDescriptionSheet(context);
                              } else if (value == '愿?ъ뾾??) {
                                widget.onNotInterested();
                              } else if (value == '梨꾨꼸 異붿쿇 ?덊븿') {
                                widget.onDontRecommendChannel();
                              } else if (value == '?좉퀬') {
                                _showReportSheet(context);
                              } else if (value == '??젣') {
                                _deletePost();
                              } else if (value == '?④린湲? || value == '蹂댁씠湲?) {
                                widget.onToggleHide(widget.post.id);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              if (isMe) {
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(value: '?ㅻ챸', child: Row(children: [Icon(Icons.info_outline, color: Colors.white70, size: 20), SizedBox(width: 12), Text('?ㅻ챸', style: TextStyle(color: Colors.white, fontSize: 14))])),
                                  PopupMenuItem<String>(value: widget.post.isHidden ? '蹂댁씠湲? : '?④린湲?, child: Row(children: [Icon(widget.post.isHidden ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 20), SizedBox(width: 12), Text(widget.post.isHidden ? '蹂댁씠湲? : '?④린湲?, style: const TextStyle(color: Colors.white, fontSize: 14))])),
                                  const PopupMenuItem<String>(value: '??젣', child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('??젣', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold))])),
                                ];
                              } else {
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(value: '?ㅻ챸', child: Row(children: [Icon(Icons.info_outline, color: Colors.white70, size: 20), SizedBox(width: 12), Text('?ㅻ챸', style: TextStyle(color: Colors.white, fontSize: 14))])),
                                  const PopupMenuItem<String>(value: '愿?ъ뾾??, child: Row(children: [Icon(Icons.block, color: Colors.white70, size: 20), SizedBox(width: 12), Text('愿?ъ뾾??, style: TextStyle(color: Colors.white, fontSize: 14))])),
                                  const PopupMenuItem<String>(value: '梨꾨꼸 異붿쿇 ?덊븿', child: Row(children: [Icon(Icons.person_off_outlined, color: Colors.white70, size: 20), SizedBox(width: 12), Text('梨꾨꼸 異붿쿇 ?덊븿', style: TextStyle(color: Colors.white, fontSize: 14))])),
                                  const PopupMenuItem<String>(value: '?좉퀬', child: Row(children: [Icon(Icons.report_gmailerrorred, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('?좉퀬', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold))])),
                                ];
                              }
                            },
                          ), // PopupMenuButton
                        ]
                      )
                    ),
                    const SizedBox(height: 12),
                    Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.access_time, color: isExpired ? Colors.white38 : Colors.cyanAccent, size: 18), const SizedBox(width: 6), Text(isExpired ? '?좏깮醫낅즺' : _formatTimer(_remainingSeconds), style: TextStyle(color: isExpired ? Colors.white38 : Colors.white, fontWeight: FontWeight.w900, fontSize: 12))]))),
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
                                '?좏깮 ?꾩뿉??蹂寃쏀븷 ???놁뒿?덈떎',
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
                  // ?? ?먮퀎湲곕? ?듦낵??'吏꾩쭨 ?댁슜'???덉쓣 ?뚮쭔 ?쒕옒洹??대┃ ???몄텧!
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
                  // ?? ?먮퀎湲곕? ?듦낵??'吏꾩쭨 ?댁슜'???덉쓣 ?뚮쭔 ?쒕옒洹??대┃ ???몄텧!
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
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28, 
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
                            if (kDebugMode) debugPrint('DEBUG: Comment icon tapped for post_id: ${widget.post.id}');
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('怨듭쑀 留곹겕媛 蹂듭궗?섏뿀?듬땲??'), duration: Duration(seconds: 1)));
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
                        '?대? ?좏깮??肄섑뀗痢좎엯?덈떎',
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
                                  '蹂몄씤 吏덈Ц?먮뒗 ?ы몴?????놁뼱??',
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
                      const Text('?곸꽭 ?ㅻ챸', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
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
      if (kDebugMode) debugPrint('DEBUG: Fetching comments for post_id: ${widget.post.id}');
      final List<dynamic> data = await SupabaseService.client
          .from('comments')
          .select()
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);
      
      if (kDebugMode) debugPrint('DEBUG: Fetched ${data.length} comments from server.');
      
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
          user: (profile != null) ? (profile['nickname'] ?? '?듬챸') : (json['user_name'] ?? '?듬챸'),
          userId: json['user_id'] ?? '',
          userInternalId: json['user_internal_id']?.toString(), // ?넄 二쇰?踰덊샇 遺덈윭?ㅺ린
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
      if (kDebugMode) debugPrint('DEBUG: Total recursive comment count: $totalCount');

      // Sync correctly calculated count back to posts table
      try {
        if (kDebugMode) debugPrint('DEBUG: Syncing comments_count ($totalCount) to Supabase posts table for post_id: ${widget.post.id}');
        await SupabaseService.client
          .from('posts')
          .update({'comments_count': totalCount})
          .eq('id', widget.post.id);
        if (kDebugMode) debugPrint('DEBUG: Sync SUCCESS!');
      } catch (e) {
        if (kDebugMode) debugPrint('DEBUG: Sync FAILED! Error: $e');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG: Fetch comments FAILED! Error: $e');
      _isSheetOpening = false;
      return;
    }

    // ?넄 二쇰?踰덊샇 湲곕컲 二쇱씤 ?뺤씤 (吏꾩쭨 ?뺤꽍!)
    bool isMe = (widget.post.uploaderInternalId != null && gUserInternalId != null && 
                 widget.post.uploaderInternalId!.trim().toLowerCase() == gUserInternalId!.trim().toLowerCase());
    
    if (kDebugMode) debugPrint('DEBUG [COMMENT]: gUserInternalId=$gUserInternalId, postUploaderInternalId=${widget.post.uploaderInternalId}, isMe=$isMe, _votedSide=$_votedSide, isExpired=$isExpired');
    if (_votedSide == 0 && !isExpired && !isMe) {
      if (kDebugMode) debugPrint('DEBUG [COMMENT]: BLOCKED! Showing AlertDialog.');
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('?좏깮 ??李몄뿬 媛??, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: const Text('?볤????뺤씤?섍퀬 ?섍껄???섎늻?ㅻ㈃\n癒쇱? ?대뒓 履쎌씠??Pick ?댁＜?몄슂!', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('?뺤씤', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
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
                  const Text('?볤?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
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
                Text('${replyingTo.user}?섏뿉寃??듦? ?④린??以?..', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                        
                        // ?넄 吏꾩쭨 二쇱씤 ?뺤씤 (?뺤꽍!)
                        bool isMe = (widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId);
                        
                        // ?쇰컲 ?좎????ы몴 ?꾩닔! ?? 二쇱씤?섏씠嫄곕굹 ?ы몴 醫낅즺??湲? ?꾨━?⑥뒪!
                        if (_votedSide == 0 && !isMe && !isExpired) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('?ы몴瑜?癒쇱? ?댁＜?몄슂!')));
                          return;
                        }

                        final newComment = CommentData(
                          user: gNameText, 
                          userId: gIdText,
                          userInternalId: gUserInternalId, // ?넄 二쇰?踰덊샇 ?μ갑!
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

                          // ??[?쒕??섏씠 ?꾨줈 X ?뺤꽍 濡쒕큸] 寃뚯떆臾??뚯씠釉붿쓽 ?볤? ?レ옄???ㅼ떆媛??낅뜲?댄듃!
                          await SupabaseService.client
                            .from('posts')
                            .update({'comments_count': widget.post.commentsCount})
                            .eq('id', widget.post.id);

                        } catch (e) {
                          if (kDebugMode) debugPrint('?볤? ???諛??レ옄 ?낅뜲?댄듃 ?ㅽ뙣: $e');
                        }
                      }
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: (_votedSide == 0 && !((widget.post.uploaderInternalId != null && widget.post.uploaderInternalId == gUserInternalId) || 
                                 (widget.post.uploaderId.replaceAll(RegExp(r'[@\s_]'), '').trim() == gIdText.replaceAll(RegExp(r'[@\s_]'), '').trim()))) 
                                 ? '?ы몴 ???볤????④꺼二쇱꽭?? 
                                 : '?볤????낅젰?섏꽭??..',
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('?ы몴瑜?癒쇱? ?댁＜?몄슂!')));
                      return;
                    }

                    final newComment = CommentData(
                      user: gNameText, 
                      userId: gIdText,
                      userInternalId: gUserInternalId, // ?넄 二쇰?踰덊샇 ?μ갑!
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

                      // ??[?쒕??섏씠 ?꾨줈 X ?뺤꽍 濡쒕큸] 寃뚯떆臾??뚯씠釉붿쓽 ?볤? ?レ옄???ㅼ떆媛??낅뜲?댄듃!
                      await SupabaseService.client
                        .from('posts')
                        .update({'comments_count': widget.post.commentsCount})
                        .eq('id', widget.post.id);

                    } catch (e) {
                      if (kDebugMode) debugPrint('?볤? ???諛??レ옄 ?낅뜲?댄듃 ?ㅽ뙣: $e');
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
            child: Text(isFollowing ? '?붾줈?? : '?붾줈??, style: TextStyle(color: isFollowing ? Colors.white70 : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _bgLabel(String text, Color color, {bool isWinner = false}) { 
    return IgnorePointer( // 諛곌꼍 湲?먭? ?곗튂 ?대깽?몃? 媛濡쒕쭑吏 ?딅룄濡??ㅼ젙 (以묒슂!)
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
        // ?렗 珥덇린?붾쭔 ?섏뿀?ㅻ㈃ ?ъ깮 ?щ?? ?곴??놁씠 ?곸긽 ?붾㈃ ?좎? (?쇱떆?뺤? ?ы븿)
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
      // ?대?吏????(湲곗〈 濡쒖쭅 洹몃?濡?罹먯떛 ?곸슜!)
      return url.trim().contains('http')
          ? CachedNetworkImage(
              imageUrl: url.trim(),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
            )
          : Image.asset(url.trim(), fit: BoxFit.cover);
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
    bool hasVoted = _votedSide != 0 || isExpired || isMe;
    return Positioned(
      bottom: 67 + MediaQuery.of(context).padding.bottom, right: 35,
      child: SizedBox(
        width: 120, height: 110,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none, // ?먮윭 諛⑹??? 諛뺤뒪瑜?踰쀬뼱?섎룄 蹂댁씠寃??ㅼ젙
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
                      // ?쇱そ A ?듦퀎 (?쒖븞??- ?곗륫 ?뺣젹)
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
                      // ?ㅻⅨ履?B ?듦퀎 (鍮④컙??- 醫뚯륫 ?뺣젹)
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
              top: 66, // ??議곌툑 ???ъ쑀 ?덇쾶 ?꾨옒濡?諛곗튂
              left: 5, right: 5, // ?? ?묒쁿 ?щ갚??以섏꽌 以묒븰 ?뺣젹 ?좊룄
              child: Center(
                child: FittedBox( // ?뮙 [??? ?묒? ?곗뿉?쒕룄 湲?먭? ??源⑥?寃??먮룞 異뺤냼!
                  fit: BoxFit.scaleDown,
                  child: _shadowText(
                    '?ы몴 ???뺤씤 媛??, 
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

  Widget _myPickLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      margin: const EdgeInsets.only(bottom: 5), // 媛꾧꺽??2?먯꽌 5濡?????뺣?
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
                            // 二쇰?踰덊샇(internal_id)瑜??곗꽑?쇰줈 ?묒꽦??蹂몄씤 ?먮퀎 (?뺤꽍!)
                            bool isMe = (c.userInternalId != null && c.userInternalId == gUserInternalId);
                            bool isPostAuthorTag = (c.userInternalId != null && widget.post.uploaderInternalId != null && c.userInternalId == widget.post.uploaderInternalId);
                            
                            if (isPostAuthorTag) {
                              String displayName = isMe ? '?섏쓽 ?쎄쿊' : widget.post.uploaderId;
                              String badge = isMe ? '(蹂몄씤)' : '(?묒꽦??';
                              
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
                          const Text(' 怨좎젙??, style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == '怨좎젙' || value == '怨좎젙?댁젣') {
                              setSheetState(() {
                                c.isPinned = !c.isPinned;
                                if (c.isPinned) {
                                  widget.post.comments.removeAt(index);
                                  widget.post.comments.insert(0, c);
                                }
                              });
                            } else if (value == '??젣') {
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
                                if (kDebugMode) debugPrint('?볤???젣 ?먮윭: $e');
                              }
                            } else if (value == '?④린湲? || value == '?④??댁젣') {
                              setSheetState(() {
                                c.isHidden = !c.isHidden;
                              });
                            } else if (value == '?좉퀬') {
                              _showReportSheet(context);
                            } else if (value == '?섏젙') {
                              _showEditCommentDialog(c, setSheetState);
                            }
                          },
                          itemBuilder: (context) {
                            List<PopupMenuEntry<String>> items = [];
                            
                            // 1. Pin/Unpin (Only for Post Owner)
                            if (isPostAuthor) {
                              items.add(PopupMenuItem(
                                value: c.isPinned ? '怨좎젙?댁젣' : '怨좎젙',
                                child: Text(c.isPinned ? '怨좎젙 ?댁젣' : '怨좎젙', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ));
                            }
                            
                            // 2. Edit (Only for Comment Author)
                            if (isCommentAuthor) {
                              items.add(const PopupMenuItem(value: '?섏젙', child: Text('?섏젙', style: TextStyle(color: Colors.white, fontSize: 13))));
                            }
                            
                            // 3. Delete (Author OR Post Owner)
                            if (isCommentAuthor || isPostAuthor) {
                              items.add(PopupMenuItem(
                                value: '??젣', 
                                child: Text('??젣', style: TextStyle(color: isCommentAuthor ? Colors.redAccent : Colors.white, fontSize: 13))
                              ));
                            }
                            
                            // 4. Hide (Only for Post Owner on OTHERS' comments)
                            if (isPostAuthor && !isCommentAuthor) {
                              items.add(PopupMenuItem(
                                value: c.isHidden ? '?④??댁젣' : '?④린湲?, 
                                child: Text(c.isHidden ? '?④? ?댁젣' : '?④린湲?, style: const TextStyle(color: Colors.white, fontSize: 13))
                              ));
                            }
                            
                            // 5. Report (Everyone except on their OWN comment)
                            if (!isCommentAuthor) {
                              items.add(const PopupMenuItem(value: '?좉퀬', child: Text('?좉퀬', style: TextStyle(color: Colors.redAccent, fontSize: 13))));
                            }
                            
                            return items;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4), 
                    Text(
                      c.isHidden ? '?④꺼吏??볤??낅땲??' : c.text, 
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
                          child: const Text('?듦? ?ш린', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ]
                )
              ),
            ],
          ),
        ),
        // ??볤?(?듦?)?ㅼ쓣 ?ш??곸쑝濡??뚮뜑留?
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
        title: const Text('?볤? ?섏젙', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: '?댁슜???낅젰?섏꽭??, hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('痍⑥냼', style: TextStyle(color: Colors.white54))),
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
                    .eq('id', c.id);
              } catch (e) {
                if (kDebugMode) debugPrint('댓글 수정 DB 저장 오류: $e');
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
              // ?렔 ?곷떒 諛?
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              
              // ?뱼 ?쒕ぉ 諛??ㅻ챸
              const Text('寃뚯떆臾??좉퀬', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('?좉퀬 ?ъ쑀瑜??좏깮?댁＜?몄슂. 寃?????좎냽??議곗튂?섍쿋?듬땲??', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 25),

              // ?뱥 ?좉퀬 ??ぉ 由ъ뒪??(?꾩씠肄??묒옱!)
              _reportItem(context, Icons.copyright, '??묎텒 移⑦빐', Colors.amberAccent),
              _reportItem(context, Icons.explicit_outlined, '遺?곸젅??肄섑뀗痢?, Colors.redAccent),
              _reportItem(context, Icons.campaign_outlined, '?ㅽ뙵 ?먮뒗 ?띾낫', Colors.blueAccent),
              _reportItem(context, Icons.psychology_alt_outlined, '?덉쐞 ?뺣낫 ?좏룷', Colors.purpleAccent),
              _reportItem(context, Icons.sentiment_very_dissatisfied, '利앹삤 ?쒗쁽 ?먮뒗 愿대∼??, Colors.orangeAccent),
              _reportItem(context, Icons.more_horiz, '湲고?', Colors.white54),
              
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
        widget.onReport(title); // ?? ?ъ쑀 ?꾨떖!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" ?ъ쑀濡??좉퀬媛 ?묒닔?섏뿀?듬땲??'),
            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }
}

``

## File: lib\widgets\social_login_button.dart
``dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String svgAsset;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool hasBorder;
  final double? iconSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const SocialLoginButton({
    super.key,
    required this.svgAsset,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.hasBorder = false,
    this.iconSize,
    this.fontWeight = FontWeight.bold,
    this.letterSpacing = -0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: const Color(0xFFDADCE0), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                left: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    svgAsset,
                    width: iconSize ?? 22,
                    height: iconSize ?? 22,
                    colorFilter: (svgAsset.contains('google')) ? null : ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                ),
              ),
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor, 
                    fontSize: 15, 
                    fontWeight: fontWeight,
                    letterSpacing: letterSpacing,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

``


