import '../../domain/entities/category.dart';
import '../../domain/entities/stream_entities.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.categoryId,
    required super.categoryName,
    required super.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      parentId: int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
    );
  }
}

class LiveStreamModel extends LiveStream {
  const LiveStreamModel({
    required super.streamId,
    required super.name,
    required super.streamIcon,
    required super.epgChannelId,
    required super.categoryId,
    super.tvArchive,
    super.tvArchiveDuration,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString() ?? '',
      epgChannelId: int.tryParse(json['epg_channel_id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id']?.toString() ?? '',
      tvArchive: int.tryParse(json['tv_archive']?.toString() ?? '0') ?? 0,
      tvArchiveDuration: int.tryParse(json['tv_archive_duration']?.toString() ?? '0') ?? 0,
    );
  }
}

class MovieModel extends Movie {
  const MovieModel({
    required super.streamId,
    required super.name,
    required super.streamIcon,
    required super.rating,
    required super.categoryId,
    required super.containerExtension,
    super.plot,
    super.cast,
    super.director,
    super.genre,
    super.releaseDate,
    super.durationSecs,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      streamId: int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      releaseDate: json['releasedate']?.toString(),
      durationSecs: int.tryParse(json['duration_secs']?.toString() ?? ''),
    );
  }

  factory MovieModel.fromInfoJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    final movieData = json['movie_data'] as Map<String, dynamic>? ?? {};
    return MovieModel(
      streamId: int.tryParse(movieData['stream_id']?.toString() ?? '0') ?? 0,
      name: movieData['name']?.toString() ?? info['name']?.toString() ?? '',
      streamIcon: info['movie_image']?.toString() ?? '',
      rating: double.tryParse(info['rating']?.toString() ?? '0') ?? 0.0,
      categoryId: movieData['category_id']?.toString() ?? '',
      containerExtension: movieData['container_extension']?.toString() ?? 'mp4',
      plot: info['plot']?.toString(),
      cast: info['cast']?.toString(),
      director: info['director']?.toString(),
      genre: info['genre']?.toString(),
      releaseDate: info['releasedate']?.toString(),
      durationSecs: int.tryParse(info['duration_secs']?.toString() ?? ''),
    );
  }
}

class SeriesModel extends Series {
  const SeriesModel({
    required super.seriesId,
    required super.name,
    required super.cover,
    required super.plot,
    required super.cast,
    required super.director,
    required super.genre,
    required super.releaseDate,
    required super.lastModified,
    required super.rating,
    required super.categoryId,
  });

  factory SeriesModel.fromJson(Map<String, dynamic> json) {
    return SeriesModel(
      seriesId: int.tryParse(json['series_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      cover: json['cover']?.toString() ?? '',
      plot: json['plot']?.toString() ?? '',
      cast: json['cast']?.toString() ?? '',
      director: json['director']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      releaseDate: json['releaseDate']?.toString() ?? json['release_date']?.toString() ?? '',
      lastModified: json['last_modified']?.toString() ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
    );
  }
}

class EpisodeModel extends Episode {
  const EpisodeModel({
    required super.id,
    required super.episodeNum,
    required super.title,
    required super.containerExtension,
    required super.season,
    super.plot,
    super.duration,
    super.movieImage,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json, int season) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    return EpisodeModel(
      id: json['id']?.toString() ?? '',
      episodeNum: int.tryParse(json['episode_num']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      season: season,
      plot: info['plot']?.toString(),
      duration: info['duration']?.toString(),
      movieImage: info['movie_image']?.toString(),
    );
  }
}

class EpgProgrammeModel extends EpgProgramme {
  const EpgProgrammeModel({
    required super.id,
    required super.title,
    required super.description,
    required super.start,
    required super.end,
    required super.channelId,
  });

  factory EpgProgrammeModel.fromJson(Map<String, dynamic> json) {
    // Xtream returns base64 encoded title/description
    return EpgProgrammeModel(
      id: json['id']?.toString() ?? '',
      title: _decodeBase64(json['title']?.toString() ?? ''),
      description: _decodeBase64(json['description']?.toString() ?? ''),
      start: _parseDate(json['start']?.toString()),
      end: _parseDate(json['end']?.toString()),
      channelId: json['channel_id']?.toString() ?? '',
    );
  }

  static String _decodeBase64(String encoded) {
    try {
      if (encoded.isEmpty) return '';
      return String.fromCharCodes(
        Uri.parse('data:text/plain;base64,$encoded').data!.contentAsBytes(),
      );
    } catch (_) {
      return encoded;
    }
  }

  static DateTime _parseDate(String? date) {
    if (date == null || date.isEmpty) return DateTime.now();
    return DateTime.tryParse(date) ?? DateTime.now();
  }
}
