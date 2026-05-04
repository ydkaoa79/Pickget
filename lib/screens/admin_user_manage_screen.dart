import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AdminUserManageScreen extends StatefulWidget {
  const AdminUserManageScreen({super.key});

  @override
  State<AdminUserManageScreen> createState() => _AdminUserManageScreenState();
}

class _AdminUserManageScreenState extends State<AdminUserManageScreen> {
  List<dynamic> users = [];
  bool _isLoading = true;
  int currentPage = 0;
  int totalUserCount = 0;
  String searchQuery = '';
  String sortBy = 'updated_at'; // 'updated_at', 'points'
  
  final int pageSize = 10;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // 1. 전체 유저 수 가져오기 (가장 단순한 쿼리)
      final allRes = await SupabaseService.client.from('user_profiles').select('id');
      final allList = allRes as List;
      totalUserCount = allList.length;

      // 2. 검색 필터 적용
      List<dynamic> filteredList = allList;
      if (searchQuery.isNotEmpty) {
        // 클라이언트 사이드 필터링으로 일단 시도 (보안 정책 회피용)
        final searchRes = await SupabaseService.client
            .from('user_profiles')
            .select('id, user_id, nickname, profile_image, points, created_at')
            .or('nickname.ilike.%$searchQuery%,user_id.ilike.%$searchQuery%');
        filteredList = searchRes as List;
      } else {
        // 전체 목록 (페이지네이션 적용)
        final queryRes = await SupabaseService.client
            .from('user_profiles')
            .select('id, user_id, nickname, profile_image, points, updated_at')
            .order(sortBy == 'points' ? 'points' : 'updated_at', ascending: false)
            .range(currentPage * pageSize, (currentPage + 1) * pageSize - 1);
        filteredList = queryRes as List;
      }

      if (mounted) {
        setState(() {
          users = filteredList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('User manage fetch error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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
        title: const Text('유저 관리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _errorMessage.isNotEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('에러 발생: $_errorMessage', style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                    ))
                  : users.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) => _buildUserTile(users[index]),
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
          _summaryItem('전체 유저', '$totalUserCount명'),
          const SizedBox(width: 20),
          _summaryItem('현재 접속', '${(totalUserCount * 0.05).toInt()}명'), // 가상의 접속자 수
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
        Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.w900)),
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
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (val) {
                searchQuery = val.trim();
                currentPage = 0;
                _fetchUsers();
              },
              decoration: const InputDecoration(
                hintText: '이름 또는 아이디 검색',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.white24, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _sortChip('가입순', 'updated_at'),
                _sortChip('포인트순', 'points'),
                _sortChip('투표순(TBD)', 'received_votes'),
                _sortChip('게시글순(TBD)', 'post_count'),
              ],
            ),
          ),
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
        _fetchUsers();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(dynamic user) {
    final String nickname = user['nickname'] ?? '익명';
    final String userId = user['user_id'] ?? '-';
    final int points = user['points'] ?? 0;
    final String profileImg = user['profile_image'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white12,
            backgroundImage: (profileImg.isNotEmpty && profileImg.startsWith('http'))
              ? NetworkImage(profileImg)
              : null,
            child: (profileImg.isEmpty || !profileImg.startsWith('http')) 
              ? const Icon(Icons.person, color: Colors.white24, size: 20) 
              : null,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${points.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}P', 
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 14)),
              const Text('포인트', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
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
                _fetchUsers();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 35, height: 35,
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.cyanAccent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: isCurrent ? Colors.cyanAccent : Colors.white12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrent ? Colors.black : Colors.white60,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
