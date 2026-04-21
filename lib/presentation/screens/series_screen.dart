import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../../domain/usecases/usecases.dart';
import '../cubits/favorites_cubit.dart';
import '../cubits/series_cubit.dart';
import '../widgets/common_widgets.dart';
import 'video_player_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<SeriesCubit>().state is SeriesInitial) {
        context.read<SeriesCubit>().loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المسلسلات',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SearchField(
                    controller: _searchController,
                    hint: 'ابحث عن مسلسل...',
                    onChanged: (v) => context.read<SeriesCubit>().search(v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SeriesCubit, SeriesState>(
                builder: (context, state) {
                  if (state is SeriesLoading || state is SeriesInitial) {
                    return const AppLoadingIndicator();
                  }
                  if (state is SeriesError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => context.read<SeriesCubit>().loadData(),
                    );
                  }
                  if (state is SeriesLoaded) {
                    return _SeriesContent(state: state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesContent extends StatelessWidget {
  final SeriesLoaded state;
  const _SeriesContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: state.categories.length + 1,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, i) {
              if (i == 0) {
                return CategoryChip(
                  label: 'الكل',
                  selected: state.selectedCategoryId == null,
                  onTap: () => context.read<SeriesCubit>().selectCategory(null),
                );
              }
              final cat = state.categories[i - 1];
              return CategoryChip(
                label: cat.categoryName,
                selected: state.selectedCategoryId == cat.categoryId,
                onTap: () => context.read<SeriesCubit>().selectCategory(cat.categoryId),
              );
            },
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: state.filteredSeries.isEmpty
              ? const EmptyStateWidget(
            icon: SDGAIconsBulk.folderLibrary,
            message: 'لا توجد مسلسلات',
          )
              : GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.6,
            ),
            itemCount: state.filteredSeries.length,
            itemBuilder: (_, i) {
              final series = state.filteredSeries[i];
              return PosterCard(
                name: series.name,
                image: series.cover,
                rating: series.rating,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SeriesDetailsScreen(series: series),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============ SERIES DETAILS ============

class SeriesDetailsScreen extends StatelessWidget {
  final Series series;
  const SeriesDetailsScreen({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => SeriesDetailsCubit(
        getSeriesInfoUseCase: GetSeriesInfoUseCase(ctx.read<IptvRepository>()),
      )..loadSeriesInfo(series.seriesId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              expandedHeight: 300.h,
              pinned: true,
              leading: Padding(
                padding: EdgeInsets.all(8.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: SDGAIcon(
                      SDGAIconsStroke.arrowRight02,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                BlocBuilder<FavoritesCubit, FavoritesState>(
                  builder: (ctx, _) {
                    final cubit = ctx.read<FavoritesCubit>();
                    final isFav = cubit.isFavorite(series.seriesId, FavoriteType.series);
                    return Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: SDGAIcon(
                            isFav
                                ? SDGAIconsBulk.favourite
                                : SDGAIconsStroke.favourite,
                            color: isFav ? AppColors.error : Colors.white,
                            size: 22.sp,
                          ),
                          onPressed: () => cubit.toggle(FavoriteItem(
                            id: series.seriesId,
                            name: series.name,
                            image: series.cover,
                            type: FavoriteType.series,
                          )),
                        ),
                      ),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    series.cover.isEmpty
                        ? Container(color: AppColors.cardLight)
                        : CachedNetworkImage(
                      imageUrl: series.cover,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppColors.cardLight),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            AppColors.background.withOpacity(0.8),
                            AppColors.background,
                          ],
                          stops: const [0.0, 0.3, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 6.h,
                      children: [
                        if (series.rating > 0)
                          _MetaChip(
                            icon: SDGAIconsBulk.starCircle,
                            iconColor: AppColors.warning,
                            label: series.rating.toStringAsFixed(1),
                          ),
                        if (series.releaseDate.isNotEmpty)
                          _MetaChip(
                            icon: SDGAIconsStroke.calendar03,
                            label: series.releaseDate,
                          ),
                        if (series.genre.isNotEmpty)
                          _MetaChip(
                            icon: SDGAIconsStroke.tag01,
                            label: series.genre,
                          ),
                      ],
                    ),
                    if (series.plot.isNotEmpty) ...[
                      SizedBox(height: 18.h),
                      Text(
                        series.plot,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          height: 1.7,
                        ),
                      ),
                    ],
                    if (series.cast.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SDGAIcon(
                            SDGAIconsStroke.userGroup,
                            color: AppColors.textMuted,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              series.cast,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 24.h),
                    const SectionHeader(title: 'الحلقات'),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<SeriesDetailsCubit, SeriesState>(
                builder: (context, state) {
                  if (state is SeriesDetailsLoading) {
                    return Padding(
                      padding: EdgeInsets.all(32.h),
                      child: const AppLoadingIndicator(),
                    );
                  }
                  if (state is SeriesDetailsLoaded) {
                    return _SeasonsList(seasons: state.episodesBySeason, series: series);
                  }
                  if (state is SeriesError) {
                    return Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        state.message,
                        style: TextStyle(color: AppColors.error, fontSize: 13.sp),
                      ),
                    );
                  }
                  return SizedBox(height: 100.h);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final SDGAIconData icon;
  final Color? iconColor;
  final String label;
  const _MetaChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SDGAIcon(icon, size: 14.sp, color: iconColor ?? AppColors.textSecondary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonsList extends StatefulWidget {
  final Map<int, List<Episode>> seasons;
  final Series series;
  const _SeasonsList({required this.seasons, required this.series});

  @override
  State<_SeasonsList> createState() => _SeasonsListState();
}

class _SeasonsListState extends State<_SeasonsList> {
  int? _expandedSeason;

  @override
  void initState() {
    super.initState();
    final keys = widget.seasons.keys.toList()..sort();
    if (keys.isNotEmpty) _expandedSeason = keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.seasons.keys.toList()..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      child: Column(
        children: keys.map((season) {
          final episodes = widget.seasons[season] ?? [];
          final expanded = _expandedSeason == season;
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () => setState(() => _expandedSeason = expanded ? null : season),
                  child: Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'الموسم $season',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          '${episodes.length} حلقة',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.sp,
                          ),
                        ),
                        const Spacer(),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: SDGAIcon(
                            SDGAIconsStroke.arrowDown01,
                            color: AppColors.textSecondary,
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (expanded)
                  Column(
                    children: episodes
                        .map((ep) => _EpisodeRow(episode: ep, series: widget.series))
                        .toList(),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  final Episode episode;
  final Series series;
  const _EpisodeRow({required this.episode, required this.series});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final repo = context.read<IptvRepository>();
        final url = repo.buildSeriesStreamUrl(
          int.tryParse(episode.id) ?? 0,
          episode.containerExtension,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              url: url,
              title: '${series.name} - ${episode.title}',
              isLive: false,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                '${episode.episodeNum}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (episode.duration != null && episode.duration!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      episode.duration!,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SDGAIcon(
                  SDGAIconsBulk.play,
                  color: AppColors.primary,
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
