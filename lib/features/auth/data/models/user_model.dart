import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.displayName,
    required super.avatarUrl,
    required super.createdAt,
    super.gamesPlayed,
    super.wins,
    super.userStatus,
  });

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt,
      gamesPlayed: entity.gamesPlayed,
      wins: entity.wins,
      userStatus: entity.userStatus,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return UserModel(
      uid: snapshot.id,
      displayName: data['displayName'] ?? 'Agent',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      gamesPlayed: data['gamesPlayed'] ?? 0,
      wins: data['wins'] ?? 0,
      userStatus: data['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'status': userStatus,
    };
  }
}
