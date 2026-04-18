import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/usecases/usecases.dart';

abstract class SeriesState extends Equatable {
  const SeriesState();
  @override
  List<Object?> get props => [];
}

class SeriesInitial extends SeriesState {}

class SeriesLoading extends SeriesState {}

class SeriesLoaded extends SeriesState {
  final List<Category> categories;
  final List<Series> seriesList;
  final List<Series> filteredSeries;
  final String? selectedCategoryId;

  const SeriesLoaded({
    required this.categories,
    required this.seriesList,
    required this.filteredSeries,
    this.selectedCategoryId,
  });

  SeriesLoaded copyWith({
    List<Category>? categories,
    List<Series>? seriesList,
    List<Series>? filteredSeries,
    String? selectedCategoryId,
    bool clearCategory = false,
  }) {
    return SeriesLoaded(
      categories: categories ?? this.categories,
      seriesList: seriesList ?? this.seriesList,
      filteredSeries: filteredSeries ?? this.filteredSeries,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }

  @override
  List<Object?> get props => [categories, seriesList, filteredSeries, selectedCategoryId];
}

class SeriesError extends SeriesState {
  final String message;
  const SeriesError(this.message);
  @override
  List<Object?> get props => [message];
}

// Series details state
class SeriesDetailsLoading extends SeriesState {}

class SeriesDetailsLoaded extends SeriesState {
  final Map<int, List<Episode>> episodesBySeason;
  const SeriesDetailsLoaded(this.episodesBySeason);
  @override
  List<Object?> get props => [episodesBySeason];
}

class SeriesCubit extends Cubit<SeriesState> {
  final GetSeriesCategoriesUseCase getCategoriesUseCase;
  final GetSeriesUseCase getSeriesUseCase;
  final GetSeriesInfoUseCase getSeriesInfoUseCase;

  SeriesCubit({
    required this.getCategoriesUseCase,
    required this.getSeriesUseCase,
    required this.getSeriesInfoUseCase,
  }) : super(SeriesInitial());

  Future<void> loadData() async {
    emit(SeriesLoading());
    final categoriesResult = await getCategoriesUseCase();
    final seriesResult = await getSeriesUseCase();

    categoriesResult.fold(
          (failure) => emit(SeriesError(failure.message)),
          (categories) {
        seriesResult.fold(
              (failure) => emit(SeriesError(failure.message)),
              (series) => emit(SeriesLoaded(
            categories: categories,
            seriesList: series,
            filteredSeries: series,
          )),
        );
      },
    );
  }

  void selectCategory(String? categoryId) {
    if (state is! SeriesLoaded) return;
    final current = state as SeriesLoaded;

    if (categoryId == null) {
      emit(current.copyWith(clearCategory: true, filteredSeries: current.seriesList));
    } else {
      final filtered = current.seriesList.where((s) => s.categoryId == categoryId).toList();
      emit(current.copyWith(selectedCategoryId: categoryId, filteredSeries: filtered));
    }
  }

  void search(String query) {
    if (state is! SeriesLoaded) return;
    final current = state as SeriesLoaded;

    final base = current.selectedCategoryId != null
        ? current.seriesList.where((s) => s.categoryId == current.selectedCategoryId).toList()
        : current.seriesList;

    if (query.isEmpty) {
      emit(current.copyWith(filteredSeries: base));
      return;
    }

    final filtered = base.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
    emit(current.copyWith(filteredSeries: filtered));
  }
}

// Separate cubit for series details to avoid losing the list state
class SeriesDetailsCubit extends Cubit<SeriesState> {
  final GetSeriesInfoUseCase getSeriesInfoUseCase;

  SeriesDetailsCubit({required this.getSeriesInfoUseCase}) : super(SeriesInitial());

  Future<void> loadSeriesInfo(int seriesId) async {
    emit(SeriesDetailsLoading());
    final result = await getSeriesInfoUseCase(seriesId);
    result.fold(
          (failure) => emit(SeriesError(failure.message)),
          (episodes) => emit(SeriesDetailsLoaded(episodes)),
    );
  }
}
