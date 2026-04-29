import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'upload_screen.dart';
import 'activity_analysis_screen.dart';
import 'edit_profile_screen.dart';
import 'channel_feed_screen.dart';

class ChannelScreen extends StatefulWidget {
  final String uploaderId;
  final List<PostData> allPosts;
  final PostData initialPost;

  const ChannelScreen({
    super.key, 
    required this.uploaderId, 
    required this.allPosts,
    required this.initialPost,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> with SingleTickerProviderStateMixin {
  String _dName = ''; String _dImg = 'assets/profiles/profile_11.jpg'; String _dBio = '';
  bool _isFollowing = false;
  late TabController _tabController;
  late List<PostData> _channelPosts;
  bool _isBioExpanded = false;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.uploaderId == '나의 픽겟') { _dName = gNameText; _dImg = gProfileImage; _dBio = gBioText; }
    else { _dName = widget.uploaderId; _dImg = widget.initialPost.uploaderImage; _dBio = '안녕하세요! ${widget.uploaderId}의 픽겟 공간입니다. ✨'; _isFollowing = widget.initialPost.isFollowing; }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      _channelPosts = widget.allPosts.where((p) {
        bool isUploader = p.uploaderId == widget.uploaderId;
        if (widget.uploaderId == '나의 픽겟') {
          return isUploader; // Show all (including hidden) for self
        } else {
          return isUploader && !p.isHidden; // Hide hidden posts for others
        }
      }).toList();
      
      if (!_channelPosts.any((p) => p.id == widget.initialPost.id) && widget.initialPost.uploaderId == widget.uploaderId) {
        if (widget.uploaderId == '나의 픽겟' || !widget.initialPost.isHidden) {
          _channelPosts.insert(0, widget.initialPost);
        }
      }
    });
  }

  void _handleTabSelection() {
    setState(() {});
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _menuItem(Icons.select_all, '전체 선택', () {
                Navigator.pop(context);
                setState(() {
                  _selectedPostIds.addAll(_channelPosts.map((p) => p.id));
                  _isSelectionMode = true;
                });
              }),
              _menuItem(Icons.deselect, '전체 해제', () {
                Navigator.pop(context);
                setState(() {
                  _selectedPostIds.clear();
                  _isSelectionMode = false;
                });
              }),
              _menuItem(Icons.share, '공유하기', () {
                Navigator.pop(context);
                if (_selectedPostIds.length != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유는 한 개의 포스트를 선택했을 때만 가능합니다.')));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시물 링크가 복사되었습니다.')));
              }, color: _selectedPostIds.length == 1 ? Colors.white : Colors.white24),
              _menuItem(Icons.visibility_off, '숨기기 / 보이기', () {
                Navigator.pop(context);
                if (_selectedPostIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('편집할 포스트를 선택해주세요.')));
                  return;
                }
                _toggleHide();
              }, color: _selectedPostIds.isNotEmpty ? Colors.white : Colors.white24),
              _menuItem(Icons.delete_outline, '삭제하기', () {
                Navigator.pop(context);
                if (_selectedPostIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제할 포스트를 선택해주세요.')));
                  return;
                }
                _confirmDelete();
              }, color: _selectedPostIds.isNotEmpty ? Colors.redAccent : Colors.redAccent.withValues(alpha: 0.3)),
              const Divider(color: Colors.white10),
              _menuItem(Icons.logout, '로그아웃', () {
                Navigator.pop(context);
                _showLogoutDialog();
              }, color: Colors.redAccent),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('로그아웃 하시겠습니까?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                gIsLoggedIn = false;
              });
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // return to MainScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃 되었습니다.'), duration: Duration(seconds: 1)),
              );
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _toggleHide() {
    if (_selectedPostIds.isEmpty) return;
    setState(() {
      for (var p in widget.allPosts) {
        if (_selectedPostIds.contains(p.id)) {
          p.isHidden = !p.isHidden;
        }
      }
      _isSelectionMode = false;
      _selectedPostIds.clear();
      _loadPosts(); // Refresh view
    });
  }

  void _confirmDelete() {
    if (_selectedPostIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text('삭제하시겠습니까?', style: TextStyle(color: Colors.white)),
        content: const Text('삭제된 포스트는 복구할 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelected();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _deleteSelected() {
    setState(() {
      widget.allPosts.removeWhere((p) => _selectedPostIds.contains(p.id));
      _isSelectionMode = false;
      _selectedPostIds.clear();
      _loadPosts(); // Refresh view
    });
  }

  Widget _uploadButton() {
    return Container(
      width: 65, height: 65,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.cyanAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadScreen()));
          },
          borderRadius: BorderRadius.circular(35),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stacked effect
                Transform.translate(
                  offset: const Offset(-4, -4),
                  child: Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(2, 2),
                  child: Transform.rotate(
                    angle: 0.1,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.add, color: Colors.cyanAccent, size: 22, weight: 900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          _buildMenuTile(Icons.share, '공유하기', () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('채널 링크가 복사되었습니다.'), duration: Duration(seconds: 1))
            );
          }),
          _buildMenuTile(Icons.block, '이 채널 추천 안 함', () => Navigator.pop(context)),
          _buildMenuTile(Icons.visibility_off, '관심 없음', () => Navigator.pop(context)),
          _buildMenuTile(Icons.report_problem_outlined, '신고하기', () => Navigator.pop(context), isDestructive: true),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }

  int _parseTotalVotes(PostData post) {
    int parseV(String s) {
      s = s.toLowerCase().replaceAll(',', '').trim();
      if (s.isEmpty) return 0;
      if (s.endsWith('k')) {
        return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
      }
      return int.tryParse(s) ?? 0;
    }
    return parseV(post.voteCountA) + parseV(post.voteCountB);
  }

  String _formatVotes(int count) {
    return formatCount(count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 0,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.uploaderId == '나의 픽겟')
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _showSettingsMenu),
              if (widget.uploaderId != '나의 픽겟')
                IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: _showMoreMenu),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: _dImg.trim().startsWith('http')
                          ? NetworkImage(_dImg.trim())
                          : AssetImage(_dImg.trim()) as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _dName,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                if (widget.uploaderId == '나의 픽겟') ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfileScreen(
                                            currentName: gNameText,
                                            currentId: gIdText,
                                            currentBio: gBioText,
                                            currentImage: gProfileImage,
                                          ),
                                        ),
                                      ).then((res) {
                                        if (res != null) {
                                          setState(() {
                                            gNameText = res['name'];
                                            gIdText = res['id'];
                                            gBioText = res['bio'];
                                            gProfileImage = res['image'];
                                            _dName = gNameText;
                                            _dBio = gBioText;
                                            _dImg = gProfileImage;
                                          });
                                        }
                                      });
                                    },
                                    child: const Icon(Icons.edit_note, color: Colors.cyanAccent, size: 24),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "@${_dName.toLowerCase().replaceAll(' ', '_')}",
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "팔로워 58.8k · 콘텐츠 ${formatCount(_channelPosts.length)}",
                              style: const TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bio with Expand Arrow
                  GestureDetector(
                    onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _dBio,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            maxLines: _isBioExpanded ? 10 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isBioExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons (Follow & Sympathy Rate Detail)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.uploaderId == '나의 픽겟') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityAnalysisScreen()));
                            } else {
                              setState(() {
                                _isFollowing = !_isFollowing;
                                // 동일 업로더의 모든 포스트 팔로우 상태 동기화
                                for (var p in widget.allPosts) {
                                  if (p.uploaderId == widget.uploaderId) {
                                    p.isFollowing = _isFollowing;
                                  }
                                }
                              });
                              HapticFeedback.mediumImpact();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (widget.uploaderId != '나의 픽겟' && _isFollowing) 
                              ? const Color(0xFF272727) 
                              : Colors.white,
                            foregroundColor: (widget.uploaderId != '나의 픽겟' && _isFollowing) 
                              ? Colors.white70 
                              : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.uploaderId != '나의 픽겟' && _isFollowing) ...[
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                widget.uploaderId == '나의 픽겟' 
                                  ? '활동분석' 
                                  : (_isFollowing ? '팔로잉' : '팔로우'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '공감도 82%',
                                style: TextStyle(
                                  color: Colors.cyanAccent, 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: Colors.black,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _profileTab('최신순', 0),
                              const SizedBox(width: 30),
                              _profileTab('픽순', 1),
                              const SizedBox(width: 30),
                              _profileTab('시간순', 2),
                            ],
                          ),
                          if (widget.uploaderId == '나의 픽겟')
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                                onPressed: _showSettingsMenu,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostGrid(),
            _buildPostGrid(),
            _buildPostGrid(),
          ],
        ),
      ),
      floatingActionButton: widget.uploaderId == '나의 픽겟' ? _uploadButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _profileTab(String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _tabController.animateTo(index); }); 
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.transparent, fontSize: 15, fontWeight: FontWeight.w900),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.cyanAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _channelPosts.length,
      itemBuilder: (context, index) {
        final post = _channelPosts[index];
        final totalVotes = _parseTotalVotes(post);
        bool isSelected = _selectedPostIds.contains(post.id);
        return GestureDetector(
          onLongPress: () {
            if (widget.uploaderId == '나의 픽겟') {
              setState(() {
                _isSelectionMode = true;
                _selectedPostIds.add(post.id);
              });
              HapticFeedback.heavyImpact();
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedPostIds.remove(post.id);
                  if (_selectedPostIds.isEmpty) _isSelectionMode = false;
                } else {
                  _selectedPostIds.add(post.id);
                }
              });
              HapticFeedback.selectionClick();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChannelFeedScreen(initialIndex: index, channelPosts: _channelPosts, allPosts: widget.allPosts,)),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              post.imageA.trim().contains('http')
                ? Image.network(post.imageA.trim(), fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null)
                : Image.asset(post.imageA.trim(), fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null),
              if (post.isHidden)
                const Center(child: Icon(Icons.visibility_off, color: Colors.white54, size: 30)),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6, left: 6, right: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatVotes(totalVotes),
                      style: const TextStyle(
                        color: Colors.white60, 
                        fontSize: 10, 
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSelectionMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.cyanAccent : Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: isSelected ? Colors.black : Colors.transparent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final PreferredSizeWidget _widget;
  _SliverAppBarDelegate(this._widget);

  @override
  double get minExtent => _widget.preferredSize.height;
  @override
  double get maxExtent => _widget.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _widget;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => true;
}

class DonutPainter extends CustomPainter {
  final double percentA; final bool isPreVote;
  DonutPainter({required this.percentA, this.isPreVote = false});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); final radius = size.width / 2 - 4; final strokeWidth = 7.0;
    final paintBg = Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, paintBg);
    if (isPreVote) {
      final paintWhite = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, paintWhite);
    } else {
      final paintA = Paint()..color = Colors.cyanAccent..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      final paintB = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, -2 * 3.14159 * percentA, false, paintA);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.57, 2 * 3.14159 * (1 - percentA), false, paintB);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
