import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_data.dart';
import '../widgets/post_view.dart';

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
                onLike: () {
                  setState(() {
                    post.isLiked = !post.isLiked;
                    if (post.isLiked) {
                      post.likesCount++;
                    } else {
                      post.likesCount--;
                    }
                  });
                  HapticFeedback.lightImpact();
                },
                onFollow: () {
                  setState(() {
                    bool newStatus = !post.isFollowing;
                    for (var p in widget.allPosts) {
                      if (p.uploaderId == post.uploaderId) {
                        p.isFollowing = newStatus;
                      }
                    }
                  });
                  HapticFeedback.mediumImpact();
                },
                onBookmark: () {
                  setState(() {
                    post.isBookmarked = !post.isBookmarked;
                  });
                  HapticFeedback.selectionClick();
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
                  setState(() {
                    post.userVotedSide = side;
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
        ],
      ),
    );
  }
}
