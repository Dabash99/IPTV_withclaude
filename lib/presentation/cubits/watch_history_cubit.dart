import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/watch_history_datasource.dart';

class WatchHistoryState extends Equatable {
  final List<WatchHistoryItem> items;
  const WatchHistoryState(this.items);
  @override
  List<Object?> get props => [items];
}

class WatchHistoryCubit extends Cubit<WatchHistoryState> {
  final WatchHistoryDataSource dataSource;
  WatchHistoryCubit(this.dataSource) : super(const WatchHistoryState([])) {
    load();
  }

  void load() => emit(WatchHistoryState(dataSource.getAll()));

  Future<void> record(WatchHistoryItem item) async {
    await dataSource.add(item);
    load();
  }

  Future<void> clear() async {
    await dataSource.clear();
    load();
  }
}
