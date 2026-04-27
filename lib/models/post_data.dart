import 'comment_data.dart';

class PostData {
  final String id;
  final String title;
  final String uploaderId;
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
  bool isFollowing = false;
  bool isBookmarked = false;
  bool isLiked = false;
  bool isHidden = false;
  final String fullDescription;
  bool isExpired = false;
  int userVotedSide = 0; // 0: none, 1: A, 2: B
  List<CommentData> comments;
  final String? shortDescA;
  final String? shortDescB;
  final List<String>? tags;

  PostData({
    required this.id,
    required this.title,
    required this.uploaderId,
    required this.uploaderImage,
    required this.timeLocation,
    required this.imageA,
    required this.imageB,
    required this.descriptionA,
    required this.descriptionB,
    this.shortDescA,
    this.shortDescB,
    this.tags,
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
    this.fullDescription = "이 포스트에 대한 상세 설명이 여기에 표시됩니다. 업로드 시 입력한 기타 설명글이 나타나는 공간입니다.",
    this.isExpired = false,
    this.userVotedSide = 0,
    List<CommentData>? comments,
  }) : comments = comments ?? [
    CommentData(user: '멋진 여행자', text: '와! 저는 A가 훨씬 세련되어 보여요. 스타일이 딱 제 취향!', side: 1, image: 'assets/profiles/profile_15.jpg'),
    CommentData(user: '패션매니아', text: '에이, 그래도 겨울엔 레드 포인트가 있는 B가 진리죠!', side: 2, image: 'assets/profiles/profile_20.jpg'),
    CommentData(user: '깔끔쟁이', text: 'A의 사이언 컬러가 사진의 전체적인 무드랑 너무 잘 어울리네요.', side: 1, image: 'assets/profiles/profile_35.jpg'),
    CommentData(user: '익명러', text: 'B가 더 고급스러워 보여요. 저만 그런가요?', side: 2, image: 'assets/profiles/profile_68.jpg'),
  ];
}
