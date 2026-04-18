import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/usecases/usecases.dart';

abstract class LiveState extends Equatable {
  const LiveState();
  @override
  List<Object?> get props => [];
}

class LiveInitial extends LiveState {}

class LiveLoading extends LiveState {}

class LiveLoaded extends LiveState {
  final List<Category> categories;
  final List<LiveStream> streams;
  final String? selectedCategoryId;
  final List<LiveStream> filteredStreams;
  final Map<int, List<EpgProgramme>> epgCache;

  const LiveLoaded({
    required this.categories,
    required this.streams,
    this.selectedCategoryId,
    required this.filteredStreams,
    this.epgCache = const {},
  });

  LiveLoaded copyWith({
    List<Category>? categories,
    List<LiveStream>? streams,
    String? selectedCategoryId,
    bool clearCategory = false,
    List<LiveStream>? filteredStreams,
    Map<int, List<EpgProgramme>>? epgCache,
  }) {
    return LiveLoaded(
      categories: categories ?? this.categories,
      streams: streams ?? this.streams,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      filteredStreams: filteredStreams ?? this.filteredStreams,
      epgCache: epgCache ?? this.epgCache,
    );
  }

  @override
  List<Object?> get props => [categories, streams, selectedCategoryId, filteredStreams, epgCache];
}

class LiveError extends LiveState {
  final String message;
  const LiveError(this.message);
  @override
  List<Object?> get props => [message];
}

class LiveCubit extends Cubit<LiveState> {
  final GetLiveCategoriesUseCase getCategoriesUseCase;
  final GetLiveStreamsUseCase getStreamsUseCase;
  final GetShortEpgUseCase getEpgUseCase;

  LiveCubit({
    required this.getCategoriesUseCase,
    required this.getStreamsUseCase,
    required this.getEpgUseCase,
  }) : super(LiveInitial());

  Future<void> loadData() async {
    emit(LiveLoading());

    final categoriesResult = await getCategoriesUseCase();
    final streamsResult = await getStreamsUseCase();

    categoriesResult.fold(
          (failure) => emit(LiveError(failure.message)),
          (categories) {
        streamsResult.fold(
              (failure) => emit(LiveError(failure.message)),
              (streams) => emit(LiveLoaded(
            categories: categories,
            streams: streams,
            filteredStreams: streams,
          )),
        );
      },
    );
  }

  void selectCategory(String? categoryId) {
    if (state is! LiveLoaded) return;
    final current = state as LiveLoaded;

    if (categoryId == null) {
      emit(current.copyWith(
        clearCategory: true,
        filteredStreams: current.streams,
      ));
    } else {
      final filtered = current.streams.where((s) => s.categoryId == categoryId).toList();
      emit(current.copyWith(
        selectedCategoryId: categoryId,
        filteredStreams: filtered,
      ));
    }
  }

  void searchStreams(String query) {
    if (state is! LiveLoaded) return;
    final current = state as LiveLoaded;

    if (query.isEmpty) {
      final base = current.selectedCategoryId != null
          ? current.streams.where((s) => s.categoryId == current.selectedCategoryId).toList()
          : current.streams;
      emit(current.copyWith(filteredStreams: base));
      return;
    }

    final base = current.selectedCategoryId != null
        ? current.streams.where((s) => s.categoryId == current.selectedCategoryId).toList()
        : current.streams;

    final filtered = base.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
    emit(current.copyWith(filteredStreams: filtered));
  }

  Future<void> loadEpgFor(int streamId) async {
    if (state is! LiveLoaded) return;
    final current = state as LiveLoaded;
    if (current.epgCache.containsKey(streamId)) return;

    final result = await getEpgUseCase(streamId);
    result.fold(
          (_) {},
          (epg) {
        final updatedCache = Map<int, List<EpgProgramme>>.from(current.epgCache);
        updatedCache[streamId] = epg;
        emit(current.copyWith(epgCache: updatedCache));
      },
    );
  }
}
