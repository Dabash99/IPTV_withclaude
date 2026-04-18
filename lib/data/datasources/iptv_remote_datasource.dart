import '../../core/constants/api_endpoints.dart';
import '../../core/errors/failures.dart';
import '../../core/network/dio_helper.dart';
import '../models/stream_models.dart';
import '../models/user_credentials_model.dart';

abstract class IptvRemoteDataSource {
  Future<UserCredentialsModel> login({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<List<CategoryModel>> getLiveCategories({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<List<LiveStreamModel>> getLiveStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  });

  Future<List<EpgProgrammeModel>> getShortEpg({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
  });

  Future<List<CategoryModel>> getVodCategories({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<List<MovieModel>> getMovies({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  });

  Future<MovieModel> getMovieInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int movieId,
  });

  Future<List<CategoryModel>> getSeriesCategories({
    required String serverUrl,
    required String username,
    required String password,
  });

  Future<List<SeriesModel>> getSeries({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  });

  Future<Map<int, List<EpisodeModel>>> getSeriesInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int seriesId,
  });
}

class IptvRemoteDataSourceImpl implements IptvRemoteDataSource {
  final DioHelper dioHelper;

  IptvRemoteDataSourceImpl(this.dioHelper);

  String _cleanUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) cleaned = cleaned.substring(0, cleaned.length - 1);
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    return cleaned;
  }

  @override
  Future<UserCredentialsModel> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final cleanedUrl = _cleanUrl(serverUrl);
    final response = await dioHelper.get(
      ApiEndpoints.playerApi(cleanedUrl),
      queryParameters: {
        'username': username,
        'password': password,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw AuthException('استجابة غير صحيحة من السيرفر');
    }

    final userInfo = data['user_info'] as Map<String, dynamic>?;
    if (userInfo == null || userInfo['auth'] == 0 || userInfo['auth'] == '0') {
      throw AuthException('بيانات الدخول غير صحيحة');
    }

    final status = userInfo['status']?.toString().toLowerCase();
    if (status != 'active') {
      throw AuthException('الحساب غير نشط: ${userInfo['status']}');
    }

    return UserCredentialsModel.fromJson(
      serverUrl: cleanedUrl,
      username: username,
      password: password,
      json: data,
    );
  }

  Future<List<dynamic>> _fetchList({
    required String serverUrl,
    required String username,
    required String password,
    required String action,
    String? categoryId,
  }) async {
    final queryParams = <String, dynamic>{
      'username': username,
      'password': password,
      'action': action,
    };
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['category_id'] = categoryId;
    }

    final response = await dioHelper.get(
      ApiEndpoints.playerApi(serverUrl),
      queryParameters: queryParams,
    );

    if (response.data is List) {
      return response.data as List<dynamic>;
    }
    return [];
  }

  @override
  Future<List<CategoryModel>> getLiveCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final data = await _fetchList(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: ApiEndpoints.getLiveCategories,
    );
    return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<LiveStreamModel>> getLiveStreams({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final data = await _fetchList(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: ApiEndpoints.getLiveStreams,
      categoryId: categoryId,
    );
    return data.map((e) => LiveStreamModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<EpgProgrammeModel>> getShortEpg({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
  }) async {
    final response = await dioHelper.get(
      ApiEndpoints.playerApi(serverUrl),
      queryParameters: {
        'username': username,
        'password': password,
        'action': ApiEndpoints.getShortEpg,
        'stream_id': streamId,
      },
    );

    final epgListings = response.data is Map
        ? (response.data['epg_listings'] as List?) ?? []
        : (response.data as List?) ?? [];

    return epgListings
        .map((e) => EpgProgrammeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CategoryModel>> getVodCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final data = await _fetchList(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: ApiEndpoints.getVodCategories,
    );
    return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MovieModel>> getMovies({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final data = await _fetchList(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: ApiEndpoints.getVodStreams,
      categoryId: categoryId,
    );
    return data.map((e) => MovieModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<MovieModel> getMovieInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int movieId,
  }) async {
    final response = await dioHelper.get(
      ApiEndpoints.playerApi(serverUrl),
      queryParameters: {
        'username': username,
        'password': password,
        'action': ApiEndpoints.getVodInfo,
        'vod_id': movieId,
      },
    );
    return MovieModel.fromInfoJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<CategoryModel>> getSeriesCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final data = await _fetchList(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: ApiEndpoints.getSeriesCategories,
    );
    return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SeriesModel>> getSeries({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final data = await _fetchList(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: ApiEndpoints.getSeries,
      categoryId: categoryId,
    );
    return data.map((e) => SeriesModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Map<int, List<EpisodeModel>>> getSeriesInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int seriesId,
  }) async {
    final response = await dioHelper.get(
      ApiEndpoints.playerApi(serverUrl),
      queryParameters: {
        'username': username,
        'password': password,
        'action': ApiEndpoints.getSeriesInfo,
        'series_id': seriesId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final episodesData = data['episodes'] as Map<String, dynamic>? ?? {};

    final result = <int, List<EpisodeModel>>{};
    episodesData.forEach((seasonKey, episodesList) {
      final season = int.tryParse(seasonKey) ?? 0;
      final list = (episodesList as List)
          .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>, season))
          .toList();
      result[season] = list;
    });

    return result;
  }
}
