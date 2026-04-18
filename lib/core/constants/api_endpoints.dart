class ApiEndpoints {
  // Xtream Codes endpoints
  static String playerApi(String baseUrl) => '$baseUrl/player_api.php';

  // Actions
  static const String getLiveCategories = 'get_live_categories';
  static const String getLiveStreams = 'get_live_streams';
  static const String getVodCategories = 'get_vod_categories';
  static const String getVodStreams = 'get_vod_streams';
  static const String getVodInfo = 'get_vod_info';
  static const String getSeriesCategories = 'get_series_categories';
  static const String getSeries = 'get_series';
  static const String getSeriesInfo = 'get_series_info';
  static const String getShortEpg = 'get_short_epg';
  static const String getSimpleDataTable = 'get_simple_data_table';

  // Stream URL builders
  static String liveStreamUrl(String baseUrl, String user, String pass, int streamId, {String ext = 'm3u8'}) =>
      '$baseUrl/live/$user/$pass/$streamId.$ext';

  static String movieStreamUrl(String baseUrl, String user, String pass, int streamId, String ext) =>
      '$baseUrl/movie/$user/$pass/$streamId.$ext';

  static String seriesStreamUrl(String baseUrl, String user, String pass, int streamId, String ext) =>
      '$baseUrl/series/$user/$pass/$streamId.$ext';
}

class StorageKeys {
  static const String serverUrl = 'server_url';
  static const String username = 'username';
  static const String password = 'password';
  static const String isLoggedIn = 'is_logged_in';
  static const String userInfo = 'user_info';
}
