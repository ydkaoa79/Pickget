import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int totalUsers = 0;
  int totalPosts = 0;
  int totalVotes = 0;
  int totalPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // 📊 전체 데이터 카운트 조회
      final usersData = await SupabaseService.client.from('user_profiles').select('id, points');
      final postsData = await SupabaseService.client.from('posts').select('id');
      final votesData = await SupabaseService.client.from('votes').select('id');

      int sumPoints = 0;
      for (var user in usersData) {
        sumPoints += (user['points'] as int? ?? 0);
      }

      if (mounted) {
        setState(() {
          totalUsers = usersData.length;
          totalPosts = postsData.length;
          totalVotes = votesData.length;
          totalPoints = sumPoints;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin stats fetch error: $e');
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
        centerTitle: true,
        title: const Text(
          'PickGet Admin', 
          style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 18)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : RefreshIndicator(
            onRefresh: _fetchStats,
            color: Colors.cyanAccent,
            backgroundColor: const Color(0xFF1A1A1A),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 서비스 현황', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _statCard('전체 유저', totalUsers.toString(), Icons.people_outline),
                      _statCard('전체 포스트', totalPosts.toString(), Icons.article_outlined),
                      _statCard('전체 투표', totalVotes.toString(), Icons.how_to_vote_outlined),
                      _statCard('전체 포인트', totalPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"), Icons.stars_outlined),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    '🚨 관리 도구', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)
                  ),
                  const SizedBox(height: 16),
                  _adminMenuTile(
                    Icons.report_gmailerrorred, 
                    '신고 관리 센터', 
                    '유저들이 신고한 콘텐츠를 검토하고 조치합니다.', 
                    () {}
                  ),
                  _adminMenuTile(
                    Icons.person_off_outlined, 
                    '차단 유저 관리', 
                    '커뮤니티 가이드 위반 유저를 관리합니다.', 
                    () {}
                  ),
                  _adminMenuTile(
                    Icons.campaign_outlined, 
                    '전체 공지 발송', 
                    '모든 유저에게 서비스 공지를 보냅니다.', 
                    () {}
                  ),
                  const SizedBox(height: 50),
                  Center(
                    child: Text(
                      'Admin ID: ${gUserInternalId?.substring(0, 8)}...',
                      style: const TextStyle(color: Colors.white12, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value, 
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)
                ),
              ),
              Text(
                label, 
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.cyanAccent, size: 22),
        ),
        title: Text(
          title, 
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)
        ),
        subtitle: Text(
          subtitle, 
          style: const TextStyle(color: Colors.white38, fontSize: 12)
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: onTap,
      ),
    );
  }
}
