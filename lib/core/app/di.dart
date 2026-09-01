import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/providers/app_version_provider.dart';
import 'package:purepath/core/providers/firebase_auth_provider.dart';
import 'package:purepath/core/providers/subscription_provider.dart';
import 'package:purepath/core/providers/user_firestore_provider.dart';
import 'package:purepath/core/providers/user_provider.dart';
import 'package:purepath/core/repositories/app_version_repository.dart';
import 'package:purepath/core/repositories/firebase_auth_repository.dart';
import 'package:purepath/core/repositories/subscription_repository.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/core/services/notification_service.dart';
import 'package:purepath/features/home/bloc/daily_reflection_bloc.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/core/providers/home_provider.dart';
import 'package:purepath/core/providers/planner_provider.dart';
import 'package:purepath/core/repositories/firestore_home_repository.dart';
import 'package:purepath/core/repositories/firestore_planner_repository.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/core/repositories/planner_repository.dart';
import 'package:purepath/features/planner/bloc/planner_bloc.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';
import 'package:purepath/features/notifications/bloc/notification_bloc.dart';
import 'package:purepath/features/paywall/bloc/subscription_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DI  (Dependency Injection)
//
// Three-layer composition identical to MacroPath:
//
//   _ProviderDI   — raw data sources (Firebase SDK wrappers)
//   _RepositoryDI — business logic + Firestore access
//   _BlocDI       — global BLoCs that any widget can read
//
// Usage:
//   DI(child: router) — wrap the entire app so every widget has access.
// ─────────────────────────────────────────────────────────────────────────────

class DI extends StatelessWidget {
  const DI({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ProviderDI(
      child: _RepositoryDI(child: _BlocDI(child: child)),
    );
  }
}

// ── Layer 1 — Providers (raw Firebase wrappers) ───────────────────────────────

class _ProviderDI extends StatelessWidget {
  const _ProviderDI({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FirebaseAuthProvider>(
          create: (_) => FirebaseAuthProvider(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
        ),
        RepositoryProvider<UserProvider>(
          create: (_) => UserProvider(),
          dispose: (p) => p.dispose(),
        ),
        RepositoryProvider<UserFirestoreProvider>(
          create: (_) => UserFirestoreProvider(),
        ),
        RepositoryProvider<AppVersionProvider>(
          create: (_) => AppVersionProvider(),
        ),
        RepositoryProvider<HomeProvider>(
          create: (_) => HomeProvider(),
        ),
        RepositoryProvider<PlannerProvider>(
          create: (_) => PlannerProvider(),
        ),
        RepositoryProvider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        RepositoryProvider<SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          dispose: (p) => p.dispose(),
        ),
      ],
      child: child,
    );
  }
}

// ── Layer 2 — Repositories (business logic) ───────────────────────────────────

class _RepositoryDI extends StatelessWidget {
  const _RepositoryDI({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FirebaseAuthRepository>(
          create: (ctx) => FirebaseAuthRepository(
            firebaseAuthProvider: ctx.read<FirebaseAuthProvider>(),
          ),
        ),
        RepositoryProvider<UserRepository>(
          create: (ctx) => UserRepository(
            userProvider: ctx.read<UserProvider>(),
            userFirestoreProvider: ctx.read<UserFirestoreProvider>(),
          ),
        ),
        RepositoryProvider<AppVersionRepository>(
          create: (ctx) => AppVersionRepository(
            provider: ctx.read<AppVersionProvider>(),
          ),
        ),
        RepositoryProvider<HomeRepository>(
          create: (ctx) => FirestoreHomeRepository(
            provider: ctx.read<HomeProvider>(),
          ),
        ),
        RepositoryProvider<PlannerRepository>(
          create: (ctx) => FirestorePlannerRepository(
            provider: ctx.read<PlannerProvider>(),
          ),
        ),
        // Eager (lazy: false): RevenueCat must be configured at startup so
        // entitlements are known before the user ever opens the paywall, and
        // so the identity stays synced with Firebase Auth for the whole
        // session.
        RepositoryProvider<SubscriptionRepository>(
          lazy: false,
          create: (ctx) => SubscriptionRepository(
            subscriptionProvider: ctx.read<SubscriptionProvider>(),
            userRepository: ctx.read<UserRepository>(),
          )..start(),
          dispose: (r) => r.dispose(),
        ),
      ],
      child: child,
    );
  }
}

// ── Layer 3 — BLoCs (global state) ───────────────────────────────────────────

class _BlocDI extends StatelessWidget {
  const _BlocDI({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (ctx) => UserBloc(
            firebaseAuthRepository: ctx.read<FirebaseAuthRepository>(),
            userRepository: ctx.read<UserRepository>(),
          ),
        ),
        BlocProvider<HomeBloc>(
          create: (ctx) => HomeBloc(
            repository: ctx.read<HomeRepository>(),
            userRepository: ctx.read<UserRepository>(),
          ),
        ),
        BlocProvider<ManageHabitsBloc>(
          create: (ctx) =>
              ManageHabitsBloc(repository: ctx.read<HomeRepository>()),
        ),
        BlocProvider<PlannerBloc>(
          create: (ctx) =>
              PlannerBloc(repository: ctx.read<PlannerRepository>()),
        ),
        BlocProvider<DailyReflectionBloc>(
          create: (ctx) =>
              DailyReflectionBloc(repository: ctx.read<HomeRepository>()),
        ),
        BlocProvider<InsightsBloc>(
          create: (ctx) =>
              InsightsBloc(repository: ctx.read<HomeRepository>()),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (ctx) => SubscriptionBloc(
            subscriptionRepository: ctx.read<SubscriptionRepository>(),
          )..add(SubscriptionStarted()),
        ),
        BlocProvider<NotificationBloc>(
          create: (ctx) => NotificationBloc(
            notificationService: ctx.read<NotificationService>(),
            homeRepository: ctx.read<HomeRepository>(),
            userRepository: ctx.read<UserRepository>(),
          )..add(const NotificationStarted()),
        ),
      ],
      child: child,
    );
  }
}
