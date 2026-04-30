import 'dart:ui';
import '../services/supabase_service.dart';

String gNameText = '테스트용';
String gIdText = '테스트용';
// 로그인 후 세팅되는 진짜 고유 ID (로그아웃 시에는 null로 초기화)
String? gUserInternalId; // ← 하드코딩 UUID 제거!
String gBioText = '안녕하세요! 저는 PickGet 유저입니다.';
String gProfileImage = 'assets/profiles/profile_11.jpg';
int gUserPoints = 0;
bool gIsLoggedIn = false;
VoidCallback? gShowLoginPopup;
VoidCallback? gRefreshFeed;
VoidCallback? gOnLogout;

String formatCount(dynamic countVal) {
  int count = 0;
  if (countVal is int) {
    count = countVal;
  } else if (countVal is String) {
    count = int.tryParse(countVal) ?? 0;
  }
  if (count >= 10000) {
    return '${(count / 10000).toStringAsFixed(1)}만';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}천';
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
