import 'package:equatable/equatable.dart';

class LiveStream extends Equatable {
  final int streamId;
  final String name;
  final String streamIcon;
  final int epgChannelId;
  final String categoryId;
  final int tvArchive;
  final int tvArchiveDuration;

  const LiveStream({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.epgChannelId,
    required this.categoryId,
    this.tvArchive = 0,
    this.tvArchiveDuration = 0,
  });

  @override
  List<Object?> get props => [streamId, name, categoryId];
}

class Movie extends Equatable {
  final int streamId;
  final String name;
  final String streamIcon;
  final double rating;
  final String categoryId;
  final String containerExtension;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final int? durationSecs;

  const Movie({
    required this.streamId,
    required this.name,
    required this.streamIcon,
    required this.rating,
    required this.categoryId,
    required this.containerExtension,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.durationSecs,
  });

  @override
  List<Object?> get props => [streamId, name, categoryId];
}

class Series extends Equatable {
  final int seriesId;
  final String name;
  final String cover;
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final String lastModified;
  final double rating;
  final String categoryId;

  const Series({
    required this.seriesId,
    required this.name,
    required this.cover,
    required this.plot,
    required this.cast,
    required this.director,
    required this.genre,
    required this.releaseDate,
    required this.lastModified,
    required this.rating,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [seriesId, name, categoryId];
}

class Episode extends Equatable {
  final String id;
  final int episodeNum;
  final String title;
  final String containerExtension;
  final int season;
  final String? plot;
  final String? duration;
  final String? movieImage;

  const Episode({
    required this.id,
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    required this.season,
    this.plot,
    this.duration,
    this.movieImage,
  });

  @override
  List<Object?> get props => [id, episodeNum, season];
}

class EpgProgramme extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String channelId;

  const EpgProgramme({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.channelId,
  });

  @override
  List<Object?> get props => [id, start, end];
}
