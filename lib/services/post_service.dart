import 'package:flutter/services.dart';

import '../core/app_state.dart';
import 'package:flutter/foundation.dart';
import '../models/post_data.dart';
import '../services/supabase_service.dart';

class PostService {
  static Future<void> toggleLike(PostData post) async {
    if (!gIsLoggedIn || gUserInternalId == null) return;

    final bool wasLiked = post.isLiked;
    final int previousLikesCount = post.likesCount;
    final bool nowLiked = !wasLiked;

    post.isLiked = nowLiked;
    if (nowLiked) {
      post.likesCount++;
      gLikedPostIds.add(post.id);
    } else {
      post.likesCount = (post.likesCount - 1).clamp(0, 999999);
      gLikedPostIds.remove(post.id);
    }
    HapticFeedback.lightImpact();

    try {
      if (nowLiked) {
        await SupabaseService.client.from('likes').insert({
          'user_id': gUserInternalId!,
          'post_id': post.id,
        });
      } else {
        await SupabaseService.client.from('likes').delete().match({
          'user_id': gUserInternalId!,
          'post_id': post.id,
        });
      }

      post.likesCount = await _syncPostLikesCountFromServer(post.id);
    } catch (e) {
      post.isLiked = wasLiked;
      post.likesCount = previousLikesCount;
      if (wasLiked) {
        gLikedPostIds.add(post.id);
      } else {
        gLikedPostIds.remove(post.id);
      }
      print('DEBUG [PostService]: Like sync error: $e');
    }
  }

  static Future<int> _syncPostLikesCountFromServer(String postId) async {
    try {
      final dynamic syncedCount = await SupabaseService.client.rpc(
        'sync_post_likes_count',
        params: {'target_post_id': postId},
      );

      if (syncedCount is int) return syncedCount;
      if (syncedCount is num) return syncedCount.toInt();
    } catch (_) {
      // Older databases may not have the RPC yet. Fall back to a server recount.
    }

    final List<dynamic> likes = await SupabaseService.client
        .from('likes')
        .select('post_id')
        .eq('post_id', postId);

    final int serverLikesCount = likes.length;

    await SupabaseService.client
        .from('posts')
        .update({'likes_count': serverLikesCount})
        .eq('id', postId);

    return serverLikesCount;
  }

  static Future<void> toggleFollow(
    PostData post, {
    List<PostData>? allPosts,
  }) async {
    if (!gIsLoggedIn ||
        gUserInternalId == null ||
        post.uploaderInternalId == null) {
      return;
    }

    final bool nowFollowing = !post.isFollowing;
    final String targetInternalId = post.uploaderInternalId!;

    post.isFollowing = nowFollowing;
    if (nowFollowing) {
      gFollowedUserIds.add(targetInternalId);
    } else {
      gFollowedUserIds.remove(targetInternalId);
    }

    if (allPosts != null) {
      for (final p in allPosts) {
        if (p.uploaderInternalId == targetInternalId) {
          p.isFollowing = nowFollowing;
        }
      }
    }
    HapticFeedback.mediumImpact();

    try {
      if (nowFollowing) {
        await SupabaseService.client.from('follows').insert({
          'follower_internal_id': gUserInternalId!,
          'following_internal_id': targetInternalId,
        });
      } else {
        await SupabaseService.client.from('follows').delete().match({
          'follower_internal_id': gUserInternalId!,
          'following_internal_id': targetInternalId,
        });
      }
    } catch (e) {
      print('DEBUG [PostService]: Follow sync error: $e');
    }
  }

  static Future<void> toggleBookmark(PostData post) async {
    if (!gIsLoggedIn || gUserInternalId == null) return;

    final bool nowBookmarked = !post.isBookmarked;

    post.isBookmarked = nowBookmarked;
    if (nowBookmarked) {
      gBookmarkedPostIds.add(post.id);
    } else {
      gBookmarkedPostIds.remove(post.id);
    }
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
      print('DEBUG [PostService]: Bookmark sync error: $e');
    }
  }

  static Future<void> toggleHide(PostData post) async {
    if (!gIsLoggedIn || gUserInternalId == null) return;

    final bool nowHidden = !post.isHidden;
    post.isHidden = nowHidden;

    try {
      await SupabaseService.client.from('posts').update({
        'tags': nowHidden
            ? [...(post.tags ?? []), '#hidden#']
            : (post.tags ?? []).where((t) => t != '#hidden#').toList(),
      }).eq('id', post.id);
    } catch (e) {
      print('DEBUG [PostService]: Hide sync error: $e');
    }
  }

  // 🚀 [표준] CDN 주소 변환기 (모든 화면 공용)
  static String toCdnUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) {
      if (url.contains('supabase.co/storage/v1/object/public/')) {
        return url.replaceFirst(
          RegExp(r'https://.*\.supabase\.co/storage/v1/object/public/'),
          'https://cdn.pickget.net/',
        );
      }
      return url;
    }
    if (url.startsWith('assets/')) return url;
    return url;
  }

  static PostData mapToPostData(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final String handle = json['uploader_id']?.toString() ?? '';
    final String? internalId = json['uploader_internal_id']?.toString() ?? profile?['id']?.toString();
    
    final String latestId = (profile != null && profile['user_id'] != null)
        ? profile['user_id'].toString()
        : handle;
    final String nickname = (profile != null && profile['nickname'] != null)
        ? profile['nickname'].toString()
        : (json['uploader_name'] ?? json['uploader_id'] ?? '익명');
    
    final String profileImg = toCdnUrl(
        (profile != null && profile['profile_image'] != null)
        ? profile['profile_image'].toString()
        : (json['user_image'] ?? ''));

    final bool isPostLiked = gIsLoggedIn && gLikedPostIds.contains(json['id'].toString());
    int initialLikesCount = json['likes_count'] ?? 0;
    if (isPostLiked && initialLikesCount < 1) initialLikesCount = 1;

    return PostData(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      uploaderId: latestId,
      uploaderInternalId: internalId,
      uploaderName: nickname,
      uploaderImage: profileImg,
      timeLocation: _calculateTimeLocation(json['created_at']),
      imageA: toCdnUrl(json['image_a'] ?? ''),
      imageB: toCdnUrl(json['image_b'] ?? ''),
      thumbA: toCdnUrl(json['thumb_a'] ?? ''),
      thumbB: toCdnUrl(json['thumb_b'] ?? ''),
      descriptionA: json['description_a'] ?? '',
      descriptionB: json['description_b'] ?? '',
      fullDescription: json['full_description'] ?? '',
      likesCount: initialLikesCount,
      commentsCount: json['comments_count'] ?? 0,
      voteCountA: json['vote_count_a']?.toString() ?? '0',
      voteCountB: json['vote_count_b']?.toString() ?? '0',
      totalVotesCount: json['total_votes_count'] ?? 0,
      percentA: json['percent_a']?.toString() ?? '50%',
      percentB: json['percent_b']?.toString() ?? '50%',
      isFollowing: gFollowedUserIds.contains(internalId),
      isLiked: isPostLiked,
      isBookmarked: gIsLoggedIn && gBookmarkedPostIds.contains(json['id'].toString()),
      userVotedSide: gUserVotes[json['id'].toString()] ?? 0,
      isExpired: _checkExpired(json),
      durationMinutes: _getDuration(json),
      isAdult: json['is_adult'] ?? false,
      isAi: json['is_ai'] ?? false,
      isAd: json['is_ad'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isHidden: (json['tags'] as List?)?.contains('#hidden#') ?? false,
    );
  }

  static String _calculateTimeLocation(String? createdAtStr) {
    if (createdAtStr == null) return '';
    final ca = DateTime.parse(createdAtStr);
    final diff = DateTime.now().difference(ca);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${ca.month}월 ${ca.day}일';
  }

  static bool _checkExpired(Map<String, dynamic> json) {
    bool exp = json['is_expired'] ?? false;
    if (exp) return true;
    final tags = (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final createdAtStr = json['created_at'];
    if (createdAtStr != null) {
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt != null) {
        for (var tag in tags) {
          if (tag.startsWith('duration:')) {
            final mins = int.tryParse(tag.split(':')[1]);
            if (mins != null && DateTime.now().isAfter(createdAt.add(Duration(minutes: mins)))) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  static int? _getDuration(Map<String, dynamic> json) {
    int? dm = json['duration_minutes'];
    if (dm != null) return dm;
    final tags = (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];
    for (var tag in tags) {
      if (tag.startsWith('duration:')) return int.tryParse(tag.split(':')[1]);
    }
    return null;
  }

  static PostData createMockPost({
    required String uploaderId,
    required String? uploaderInternalId,
    required String uploaderName,
    required String uploaderImage,
  }) {
    return PostData(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: '$uploaderName님의 PICKGET 공간',
      uploaderId: uploaderId,
      uploaderInternalId: uploaderInternalId,
      uploaderName: uploaderName,
      uploaderImage: uploaderImage,
      timeLocation: '활동 중',
      imageA: '',
      imageB: '',
      thumbA: '',
      thumbB: '',
      descriptionA: '',
      descriptionB: '',
      fullDescription: '이 유저의 포스트가 현재 로드되지 않았습니다.',
      likesCount: 0,
      commentsCount: 0,
      voteCountA: '0',
      voteCountB: '0',
      totalVotesCount: 0,
      percentA: '50%',
      percentB: '50%',
      tags: [],
      isExpired: false,
    );
  }

  // 🚩 [신규] 중앙 집중형 신고 로직: 앱 어디서든 이 함수만 호출하면 신고 완료!
  static Future<bool> submitReport({
    required String postId,
    required String? reportedInternalId,
    required String reason,
  }) async {
    if (gUserInternalId == null) return false;
    try {
      await SupabaseService.client.from('reports').insert({
        'reporter_internal_id': gUserInternalId,
        'reported_internal_id': reportedInternalId,
        'post_id': postId,
        'reason': reason,
      });
      debugPrint('DEBUG [REPORT]: 신고 성공 - 사유: $reason / 대상: $reportedInternalId');
      return true;
    } catch (e) {
      debugPrint('DEBUG [REPORT]: 신고 실패 - $e');
      return false;
    }
  }
}
