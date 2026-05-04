import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/post_service.dart';
import '../core/supabase_config.dart'; // 🚀 추가
import '../core/app_state.dart';
import '../models/post_data.dart';
import 'channel_screen.dart';
import '../main.dart';

class AdminPointManageScreen extends StatefulWidget {
  const AdminPointManageScreen({super.key});

  @override
  State<AdminPointManageScreen> createState() => _AdminPointManageScreenState();
}

class _AdminPointManageScreenState extends State<AdminPointManageScreen> {
  List<dynamic> userStats = [];
  bool _isLoading = true;
  int currentPage = 0;
  int totalUserCount = 0;
  String searchQuery = '';
  String sortBy = 'total_earned'; 
  final int pageSize = 15;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserStats() async {
    setState(() => _isLoading = true);
    try {
      dynamic countQuery = SupabaseService.client.from('user_profiles').select('id');
      if (searchQuery.isNotEmpty) {
        countQuery = countQuery.or('user_id.ilike.%$searchQuery%,nickname.ilike.%$searchQuery%');
      }
      final countRes = await countQuery;
      totalUserCount = (countRes as List).length;

      dynamic query = SupabaseService.client.from('user_point_stats').select();
      if (searchQuery.isNotEmpty) {
        query = query.or('handle.ilike.%$searchQuery%,nickname.ilike.%$searchQuery%');
      }
      query = query.order(sortBy, ascending: false);

      final from = currentPage * pageSize;
      final to = from + pageSize - 1;
      final response = await query.range(from, to);

      if (mounted) {
        setState(() {
          userStats = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch point stats error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getProfileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${CloudflareConfig.cdnUrl}profile_images/$path'; // 🚀 수정
  }

  void _showHistoryPopup(String userInternalId, String nickname, bool isEarnedOnly, bool isSpentOnly) {
    DateTimeRange? selectedRange;
    String filterType = 'today'; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            String rangeText = '오늘 내역';
            if (filterType == 'custom' && selectedRange != null) {
              rangeText = '${DateFormat('yyyy.MM.dd').format(selectedRange!.start)} ~ ${DateFormat('yyyy.MM.dd').format(selectedRange!.end)}';
            } else if (filterType == '7days') {
              rangeText = '최근 7일';
            } else if (filterType == '30days') {
              rangeText = '최근 30일';
            } else if (filterType == 'all') {
              rangeText = '전체 기간';
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$nickname님의 ${isEarnedOnly ? "총지급" : isSpentOnly ? "지급완료(사용)" : "전체 흐름"}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                        padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(rangeText, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _popupFilterChip('오늘', 'today', filterType, (v) => setPopupState(() => filterType = v)),
                        _popupFilterChip('7일', '7days', filterType, (v) => setPopupState(() => filterType = v)),
                        _popupFilterChip('30일', '30days', filterType, (v) => setPopupState(() => filterType = v)),
                        _popupFilterChip('전체', 'all', filterType, (v) => setPopupState(() => filterType = v)),
                        const SizedBox(width: 8),
                        const VerticalDivider(color: Colors.white10, width: 1),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final DateTimeRange? picked = await showDateRangePicker(
                              context: context,
                              initialDateRange: selectedRange,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent, onPrimary: Colors.black, surface: Color(0xFF1A1A1A), onSurface: Colors.white),
                                    dialogBackgroundColor: const Color(0xFF1A1A1A),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setPopupState(() {
                                selectedRange = picked;
                                filterType = 'custom';
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: filterType == 'custom' ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 10, color: filterType == 'custom' ? Colors.black : Colors.white38),
                                const SizedBox(width: 4),
                                Text('날짜 선택', style: TextStyle(color: filterType == 'custom' ? Colors.black : Colors.white60, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder(
                  key: ValueKey('$filterType-${selectedRange?.start}-${selectedRange?.end}'),
                  future: _fetchUserHistory(userInternalId, isEarnedOnly, isSpentOnly, filterType, selectedRange),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
                              const SizedBox(height: 10),
                              const Text('데이터 로딩 오류', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(snapshot.error.toString(), style: const TextStyle(color: Colors.white24, fontSize: 9), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }
                    final history = snapshot.data as List<dynamic>? ?? [];
                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white10, size: 40),
                            const SizedBox(height: 12),
                            Text('${rangeText}에 내역이 없습니다.', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                            const SizedBox(height: 16),
                            if (filterType != 'all') 
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, elevation: 0),
                                onPressed: () => setPopupState(() => filterType = 'all'),
                                child: const Text('전체 내역 보기', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 10),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final int amount = item['amount'] ?? 0;
                        final DateTime date = DateTime.parse(item['created_at']).toLocal();
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          title: Text(item['description'] ?? '내역 없음', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(DateFormat('yyyy.MM.dd HH:mm').format(date), style: const TextStyle(color: Colors.white24, fontSize: 11)),
                          trailing: Text(
                            '${amount > 0 ? "+" : ""}$amount P',
                            style: TextStyle(color: amount > 0 ? Colors.cyanAccent : Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
            );
          }
        );
      },
    );
  }

  Widget _popupFilterChip(String label, String value, String currentFilter, Function(String) onSelect) {
    bool isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Future<List<dynamic>> _fetchUserHistory(String userInternalId, bool isEarned, bool isSpent, String filterType, DateTimeRange? range) async {
    try {
      var query = SupabaseService.client
          .from('points_history')
          .select('*')
          .eq('user_internal_id', userInternalId);

      if (isEarned) query = query.gt('amount', 0);
      if (isSpent) query = query.lt('amount', 0);

      if (filterType == 'today') {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
        query = query.gte('created_at', start);
      } else if (filterType == '7days') {
        final start = DateTime.now().subtract(const Duration(days: 7)).toUtc().toIso8601String();
        query = query.gte('created_at', start);
      } else if (filterType == '30days') {
        final start = DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String();
        query = query.gte('created_at', start);
      } else if (filterType == 'custom' && range != null) {
        final start = DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0).toUtc().toIso8601String();
        final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59).toUtc().toIso8601String();
        query = query.gte('created_at', start).lte('created_at', end);
      }

      final response = await query.order('created_at', ascending: false).limit(100);
      return response as List<dynamic>;
    } catch (e) {
      debugPrint('Fetch user history error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (totalUserCount / pageSize).ceil();
    if (totalPages == 0) totalPages = 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('포인트 상세 관리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortTabs(),
          const SizedBox(height: 10),
          _buildTableHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : ListView.builder(
                  itemCount: userStats.length,
                  itemBuilder: (context, index) => _buildUserRow(userStats[index]),
                ),
          ),
          _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onSubmitted: (val) {
            searchQuery = val.trim();
            currentPage = 0;
            _fetchUserStats();
          },
          decoration: InputDecoration(
            hintText: '유저 닉네임 또는 아이디 검색',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildSortTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _sortChip('총지급순', 'total_earned'),
          _sortChip('지급완료순', 'total_spent'),
          _sortChip('현재잔액순', 'current_points'),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    bool isSelected = sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          sortBy = value;
          currentPage = 0;
        });
        _fetchUserStats();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white10),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('유저 프로필', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('총지급', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('지급완료', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('현재', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildUserRow(dynamic user) {
    final profileUrl = _getProfileUrl(user['profile_image']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                final String handle = user['handle'];
                final String internalId = user['user_internal_id'];

                // 🏛️ [데이터 지능화] 전역 포스트 목록(gAllPosts)에서 이 유저의 진짜 포스트가 있는지 먼저 탐색
                PostData? realPost;
                try {
                  // handle이 일치하는 첫 번째 포스트 찾기
                  realPost = gAllPosts.firstWhere((p) => p.uploaderId == handle);
                } catch (_) {}

                // 🚀 진짜 포스트가 있으면 그걸 사용하고, 없으면 "메인 포스트 규격"과 동일한 표준 mockPost 생성
                final postToPass = realPost ?? PostService.createMockPost(
                  uploaderId: handle,
                  uploaderInternalId: internalId, // 🆔 중요: UUID를 정확히 넘겨야 공감도 계산 등이 작동함
                  uploaderName: user['nickname'] ?? '익명',
                  uploaderImage: profileUrl.isNotEmpty ? profileUrl : '',
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelScreen(
                      uploaderId: handle,
                      allPosts: gAllPosts,
                      initialPost: postToPass,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white10,
                    backgroundImage: profileUrl.isNotEmpty ? NetworkImage(profileUrl) : null,
                    child: profileUrl.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.white24) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['nickname'] ?? '익명', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('@${user['handle']}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showHistoryPopup(user['user_internal_id'], user['nickname'], true, false),
              child: Text(_formatP(user['total_earned']), style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showHistoryPopup(user['user_internal_id'], user['nickname'], false, true),
              child: Text(_formatP(user['total_spent']), style: const TextStyle(color: Colors.pinkAccent, fontSize: 12), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showHistoryPopup(user['user_internal_id'], user['nickname'], false, false),
              child: Text(_formatP(user['current_points']), style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
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
                _fetchUserStats();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
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

  String _formatP(dynamic val) {
    int n = val ?? 0;
    return n.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},");
  }
}
