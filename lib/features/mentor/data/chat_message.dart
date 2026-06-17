class ChatMessage {
  final String? id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? mentorId;
  final String? userId;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.mentorId,
    this.userId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['created_at']).toLocal(),
      mentorId: json['mentor_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'mentor_id': mentorId,
      'user_id': userId,
      // 'created_at' is handled by DB default
    };
  }
}
