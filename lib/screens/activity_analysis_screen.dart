import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'point_screen.dart';
import '../services/supabase_service.dart';

class ActivityAnalysisScreen extends StatefulWidget {
  final String targetInternalId;
  final String targetNickname;
  final String targetProfileImage;

  const ActivityAnalysisScreen({
    super.key,
    required this.targetInternalId,
    required this.targetNickname,
    required this.targetProfileImage,
  });

  @override
  State<ActivityAnalysisScreen> createState() => _ActivityAnalysisScreenState();
}

class _ActivityAnalysisScreenState extends State<ActivityAnalysisScreen> {
  int totalContentCount = 0;
  int totalPicks = 0;
  int totalLikes = 0;
  int currentPoints = 0; // [신규] 서버에서 실시간으로 가져온 포인트
  int myVotedCount = 0;
  int myMatchCount = 0;
  double empathyRate = 0.0;
  Map<String, int> categoryCounts = {};
  List<int> weeklyPicks = [0, 0, 0, 0, 0, 0, 0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // 0. 💰 [포인트 조회] 서버에서 최신 포인트 정보를 가져옵니다.
      final profileData = await SupabaseService.client
          .from('user_profiles')
          .select('points')
          .eq('user_id', widget.targetInternalId)
          .maybeSingle();
      
      if (profileData != null && profileData['points'] != null) {
        int latestPoints = profileData['points'] as int;
        if (widget.targetInternalId == gUserInternalId) {
          gUserPoints = latestPoints; 
        }
        currentPoints = latestPoints;
      }

      // 1. 🚀 [전수 조사] 대상 유저의 모든 게시물 데이터 가져오기
      final List<dynamic> allPosts = await SupabaseService.client
          .from('posts')
          .select('vote_count_a, vote_count_b, likes_count, tags, created_at')
          .eq('uploader_internal_id', widget.targetInternalId);

      int picksReceived = 0;
      int likesReceived = 0;
      Map<String, int> categories = {};
      List<int> trend = [0, 0, 0, 0, 0, 0, 0];
      DateTime now = DateTime.now();

      for (var p in allPosts) {
        // Pick & 하트 집계
        int countA = _parseVotes(p['vote_count_a']?.toString() ?? '0');
        int countB = _parseVotes(p['vote_count_b']?.toString() ?? '0');
        picksReceived += (countA + countB);
        likesReceived += (p['likes_count'] as int? ?? 0);

        // 카테고리(태그) 분석
        final List<dynamic> tags = p['tags'] as List? ?? [];
        for (var tag in tags) {
          String t = tag.toString().replaceAll('#', '').trim();
          if (t.isNotEmpty && !t.contains('duration:')) {
            categories[t] = (categories[t] ?? 0) + 1;
          }
        }

        // 주간 트렌드 (최근 7일)
        final DateTime? createdAt = p['created_at'] != null ? DateTime.tryParse(p['created_at']) : null;
        if (createdAt != null) {
          int diffDays = now.difference(createdAt).inDays;
          if (diffDays >= 0 && diffDays < 7) {
            trend[6 - diffDays] += (countA + countB);
          }
        }
      }

      // 2. 🗳️ 투표 내역 및 공감도 전수 조사
      final List<dynamic> userVotes = await SupabaseService.client
          .from('votes')
          .select('post_id, side')
          .eq('user_internal_id', widget.targetInternalId);

      int votedCount = 0;
      int matchCount = 0;

      if (userVotes.isNotEmpty) {
        final List<String> votedPostIds = userVotes.map((v) => v['post_id'].toString()).toList();
        
        // 투표한 게시물들의 결과를 한 번에 가져오기 (성능 최적화!)
        final List<dynamic> votedPostsData = await SupabaseService.client
            .from('posts')
            .select('id, vote_count_a, vote_count_b, created_at, tags')
            .inFilter('id', votedPostIds);

        Map<String, dynamic> postsMap = {for (var p in votedPostsData) p['id'].toString(): p};

        for (var vote in userVotes) {
          final postId = vote['post_id'].toString();
          final mySide = vote['side'] as int;
          final postData = postsMap[postId];

          if (postData != null) {
            // 마감 여부 확인 알고리즘
            bool isExpiredPost = false;
            final String? caStr = postData['created_at'];
            final List<dynamic> tags = postData['tags'] as List? ?? [];
            if (caStr != null) {
              final ca = DateTime.tryParse(caStr);
              if (ca != null) {
                for (var t in tags) {
                  if (t.toString().startsWith('duration:')) {
                    final mins = int.tryParse(t.toString().split(':')[1]);
                    if (mins != null && now.isAfter(ca.add(Duration(minutes: mins)))) isExpiredPost = true;
                  }
                }
              }
            }

            if (!isExpiredPost) continue;

            votedCount++;
            int cA = _parseVotes(postData['vote_count_a']?.toString() ?? '0');
            int cB = _parseVotes(postData['vote_count_b']?.toString() ?? '0');
            int winnerSide = (cA > cB) ? 1 : (cB > cA ? 2 : 0);
            if (mySide == winnerSide || winnerSide == 0) matchCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalContentCount = allPosts.length;
          totalPicks = picksReceived;
          totalLikes = likesReceived;
          categoryCounts = categories;
          weeklyPicks = trend;
          myVotedCount = votedCount;
          myMatchCount = matchCount;
          empathyRate = votedCount > 0 ? (matchCount / votedCount) * 100 : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('활동 분석 데이터 계산 실패: $e');
      if (mounted) setState(() => _isLoading = false);
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
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}만';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}천';
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : RefreshIndicator(
            onRefresh: _calculateStats,
            color: Colors.cyanAccent,
            backgroundColor: const Color(0xFF1A1A1A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
          ),
    );
  }

  Widget _buildProfileHeader() {
    final bool isMe = widget.targetInternalId == gUserInternalId;
    final String displayImg = isMe ? gProfileImage : widget.targetProfileImage;
    final String displayName = isMe ? gNameText : widget.targetNickname;

    return Row(
      children: [
        displayImg.isEmpty
          ? Container(
              width: 60, height: 60,
              decoration: const BoxDecoration(color: Color(0xFF1A1A1A), shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white54, size: 30),
            )
          : Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: displayImg.startsWith('http') ? NetworkImage(displayImg) : AssetImage(displayImg) as ImageProvider, 
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
            Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('분석 기준: 전체 데이터', style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dynamicAspectRatio = screenWidth < 360 ? 1.3 : (screenWidth < 400 ? 1.45 : 1.6);
    final bool isMe = widget.targetInternalId == gUserInternalId;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: dynamicAspectRatio,
      children: [
        _statCard('콘텐츠 수', _formatNumber(totalContentCount), Icons.article_outlined),
        _statCard('받은 Pick', _formatNumber(totalPicks), Icons.front_hand_outlined),
        _statCard('받은 하트', _formatNumber(totalLikes), Icons.favorite_border),
        if (isMe)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PointScreen(currentPoints: currentPoints))),
            child: _statCard('활동 포인트', currentPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"), Icons.stars_outlined, isLink: true),
          )
        else
          _statCard('영향력 지수', _formatNumber(totalPicks + totalLikes), Icons.bolt_outlined),
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
                    _buildSympathyStatItem('참여 투표', _formatNumber(myVotedCount), Colors.white54),
                    const SizedBox(height: 16),
                    _buildSympathyStatItem('공감 성공', _formatNumber(myMatchCount), Colors.cyanAccent),
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
              '이 유저는 대중들과 ${empathyRate.toInt()}% 공감하고 있습니다!',
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
    
    if (topEntries.isEmpty) return const SizedBox();

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
    int todayIdx = DateTime.now().weekday - 1;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(24)),
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
        Text(pickCount > 999 ? '${(pickCount / 1000).toStringAsFixed(1)}k' : '$pickCount',
          style: TextStyle(color: isToday ? Colors.cyanAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: 14,
          height: 100 * heightFactor.clamp(0.05, 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [isToday ? Colors.cyanAccent : Colors.cyanAccent.withValues(alpha: 0.4),
                       isToday ? Colors.cyanAccent.withValues(alpha: 0.6) : Colors.cyanAccent.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 10),
        Text(day, style: TextStyle(color: isToday ? Colors.cyanAccent : Colors.white30, fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildEmpathyManual() {
    return Column(children: [_manualRow('81~100%', '공감왕'), _manualRow('61~80%', '공감 마스터'), _manualRow('41~60%', '소통 전문가'), _manualRow('21~40%', '취향 탐험가'), _manualRow('0~20%', '개성파')]);
  }

  Widget _manualRow(String range, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(range, style: const TextStyle(color: Colors.white30, fontSize: 13)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))]),
    );
  }
}
