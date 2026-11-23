import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/friend_entity.dart';

class FriendModel extends FriendEntity {
  const FriendModel({
    required super.uid,
    required super.displayName,
    required super.avatarUrl,
    required super.addedAt,
  });

  factory FriendModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return FriendModel(
      uid: snapshot.id,
      displayName: data['displayName'] ?? 'Agent',
      avatarUrl: data['avatarUrl'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }
}
