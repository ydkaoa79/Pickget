import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  double _empathyRate = 0.0; // [신규] 진짜 공감도 저장을 위한 변수
  int _followerCount = 0; // [신규] 실제 팔로워 수

  bool get isMe {
    // 🆔 오직 주민번호(UUID) 하나로만 판단 (진짜 정석!)
    String nId(String? s) => (s ?? '').trim().toLowerCase();
    
    if (widget.initialPost.uploaderInternalId != null && gUserInternalId != null) {
      if (nId(widget.initialPost.uploaderInternalId) == nId(gUserInternalId)) {
        return true;
      }
    }
    
    // 예외/안전장치 (아이디 기반)
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    return normalized(widget.uploaderId) == normalized(gIdText) || 
           widget.uploaderId == 'me';
  }

  @override
  void initState() {
    super.initState();
    // 🏛️ 정석 데이터 초기화!
    if (isMe) {
      _dName = gNameText;
      _dImg = gProfileImage;
      _dBio = gBioText;
    } else {
      _dName = widget.initialPost.uploaderName; // 진짜 이름을 이름 자리에!
      _dImg = widget.initialPost.uploaderImage;
      _dBio = '안녕하세요! ${widget.initialPost.uploaderName}의 픽겟 공간입니다. ✨';
      _isFollowing = widget.initialPost.isFollowing;
    }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPosts();
    _calculateRealEmpathy(); // [신규] 진짜 공감도 계산 시작
    _fetchFollowerCount(); // [신규] 실제 팔로워 수 조회

    // 🏛️ 정석 강제 새로고침: 혹시 모를 인식 지연을 방지하기 위해 0.1초 뒤 다시 확인!
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  // 🏛️ [활동분석 정석 로직 이식] 진짜 공감도 계산 함수
  Future<void> _calculateRealEmpathy() async {
    try {
      final String? targetInternalId = isMe ? gUserInternalId : widget.initialPost.uploaderInternalId;
      if (targetInternalId == null) return;

      // 1. 투표 참여 내역 가져오기
      final List<dynamic> myVotes = await SupabaseService.client
          .from('votes')
          .select('post_id, side')
          .eq('user_internal_id', targetInternalId);

      int votedCount = 0;
      int matchCount = 0;

      if (myVotes.isNotEmpty) {
        for (var vote in myVotes) {
          final postId = vote['post_id'].toString();
          final mySide = vote['side'] as int;

          final postData = await SupabaseService.client
              .from('posts')
              .select('vote_count_a, vote_count_b, created_at, tags')
              .eq('id', postId)
              .maybeSingle();

          if (postData != null) {
            // 종료 여부 직접 계산 (활동분석 로직과 동일)
            bool isExpiredPost = false;
            final String? createdAtStr = postData['created_at'];
            final List<dynamic> tags = postData['tags'] as List? ?? [];
            
            if (createdAtStr != null) {
              final createdAt = DateTime.tryParse(createdAtStr);
              if (createdAt != null) {
                for (var tag in tags) {
                  String t = tag.toString();
                  if (t.startsWith('duration:')) {
                    final mins = int.tryParse(t.split(':')[1]);
                    if (mins != null && DateTime.now().isAfter(createdAt.add(Duration(minutes: mins)))) {
                      isExpiredPost = true;
                    }
                  }
                }
              }
            }

            if (!isExpiredPost) continue; 

            votedCount++; 
            int countA = _parseTotalVotesRaw(postData['vote_count_a']?.toString() ?? '0');
            int countB = _parseTotalVotesRaw(postData['vote_count_b']?.toString() ?? '0');
            int winnerSide = (countA > countB) ? 1 : (countB > countA ? 2 : 0);
            
            if (mySide == winnerSide || winnerSide == 0) {
              matchCount++;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _empathyRate = votedCount > 0 ? (matchCount / votedCount) * 100 : 0.0;
        });
      }
    } catch (e) {
      print('채널 공감도 계산 실패: $e');
    }
  }

  bool _isVideo(String url) {
    final path = url.toLowerCase();
    return path.endsWith('.mp4') || 
           path.endsWith('.mov') || 
           path.endsWith('.m4v') || 
           path.endsWith('.avi') || 
           path.endsWith('.wmv') || 
           path.endsWith('.mkv') || 
           path.endsWith('.3gp');
  }

  int _parseTotalVotesRaw(String s) {
    s = s.toLowerCase().replaceAll(',', '').trim();
    if (s.isEmpty) return 0;
    if (s.endsWith('k')) return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
    return int.tryParse(s) ?? 0;
  }

  // 🏛️ [신규] 실제 팔로워 수 조회 함수
  Future<void> _fetchFollowerCount() async {
    try {
      final String? targetInternalId = isMe ? gUserInternalId : widget.initialPost.uploaderInternalId;
      if (targetInternalId == null) return;

      // follows 테이블에서 나를 팔로우한 데이터를 가져와 개수를 셉니다. (정확한 컬럼명 적용)
      final List<dynamic> response = await SupabaseService.client
          .from('follows')
          .select('id')
          .eq('following_internal_id', targetInternalId);
      
      if (mounted) {
        setState(() {
          _followerCount = response.length;
        });
      }
    } catch (e) {
      print('팔로워 수 조회 실패: $e');
    }
  }

  void _loadPosts() {
    String normalized(String id) => id.replaceAll(RegExp(r'[@\s_]'), '').trim();
    String currentChannelId = normalized(widget.uploaderId);

    setState(() {
      _channelPosts = widget.allPosts.where((p) {
        // 🆔 주민번호(UUID) 기반 정석 필터링!
        if (isMe) {
          // 내 채널일 때: 내 주민번호와 일치하는 것만!
          return p.uploaderInternalId == gUserInternalId;
        } else {
          // 타인 페이지일 경우: 그 사람의 주민번호와 일치하는 것만!
          bool isSameOwner = (p.uploaderInternalId != null && p.uploaderInternalId == widget.initialPost.uploaderInternalId);
          return isSameOwner && !p.isHidden;
        }
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
              const SizedBox(height: 20),
              const Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
              List<String> successIds = [];
              for (var id in idsToDelete) {
                try {
                  // 🔥 [핵심] 외래 키 제약 때문에 연관 데이터 먼저 삭제 후 게시물 삭제!
                  await Future.wait([
                    SupabaseService.client.from('votes').delete().eq('post_id', id),
                    SupabaseService.client.from('comments').delete().eq('post_id', id),
                    SupabaseService.client.from('likes').delete().eq('post_id', id),
                    SupabaseService.client.from('bookmarks').delete().eq('post_id', id),
                  ]);
                  // 연관 데이터 삭제 완료 후 게시물 삭제
                  await SupabaseService.client.from('posts').delete().eq('id', id);
                  successIds.add(id);
                } catch (e) {
                  debugPrint('Delete error for $id: $e');
                }
              }
              
              setState(() {
                widget.allPosts.removeWhere((p) => successIds.contains(p.id));
                _loadPosts();
                _selectedPostIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${successIds.length}개의 게시물이 삭제되었습니다.')));
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
        
        // Use isHidden property to get the true current state
        bool currentlyHidden = post.isHidden;
        List<String> currentTags = List<String>.from(post.tags ?? []);
        
        if (currentlyHidden) {
          currentTags.remove('#hidden#');
        } else {
          if (!currentTags.contains('#hidden#')) {
            currentTags.add('#hidden#');
          }
        }
        
        await SupabaseService.client.from('posts').update({'tags': currentTags}).eq('id', targetId);
        
        setState(() {
          post.isHidden = !currentlyHidden;
          // Update the internal tags list content directly
          if (post.tags != null) {
            if (currentlyHidden) {
              post.tags!.remove('#hidden#');
            } else {
              if (!post.tags!.contains('#hidden#')) post.tags!.add('#hidden#');
            }
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
    return post.totalVotes;
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
              if (isMe)
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: _showSettingsMenu),
              if (!isMe)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white), 
                  padding: const EdgeInsets.all(12), // 터치 영역 확대를 위해 패딩 추가
                  onPressed: _showMoreMenu
                ),
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
                      Builder(builder: (_) {
                        final img = (isMe ? gProfileImage : _dImg).trim();
                        return img.isEmpty
                          ? const CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.person, color: Colors.white54, size: 40),
                            )
                          : CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.black,
                              backgroundImage: img.startsWith('http')
                                ? NetworkImage(img)
                                : AssetImage(img) as ImageProvider,
                            );
                      }),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isMe ? gNameText : _dName, // 🏛️ 주인님이면 최신 이름을, 아니면 소환된 이름을!
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
                                            // 🎯 내 게시물 정보들도 실시간으로 동기화 (메인 안 나가도 바로 보이게!)
                                            for (var p in widget.allPosts) {
                                              if (p.uploaderInternalId == gUserInternalId) {
                                                p.uploaderId = res['id'];
                                                p.uploaderName = res['name'];
                                                p.uploaderImage = res['image'];
                                              }
                                            }
                                            // Global Feed Refresh!
                                            gRefreshFeed?.call();
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
                              "@${isMe ? gIdText : widget.uploaderId}", // 🆔 진짜 아이디 (@...)
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "팔로워 ${formatCount(_followerCount)} · 콘텐츠 ${formatCount(_channelPosts.length)}",
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
                            isMe ? gBioText : _dBio,
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActivityAnalysisScreen(
                                    targetInternalId: gUserInternalId!,
                                    targetNickname: gNameText,
                                    targetProfileImage: gProfileImage,
                                  ),
                                ),
                              );
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
                                    .insert({
                                      'follower_internal_id': gUserInternalId!, 
                                      'following_internal_id': widget.initialPost.uploaderInternalId!
                                    });
                                } else {
                                  await SupabaseService.client
                                    .from('follows')
                                    .delete()
                                    .match({
                                      'follower_internal_id': gUserInternalId!, 
                                      'following_internal_id': widget.initialPost.uploaderInternalId!
                                    });
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
                        child: GestureDetector(
                          onTap: () {
                            if (!isMe) return; // 🛡️ [보안] 내 채널이 아니면 상세 분석을 볼 수 없습니다!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityAnalysisScreen(
                                  targetInternalId: widget.initialPost.uploaderInternalId!,
                                  targetNickname: isMe ? gNameText : _dName,
                                  targetProfileImage: isMe ? gProfileImage : _dImg,
                                ),
                              ),
                            );
                          },
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
                                  '공감도 ${_empathyRate.toInt()}%',
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
                              _profileTab('댓글순', 2),
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
    // 탭 인덱스에 따라 리스트 정렬
    List<PostData> sortedPosts = List.from(_channelPosts);
    int tabIndex = _tabController.index;

    if (tabIndex == 0) {
      // 최신순
      sortedPosts.sort((a, b) => (b.createdAt).compareTo(a.createdAt));
    } else if (tabIndex == 1) {
      // 픽순
      sortedPosts.sort((a, b) => b.totalVotes.compareTo(a.totalVotes));
    } else if (tabIndex == 2) {
      // 댓글순
      sortedPosts.sort((a, b) => b.commentsCount.compareTo(a.commentsCount));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: sortedPosts.length,
      itemBuilder: (context, index) {
        final post = sortedPosts[index];
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
                MaterialPageRoute(builder: (context) => ChannelFeedScreen(initialIndex: index, channelPosts: sortedPosts, allPosts: widget.allPosts,)),
              ).then((_) {
                if (mounted) {
                  setState(() {
                    _loadPosts();
                  });
                }
              });
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              (post.thumbA != null && post.thumbA!.isNotEmpty)
                ? Opacity(
                    opacity: post.isHidden ? 0.5 : 1.0,
                    child: CachedNetworkImage(
                      imageUrl: post.thumbA!.trim(),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                    ),
                  )
                : (_isVideo(post.imageA)
                   ? Container(color: Colors.black26, child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54)))
                   : (post.imageA.trim().contains('http')
                        ? Opacity(
                            opacity: post.isHidden ? 0.5 : 1.0,
                            child: CachedNetworkImage(
                              imageUrl: post.imageA.trim(),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.white10),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                            ),
                          )
                        : Image.asset(post.imageA.trim(), fit: BoxFit.cover, opacity: post.isHidden ? const AlwaysStoppedAnimation(0.5) : null))),
              
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
