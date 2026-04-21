import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WatchHistoryItem {
  final int id;
  final String name;
  final String image;
  final String type; // 'movie' | 'series'
  final String? extension;
  final int? progressSeconds;
  final int? durationSeconds;
  final DateTime lastWatched;

  WatchHistoryItem({
    required this.id,
    required this.name,
    required this.image,
    required this.type,
    this.extension,
    this.progressSeconds,
    this.durationSeconds,
    required this.lastWatched,
  });

  double get progress {
    if (progressSeconds == null || durationSeconds == null || durationSeconds! <= 0) {
      return 0.0;
    }
    return (progressSeconds! / durationSeconds!).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'type': type,
    'extension': extension,
    'progressSeconds': progressSeconds,
    'durationSeconds': durationSeconds,
    'lastWatched': lastWatched.toIso8601String(),
  };

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) => WatchHistoryItem(
    id: json['id'] as int,
    name: json['name'] as String,
    image: json['image'] as String,
    type: json['type'] as String,
    extension: json['extension'] as String?,
    progressSeconds: json['progressSeconds'] as int?,
    durationSeconds: json['durationSeconds'] as int?,
    lastWatched: DateTime.parse(json['lastWatched'] as String),
  );
}

class WatchHistoryDataSource {
  static const _key = 'watch_history_v1';
  static const _maxItems = 20;
  final SharedPreferences prefs;

  WatchHistoryDataSource(this.prefs);

  List<WatchHistoryItem> getAll() {
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => WatchHistoryItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
  }

  Future<void> add(WatchHistoryItem item) async {
    final current = getAll();
    current.removeWhere((i) => i.id == item.id && i.type == item.type);
    current.insert(0, item);
    final trimmed = current.take(_maxItems).toList();
    await prefs.setStringList(
      _key,
      trimmed.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  Future<void> clear() async => prefs.remove(_key);
}
