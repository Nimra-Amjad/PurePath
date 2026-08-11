import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:purepath/core/enums/onboarding_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserModel
//
// Single model for everything stored in the Firestore `users` collection.
// Preferences (goal, challenge, notificationsEnabled) are embedded here so
// one document round-trip gives the complete user picture.
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class UserModel {
  const UserModel({
    required this.fullName,
    required this.uid,
    required this.onboardingStatus,
    required this.email,
    required this.password,
    this.username,
    this.fcmToken,
    this.imgUrl,
    this.streak = 0,
    this.stripeSubscriptionId = '',
    // ── Preferences ─────────────────────────────────────────────────────────
    this.goal,
    this.challenge,
    this.activityLevel,
    this.notificationsEnabled = false,
    this.hasCelebratedFirstCompletion = false,
  });

  // ── Core identity ──────────────────────────────────────────────────────────
  final String fullName;

  /// Handle-style username chosen during onboarding (e.g. `nimraamjad_5`).
  /// Distinct from [fullName]; null for users created before this existed.
  final String? username;

  final String uid;
  final OnboardingStatus onboardingStatus;
  final String email;
  final String password;
  final String? fcmToken;
  final String? imgUrl;

  /// Length of the user's current consecutive-day completion streak.
  /// Recomputed from the insights data after every habit toggle, so
  /// backfilling a missed day correctly extends (or repairs) the streak.
  /// Drives badge unlocks and the profile tier card.
  final int streak;

  final String stripeSubscriptionId;

  // ── Preferences (filled during onboarding) ─────────────────────────────────
  final String? goal;
  final String? challenge;
  final String? activityLevel;
  final bool notificationsEnabled;

  /// True once the user has been shown the one-time "first habit completed"
  /// motivational popup. Persisted so the celebration never repeats.
  final bool hasCelebratedFirstCompletion;

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get hasCompletedOnboarding =>
      onboardingStatus == OnboardingStatus.completed;

  bool get isOnboardingInProgress =>
      onboardingStatus == OnboardingStatus.inProgress;

  String get firstName {
    final i = fullName.indexOf(' ');
    return i != -1 ? fullName.substring(0, i) : fullName;
  }

  String get lastName {
    final i = fullName.indexOf(' ');
    return (i != -1 && i + 1 < fullName.length)
        ? fullName.substring(i + 1)
        : '';
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? fullName,
    String? username,
    String? uid,
    OnboardingStatus? onboardingStatus,
    String? email,
    String? password,
    String? fcmToken,
    String? imgUrl,
    int? streak,
    String? stripeSubscriptionId,
    String? goal,
    String? challenge,
    String? activityLevel,
    bool? notificationsEnabled,
    bool? hasCelebratedFirstCompletion,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      uid: uid ?? this.uid,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      email: email ?? this.email,
      password: password ?? this.password,
      fcmToken: fcmToken ?? this.fcmToken,
      imgUrl: imgUrl ?? this.imgUrl,
      streak: streak ?? this.streak,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      goal: goal ?? this.goal,
      challenge: challenge ?? this.challenge,
      activityLevel: activityLevel ?? this.activityLevel,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasCelebratedFirstCompletion:
          hasCelebratedFirstCompletion ?? this.hasCelebratedFirstCompletion,
    );
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'uid': uid,
      'onboardingStatus': onboardingStatus.toValue(),
      'email': email,
      'password': password,
      'fcmToken': fcmToken,
      'imgUrl': imgUrl,
      'streak': streak,
      'subscriptionId': stripeSubscriptionId,
      'goal': goal,
      'challenge': challenge,
      'activityLevel': activityLevel,
      'notificationsEnabled': notificationsEnabled,
      'hasCelebratedFirstCompletion': hasCelebratedFirstCompletion,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] as String? ?? '',
      username: map['username'] as String?,
      uid: map['uid'] as String? ?? '',
      onboardingStatus: OnboardingStatus.fromValue(
        map['onboardingStatus'] as String? ?? 'in_progress',
      ),
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      fcmToken: map['fcmToken'] as String?,
      imgUrl: map['imgUrl'] as String?,
      // Read the new `streak` key, falling back to the legacy `coins` key so
      // existing users don't lose their streak before it's rewritten.
      streak:
          (map['streak'] as num?)?.toInt() ??
          (map['coins'] as num?)?.toInt() ??
          0,
      stripeSubscriptionId: map['subscriptionId'] as String? ?? '',
      goal: map['goal'] as String?,
      challenge: map['challenge'] as String?,
      activityLevel: map['activityLevel'] as String?,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? false,
      hasCelebratedFirstCompletion:
          map['hasCelebratedFirstCompletion'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // ── Factories ──────────────────────────────────────────────────────────────

  factory UserModel.empty() => UserModel(
    fullName: '',
    uid: '',
    onboardingStatus: OnboardingStatus.inProgress,
    email: '',
    password: '',
  );

  // ── Equality ───────────────────────────────────────────────────────────────

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;
    return other.fullName == fullName &&
        other.username == username &&
        other.uid == uid &&
        other.onboardingStatus == onboardingStatus &&
        other.email == email &&
        other.password == password &&
        other.fcmToken == fcmToken &&
        other.imgUrl == imgUrl &&
        other.streak == streak &&
        other.stripeSubscriptionId == stripeSubscriptionId &&
        other.goal == goal &&
        other.challenge == challenge &&
        other.activityLevel == activityLevel &&
        other.notificationsEnabled == notificationsEnabled &&
        other.hasCelebratedFirstCompletion == hasCelebratedFirstCompletion;
  }

  @override
  int get hashCode {
    return fullName.hashCode ^
        (username?.hashCode ?? 0) ^
        uid.hashCode ^
        onboardingStatus.hashCode ^
        email.hashCode ^
        password.hashCode ^
        (fcmToken?.hashCode ?? 0) ^
        (imgUrl?.hashCode ?? 0) ^
        streak.hashCode ^
        stripeSubscriptionId.hashCode ^
        (goal?.hashCode ?? 0) ^
        (challenge?.hashCode ?? 0) ^
        (activityLevel?.hashCode ?? 0) ^
        notificationsEnabled.hashCode ^
        hasCelebratedFirstCompletion.hashCode;
  }

  @override
  String toString() =>
      'UserModel('
      'fullName: $fullName, '
      'username: $username, '
      'uid: $uid, '
      'onboardingStatus: ${onboardingStatus.toValue()}, '
      'email: $email, '
      'goal: $goal, '
      'challenge: $challenge, '
      'activityLevel: $activityLevel, '
      'notificationsEnabled: $notificationsEnabled, '
      'streak: $streak'
      ')';
}
