class ChatMessageEntity {
  final String id;
  final String senderId;
  final String senderDisplayName;
  final String senderAvatarUrl;
  final String message;
  final String channelType; // 'public', 'mafia', 'ghost'
  final DateTime timestamp;

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderDisplayName,
    required this.senderAvatarUrl,
    required this.message,
    this.channelType = 'public',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderDisplayName': senderDisplayName,
      'senderAvatarUrl': senderAvatarUrl,
      'message': message,
      'channelType': channelType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderDisplayName: json['senderDisplayName'] ?? 'Agent',
      senderAvatarUrl: json['senderAvatarUrl'] ?? '',
      message: json['message'] ?? '',
      channelType: json['channelType'] ?? 'public',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
