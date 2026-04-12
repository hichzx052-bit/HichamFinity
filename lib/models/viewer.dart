class Viewer {
  final String username;
  final String? displayName;
  final String? profilePicUrl;
  int totalLikes;
  int totalGifts;
  int totalGiftValue;
  int totalComments;
  DateTime joinedAt;
  DateTime lastActiveAt;

  Viewer({
    required this.username,
    this.displayName,
    this.profilePicUrl,
    this.totalLikes = 0,
    this.totalGifts = 0,
    this.totalGiftValue = 0,
    this.totalComments = 0,
    required this.joinedAt,
    required this.lastActiveAt,
  });

  String get name => displayName ?? username;
}
