import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/friend_request_entity.dart';

class FriendRequestModel extends FriendRequestEntity {
  const FriendRequestModel({
    required super.id,
    required super.senderId,
    required super.senderDisplayName,
    required super.senderAvatarUrl,
    required super.receiverId,
    super.status,
    required super.createdAt,
  });

  factory FriendRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return FriendRequestModel(
      id: snapshot.id,
      senderId: data['senderId'] ?? '',
      senderDisplayName: data['senderDisplayName'] ?? 'Agent',
      senderAvatarUrl: data['senderAvatarUrl'] ?? '',
      receiverId: data['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderDisplayName': senderDisplayName,
      'senderAvatarUrl': senderAvatarUrl,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
