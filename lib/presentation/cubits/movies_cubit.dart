import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/usecases/usecases.dart';

abstract class MoviesState extends Equatable {
  const MoviesState();
  @override
  List<Object?> get props => [];
}

class MoviesInitial extends MoviesState {}

class MoviesLoading extends MoviesState {}

class MoviesLoaded extends MoviesState {
  final List<Category> categories;
  final List<Movie> movies;
  final List<Movie> filteredMovies;
  final String? selectedCategoryId;

  const MoviesLoaded({
    required this.categories,
    required this.movies,
    required this.filteredMovies,
    this.selectedCategoryId,
  });

  MoviesLoaded copyWith({
    List<Category>? categories,
    List<Movie>? movies,
    List<Movie>? filteredMovies,
    String? selectedCategoryId,
    bool clearCategory = false,
  }) {
    return MoviesLoaded(
      categories: categories ?? this.categories,
      movies: movies ?? this.movies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }

  @override
  List<Object?> get props => [categories, movies, filteredMovies, selectedCategoryId];
}

class MoviesError extends MoviesState {
  final String message;
  const MoviesError(this.message);
  @override
  List<Object?> get props => [message];
}

class MoviesCubit extends Cubit<MoviesState> {
  final GetVodCategoriesUseCase getCategoriesUseCase;
  final GetMoviesUseCase getMoviesUseCase;

  MoviesCubit({
    required this.getCategoriesUseCase,
    required this.getMoviesUseCase,
  }) : super(MoviesInitial());

  Future<void> loadData() async {
    emit(MoviesLoading());
    final categoriesResult = await getCategoriesUseCase();
    final moviesResult = await getMoviesUseCase();

    categoriesResult.fold(
          (failure) => emit(MoviesError(failure.message)),
          (categories) {
        moviesResult.fold(
              (failure) => emit(MoviesError(failure.message)),
              (movies) => emit(MoviesLoaded(
            categories: categories,
            movies: movies,
            filteredMovies: movies,
          )),
        );
      },
    );
  }

  void selectCategory(String? categoryId) {
    if (state is! MoviesLoaded) return;
    final current = state as MoviesLoaded;

    if (categoryId == null) {
      emit(current.copyWith(clearCategory: true, filteredMovies: current.movies));
    } else {
      final filtered = current.movies.where((m) => m.categoryId == categoryId).toList();
      emit(current.copyWith(selectedCategoryId: categoryId, filteredMovies: filtered));
    }
  }

  void search(String query) {
    if (state is! MoviesLoaded) return;
    final current = state as MoviesLoaded;

    final base = current.selectedCategoryId != null
        ? current.movies.where((m) => m.categoryId == current.selectedCategoryId).toList()
        : current.movies;

    if (query.isEmpty) {
      emit(current.copyWith(filteredMovies: base));
      return;
    }

    final filtered = base.where((m) => m.name.toLowerCase().contains(query.toLowerCase())).toList();
    emit(current.copyWith(filteredMovies: filtered));
  }
}
