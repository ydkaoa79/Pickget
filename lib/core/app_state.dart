
import 'dart:ui';
import '../services/supabase_service.dart';

String gNameText = '테스트용';
String gIdText = '테스트용';
// 🆔 서버와 일치하는 진짜 주민번호 (정식 서비스 전에는 null로 변경)
String? gUserInternalId = '3ee25993-1578-4283-a99b-109a51fe5f78'; 
String gBioText = '세상의 모든 선택지를 픽겟하다. 하고 싶은 거 다 해요 ✨ 매일 새로운 선택지로 여러분의 참여를 기다립니다!';
String gProfileImage = 'assets/profiles/profile_11.jpg';
int gUserPoints = 0;
bool gIsLoggedIn = false;
VoidCallback? gShowLoginPopup;
VoidCallback? gRefreshFeed; 
VoidCallback? gOnLogout; // 🔄 로그아웃 신호기 복구!

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
