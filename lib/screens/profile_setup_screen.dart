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
... (생략)
""";

  final String _privacyText = """
... (생략)
""";

  final String _thirdPartyText = """
... (생략)
""";

  final String _marketingText = """
본 동의를 통해 PickGet에서 제공하는 선택 참여 보상 안내, 신규 리워드 상품 입고 알림, 이벤트 소식 등을 Push 알림 또는 이메일로 받아보실 수 있습니다.
※ 동의하지 않으셔도 서비스 이용이 가능하며, 설정에서 언제든 변경할 수 있습니다.
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
