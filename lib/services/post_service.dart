import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_data.dart';
import '../core/app_state.dart';
import '../services/supabase_service.dart';

class PostService {
  /// ❤️ 좋아요 처리 (토글)
  static Future<void> toggleLike(PostData post) async {
    if (!gIsLoggedIn || gUserInternalId == null) return;

    final bool nowLiked = !post.isLiked;
    
    // 1. 메모리/전역 상태 선반영
    post.isLiked = nowLiked;
    if (nowLiked) {
      post.likesCount++;
      gLikedPostIds.add(post.id);
    } else {
      post.likesCount = (post.likesCount - 1).clamp(0, 999999);
      gLikedPostIds.remove(post.id);
    }
    HapticFeedback.lightImpact();

    // 2. 서버 동기화
    try {
      if (nowLiked) {
        await SupabaseService.client.from('likes').insert({
          'user_id': gUserInternalId,
          'post_id': post.id,
        });
      } else {
        await SupabaseService.client.from('likes').delete().match({
          'user_id': gUserInternalId!,
          'post_id': post.id,
        });
      }
      
      // 게시물 테이블 숫자 업데이트
      await SupabaseService.client.from('posts').update({
        'likes_count': post.likesCount
      }).eq('id', post.id);
    } catch (e) {
      print('DEBUG [PostService]: Like sync error: $e');
    }
  }

  /// 👤 팔로우 처리 (토글)
  static Future<void> toggleFollow(PostData post, {List<PostData>? allPosts}) async {
    if (!gIsLoggedIn || gUserInternalId == null || post.uploaderInternalId == null) return;

    final bool nowFollowing = !post.isFollowing;
    final String targetInternalId = post.uploaderInternalId!;

    // 1. 메모리/전역 상태 선반영
    post.isFollowing = nowFollowing;
    if (nowFollowing) {
      gFollowedUserIds.add(targetInternalId);
    } else {
      gFollowedUserIds.remove(targetInternalId);
    }
    
    // 화면에 있는 같은 작성자의 다른 글들도 팔로우 상태 업데이트
    if (allPosts != null) {
      for (var p in allPosts) {
        if (p.uploaderInternalId == targetInternalId) {
          p.isFollowing = nowFollowing;
        }
      }
    }
    HapticFeedback.mediumImpact();

    // 2. 서버 동기화
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

  /// 🔖 즐겨찾기(북마크) 처리 (토글)
  static Future<void> toggleBookmark(PostData post) async {
    if (!gIsLoggedIn || gUserInternalId == null) return;

    final bool nowBookmarked = !post.isBookmarked;
    
    // 1. 메모리/전역 상태 선반영
    post.isBookmarked = nowBookmarked;
    if (nowBookmarked) {
      gBookmarkedPostIds.add(post.id);
    } else {
      gBookmarkedPostIds.remove(post.id);
    }
    HapticFeedback.selectionClick();

    // 2. 서버 동기화
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

  /// 🚫 숨기기 처리 (토글)
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
