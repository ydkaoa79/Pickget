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
      // 🧹 [내역 대청소] 기존의 모든 가짜/테스트 내역을 싹 비웁니다. (포인트 점수는 유지!)
      await SupabaseService.client
          .from('points_history')
          .delete()
          .eq('user_internal_id', gUserInternalId!);

      print('DEBUG [CLEANUP]: All point history cleared. Current points are preserved.');

      // --- 이후 정상적으로 내역 가져오기 (이제 텅 비어있을 것임) ---
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
            title: item['description'] ?? '포인트 변동',
            amount: amount.abs(),
            date: dateStr,
            isEarned: amount > 0,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('포인트 내역 가져오기 실패: $e');
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
        title: const Text('나의 포인트', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 상단 프리미엄 포인트 카드 ---
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
                        child: const Text('현재 보유한 포인트', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
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
                              Text('사용하기', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
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
                            Text('30일 이내 소멸 예정', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500)),
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
                          '포인트 이용안내 및 소멸정책',
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

            // --- 포인트 내역 헤더 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('포인트 내역', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('최근 3개월', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 포인트 내역 리스트 ---
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

            // --- 중요: 과거 버전의 모든 경고문/정책 안내 섹션 ---
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
                      Text('포인트 이용 안내 및 소멸 정책', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _policyItem('유효기간', '각 포인트 적립일로부터 1년 (365일) 동안 유지됩니다.'),
                  _policyItem('소멸 방식', '유효기간이 경과한 포인트는 해당 일자 자정에 자동 소멸됩니다.'),
                  _policyItem('사용 원칙', '먼저 적립된 포인트가 먼저 사용되는 \'선입선출\' 방식입니다.'),
                  _policyItem('사전 안내', '소멸 30일 전과 7일 전에 앱 알림으로 미리 안내해 드립니다.'),
                  const SizedBox(height: 12),
                  const Text(
                    '* 소멸된 포인트는 복구가 불가능하오니 기간 내에 상품 구매 등으로 사용하시길 바랍니다.\n* 최근 3개월 내역만 표시되며, 전체 내역은 고객센터를 통해 확인 가능합니다.',
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
          const Text('• ', style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
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
