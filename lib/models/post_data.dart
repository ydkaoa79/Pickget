import 'comment_data.dart';

class PostData {
  final String id;
  final String title;
  final String uploaderId;
  final String? uploaderInternalId; // 🆔 주민번호 필드 추가!
  final String uploaderName;
  final String uploaderImage;
  final String timeLocation;
  final String imageA;
  final String imageB;
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
  
  DateTime get endTime => createdAt.add(Duration(minutes: durationMinutes ?? 1440));

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
    this.userVotedSide = 0,
    List<CommentData>? comments,
  }) : createdAt = createdAt ?? DateTime.now(),
       comments = comments ?? [];
}
