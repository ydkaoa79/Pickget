import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import 'upload_screen.dart';
import 'activity_analysis_screen.dart';
import 'edit_profile_screen.dart';
import 'channel_feed_screen.dart';
import '../services/supabase_service.dart';

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
  bool _isSelectionMode = false;
  final Set<String> _selectedPostIds = {};

  bool get isMe {
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    return normalized(widget.uploaderId) == normalized('나의 픽겟') || widget.uploaderId == 'me';
  }

  @override
  void initState() {
    super.initState();
    // ID 정규화 (공백, @, _ 제거)
    String normalizedId(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    String myId = normalizedId('나의픽겟');
    String targetId = normalizedId(widget.uploaderId);

    if (targetId == myId) { _dName = gNameText; _dImg = gProfileImage; _dBio = gBioText; }
    else { _dName = widget.uploaderId; _dImg = widget.initialPost.uploaderImage; _dBio = '안녕하세요! ${widget.uploaderId}의 픽겟 공간입니다. ✨'; _isFollowing = widget.initialPost.isFollowing; }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPosts();
  }

  void _loadPosts() {
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    String currentChannelId = normalized(widget.uploaderId);
    String myId = normalized('나의 픽겟');

    setState(() {
      _channelPosts = widget.allPosts.where((p) {
        String postUploaderId = normalized(p.uploaderId);
        bool isUploader = postUploaderId == currentChannelId || (isMe && postUploaderId == myId);
        return isMe ? isUploader : (isUploader && !p.isHidden);
      }).toList();
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
              _menuItem(Icons.logout, '로그아웃', () {
                Navigator.pop(context);
                _showLogoutDialog();
              }, color: Colors.redAccent),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  void _showPostManagementMenu() {
    if (!isMe) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 15),
                Text(
                  _selectedPostIds.isEmpty ? '게시물 관리' : '${_selectedPostIds.length}개 선택됨',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12),
                _menuItem(Icons.check_box_outlined, _isSelectionMode ? '선택 모드 종료' : '선택 모드 시작', () {
                  Navigator.pop(context);
                  setState(() {
                    _isSelectionMode = !_isSelectionMode;
                    if (!_isSelectionMode) _selectedPostIds.clear();
                  });
                }),
                _menuItem(Icons.select_all, '전체 선택', () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedPostIds.addAll(_channelPosts.map((p) => p.id));
                  });
                  setModalState(() {});
                }),
                _menuItem(Icons.deselect, '전체 해제', () {
                  setState(() {
                    _selectedPostIds.clear();
                  });
                  setModalState(() {});
                }),
                _menuItem(Icons.visibility_off, '숨기기 / 보이기', () {
                  if (_selectedPostIds.isEmpty) return;
                  Navigator.pop(context);
                  _toggleHide();
                }),
                _menuItem(Icons.delete_outline, '선택 삭제', () {
                  if (_selectedPostIds.isEmpty) return;
                  Navigator.pop(context);
                  _deletePosts();
                }, color: Colors.redAccent),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deletePosts() {
    if (_selectedPostIds.isEmpty) return;
    
    // Create a copy to avoid modification issues during async loop
    final idsToDelete = _selectedPostIds.toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('${idsToDelete.length}개의 게시물을 삭제하시겠습니까?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('삭제된 게시물은 복구할 수 없습니다.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              int deletedCount = 0;
              for (var id in idsToDelete) {
                try {
                  // Try numeric ID first, then fallback to string
                  final dynamic targetId = int.tryParse(id) ?? id;
                  await SupabaseService.client.from('posts').delete().eq('id', targetId);
                  deletedCount++;
                } catch (e) {
                  debugPrint('Delete error for $id: $e');
                }
              }
              
              setState(() {
                widget.allPosts.removeWhere((p) => idsToDelete.contains(p.id));
                _loadPosts();
                _selectedPostIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$deletedCount개의 게시물이 삭제되었습니다.')));
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _toggleHide() async {
    if (_selectedPostIds.isEmpty) return;
    final idsToToggle = _selectedPostIds.toList();
    int count = 0;
    
    for (var id in idsToToggle) {
      try {
        final post = widget.allPosts.firstWhere((p) => p.id == id);
        final dynamic targetId = int.tryParse(id) ?? id;
        
        // Use tags to store hidden state since is_hidden column is missing
        List<String> currentTags = List<String>.from(post.tags ?? []);
        bool currentlyHidden = currentTags.contains('#hidden#');
        
        if (currentlyHidden) {
          currentTags.remove('#hidden#');
        } else {
          currentTags.add('#hidden#');
        }
        
        await SupabaseService.client.from('posts').update({'tags': currentTags}).eq('id', targetId);
        
        setState(() {
          post.isHidden = !currentlyHidden;
          // Also update the tags in the object to stay in sync
          final index = widget.allPosts.indexWhere((p) => p.id == id);
          if (index != -1) {
            final List<String> updatedTags = List<String>.from(widget.allPosts[index].tags ?? []);
            if (currentlyHidden) updatedTags.remove('#hidden#'); else updatedTags.add('#hidden#');
            // We need a way to update tags in PostData, but for now let's use isHidden property
          }
        });
        count++;
      } catch (e) {
        debugPrint('Update error for $id: $e');
      }
    }
    
    setState(() {
      _loadPosts();
      _selectedPostIds.clear();
      _isSelectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count개의 게시물 상태가 변경되었습니다.')));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('로그아웃 하시겠습니까?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                gIsLoggedIn = false;
                gUserPoints = 0; // 지갑 즉시 압수!
              });
              gOnLogout?.call(); // 메인 화면에도 알림!
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
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
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const UploadScreen())
            ).then((newPost) {
              if (newPost != null && newPost is PostData) {
                setState(() {
                  widget.allPosts.insert(0, newPost);
                  _loadPosts();
                });
              }
            });
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
    String normalizedId(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    bool isMe = normalizedId(widget.uploaderId) == normalizedId('나의픽겟');

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
              if (isMe)
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _showSettingsMenu),
              if (!isMe)
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
                                if (isMe) ...[
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
                          onPressed: () async {
                            if (isMe) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityAnalysisScreen(userPosts: _channelPosts)));
                            } else {
                              if (!gIsLoggedIn) {
                                gShowLoginPopup?.call();
                                return;
                              }
                              final bool nowFollowing = !_isFollowing;
                              setState(() {
                                _isFollowing = nowFollowing;
                                // 동일 업로더의 모든 포스트 팔로우 상태 동기화
                                for (var p in widget.allPosts) {
                                  if (p.uploaderId == widget.uploaderId) {
                                    p.isFollowing = nowFollowing;
                                  }
                                }
                              });
                              HapticFeedback.mediumImpact();

                              try {
                                if (nowFollowing) {
                                  await SupabaseService.client
                                    .from('follows')
                                    .insert({'follower_id': gIdText, 'following_id': widget.uploaderId});
                                } else {
                                  await SupabaseService.client
                                    .from('follows')
                                    .delete()
                                    .match({'follower_id': gIdText, 'following_id': widget.uploaderId});
                                }
                              } catch (e) {
                                debugPrint('팔로우 서버 동기화 에러: $e');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (!isMe && _isFollowing) 
                              ? const Color(0xFF272727) 
                              : Colors.white,
                            foregroundColor: (!isMe && _isFollowing) 
                              ? Colors.white70 
                              : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe && _isFollowing) ...[
                                const Icon(Icons.check, size: 18),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                isMe 
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '공감도 ${() {
                                  int picks = 0;
                                  int likes = 0;
                                  for (var p in _channelPosts) {
                                    picks += _parseTotalVotes(p);
                                    likes += p.likesCount;
                                  }
                                  if (picks == 0) return "0";
                                  return ((likes / picks) * 200 + 70).toInt().clamp(70, 99).toString();
                                }()}%',
                                style: const TextStyle(
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
                          if (isMe)
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                                onPressed: _showPostManagementMenu,
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
      floatingActionButton: isMe ? _uploadButton() : null,
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

        // Calculate expired status
        bool isExpired = post.isExpired;
        if (!isExpired && post.tags != null) {
          final now = DateTime.now();
          for (var tag in post.tags!) {
            if (tag.startsWith('duration:')) {
              final mins = int.tryParse(tag.split(':')[1]);
              if (mins != null && now.isAfter(post.createdAt.add(Duration(minutes: mins)))) {
                isExpired = true;
              }
              break;
            }
          }
        }

        return GestureDetector(
          onLongPress: () {
            if (isMe) {
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
                if (_selectedPostIds.contains(post.id)) {
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
              
              // Status Badge (Top Left)
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.black.withValues(alpha: 0.6) : Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isExpired ? '선택종료' : '선택중',
                    style: TextStyle(
                      color: isExpired ? Colors.white70 : Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

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
                  right: 8, // Moved to right to avoid overlap with status badge
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
