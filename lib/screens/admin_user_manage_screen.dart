import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/post_data.dart';
import 'channel_screen.dart';
import '../main.dart'; // To access global state if needed
import '../core/app_state.dart'; 

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
  String sortBy = 'updated_at'; // 'updated_at', 'points', 'votes', 'posts'
  String _errorMessage = '';
  
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // 🏛️ [핵심] 유저의 포스트 수와 받은 투표 수를 실시간으로 계산해서 병합하는 함수
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // 1. 전체 유저 수 가져오기
      final allRes = await SupabaseService.client.from('user_profiles').select('id');
      totalUserCount = (allRes as List).length;

      // 2. 기본 유저 정보 가져오기
      dynamic query = SupabaseService.client
          .from('user_profiles')
          .select('id, user_id, nickname, profile_image, points, updated_at');

      if (searchQuery.isNotEmpty) {
        query = query.or('nickname.ilike.%$searchQuery%,user_id.ilike.%$searchQuery%');
      }

      // 포인트순 정렬은 DB에서 직접 가능
      if (sortBy == 'points') {
        query = query.order('points', ascending: false);
      } else if (sortBy == 'updated_at') {
        query = query.order('updated_at', ascending: false);
      }

      final List<dynamic> baseUsers = await query;

      // 3. 🚀 [데이터 보강] 각 유저별 게시글 수 및 투표 수 계산
      List<Map<String, dynamic>> enrichedUsers = [];
      
      for (var user in baseUsers) {
        final String internalId = user['id'];
        
        // 해당 유저의 모든 게시물 가져오기
        final postsRes = await SupabaseService.client
            .from('posts')
            .select('vote_count_a, vote_count_b')
            .eq('uploader_internal_id', internalId);
        
        final List<dynamic> posts = postsRes as List;
        int postCount = posts.length;
        int totalVotes = 0;
        
        for (var p in posts) {
          totalVotes += _parseCount(p['vote_count_a']) + _parseCount(p['vote_count_b']);
        }
        
        enrichedUsers.add({
          ...user,
          'post_count': postCount,
          'total_votes': totalVotes,
        });
      }

      // 4. 📊 [클라이언트 정렬] 받은 투표순 / 게시글순 정렬 처리
      if (sortBy == 'votes') {
        enrichedUsers.sort((a, b) => b['total_votes'].compareTo(a['total_votes']));
      } else if (sortBy == 'posts') {
        enrichedUsers.sort((a, b) => b['post_count'].compareTo(a['post_count']));
      }

      // 5. 페이지네이션 적용 (데이터가 보강된 후 자름)
      final from = currentPage * pageSize;
      final to = (from + pageSize < enrichedUsers.length) ? from + pageSize : enrichedUsers.length;
      final pagedUsers = enrichedUsers.sublist(from, to);

      if (mounted) {
        setState(() {
          users = pagedUsers;
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
          _summaryItem('현재 접속', '${(totalUserCount * 0.05).toInt()}명'),
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
                _sortChip('투표순', 'votes'),
                _sortChip('게시글순', 'posts'),
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
    final int posts = user['post_count'] ?? 0;
    final int votes = user['total_votes'] ?? 0;

    return GestureDetector(
      onTap: () {
        // 🏛️ [순간이동] 해당 유저의 채널 페이지로 이동!
        // 최소한의 PostData 객체를 생성하여 전달합니다.
        final mockPost = PostData(
          id: 'temp',
          title: '',
          uploaderId: userId,
          uploaderInternalId: user['id'],
          uploaderName: nickname,
          uploaderImage: profileImg,
          timeLocation: '',
          imageA: '',
          imageB: '',
          descriptionA: '',
          descriptionB: '',
          likesCount: 0,
          commentsCount: 0,
          voteCountA: '0',
          voteCountB: '0',
          percentA: '50%',
          percentB: '50%',
          tags: [],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChannelScreen(
              uploaderId: userId,
              allPosts: gAllPosts, // 전역 포스트 리스트 전달
              initialPost: mockPost,
            ),
          ),
        );
      },
      child: Container(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _miniStat('게시글 $posts'),
                      const SizedBox(width: 8),
                      _miniStat('투표 $votes'),
                    ],
                  ),
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
      ),
    );
  }

  Widget _miniStat(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
