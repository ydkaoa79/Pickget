import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';

class AdminPostManageScreen extends StatefulWidget {
  const AdminPostManageScreen({super.key});

  @override
  State<AdminPostManageScreen> createState() => _AdminPostManageScreenState();
}

class _AdminPostManageScreenState extends State<AdminPostManageScreen> {
  List<dynamic> allFetchedPosts = []; 
  List<dynamic> filteredPosts = []; 
  bool _isLoading = true;
  int currentPage = 0;
  String searchQuery = '';
  String sortBy = 'updated_at'; 
  bool isAscending = false;
  String statusFilter = 'all'; 
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
      // 🚀 [핵심] DB에는 is_expired 필터링을 절대 요청하지 않습니다 (에러 원인)
      var query = SupabaseService.client
          .from('posts')
          .select('id, title, uploader_id, vote_count_a, vote_count_b, updated_at, tags');

      if (sortBy == 'updated_at') {
        query = query.order('updated_at', ascending: isAscending);
      }

      final List<dynamic> fetchedData = await query;

      // 📊 앱 내에서 데이터 가공 및 상태 계산
      allFetchedPosts = fetchedData.map((p) {
        int a = _parseCount(p['vote_count_a']);
        int b = _parseCount(p['vote_count_b']);
        
        final tags = (p['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final updatedAt = p['updated_at'] != null ? DateTime.parse(p['updated_at']) : DateTime.now();
        int? durationMins;
        for (var tag in tags) {
          if (tag.startsWith('duration:')) {
            durationMins = int.tryParse(tag.split(':')[1]);
          }
        }
        
        bool isExpired = false;
        if (durationMins != null) {
          if (DateTime.now().isAfter(updatedAt.add(Duration(minutes: durationMins)))) {
            isExpired = true;
          }
        }

        return {
          ...p,
          'total_votes': a + b,
          'v_a': a,
          'v_b': b,
          'is_expired_calc': isExpired,
        };
      }).toList();

      _applyFilters();

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

  void _applyFilters() {
    List<dynamic> results = List.from(allFetchedPosts);

    if (searchQuery.isNotEmpty) {
      results = results.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final uploader = (p['uploader_id'] ?? '').toString().toLowerCase();
        return title.contains(searchQuery.toLowerCase()) || uploader.contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (statusFilter == 'active') {
      results = results.where((p) => p['is_expired_calc'] == false).toList();
    } else if (statusFilter == 'expired') {
      results = results.where((p) => p['is_expired_calc'] == true).toList();
    }

    if (sortBy == 'total_votes') {
      results.sort((a, b) {
        int valA = a['total_votes'];
        int valB = b['total_votes'];
        return isAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    }

    if (mounted) {
      setState(() {
        filteredPosts = results;
        _isLoading = false;
      });
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
    int totalCount = filteredPosts.length;
    int totalPages = (totalCount / pageSize).ceil();
    if (totalPages == 0) totalPages = 1;

    final from = currentPage * pageSize;
    final to = (from + pageSize < totalCount) ? from + pageSize : totalCount;
    final pagedItems = (totalCount > from) ? filteredPosts.sublist(from, to) : [];

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
                  : filteredPosts.isEmpty
                    ? const Center(child: Text('결과가 없습니다.', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: pagedItems.length,
                        itemBuilder: (context, index) => _buildPostRow(pagedItems[index]),
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
              onChanged: (val) {
                searchQuery = val.trim();
                currentPage = 0;
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: '제목 또는 작성자 검색',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.cancel, color: Colors.white38, size: 18), onPressed: () {
                      _searchController.clear();
                      searchQuery = '';
                      _applyFilters();
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
                const SizedBox(width: 10, child: VerticalDivider(color: Colors.white12, thickness: 1)),
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
        if (isSort && value == 'updated_at') {
          _fetchPosts(); 
        } else {
          _applyFilters(); 
        }
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
    final bool isExpired = post['is_expired_calc'] ?? false;
    
    String status = '투표중';
    Color statusColor = Colors.orangeAccent;
    
    if (isExpired) {
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

    return Container(
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
