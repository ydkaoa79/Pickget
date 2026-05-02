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

  final List<String> _ageGroups = ['10대', '20대', '30대', '40대', '50대 이상'];
  final List<String> _regions = [
    '서울',
    '경기',
    '인천',
    '부산',
    '대구',
    '광주',
    '대전',
    '울산',
    '세종',
    '강원',
    '충북',
    '충남',
    '전북',
    '전남',
    '경북',
    '경남',
    '제주',
  ];

  final String _tosText = """
제1조 (목적)
본 약관은 회사가 제공하는 'PickGet(픽겟)' 서비스의 이용 조건 및 절차, 회사와 회원 간의 권리, 의무 및 책임 사항을 규정합니다.

제2조 (포인트 적립 및 사용)
① 회원은 서비스 내 투표 참여, 이벤트 참여 등 회사가 정한 방법에 따라 포인트를 적립할 수 있습니다.
② 적립된 포인트는 회사가 정한 기준에 따라 상품 교환 등에 사용할 수 있습니다.
③ 부정한 방법(매크로, 다중 계정 등)으로 포인트를 획득한 경우, 회사는 사전 통보 없이 해당 포인트를 회수하고 회원의 서비스 이용을 제한할 수 있습니다.

제3조 (회원 게시물 관리)
① 회원이 작성한 투표 콘텐츠 등 게시물의 저작권은 회원에게 있으며, 회사는 서비스 운영 및 홍보 목적으로 이를 활용할 수 있습니다.
② 회사는 타인의 권리를 침해하거나 서비스 운영 목적에 부합하지 않는 게시물을 임의로 삭제하거나 블라인드 처리할 수 있습니다.

제4조 (데이터 보관 및 활용)
회사는 회원의 중복 참여 방지, 포인트 정산 및 부정 사용 탐지를 위해 서비스 이용 기록을 수집하며, 해당 정보는 회원의 탈퇴 시까지 보관됩니다.
""";

  final String _privacyText = """
1. 수집하는 개인정보 항목
회사는 서비스 제공을 위해 아래의 개인정보를 수집합니다.
필수항목: 이메일 주소, 기기 식별값, 닉네임, 서비스 이용 기록(투표 참여 이력 등)

2. 개인정보의 수집 및 이용 목적
- 회원 식별 및 가입 의사 확인
- 포인트 적립 및 사용 내역 관리
- 부정 이용 방지 및 비인가 사용 확인
- 맞춤형 서비스 제공 및 통계 분석

3. 개인정보의 보유 및 이용 기간
원칙적으로 회원의 개인정보는 회원 탈퇴 시 지체 없이 파기됩니다. 단, 부정 이용 방지 및 관련 법령에 의한 보존이 필요한 경우 예외적으로 일정 기간 보관될 수 있습니다.

4. 개인정보 보호책임자
회사는 개인정보를 보호하고 관련 불만을 처리하기 위해 아래와 같이 책임자를 지정하고 있습니다.
담당부서: PickGet 운영팀
연락처: support@pickget.net
""";

  final String _thirdPartyText = """
1. 제공받는 자: '스폰서 투표'를 진행하는 해당 기업 및 브랜드 파트너
2. 제공 목적: 투표 결과 분석(연령, 성별 등 통계 처리), 경품 이벤트 당첨자 선정 및 배송
3. 제공 항목: 성별, 연령대, 투표 응답 데이터 (경품 배송 시에 한하여 식별 정보 제한적 제공)
4. 보유 및 이용 기간: 해당 목적 달성 시 즉시 파기
""";

  final String _marketingText = """
1. 수집 목적: 신규 서비스 안내, 이벤트 및 맞춤형 혜택 정보 제공
2. 수집 항목: 휴대전화 번호, 이메일 주소, 앱 푸시 토큰
3. 보유 및 이용 기간: 동의 철회 또는 회원 탈퇴 시까지
4. 철회 안내: 회원은 언제든지 앱 내 설정에서 수신 동의를 철회할 수 있습니다.
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
                child: const Text('닫기'),
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
                        '회원가입 완료 🏁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '필수 약관 및 기본 정보를 확인해주세요.',
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
                              '전체 동의',
                              _agreeToAll,
                              (val) => _updateAllAgreements(val),
                              isBold: true,
                            ),
                            const Divider(color: Colors.white10, height: 16),
                            _buildTermsRow(
                              '[필수] 서비스 이용약관',
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
                                  _showTermsDetail('서비스 이용약관', _tosText),
                            ),
                            const SizedBox(height: 8),
                            _buildTermsRow(
                              '[필수] 개인정보 처리방침',
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
                                  _showTermsDetail('개인정보 처리방침', _privacyText),
                            ),
                            const SizedBox(height: 8),
                            _buildTermsRow(
                              '[필수] 제3자 데이터 제공',
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
                                '개인정보 제3자 제공 동의',
                                _thirdPartyText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTermsRow(
                              '[선택] 마케팅 정보 수신',
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
                                '마케팅 정보 수신 동의',
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
                              _buildSectionTitle('성별'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildChoiceChip(
                                      '남',
                                      _selectedGender == '남성',
                                      () => setState(() => _selectedGender = '남성')),
                                  const SizedBox(width: 8),
                                  _buildChoiceChip(
                                      '여',
                                      _selectedGender == '여성',
                                      () => setState(() => _selectedGender = '여성')),
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
                                _buildSectionTitle('거주 지역'),
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
                                        '지역 선택',
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

                      _buildSectionTitle('연령대'),
                      const SizedBox(height: 12),
                      Row(
                        children: _ageGroups.map((age) {
                          final bool isLast = age == _ageGroups.last;
                          return Expanded(
                            flex: isLast ? 14 : 10, // Give '50대 이상' more space
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
                          child: Text(_canSubmit ? '가입 완료하고 시작하기' : '항목을 모두 채워주세요'),
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
