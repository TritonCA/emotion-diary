import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/repositories/entries_repository.dart';
import 'entries_state.dart';

/// App-scoped single source of truth for the entry list. Record adds entries
/// through this owner; History and Stats observe it (no cross-feature
/// callbacks per ARCH rule #4).
class EntriesCubit extends Cubit<EntriesState> {
  EntriesCubit(this._repo) : super(const EntriesState());
  final EntriesRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: EntriesStatus.loading));
    final entries = await _repo.getAll();
    emit(state.copyWith(status: EntriesStatus.ready, entries: entries));
  }

  /// Re-read after a mutation performed by a use case elsewhere.
  Future<void> refresh() => load();
}
