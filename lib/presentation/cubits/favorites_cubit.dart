import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/favorites_datasource.dart';

class FavoritesState extends Equatable {
  final List<FavoriteItem> items;
  const FavoritesState(this.items);

  @override
  List<Object?> get props => [items];
}

class FavoritesCubit extends Cubit<FavoritesState> {
  final FavoritesDataSource dataSource;

  FavoritesCubit(this.dataSource) : super(const FavoritesState([])) {
    load();
  }

  void load() => emit(FavoritesState(dataSource.getAll()));

  Future<void> toggle(FavoriteItem item) async {
    await dataSource.toggle(item);
    load();
  }

  bool isFavorite(int id, FavoriteType type) => dataSource.isFavorite(id, type);
}
