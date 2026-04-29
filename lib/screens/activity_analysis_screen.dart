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
      // 1. 내가 투표한 모든 내역 가져오기
      final List<dynamic> myVotes = await SupabaseService.client
          .from('votes')
          .select('post_id, side')
          .eq('user_internal_id', gUserInternalId!);

      if (myVotes.isEmpty) {
        setState(() { empathyRate = 0.0; });
        return;
      }

      int totalVotedCount = myVotes.length;
      int matchCount = 0;

      // 2. 투표한 게시물들의 실제 결과와 비교하기
      for (var vote in myVotes) {
        final postId = vote['post_id'].toString();
        final mySide = vote['side'] as int;

        // 해당 게시물의 최신 득표 현황 가져오기
        final postData = await SupabaseService.client
            .from('posts')
            .select('vote_count_a, vote_count_b')
            .eq('id', postId)
            .maybeSingle();

        if (postData != null) {
          int countA = postData['vote_count_a'] ?? 0;
          int countB = postData['vote_count_b'] ?? 0;
          
          int winnerSide = (countA > countB) ? 1 : (countB > countA ? 2 : 0);
          
          // 내 선택이 다수결(승자)과 일치하거나, 비겼을 때 공감으로 인정
          if (mySide == winnerSide || winnerSide == 0) {
            matchCount++;
          }
        }
      }

      setState(() {
        totalPicks = widget.userPosts.length;
        totalLikes = widget.userPosts.fold(0, (sum, p) => sum + p.likesCount);
        // 🎯 주인님의 정석 공식: (맞춘 횟수 / 총 투표 횟수) * 100
        empathyRate = (matchCount / totalVotedCount) * 100;
      });
    } catch (e) {
      print('공감도 계산 실패: $e');
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
        title: const Text('활동분석', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            _buildTrendSection('주간 받은 Pick 트렌드', weeklyPicks),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('콘텐츠 수', _formatNumber(widget.userPosts.length), Icons.article_outlined),
        _statCard('받은 Pick', _formatNumber(totalPicks), Icons.front_hand_outlined),
        _statCard('받은 하트', _formatNumber(totalLikes), Icons.favorite_border),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PointScreen(currentPoints: gUserPoints))),
          child: _statCard('활동 포인트', gUserPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"), Icons.stars_outlined, isLink: true),
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
              Text(value, style: TextStyle(color: isLink ? Colors.cyanAccent : Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
              Text('대중과의 공감도', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
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
                      width: 120, height: 120,
                      child: CircularProgressIndicator(
                        value: empathyRate / 100,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        color: Colors.cyanAccent,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${empathyRate.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        const Text('공감도', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
                    _buildSympathyStatItem('총 피드백', _formatNumber(totalPicks + totalLikes), Colors.white54),
                    const SizedBox(height: 16),
                    _buildSympathyStatItem('긍정 반응', _formatNumber(totalLikes), Colors.cyanAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          const Text('공감도 단계 안내', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildEmpathyManual(),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.cyanAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Text(
              '당신의 게시물은 유저들과 ${empathyRate.toInt()}% 공감하고 있습니다!',
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
        const Text('관심 카테고리 분석', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
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

    List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
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
              Text('최근 7일', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
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
        _manualRow('81~100%', '공감왕'),
        _manualRow('61~80%', '공감 마스터'),
        _manualRow('41~60%', '소통 전문가'),
        _manualRow('21~40%', '취향 탐험가'),
        _manualRow('0~20%', '개성파'),
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
