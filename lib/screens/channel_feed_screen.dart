import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../widgets/post_view.dart';
import '../core/app_state.dart';
import 'channel_screen.dart';
import '../services/supabase_service.dart';

class ChannelFeedScreen extends StatefulWidget {
  final int initialIndex;
  final List<PostData> channelPosts;
  final List<PostData> allPosts;

  const ChannelFeedScreen({
    super.key,
    required this.initialIndex,
    required this.channelPosts,
    required this.allPosts,
  });

  @override
  State<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends State<ChannelFeedScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            itemCount: widget.channelPosts.length,
            itemBuilder: (context, index) {
              final post = widget.channelPosts[index];
              return PostView(
                key: ValueKey('channel_feed_${post.id}'),
                post: post,
                onLike: () async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  final bool nowLiked = !post.isLiked;
                  setState(() {
                    post.isLiked = nowLiked;
                    if (nowLiked) {
                      post.likesCount++;
                    } else {
                      post.likesCount--;
                    }
                  });
                  HapticFeedback.lightImpact();

                  try {
                    if (nowLiked) {
                      await SupabaseService.client.from('likes').insert({
                        'user_id': gUserInternalId,
                        'post_id': post.id,
                      });
                      // 포인트 적립 (+1P)
                      await SupabaseService.client.from('points_history').insert({
                        'user_id': gUserInternalId,
                        'amount': 1,
                        'description': '게시물 좋아요 보너스',
                      });
                    } else {
                      await SupabaseService.client.from('likes').delete().match({
                        'user_id': gUserInternalId!,
                        'post_id': post.id,
                      });
                    }
                    // 게시물 테이블의 좋아요 수 업데이트
                    await SupabaseService.client.from('posts').update({
                      'likes_count': post.likesCount
                    }).eq('id', post.id);
                  } catch (e) {
                    print('좋아요 동기화 에러: $e');
                  }
                },
                onFollow: () async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  final bool nowFollowing = !post.isFollowing;
                  setState(() {
                    for (var p in widget.allPosts) {
                      if (p.uploaderId == post.uploaderId) {
                        p.isFollowing = nowFollowing;
                      }
                    }
                  });
                  HapticFeedback.mediumImpact();

                  try {
                    if (nowFollowing) {
                      await SupabaseService.client.from('follows').insert({
                        'follower_internal_id': gUserInternalId!,
                        'following_internal_id': post.uploaderInternalId!,
                      });
                    } else {
                      await SupabaseService.client.from('follows').delete().match({
                        'follower_internal_id': gUserInternalId!,
                        'following_internal_id': post.uploaderInternalId!,
                      });
                    }
                  } catch (e) {
                    print('팔로우 동기화 에러: $e');
                  }
                },
                onBookmark: () async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  final bool nowBookmarked = !post.isBookmarked;
                  setState(() {
                    post.isBookmarked = nowBookmarked;
                  });
                  HapticFeedback.selectionClick();

                  try {
                    if (nowBookmarked) {
                      await SupabaseService.client.from('bookmarks').insert({
                        'user_id': gUserInternalId!,
                        'post_id': post.id,
                      });
                    } else {
                      await SupabaseService.client.from('bookmarks').delete().match({
                        'user_id': gUserInternalId!,
                        'post_id': post.id,
                      });
                    }
                  } catch (e) {
                    print('즐겨찾기 동기화 에러: $e');
                  }
                },
                onNotInterested: () {
                  setState(() {
                    widget.channelPosts.removeAt(index);
                    if (widget.channelPosts.isEmpty) Navigator.pop(context);
                  });
                },
                onDontRecommendChannel: () {
                  Navigator.pop(context);
                },
                onReport: (reason) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('신고가 접수되었습니다: $reason'), duration: const Duration(seconds: 1))
                  );
                },
                onVote: (side) {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  setState(() {
                    post.userVotedSide = side;
                  });
                },
                onDelete: (postId) {
                  setState(() {
                    widget.channelPosts.removeWhere((p) => p.id == postId);
                    widget.allPosts.removeWhere((p) => p.id == postId);
                    if (widget.channelPosts.isEmpty) {
                      Navigator.pop(context);
                    }
                  });
                },
                onToggleHide: (postId) async {
                  setState(() {
                    post.isHidden = !post.isHidden;
                  });
                  try {
                    await SupabaseService.client
                        .from('posts')
                        .update({'tags': post.isHidden ? [...(post.tags ?? []), '#hidden#'] : (post.tags ?? []).where((t) => t != '#hidden#').toList()})
                        .eq('id', postId);
                  } catch (e) {
                    print('숨기기 동기화 에러: $e');
                  }
                },
                onProfileTap: () {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
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
              );
            },
          ),
          // 상단 뒤로가기 버튼 (플로팅)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // 상단 홈 버튼 (플로팅 - 한 번에 메인으로)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              ),
              onPressed: () {
                // 첫 화면(메인)이 나올 때까지 모든 화면을 닫음
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),
        ],
      ),
    );
  }
}
