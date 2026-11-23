enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequestEntity {
  final String id;
  final String senderId;
  final String senderDisplayName;
  final String senderAvatarUrl;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequestEntity({
    required this.id,
    required this.senderId,
    required this.senderDisplayName,
    required this.senderAvatarUrl,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderDisplayName': senderDisplayName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FriendRequestEntity.fromJson(Map<String, dynamic> json) {
    return FriendRequestEntity(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderDisplayName: json['senderDisplayName'] ?? 'Agent',
      senderAvatarUrl: json['senderAvatarUrl'] ?? '',
      receiverId: json['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
