import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';
import 'channel_feed_screen.dart';

class AdminPostManageScreen extends StatefulWidget {
  const AdminPostManageScreen({super.key});

  @override
  State<AdminPostManageScreen> createState() => _AdminPostManageScreenState();
}

class _AdminPostManageScreenState extends State<AdminPostManageScreen> {
  List<dynamic> posts = [];
  bool _isLoading = true;
  int currentPage = 0;
  int totalPostCount = 0;
  String searchQuery = '';
  String sortBy = 'updated_at'; // created_at 대신 updated_at 사용
  bool isAscending = false;
  String statusFilter = 'all'; // 'all', 'active', 'expired'
  String _errorMessage = '';
  
  final int pageSize = 15;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // 1. 전체 포스트 수 가져오기
      var countQuery = SupabaseService.client.from('posts').select('id');
      if (searchQuery.isNotEmpty) {
        countQuery = countQuery.or('title.ilike.%$searchQuery%,uploader_id.ilike.%$searchQuery%');
      }
      if (statusFilter == 'active') {
        countQuery = countQuery.eq('is_expired', false);
      } else if (statusFilter == 'expired') {
        countQuery = countQuery.eq('is_expired', true);
      }
      
      final countRes = await countQuery;
      totalPostCount = (countRes as List).length;

      // 2. 실제 데이터 가져오기
      dynamic query = SupabaseService.client
          .from('posts')
          .select('id, title, uploader_id, vote_count_a, vote_count_b, is_expired, updated_at'); // updated_at 사용

      if (searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,uploader_id.ilike.%$searchQuery%');
      }

      if (statusFilter == 'active') {
        query = query.eq('is_expired', false);
      } else if (statusFilter == 'expired') {
        query = query.eq('is_expired', true);
      }

      // 정렬 적용
      if (sortBy == 'updated_at') {
        query = query.order('updated_at', ascending: isAscending);
      }

      final List<dynamic> fetchedData = await query;

      // 3. 데이터 가공
      List<dynamic> enrichedPosts = fetchedData.map((p) {
        int a = _parseCount(p['vote_count_a']);
        int b = _parseCount(p['vote_count_b']);
        return {
          ...p,
          'total_votes': a + b,
          'v_a': a,
          'v_b': b,
        };
      }).toList();

      if (sortBy == 'total_votes') {
        enrichedPosts.sort((a, b) {
          int valA = a['total_votes'];
          int valB = b['total_votes'];
          return isAscending ? valA.compareTo(valB) : valB.compareTo(valA);
        });
      }

      // 4. 페이지네이션
      final from = currentPage * pageSize;
      final to = (from + pageSize < enrichedPosts.length) ? from + pageSize : enrichedPosts.length;
      final pagedPosts = (enrichedPosts.length > from) ? enrichedPosts.sublist(from, to) : [];

      if (mounted) {
        setState(() {
          posts = pagedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Post manage fetch error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _parseCount(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    String s = val.toString().toLowerCase().replaceAll(',', '').trim();
    if (s.endsWith('k')) {
      return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
    }
    return int.tryParse(s) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (totalPostCount / pageSize).ceil();
    if (totalPages == 0) totalPages = 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('포스트 관리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterBar(),
            _buildHeaderTable(),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _errorMessage.isNotEmpty
                  ? Center(child: Text('에러: $_errorMessage', style: const TextStyle(color: Colors.redAccent, fontSize: 12)))
                  : posts.isEmpty
                    ? const Center(child: Text('포스트가 없습니다.', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) => _buildPostRow(posts[index]),
                      ),
            ),
            _buildPagination(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                _fetchPosts();
              },
              decoration: InputDecoration(
                hintText: '제목 또는 작성자 검색',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.cancel, color: Colors.white38, size: 18), onPressed: () {
                      _searchController.clear();
                      searchQuery = '';
                      _fetchPosts();
                    }) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('전체', 'all', isStatus: true),
                _filterChip('투표중', 'active', isStatus: true),
                _filterChip('종료됨', 'expired', isStatus: true),
                const SizedBox(width: 10, child: VerticalDivider(color: Colors.white12)),
                _filterChip('최신순', 'updated_at', isSort: true, defaultAsc: false),
                _filterChip('투표순', 'total_votes', isSort: true, defaultAsc: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, {bool isStatus = false, bool isSort = false, bool defaultAsc = true}) {
    bool isSelected = isStatus ? (statusFilter == value) : (sortBy == value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isStatus) statusFilter = value;
          if (isSort) {
            if (sortBy == value) {
              isAscending = !isAscending;
            } else {
              sortBy = value;
              isAscending = defaultAsc;
            }
          }
          currentPage = 0;
        });
        _fetchPosts();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            if (isSort && isSelected) ...[
              const SizedBox(width: 4),
              Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: Colors.black),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withValues(alpha: 0.05),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('포스트 제목', style: TextStyle(color: Colors.white38, fontSize: 11))),
          Expanded(flex: 2, child: Text('총투표', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('A', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text('B', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('결과상태', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildPostRow(dynamic post) {
    final String title = post['title'] ?? '제목 없음';
    final int total = post['total_votes'] ?? 0;
    final int a = post['v_a'] ?? 0;
    final int b = post['v_b'] ?? 0;
    final bool expired = post['is_expired'] ?? false;
    
    String status = '투표중';
    Color statusColor = Colors.orangeAccent;
    
    if (expired) {
      if (a > b) {
        status = 'A 승';
        statusColor = Colors.cyanAccent;
      } else if (b > a) {
        status = 'B 승';
        statusColor = Colors.pinkAccent;
      } else {
        status = '무승부';
        statusColor = Colors.white54;
      }
    }

    return InkWell(
      onTap: () {
        // 상세 확인 가능하게 처리 가능
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('@${post['uploader_id']}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(formatCount(total), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            Expanded(flex: 1, child: Text(formatCount(a), style: const TextStyle(color: Colors.cyanAccent, fontSize: 11), textAlign: TextAlign.center)),
            Expanded(flex: 1, child: Text(formatCount(b), style: const TextStyle(color: Colors.pinkAccent, fontSize: 11), textAlign: TextAlign.center)),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
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
              onTap: () {
                setState(() => currentPage = index);
                _fetchPosts();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.cyanAccent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isCurrent ? Colors.cyanAccent : Colors.white12),
                ),
                child: Center(
                  child: Text('${index + 1}', style: TextStyle(color: isCurrent ? Colors.black : Colors.white60, fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
