import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/providers/firebase_auth_provider.dart';
import 'package:purepath/core/providers/user_provider.dart';
import 'package:purepath/core/repositories/firebase_auth_repository.dart';
import 'package:purepath/core/repositories/user_repository.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/bloc/manage_habits_bloc.dart';
import 'package:purepath/features/home/repositories/firestore_home_repository.dart';
import 'package:purepath/features/home/repositories/home_repository.dart';
import 'package:purepath/features/insights/bloc/insights_bloc.dart';

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
          ),
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) => FirestoreHomeRepository(),
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
          create: (ctx) => HomeBloc(repository: ctx.read<HomeRepository>()),
        ),
        BlocProvider<ManageHabitsBloc>(
          create: (ctx) =>
              ManageHabitsBloc(repository: ctx.read<HomeRepository>()),
        ),
        BlocProvider<InsightsBloc>(
          create: (ctx) =>
              InsightsBloc(repository: ctx.read<HomeRepository>()),
        ),
      ],
      child: child,
    );
  }
}
