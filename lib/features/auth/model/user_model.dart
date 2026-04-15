import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:purepath/core/enums/onboarding_enums.dart';

@immutable
class UserModel {
  final String fullName;
  final String uid;
  final OnboardingStatus onboardingStatus; // ← changed from String to enum
  final String email;
  final String password;
  final String? fcmToken;
  final String? imgUrl;
  final bool isStreakLocked;
  final DateTime? lastLoggedDate;
  final DateTime? freezedDate;
  final bool isNotificationOn;
  final int streakCount;
  final String stripeSubscriptionId;

  const UserModel({
    required this.fullName,
    required this.uid,
    required this.onboardingStatus,
    required this.email,
    required this.password,
    this.fcmToken,
    this.imgUrl,
    this.isStreakLocked = false,
    this.isNotificationOn = true,
    this.lastLoggedDate,
    this.freezedDate,
    this.streakCount = 0,
    this.stripeSubscriptionId = '',
  });

  UserModel copyWith({
    String? fullName,
    String? uid,
    OnboardingStatus? onboardingStatus, // ← enum
    String? email,
    String? password,
    String? fcmToken,
    String? imgUrl,
    bool? isStreakLocked,
    bool? isNotificationOn,
    DateTime? lastLoggedDate,
    DateTime? freezedDate,
    int? streakCount,
    String? stripeSubscriptionId,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      uid: uid ?? this.uid,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      email: email ?? this.email,
      password: password ?? this.password,
      fcmToken: fcmToken ?? this.fcmToken,
      imgUrl: imgUrl ?? this.imgUrl,
      isStreakLocked: isStreakLocked ?? this.isStreakLocked,
      isNotificationOn: isNotificationOn ?? this.isNotificationOn,
      lastLoggedDate: lastLoggedDate ?? this.lastLoggedDate,
      freezedDate: freezedDate ?? this.freezedDate,
      streakCount: streakCount ?? this.streakCount,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'uid': uid,
      'onboardingStatus': onboardingStatus.toValue(), // ← saves as string
      'email': email,
      'password': password,
      'fcmToken': fcmToken,
      'imgUrl': imgUrl,
      'isStreakLocked': isStreakLocked,
      'isNotificationOn': isNotificationOn,
      'lastLoggedDate': lastLoggedDate?.toIso8601String(),
      'freezedDate': freezedDate?.toIso8601String(),
      'streakCount': streakCount,
      'subscriptionId': stripeSubscriptionId,
    };
  }

  factory UserModel.empty() => UserModel(
        fullName: '',
        uid: '',
        onboardingStatus: OnboardingStatus.notStarted, // ← default
        email: '',
        password: '',
        fcmToken: '',
        imgUrl: null,
        isStreakLocked: false,
        isNotificationOn: true,
        lastLoggedDate: null,
        freezedDate: null,
        streakCount: 0,
        stripeSubscriptionId: '',
      );

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] as String,
      uid: map['uid'] as String,
      onboardingStatus: OnboardingStatus.fromValue( // ← parses from string
        map['onboardingStatus'] as String? ?? 'not_started',
      ),
      email: map['email'] as String,
      password: map['password'] as String? ?? '',
      fcmToken: map['fcmToken'] as String? ?? '',
      imgUrl: map['imgUrl'] as String?,
      isStreakLocked: map['isStreakLocked'] as bool? ?? false,
      isNotificationOn: map['isNotificationOn'] as bool? ?? true,
      lastLoggedDate: map['lastLoggedDate'] != null
          ? DateTime.parse(map['lastLoggedDate'] as String)
          : null,
      freezedDate: map['freezedDate'] != null
          ? DateTime.parse(map['freezedDate'] as String)
          : null,
      streakCount: map['streakCount'] as int? ?? 0,
      stripeSubscriptionId: map['subscriptionId'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get hasCompletedOnboarding =>
      onboardingStatus == OnboardingStatus.completed;

  bool get isOnboardingInProgress =>
      onboardingStatus == OnboardingStatus.inProgress;

  @override
  String toString() {
    return 'UserModel(fullName: $fullName, uid: $uid, onboardingStatus: ${onboardingStatus.toValue()}, email: $email, password: $password, fcmToken: $fcmToken, imgUrl: $imgUrl, isStreakLocked: $isStreakLocked, isNotificationOn: $isNotificationOn, lastLoggedDate: $lastLoggedDate, freezedDate: $freezedDate, streakCount: $streakCount)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.fullName == fullName &&
        other.uid == uid &&
        other.onboardingStatus == onboardingStatus &&
        other.email == email &&
        other.password == password &&
        other.fcmToken == fcmToken &&
        other.imgUrl == imgUrl &&
        other.isStreakLocked == isStreakLocked &&
        other.isNotificationOn == isNotificationOn &&
        other.lastLoggedDate == lastLoggedDate &&
        other.freezedDate == freezedDate &&
        other.streakCount == streakCount;
  }

  @override
  int get hashCode {
    return fullName.hashCode ^
        uid.hashCode ^
        onboardingStatus.hashCode ^
        email.hashCode ^
        password.hashCode ^
        (fcmToken?.hashCode ?? 0) ^
        (imgUrl?.hashCode ?? 0) ^
        isStreakLocked.hashCode ^
        isNotificationOn.hashCode ^
        (lastLoggedDate?.hashCode ?? 0) ^
        (freezedDate?.hashCode ?? 0) ^
        streakCount.hashCode;
  }

  String get firstName {
    final index = fullName.indexOf(' ');
    return index != -1 ? fullName.substring(0, index) : fullName;
  }

  String get lastName {
    final index = fullName.indexOf(' ');
    return (index != -1 && index + 1 < fullName.length)
        ? fullName.substring(index + 1)
        : '';
  }
}