import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/downloads_datasource.dart';

class DownloadsState extends Equatable {
  final List<DownloadItem> items;
  const DownloadsState(this.items);
  @override
  List<Object?> get props => [items];
}

class DownloadsCubit extends Cubit<DownloadsState> {
  final DownloadsDataSource dataSource;

  DownloadsCubit(this.dataSource) : super(const DownloadsState([])) {
    load();
  }

  void load() => emit(DownloadsState(dataSource.getAll()));

  Future<void> startDownload({
    required int contentId,
    required String name,
    required String image,
    required String type,
    required String url,
    required String extension,
  }) async {
    final item = DownloadItem(
      contentId: contentId,
      name: name,
      image: image,
      type: type,
      url: url,
      extension: extension,
    );

    // Reload immediately so UI reflects the queued state
    await dataSource.startDownload(
      item: item,
      onUpdate: (_) => load(),
    );
    load();
  }

  Future<void> cancel(DownloadItem item) async {
    dataSource.cancelDownload(item.uniqueKey);
    load();
  }

  Future<void> remove(DownloadItem item) async {
    await dataSource.remove(item);
    load();
  }

  bool isDownloaded(int contentId, String type) =>
      dataSource.isDownloaded(contentId, type);

  DownloadItem? findItem(int contentId, String type) =>
      dataSource.findItem(contentId, type);
}
