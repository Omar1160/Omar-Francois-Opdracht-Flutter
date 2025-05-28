class AppNotification {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'] ?? '',
      title: map['title'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }
}
