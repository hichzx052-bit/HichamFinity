class Viewer {
  final String username;
  final String displayName;
  final String? profilePicUrl;
  final DateTime lastSeen;

  Viewer({
    required this.username,
    required this.displayName,
    this.profilePicUrl,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();
}
