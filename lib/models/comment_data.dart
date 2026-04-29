class CommentData {
  String? id; // Supabase UUID
  String? parentId; // Parent comment UUID for replies
  final String user;
  final String userId; 
  final String? userInternalId; // 🆔 댓글 작성자 주민번호 추가!
  String text;
  final int side;
  final String image;
  bool isPinned;
  bool isHidden;
  List<CommentData> replies;

  CommentData({
    this.id,
    this.parentId,
    required this.user, 
    required this.userId,
    this.userInternalId,
    required this.text, 
    required this.side, 
    required this.image,
    this.isPinned = false,
    this.isHidden = false,
    List<CommentData>? replies,
  }) : replies = replies ?? [];
}
