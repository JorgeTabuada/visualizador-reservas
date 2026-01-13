import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Interface do datasource remoto de autenticação
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Future<bool> isAuthenticated();
  Future<UserModel> registerUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String organizationId,
    String? departmentId,
  });
  Future<UserModel> updateUser(UserModel user);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  Stream<UserModel?> get authStateChanges;
}

/// Implementação do datasource de autenticação com Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  CollectionReference get _usersCollection =>
      firestore.collection(AppConstants.usersCollection);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Autenticar com Firebase Auth
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Falha ao obter utilizador após login');
    }

    // Obter dados do utilizador do Firestore
    final userDoc = await _usersCollection.doc(firebaseUser.uid).get();

    if (!userDoc.exists) {
      // Criar documento de utilizador se não existir
      final newUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName ?? email.split('@').first,
        photoUrl: firebaseUser.photoURL,
        role: UserRole.teamLeader,
        organizationId: 'default',
        permissions: UserPermissions.teamLeader(),
        notificationSettings: const NotificationSettings(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _usersCollection.doc(firebaseUser.uid).set(newUser.toJson());
      return newUser;
    }

    // Atualizar último login
    await _usersCollection.doc(firebaseUser.uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return UserModel.fromFirestore(userDoc);
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
    if (!userDoc.exists) return null;

    return UserModel.fromFirestore(userDoc);
  }

  @override
  Future<bool> isAuthenticated() async {
    return firebaseAuth.currentUser != null;
  }

  @override
  Future<UserModel> registerUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String organizationId,
    String? departmentId,
  }) async {
    // Criar utilizador no Firebase Auth
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Falha ao criar utilizador');
    }

    // Atualizar display name no Firebase Auth
    await firebaseUser.updateDisplayName(displayName);

    // Criar documento do utilizador no Firestore
    final userRole = UserRole.fromString(role);
    final newUser = UserModel(
      id: firebaseUser.uid,
      email: email.trim(),
      displayName: displayName,
      role: userRole,
      organizationId: organizationId,
      departmentId: departmentId,
      permissions: UserPermissions.fromRole(userRole),
      notificationSettings: const NotificationSettings(),
      createdAt: DateTime.now(),
    );

    await _usersCollection.doc(firebaseUser.uid).set(newUser.toJson());

    return newUser;
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    final updateData = user.toJson();
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _usersCollection.doc(user.id).update(updateData);

    final updatedDoc = await _usersCollection.doc(user.id).get();
    return UserModel.fromFirestore(updatedDoc);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Utilizador não autenticado');
    }

    // Re-autenticar antes de alterar password
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Atualizar password
    await user.updatePassword(newPassword);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    });
  }
}
