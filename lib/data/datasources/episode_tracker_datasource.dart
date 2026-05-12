import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EpisodeTrackerDataSource {
  static const _key = 'episode_tracker_v1';
  final SharedPreferences prefs;

  EpisodeTrackerDataSource(this.prefs);

  // Returns -1 the first time a series is seen (used to set baseline without notifying)
  int getKnownCount(int seriesId) {
    final raw = prefs.getString(_key);
    if (raw == null) return -1;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final val = map[seriesId.toString()];
    return val == null ? -1 : val as int;
  }

  Future<void> setKnownCount(int seriesId, int count) async {
    final raw = prefs.getString(_key);
    final map = raw != null
        ? jsonDecode(raw) as Map<String, dynamic>
        : <String, dynamic>{};
    map[seriesId.toString()] = count;
    await prefs.setString(_key, jsonEncode(map));
  }

  // Remove entries for series no longer in favorites to avoid stale data
  Future<void> prune(Set<int> activeIds) async {
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    map.removeWhere((k, _) => !activeIds.contains(int.tryParse(k)));
    await prefs.setString(_key, jsonEncode(map));
  }
}
