import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../widgets/post_view.dart';
import '../core/app_state.dart';
import 'channel_screen.dart';
import '../services/supabase_service.dart';
import '../services/post_service.dart';

class ChannelFeedScreen extends StatefulWidget {
  final int initialIndex;
  final List<PostData> channelPosts;
  final List<PostData> allPosts;
  final Future<void> Function()? onLoadMore;

  const ChannelFeedScreen({
    super.key,
    required this.initialIndex,
    required this.channelPosts,
    required this.allPosts,
    this.onLoadMore,
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
            onPageChanged: (index) async {
              if (index >= widget.channelPosts.length - 5) {
                await widget.onLoadMore?.call();
                if (mounted) setState(() {});
              }
            },
            itemBuilder: (context, index) {
              final post = widget.channelPosts[index];
              return PostView(
                key: ValueKey('channel_feed_${post.id}'),
                post: post,
                onNotInterested: () {
                  setState(() {
                    widget.channelPosts.removeAt(index);
                    if (widget.channelPosts.isEmpty) Navigator.pop(context);
                  });
                },
                onDontRecommendChannel: () {
                  Navigator.pop(context);
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
                onToggleHide: (postId) {
                  PostService.toggleHide(post);
                  setState(() {
                    widget.channelPosts.removeWhere((p) => p.id == postId);
                    if (widget.channelPosts.isEmpty) Navigator.pop(context);
                  });
                },
                onVote: (side) {
                  setState(() {
                    post.userVotedSide = side;
                  });
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
                onReport: (reason) async {
                  if (!gIsLoggedIn) {
                    gShowLoginPopup?.call();
                    return;
                  }
                  await PostService.submitReport(
                    postId: post.id,
                    reportedInternalId: post.uploaderInternalId,
                    reason: reason,
                  );
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
