import 'package:flutter/material.dart';
import '../models/post_data.dart';
import 'channel_screen.dart';
import 'channel_feed_screen.dart';
import '../services/supabase_service.dart';
import '../core/app_state.dart';

class SearchScreen extends StatefulWidget {
  final List<PostData> allPosts;
  const SearchScreen({super.key, required this.allPosts});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PostData> _searchResults = [];
  bool _isSearching = false;

  List<String> _searchHistory = [];
  final List<Map<String, dynamic>> _popularSearches = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!gIsLoggedIn) return;
    try {
      final List<dynamic> data = await SupabaseService.client
          .from('search_history')
          .select('keyword')
          .eq('user_id', gIdText)
          .order('created_at', ascending: false)
          .limit(10);
      
      setState(() {
        _searchHistory = data.map((item) => item['keyword'].toString()).toList();
      });
    } catch (e) {
      print('검색 기록 불러오기 실패: $e');
    }
  }

  Future<void> _saveKeyword(String query) async {
    if (!gIsLoggedIn) return;
    try {
      // 중복 체크 및 업데이트 (Upsert 느낌으로)
      await SupabaseService.client
          .from('search_history')
          .upsert({
            'user_id': gIdText, 
            'keyword': query,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,keyword');
    } catch (e) {
      print('검색어 저장 실패: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = widget.allPosts.where((p) => 
        p.title.toLowerCase().contains(query.toLowerCase()) || 
        p.uploaderId.toLowerCase().contains(query.toLowerCase()) || 
        (p.tags?.any((t) => t.toLowerCase().contains(query.toLowerCase())) == true)
      ).toList();
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    
    // 로컬 상태 업데이트 (중복 방지 및 최신화)
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) _searchHistory.removeLast();
      _isSearching = true;
    });
    
    // 실시간 필터링도 같이 수행
    _filterResults(query);
    
    // 서버에 저장
    _saveKeyword(query);
  }

  void _deleteHistoryItem(String item) {
    setState(() {
      _searchHistory.remove(item);
    });
    // 서버에서 삭제
    if (gIsLoggedIn) {
      SupabaseService.client
          .from('search_history')
          .delete()
          .match({'user_id': gIdText, 'keyword': item})
          .then((_) => print('검색어 서버 삭제 완료'))
          .catchError((e) => print('검색어 서버 삭제 실패: $e'));
    }
  }

  void _clearAllHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // 서버에서 전체 삭제
    if (gIsLoggedIn) {
      SupabaseService.client
          .from('search_history')
          .delete()
          .eq('user_id', gIdText)
          .then((_) => print('전체 검색 기록 서버 삭제 완료'))
          .catchError((e) => print('전체 검색 기록 서버 삭제 실패: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            // 타자 칠 때는 검색 결과만 필터링 (서버 저장 X)
                            _filterResults(val);
                          },
                          onSubmitted: (val) {
                            // 엔터 눌렀을 때만 진짜 검색으로 인정하고 저장!
                            _performSearch(val);
                          },
                          decoration: const InputDecoration(
                            hintText: '질문 제목, 채널명, 태그 검색',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isSearching ? _buildSearchResults() : _buildDiscoveryView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('최근 검색어', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_searchHistory.isNotEmpty)
              TextButton(
                onPressed: _clearAllHistory,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('전체 삭제', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _searchHistory.map((item) => Container(
            padding: const EdgeInsets.only(left: 14, right: 8, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    // 키워드 클릭 시 키보드 즉시 숨김
                    FocusScope.of(context).unfocus();
                    _searchController.text = item;
                    _performSearch(item);
                  },
                  child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _deleteHistoryItem(item),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white38, size: 12),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        const SizedBox(height: 40),
        const Text('실시간 인기 검색어', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: List.generate(_popularSearches.length, (index) {
              final item = _popularSearches[index];
              return _popularSearchTile(index + 1, item['term'], item['status'], item['change']);
            }),
          ),
        ),
        const SizedBox(height: 40),
        const Text('추천 카테고리', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _categoryTile(Icons.shopping_bag_outlined, '패션 & 스타일', '실시간 트렌드 확인'),
        _categoryTile(Icons.restaurant_outlined, '맛집 & 카페', '주변 핫플레이스'),
        _categoryTile(Icons.favorite_border, '연애 & 고민', '익명 고민 상담'),
        _categoryTile(Icons.flight_takeoff, '여행 & 라이프', '여행 꿀팁 공유'),
      ],
    );
  }

  Widget _categoryTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _popularSearchTile(int rank, String term, String status, int change) {
    return InkWell(
      onTap: () {
        // 인기 검색어 클릭 시 키보드 즉시 숨김
        FocusScope.of(context).unfocus();
        _searchController.text = term;
        _performSearch(term);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank', 
                style: TextStyle(
                  color: rank <= 3 ? Colors.cyanAccent : Colors.white38, 
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                )
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                term, 
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusIndicator(status, change),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status, int change) {
    if (status == 'NEW') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text('NEW', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900)),
      );
    } else if (status == 'UP') {
      return Row(
        children: [
          const Icon(Icons.arrow_drop_up, color: Colors.redAccent, size: 18),
          Text('$change', style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (status == 'DOWN') {
      return Row(
        children: [
          const Icon(Icons.arrow_drop_down, color: Colors.blueAccent, size: 18),
          Text('$change', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return const Text('-', style: TextStyle(color: Colors.white24, fontSize: 12));
  }

  Widget _buildSearchResults() {
    final displayList = _searchResults.isEmpty ? widget.allPosts.take(4).toList() : _searchResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            _searchResults.isEmpty ? '추천 콘텐츠' : '검색 결과',
            style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: GridView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final post = displayList[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // 1. 영상 피드로 이동 (썸네일 + 그라데이션 영역)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChannelFeedScreen(
                                initialIndex: index,
                                channelPosts: displayList,
                                allPosts: widget.allPosts,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: post.imageA.trim().contains('http')
                                ? Image.network(post.imageA.trim(), fit: BoxFit.cover)
                                : Image.asset(post.imageA.trim(), fit: BoxFit.cover),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 2. 상태 배지 (단순 표시)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: post.isExpired ? Colors.black54 : Colors.cyanAccent.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            post.isExpired ? '선택종료' : '선택중',
                            style: TextStyle(
                              color: post.isExpired ? Colors.white70 : Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      // 3. 하단 정보 (제목 클릭 시에도 피드 이동)
                      Positioned(
                        bottom: 12, left: 12, right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChannelFeedScreen(
                                      initialIndex: index,
                                      channelPosts: displayList,
                                      allPosts: widget.allPosts,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                post.title, 
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${(post.likesCount / 100).toStringAsFixed(1)}k views', 
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9),
                                ),
                                const Spacer(),
                                // 4. 아이디 클릭 시에만 유저 채널 이동 (독립적 클릭 영역)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChannelScreen(
                                          uploaderId: post.uploaderId,
                                          allPosts: widget.allPosts,
                                          initialPost: post,
                                        ),
                                      ),
                                    ).then((_) {
                                      if (mounted) setState(() {});
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      post.uploaderId, 
                                      style: const TextStyle(
                                        color: Colors.cyanAccent, 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}
}
