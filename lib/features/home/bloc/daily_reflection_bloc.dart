import 'package:bloc/bloc.dart';
import 'package:purepath/core/repositories/home_repository.dart';
import 'package:purepath/features/home/models/daily_reflection.dart';

part 'daily_reflection_event.dart';
part 'daily_reflection_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Daily reflection BLoC
//
// Owns the mood + note for each day, independently of the habit data in
// [HomeBloc]. Reflections are cached by date (like HomeBloc caches weeks) so
// re-selecting a day is instant and never re-hits Firestore.
//
//   • [ReflectionRequested]  loads a day on demand (cache miss only)
//   • [ReflectionSaved]      writes optimistically, then persists
//
// Knows nothing about Flutter — it works purely in DateTime / DailyReflection.
// ─────────────────────────────────────────────────────────────────────────────

class DailyReflectionBloc
    extends Bloc<DailyReflectionEvent, DailyReflectionState> {
  final HomeRepository _repository;

  DailyReflectionBloc({required HomeRepository repository})
    : _repository = repository,
      super(const DailyReflectionState()) {
    on<ReflectionRequested>(_onRequested);
    on<ReflectionSaved>(_onSaved);
  }

  /// Loads the reflection for [event.date] unless it's already cached. The
  /// empty-but-loaded state and the missing-day state both cache as an empty
  /// [DailyReflection], so the card renders its prompt without re-fetching.
  Future<void> _onRequested(
    ReflectionRequested event,
    Emitter<DailyReflectionState> emit,
  ) async {
    final date = _dateOnly(event.date);
    if (state.byDate.containsKey(date)) return;

    final reflection = await _repository.getReflection(date);
    emit(state.withReflection(date, reflection ?? const DailyReflection()));
  }

  /// Saves [event.reflection] for [event.date]. Updates the cache immediately
  /// (optimistic) so the card reflects the change the moment the sheet closes,
  /// then persists. A failed write leaves the optimistic value in place — the
  /// user can re-open the sheet and save again.
  Future<void> _onSaved(
    ReflectionSaved event,
    Emitter<DailyReflectionState> emit,
  ) async {
    final date = _dateOnly(event.date);
    emit(state.withReflection(date, event.reflection));

    try {
      await _repository.setReflection(date: date, reflection: event.reflection);
    } catch (_) {
      // Non-fatal: the optimistic cache value stays, retry is a re-save.
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
