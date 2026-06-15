enum SenderType { user, ai }

class ChatMessageModel {
  final String id;
  final SenderType senderType;
  final String message;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      senderType: SenderType.values.firstWhere(
        (s) => s.name == json['senderType'],
        orElse: () => SenderType.user,
      ),
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderType': senderType.name,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
