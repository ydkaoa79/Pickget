import 'package:flutter/material.dart';

// Global Profile State
String gProfileImage = 'assets/profiles/profile_11.jpg';
String gNameText = '나의 픽겟';
String gIdText = '나의픽겟'; // 고정된 고유 아이디 (내부 식별용)
String gBioText = '세상의 모든 선택지를 픽겟하다. 하고 싶은 거 다 해요 ✨ 매일 새로운 선택지로 여러분의 참여를 기다립니다!';
bool gIsLoggedIn = false;
VoidCallback? gShowLoginPopup;
VoidCallback? gOnLogout;

// 유저 포인트 전역 상태
int gUserPoints = 0;

// Utils
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
