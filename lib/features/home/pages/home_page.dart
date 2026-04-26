import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/widgets/space.dart';
import 'package:purepath/features/home/bloc/home_bloc.dart';
import 'package:purepath/features/home/repositories/dummy_home_repository.dart';
import 'package:purepath/features/home/widgets/daily_progress_card.dart';
import 'package:purepath/features/home/widgets/habit_tile_widget.dart';
import 'package:purepath/features/home/widgets/home_header_widget.dart';
import 'package:purepath/features/home/widgets/horizontal_calendar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home page
//
// Entry point for the home tab. Its only job:
//   1. Create and provide the [HomeBloc] (scoped to this screen)
//   2. Trigger [HomeStarted] to kick off the initial data load
//
// All UI lives in [_HomeView] below.
//
// TO CONNECT FIRESTORE:
//   Replace DummyHomeRepository() with FirestoreHomeRepository()
//   inside the BlocProvider.create — nothing else changes.
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(repository: DummyHomeRepository())
        ..add(HomeStarted()),
      child: const _HomeView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home view
//
// Reads HomeState via BlocBuilder and passes data down to dumb widgets.
// Contains no business logic — only layout decisions.
// ─────────────────────────────────────────────────────────────────────────────

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ─────────────────────────────────────────────────
              const HomeHeaderWidget(),
              Space.vertical(20),

              // ── Weekly calendar ───────────────────────────────────────────
              // The calendar is a pure UI widget.
              // It fires callbacks; we forward them to the BLoC as events.
              TrainingCalendar(
                weekData: state.weekData,
                selectedDate: state.selectedDate,
                visibleWeekStart: state.visibleWeekStart,
                onDateSelected: (date) {
                  context.read<HomeBloc>().add(HomeDateSelected(date));
                },
                onWeekChanged: (weekStart) {
                  context.read<HomeBloc>().add(HomeWeekChanged(weekStart));
                },
              ),

              Space.vertical(20),

              // ── Content below calendar ────────────────────────────────────
              // Shows loading indicator, error, or the selected day's data.
              _buildContent(context, state),

              Space.vertical(24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.loading:
        return const _LoadingView();

      case HomeStatus.error:
        return _ErrorView(message: state.errorMessage ?? 'Something went wrong');

      case HomeStatus.loaded:
        final summary = state.selectedDaySummary;

        // Summary missing means the user swiped to a week that's still loading.
        if (summary == null) return const _LoadingView();

        return Column(
          children: [
            DailyProgressCard(summary: summary),
            Space.vertical(16),
            ...summary.habits.map(
              (habit) => HabitTileWidget(
                habit: habit,
                onTap: () => context.read<HomeBloc>().add(
                  HabitToggled(habit.id),
                ),
              ),
            ),
          ],
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading view
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(color: purple),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            Space.vertical(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.normal.copyWith(color: kDarkGreyColor),
            ),
            Space.vertical(16),
            TextButton(
              onPressed: () =>
                  context.read<HomeBloc>().add(HomeStarted()),
              child: Text(
                'Retry',
                style: AppTextStyles.medium.copyWith(color: purple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
