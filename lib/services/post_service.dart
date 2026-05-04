import 'package:flutter/services.dart';

import '../core/app_state.dart';
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
}
