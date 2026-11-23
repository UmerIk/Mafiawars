import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;

  AuthRepositoryImpl({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuthOverride = firebaseAuth,
        _firestoreOverride = firestore;

  fb_auth.FirebaseAuth get _firebaseAuth {
    if (_firebaseAuthOverride != null) return _firebaseAuthOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase App not initialized');
    }
    return fb_auth.FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    if (_firestoreOverride != null) return _firestoreOverride;
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase App not initialized');
    }
    return FirebaseFirestore.instance;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    try {
      if (Firebase.apps.isEmpty) return Stream.value(null);
      return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        return await getUserProfile(firebaseUser.uid);
      });
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  UserEntity? get currentUser {
    try {
      if (Firebase.apps.isEmpty) return null;
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser == null) return null;
      return UserEntity(
        uid: fbUser.uid,
        displayName: fbUser.displayName ?? 'Agent',
        avatarUrl: fbUser.photoURL ?? '',
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserEntity> signInAnonymously({required String displayName}) async {
    final credential = await _firebaseAuth.signInAnonymously();
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Anonymous sign-in failed: no user returned.');
    }

    final userRef = _firestore.collection('users').doc(fbUser.uid);
    final docSnapshot = await userRef.get();

    UserEntity userEntity;
    if (docSnapshot.exists) {
      userEntity = UserModel.fromFirestore(docSnapshot);
    } else {
      userEntity = UserEntity(
        uid: fbUser.uid,
        displayName: displayName.trim().isEmpty ? 'Agent_${fbUser.uid.substring(0, 4)}' : displayName.trim(),
        avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=${fbUser.uid}',
        createdAt: DateTime.now(),
      );
      await userRef.set(UserModel.fromEntity(userEntity).toFirestore());
    }

    return userEntity;
  }

  @override
  Future<void> updateProfile({required String displayName, required String avatarUrl}) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) throw Exception('No authenticated user found.');

    final userRef = _firestore.collection('users').doc(fbUser.uid);
    await userRef.update({
      'displayName': displayName.trim(),
      'avatarUrl': avatarUrl,
    });
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        final newUser = UserEntity(
          uid: uid,
          displayName: 'Agent_${uid.substring(0, 4)}',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=$uid',
          createdAt: DateTime.now(),
  );
        await _firestore.collection('users').doc(uid).set(UserModel.fromEntity(newUser).toFirestore());
        return newUser;
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}
