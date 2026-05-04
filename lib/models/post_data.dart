import 'comment_data.dart';

class PostData {
  final String id;
  final String title;
  String uploaderId;
  final String? uploaderInternalId; // 🆔 주민번호 필드 추가!
  String uploaderName;
  String uploaderImage;
  final String timeLocation;
  final String imageA;
  final String imageB;
  final String? thumbA;
  final String? thumbB;
  final String descriptionA;
  final String descriptionB;
  int likesCount;
  int commentsCount;
  String voteCountA;
  String voteCountB;
  String percentA;
  String percentB;
  bool isFollowing;
  bool isBookmarked;
  bool isLiked;
  bool isHidden;
  final String fullDescription;
  bool isExpired;
  int userVotedSide; // 0: none, 1: A, 2: B
  List<CommentData> comments;
  final String? shortDescA;
  final String? shortDescB;
  final List<String>? tags;
  final int? durationMinutes;
  final int? targetPickCount;
  final DateTime createdAt;
  int totalVotesCount;
  final bool isAdult;
  final bool isAi;
  final bool isAd;
  
  DateTime get endTime => createdAt.add(Duration(minutes: durationMinutes ?? 1440));
  
  // 🗳️ 진짜 투표수 합계 계산 (DB 컬럼이 있으면 우선 사용, 없으면 직접 계산)
  int get totalVotes {
    if (totalVotesCount > 0) return totalVotesCount;
    
    int parseV(String s) {
      s = s.toLowerCase().replaceAll(',', '').trim();
      if (s.isEmpty) return 0;
      if (s.endsWith('k')) {
        return ((double.tryParse(s.substring(0, s.length - 1)) ?? 0) * 1000).toInt();
      }
      return int.tryParse(s) ?? 0;
    }
    return parseV(voteCountA) + parseV(voteCountB);
  }

  PostData({
    required this.id,
    required this.title,
    required this.uploaderId,
    this.uploaderInternalId,
    required this.uploaderName,
    required this.uploaderImage,
    required this.timeLocation,
    required this.imageA,
    required this.imageB,
    this.thumbA,
    this.thumbB,
    required this.descriptionA,
    required this.descriptionB,
    this.shortDescA,
    this.shortDescB,
    this.tags,
    this.durationMinutes,
    this.targetPickCount,
    DateTime? createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.voteCountA,
    required this.voteCountB,
    required this.percentA,
    required this.percentB,
    this.isFollowing = false,
    this.isBookmarked = false,
    this.isLiked = false,
    this.isHidden = false,
    this.fullDescription = "이 포스트에 대한 상세 설명이 여기에 표시됩니다.",
    this.isExpired = false,
    this.isAdult = false,
    this.isAi = false,
    this.isAd = false,
    this.userVotedSide = 0,
    this.totalVotesCount = 0, // 기본값 추가
    List<CommentData>? comments,
  }) : createdAt = createdAt ?? DateTime.now(),
       comments = comments ?? [];

  // 🏛️ [신규] DB 데이터를 PostData 객체로 변환하는 정석 생성자
  factory PostData.fromMap(Map<String, dynamic> map) {
    return PostData(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      uploaderId: map['uploader_id']?.toString() ?? 'anonymous',
      uploaderInternalId: map['uploader_internal_id']?.toString(),
      uploaderName: map['uploader_name']?.toString() ?? '익명',
      uploaderImage: map['uploader_image']?.toString() ?? '',
      timeLocation: '', // 필요 시 DB 컬럼 추가
      imageA: map['image_a']?.toString() ?? '',
      imageB: map['image_b']?.toString() ?? '',
      thumbA: map['thumb_a']?.toString(),
      thumbB: map['thumb_b']?.toString(),
      descriptionA: map['description_a']?.toString() ?? '',
      descriptionB: map['description_b']?.toString() ?? '',
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      voteCountA: map['vote_count_a']?.toString() ?? '0',
      voteCountB: map['vote_count_b']?.toString() ?? '0',
      percentA: '50%', // 초기값
      percentB: '50%', // 초기값
      fullDescription: map['full_description']?.toString() ?? '',
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList(),
      durationMinutes: map['duration_minutes'],
      targetPickCount: map['target_pick_count'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      isAdult: map['is_adult'] ?? false,
      isAi: map['is_ai'] ?? false,
      isAd: map['is_ad'] ?? false,
      isHidden: map['is_hidden'] ?? false,
    );
  }
}
