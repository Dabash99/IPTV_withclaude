import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum FavoriteType { live, movie, series }

class FavoriteItem {
  final int id;
  final String name;
  final String image;
  final FavoriteType type;
  final String? extension;

  FavoriteItem({
    required this.id,
    required this.name,
    required this.image,
    required this.type,
    this.extension,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'type': type.name,
    'extension': extension,
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: json['id'] as int,
    name: json['name'] as String,
    image: json['image'] as String,
    type: FavoriteType.values.firstWhere((e) => e.name == json['type']),
    extension: json['extension'] as String?,
  );
}

class FavoritesDataSource {
  static const _key = 'favorites_v1';
  final SharedPreferences prefs;

  FavoritesDataSource(this.prefs);

  List<FavoriteItem> getAll() {
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => FavoriteItem.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  List<FavoriteItem> getByType(FavoriteType type) =>
      getAll().where((f) => f.type == type).toList();

  bool isFavorite(int id, FavoriteType type) =>
      getAll().any((f) => f.id == id && f.type == type);

  Future<void> toggle(FavoriteItem item) async {
    final current = getAll();
    final existingIndex = current.indexWhere((f) => f.id == item.id && f.type == item.type);
    if (existingIndex >= 0) {
      current.removeAt(existingIndex);
    } else {
      current.add(item);
    }
    await prefs.setStringList(_key, current.map((f) => jsonEncode(f.toJson())).toList());
  }

  Future<void> clear() async => prefs.remove(_key);
}
