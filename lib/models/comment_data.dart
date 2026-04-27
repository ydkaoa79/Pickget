class CommentData {
  final String user;
  String text;
  final int side;
  final String image;
  bool isPinned;
  bool isHidden;
  List<CommentData> replies;

  CommentData({
    required this.user, 
    required this.text, 
    required this.side, 
    required this.image,
    this.isPinned = false,
    this.isHidden = false,
    List<CommentData>? replies,
  }) : replies = replies ?? [];
}
