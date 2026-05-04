import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';
import 'admin_user_manage_screen.dart';
import 'admin_post_manage_screen.dart';
import 'admin_point_manage_screen.dart';
import 'admin_report_manage_screen.dart'; // 👮‍♂️ 신고 관리 페이지 추가

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int totalUsers = 0;
  int totalPosts = 0;
  int totalPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // 📊 기본적인 서비스 현황 데이터만 조회
      final usersData = await SupabaseService.client.from('user_profiles').select('id, points');
      final postsData = await SupabaseService.client.from('posts').select('id');

      int sumPoints = 0;
      for (var user in usersData) {
        sumPoints += (user['points'] as int? ?? 0);
      }

      if (mounted) {
        setState(() {
          totalUsers = usersData.length;
          totalPosts = postsData.length;
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
      body: SafeArea(
        child: _isLoading 
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
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminUserManageScreen()),
                          ),
                          child: _statCard('전체 유저', totalUsers.toString(), Icons.people_outline),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminPostManageScreen()),
                          ),
                          child: _statCard('전체 포스트', totalPosts.toString(), Icons.article_outlined),
                        ),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('상품지급현황 상세 페이지는 준비 중입니다.'))
                            );
                          },
                          child: _statCard('상품지급현황', '0', Icons.redeem),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminPointManageScreen()),
                          ), // 💰 포인트 카드 클릭 시 새 페이지로 이동
                          child: _statCard('현재 총 지급 포인트', totalPoints.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},"), Icons.stars_outlined),
                        ),
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
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminReportManageScreen()),
                      )
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
      ),
    );
  }

  Widget _adminMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.redAccent, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.5), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
