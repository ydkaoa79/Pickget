import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/post_service.dart';
import '../models/post_data.dart';
import 'channel_screen.dart';
import 'channel_feed_screen.dart';
import '../main.dart'; 
import '../core/app_state.dart'; 
import '../core/supabase_config.dart';

class AdminReportManageScreen extends StatefulWidget {
  const AdminReportManageScreen({super.key});

  @override
  State<AdminReportManageScreen> createState() => _AdminReportManageScreenState();
}

class _AdminReportManageScreenState extends State<AdminReportManageScreen> {
  List<dynamic> reportedUsers = [];
  bool _isLoading = true;
  int currentPage = 0;
  int totalReportedCount = 0;
  String searchQuery = '';
  String sortBy = 'report_count'; // 'report_count', 'updated_at'
  String _errorMessage = '';
  
  final int pageSize = 10;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReportedUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // 1. 모든 신고 데이터 가져오기 (통계용)
      // 실제 서비스에서는 RPC나 View를 쓰는 것이 좋지만, 현재는 클라이언트에서 가공합니다.
      final reportsRes = await SupabaseService.client
          .from('reports')
          .select('reported_internal_id');
      
      final List<dynamic> allReports = reportsRes as List;
      
      // 유저별 신고 횟수 카운트
      Map<String, int> reportCounts = {};
      for (var r in allReports) {
        String id = r['reported_internal_id'];
        reportCounts[id] = (reportCounts[id] ?? 0) + 1;
      }

      if (reportCounts.isEmpty) {
        if (mounted) {
          setState(() {
            reportedUsers = [];
            totalReportedCount = 0;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. 신고당한 유저들의 프로필 정보 가져오기
      dynamic query = SupabaseService.client
          .from('user_profiles')
          .select('id, user_id, nickname, profile_image, points, updated_at')
          .inFilter('id', reportCounts.keys.toList());

      if (searchQuery.isNotEmpty) {
        query = query.or('nickname.ilike.%$searchQuery%,user_id.ilike.%$searchQuery%');
      }

      final List<dynamic> profiles = await query;

      // 3. 데이터 결합
      List<Map<String, dynamic>> enriched = profiles.map((p) {
        final String id = p['id'];
        return Map<String, dynamic>.from(p)..addAll({
          'report_count': reportCounts[id] ?? 0,
        });
      }).toList();

      // 4. 정렬
      if (sortBy == 'report_count') {
        enriched.sort((a, b) => b['report_count'].compareTo(a['report_count']));
      } else {
        enriched.sort((a, b) => b['updated_at'].compareTo(a['updated_at']));
      }

      totalReportedCount = enriched.length;

      // 5. 페이지네이션
      final from = currentPage * pageSize;
      final to = (from + pageSize < enriched.length) ? from + pageSize : enriched.length;
      final paged = enriched.sublist(from, to);

      if (mounted) {
        setState(() {
          reportedUsers = paged;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Report manage fetch error: $e');
      if (mounted) {
        setState(() {
          if (e.toString().contains('42P01')) {
            _errorMessage = '⚠️ reports 테이블이 존재하지 않습니다.\n신고 기능이 먼저 활성화되어야 합니다.';
          } else {
            _errorMessage = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (totalReportedCount / pageSize).ceil();
    if (totalPages == 0) totalPages = 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('신고 관리 센터', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSummary(),
            _buildSearchAndSortBar(),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
                : _errorMessage.isNotEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                    ))
                  : reportedUsers.isEmpty
                    ? const Center(child: Text('신고된 내역이 없습니다.', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: reportedUsers.length,
                        itemBuilder: (context, index) => _buildUserTile(reportedUsers[index]),
                      ),
            ),
            _buildPagination(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _summaryItem('요주의 유저', '$totalReportedCount명'),
          const SizedBox(width: 20),
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Container(
            height: 45,
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (val) {
                searchQuery = val.trim();
                currentPage = 0;
                _fetchReportedUsers();
              },
              decoration: InputDecoration(
                hintText: '신고대상 이름 또는 아이디 검색',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.cancel, color: Colors.white38, size: 20), onPressed: () {
                      setState(() { _searchController.clear(); searchQuery = ''; currentPage = 0; });
                      _fetchReportedUsers();
                    }) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _sortChip('신고순', 'report_count'),
              _sortChip('최신순', 'updated_at'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    bool isSelected = sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() { sortBy = value; currentPage = 0; });
        _fetchReportedUsers();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? Colors.redAccent : const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  String _getProfileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${CloudflareConfig.cdnUrl}profile_images/$path';
  }
  Widget _buildUserTile(dynamic user) {
    final String nickname = user['nickname'] ?? '익명';
    final String userId = user['user_id'] ?? '-';
    final int reportCount = user['report_count'] ?? 0;
    final String profileUrl = _getProfileUrl(user['profile_image']);

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
      child: Row(
        children: [
          // 1. 프로필 & 유저 정보 (클릭 시 채널 이동)
          Expanded(
            child: InkWell(
              onTap: () {
                PostData? realPost;
                try {
                  realPost = gAllPosts.firstWhere((p) => p.uploaderId == userId);
                } catch (_) {}

                final mockPost = realPost ?? PostService.createMockPost(
                  uploaderId: userId,
                  uploaderInternalId: user['id'],
                  uploaderName: nickname,
                  uploaderImage: profileUrl.isNotEmpty ? profileUrl : '',
                );

                Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelScreen(uploaderId: userId, allPosts: gAllPosts, initialPost: mockPost)));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white12,
                      backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                      child: profileUrl.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 20) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('@$userId', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 2. 신고 횟수 버튼 (클릭 시 상세 팝업)
          InkWell(
            onTap: () => _showReportDetails(context, user['id'], nickname),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('신고 ${reportCount}회', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 15)),
                      const Text('상세보기 >', style: TextStyle(color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚩 [신규] 신고 상세 내역 팝업
  void _showReportDetails(BuildContext context, String internalId, String nickname) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$nickname님 신고 내역', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<dynamic>>(
            future: SupabaseService.client
                .from('reports')
                .select('reason, created_at, post_id, posts(*, profiles:user_profiles!uploader_internal_id(*))')
                .eq('reported_internal_id', internalId)
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.redAccent)));
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('상세 내역을 불러올 수 없습니다.', style: TextStyle(color: Colors.white38)),
                );
              }

              final reports = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                itemCount: reports.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final r = reports[index];
                  final postMap = r['posts'];
                  final postTitle = (postMap != null) ? postMap['title'] : '삭제된 게시물';
                  final reason = r['reason'] ?? '사유 없음';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            if (postMap == null) return;
                            final postData = PostService.mapToPostData(postMap);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChannelFeedScreen(
                                  initialIndex: 0,
                                  channelPosts: [postData],
                                  allPosts: [postData],
                                ),
                              ),
                            );
                          },
                          child: Text('📍 $postTitle', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(height: 4),
                        Text('💬 $reason', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: const Color(0xFF0A0A0A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalPages, (index) {
            bool isCurrent = currentPage == index;
            return GestureDetector(
              onTap: () { setState(() => currentPage = index); _fetchReportedUsers(); },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 35, height: 35,
                decoration: BoxDecoration(color: isCurrent ? Colors.redAccent : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: isCurrent ? Colors.redAccent : Colors.white12)),
                child: Center(child: Text('${index + 1}', style: TextStyle(color: isCurrent ? Colors.white : Colors.white60, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal))),
              ),
            );
          }),
        ),
      ),
    );
  }
}
