import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:purepath/features/auth/model/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserProvider
//
// Single source of truth for in-memory user data.
// Holds both the raw Firebase user and the Firestore UserModel.
// Broadcasts changes over streams so the UserBloc can react reactively.
//
// Pattern mirrors MacroPath's UserProvider — one place that owns the data,
// everything else reads or writes through it.
// ─────────────────────────────────────────────────────────────────────────────

class UserProvider {
  UserProvider();

  User? _firebaseUser;
  UserModel? _localUser;

  // ── Getters ───────────────────────────────────────────────────────────────

  User? get firebaseUser => _firebaseUser;
  UserModel? get localUser => _localUser;

  // ── Streams ───────────────────────────────────────────────────────────────

  final _firebaseUserController = StreamController<User?>.broadcast();
  final _userModelController = StreamController<UserModel?>.broadcast();

  Stream<User?> get firebaseUserStream => _firebaseUserController.stream;
  Stream<UserModel?> get userModelStream => _userModelController.stream;

  // ── Updaters ──────────────────────────────────────────────────────────────

  void updateFirebaseUser(User? user) {
    _firebaseUser = user;
    _firebaseUserController.add(user);
  }

  void updateLocalUser(UserModel? user) {
    _localUser = user;
    _userModelController.add(user);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _firebaseUserController.close();
    _userModelController.close();
  }
}
