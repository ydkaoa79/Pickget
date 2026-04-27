import 'package:flutter/material.dart';
import '../models/post_data.dart';
import 'channel_screen.dart';

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

  final List<String> _popularTags = ['#패션', '#데이트', '#홍대맛집', '#출근룩', '#인생샷', '#여행지', '#오운완', '#오늘의메뉴'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchResults = widget.allPosts.where((p) => 
        p.title.contains(query) || 
        p.uploaderId.contains(query) || 
        (p.tags?.any((t) => t.contains(query)) == true)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        style: const TextStyle(color: Colors.white),
                        onChanged: _performSearch,
                        decoration: const InputDecoration(
                          hintText: '투표 제목, 채널명, 태그 검색',
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
    );
  }

  Widget _buildDiscoveryView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('인기 태그', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _popularTags.map((tag) => GestureDetector(
            onTap: () {
              _searchController.text = tag.replaceAll('#', '');
              _performSearch(_searchController.text);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
              ),
              child: Text(tag, style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 40),
        const Text('추천 카테고리', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _categoryTile(Icons.shopping_bag_outlined, '패션 & 스타일', '3,452개의 픽겟'),
        _categoryTile(Icons.restaurant_outlined, '맛집 & 카페', '1,245개의 픽겟'),
        _categoryTile(Icons.favorite_border, '연애 & 고민', '2,890개의 픽겟'),
        _categoryTile(Icons.flight_takeoff, '여행 & 라이프', '980개의 픽겟'),
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

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.white10, size: 64),
            const SizedBox(height: 16),
            const Text('검색 결과가 없습니다', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return ListTile(
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
            );
          },
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: AssetImage(post.imageA), fit: BoxFit.cover),
            ),
          ),
          title: Text(post.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(post.uploaderId, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white10),
        );
      },
    );
  }
}
