import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DownloadStatus { queued, downloading, completed, failed, paused }

class DownloadItem {
  final int contentId;
  final String name;
  final String image;
  final String type; // 'movie' | 'series'
  final String url;
  final String extension;
  final String? localPath;
  final DownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  DownloadItem({
    required this.contentId,
    required this.name,
    required this.image,
    required this.type,
    required this.url,
    required this.extension,
    this.localPath,
    this.status = DownloadStatus.queued,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  String get uniqueKey => '${type}_$contentId';

  double get progress {
    if (totalBytes <= 0) return 0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  DownloadItem copyWith({
    String? localPath,
    DownloadStatus? status,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) =>
      DownloadItem(
        contentId: contentId,
        name: name,
        image: image,
        type: type,
        url: url,
        extension: extension,
        localPath: localPath ?? this.localPath,
        status: status ?? this.status,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        errorMessage: errorMessage,
      );

  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'name': name,
    'image': image,
    'type': type,
    'url': url,
    'extension': extension,
    'localPath': localPath,
    'status': status.name,
    'downloadedBytes': downloadedBytes,
    'totalBytes': totalBytes,
    'errorMessage': errorMessage,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    contentId: json['contentId'] as int,
    name: json['name'] as String,
    image: json['image'] as String,
    type: json['type'] as String,
    url: json['url'] as String,
    extension: json['extension'] as String,
    localPath: json['localPath'] as String?,
    status: DownloadStatus.values.firstWhere(
          (s) => s.name == json['status'],
      orElse: () => DownloadStatus.queued,
    ),
    downloadedBytes: json['downloadedBytes'] as int? ?? 0,
    totalBytes: json['totalBytes'] as int? ?? 0,
    errorMessage: json['errorMessage'] as String?,
  );
}

class DownloadsDataSource {
  static const _key = 'downloads_v1';
  final SharedPreferences prefs;
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadsDataSource(this.prefs);

  // ------------ Storage ------------
  List<DownloadItem> getAll() {
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => DownloadItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<DownloadItem> items) async {
    await prefs.setStringList(
      _key,
      items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  Future<void> _upsert(DownloadItem item) async {
    final list = getAll();
    final idx = list.indexWhere((i) => i.uniqueKey == item.uniqueKey);
    if (idx >= 0) {
      list[idx] = item;
    } else {
      list.add(item);
    }
    await _saveAll(list);
  }

  // ------------ Validation ------------
  /// HLS streams (.m3u8) cannot be downloaded as a single file
  static bool isDownloadable(String extension) {
    final ext = extension.toLowerCase();
    return ext == 'mp4' || ext == 'mkv' || ext == 'avi' || ext == 'webm';
  }

  // ------------ Operations ------------
  Future<String> _getDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/iptv_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> startDownload({
    required DownloadItem item,
    required void Function(DownloadItem) onUpdate,
  }) async {
    if (!isDownloadable(item.extension)) {
      final failed = item.copyWith(
        status: DownloadStatus.failed,
        errorMessage: 'HLS streams cannot be downloaded',
      );
      await _upsert(failed);
      onUpdate(failed);
      return;
    }

    final dir = await _getDownloadDir();
    final safeName = item.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final filePath = '$dir/${item.uniqueKey}_$safeName.${item.extension}';

    final cancelToken = CancelToken();
    _cancelTokens[item.uniqueKey] = cancelToken;

    final downloading = item.copyWith(
      status: DownloadStatus.downloading,
      localPath: filePath,
    );
    await _upsert(downloading);
    onUpdate(downloading);

    try {
      await _dio.download(
        item.url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) async {
          final updated = downloading.copyWith(
            downloadedBytes: received,
            totalBytes: total > 0 ? total : downloading.totalBytes,
          );
          await _upsert(updated);
          onUpdate(updated);
        },
      );

      final completed = downloading.copyWith(
        status: DownloadStatus.completed,
        downloadedBytes: downloading.totalBytes,
      );
      await _upsert(completed);
      onUpdate(completed);
      _cancelTokens.remove(item.uniqueKey);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // User cancelled - delete partial file and remove from list
        await _delete(item);
      } else {
        final failed = downloading.copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.message ?? 'Download failed',
        );
        await _upsert(failed);
        onUpdate(failed);
      }
      _cancelTokens.remove(item.uniqueKey);
    } catch (e) {
      final failed = downloading.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      await _upsert(failed);
      onUpdate(failed);
      _cancelTokens.remove(item.uniqueKey);
    }
  }

  void cancelDownload(String uniqueKey) {
    _cancelTokens[uniqueKey]?.cancel('Cancelled by user');
    _cancelTokens.remove(uniqueKey);
  }

  Future<void> _delete(DownloadItem item) async {
    if (item.localPath != null) {
      try {
        final f = File(item.localPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    final list = getAll();
    list.removeWhere((i) => i.uniqueKey == item.uniqueKey);
    await _saveAll(list);
  }

  Future<void> remove(DownloadItem item) async {
    cancelDownload(item.uniqueKey);
    await _delete(item);
  }

  bool isDownloaded(int contentId, String type) {
    final list = getAll();
    return list.any((i) =>
    i.contentId == contentId &&
        i.type == type &&
        i.status == DownloadStatus.completed);
  }

  DownloadItem? findItem(int contentId, String type) {
    final list = getAll();
    try {
      return list.firstWhere(
            (i) => i.contentId == contentId && i.type == type,
      );
    } catch (_) {
      return null;
    }
  }
}
