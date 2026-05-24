import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../entries/application/entries_cubit.dart';
import '../../entries/application/entries_state.dart';
import '../domain/entities/mood_stats.dart';
import '../domain/use_cases/compute_stats.dart';
import 'stats_state.dart';

/// ViewModel for Statistics. Observes the shared [EntriesCubit] and recomputes
/// [MoodStats] via the pure [ComputeStats] use case.
class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._entries, this._compute) : super(const StatsState()) {
    _sub = _entries.stream.listen((_) => _recompute());
    _recompute();
  }

  final EntriesCubit _entries;
  final ComputeStats _compute;
  late final StreamSubscription<EntriesState> _sub;

  void setPeriod(StatsPeriod period) {
    emit(state.copyWith(period: period));
    _recompute();
  }

  void _recompute() {
    final stats = _compute(_entries.state.entries, state.period);
    emit(state.copyWith(stats: stats));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
