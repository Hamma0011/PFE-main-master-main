class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? etablissementId;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.etablissementId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      etablissementId: json['etablissement_id'],
    );
  }

    NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    bool? read,
    DateTime? createdAt,
    String? etablissementId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      etablissementId: etablissementId ?? this.etablissementId,
    );
  }
}
