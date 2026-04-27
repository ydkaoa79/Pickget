import 'package:flutter/material.dart';
import 'store_screen.dart';

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
  late int _userPoints;
  final List<PointHistoryItem> _history = [
    PointHistoryItem(title: '친구 초대 보상', amount: 500, date: '2026.04.27', isEarned: true),
    PointHistoryItem(title: '출석 체크 보상', amount: 100, date: '2026.04.27', isEarned: true),
    PointHistoryItem(title: '게시물 좋아요 보상', amount: 50, date: '2026.04.26', isEarned: true),
    PointHistoryItem(title: '현금 인출 신청', amount: 10000, date: '2026.04.25', isEarned: false),
    PointHistoryItem(title: '상품권 교환', amount: 5000, date: '2026.04.24', isEarned: false),
    PointHistoryItem(title: '투표 참여 보상', amount: 10, date: '2026.04.23', isEarned: true),
    PointHistoryItem(title: '이벤트 당첨 보너스', amount: 2000, date: '2026.04.20', isEarned: true),
    PointHistoryItem(title: '친구 초대 보상', amount: 500, date: '2026.04.18', isEarned: true),
    PointHistoryItem(title: '베스트 코디 선정', amount: 1000, date: '2026.04.15', isEarned: true),
    PointHistoryItem(title: '광고 시청 보상', amount: 50, date: '2026.04.10', isEarned: true),
    PointHistoryItem(title: '출석 체크 보상', amount: 100, date: '2026.04.05', isEarned: true),
    PointHistoryItem(title: '상품권 교환', amount: 3000, date: '2026.04.01', isEarned: false),
    PointHistoryItem(title: '게시물 좋아요 보상', amount: 50, date: '2026.03.25', isEarned: true),
    PointHistoryItem(title: '친구 초대 보상', amount: 500, date: '2026.03.20', isEarned: true),
  ];

  @override
  void initState() {
    super.initState();
    _userPoints = widget.currentPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('나의 포인트', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C2C2C), Color(0xFF1C1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('나의 보유 포인트', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('P', style: TextStyle(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Text(
                            _userPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StoreScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('포인트 사용', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withValues(alpha: 0.05)),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('30일 이내 소멸 예정', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Text('150 P', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('포인트 내역', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('최근 3개월', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '* 앱에서는 최근 3개월 내역만 표시되며, 전체 내역은 고객센터를 통해 확인하실 수 있습니다. (관련 법령에 의거 5년간 보관)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              itemBuilder: (context, index) {
                final item = _history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (item.isEarned ? Colors.cyanAccent : Colors.orangeAccent).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.isEarned ? Icons.add : Icons.remove,
                          color: item.isEarned ? Colors.cyanAccent : Colors.orangeAccent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(item.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        "${item.isEarned ? '+' : '-'}${item.amount} P",
                        style: TextStyle(
                          color: item.isEarned ? Colors.cyanAccent : Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
