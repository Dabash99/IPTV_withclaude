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
import '../widgets/app_drawer.dart';
import '../widgets/app_logo.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'video_player_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSearch = false;

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
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        onNavigate: (index) =>
            HomeTabController.of(context)?.switchTab(index),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: Row(
                children: [
                  _IconBtn(
                    icon: SDGAIconsStroke.menu02,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  SizedBox(width: 10.w),
                  const AppLogoHorizontal(),
                  const Spacer(),
                  _IconBtn(
                    icon: _showSearch ? SDGAIconsStroke.cancel01 : SDGAIconsStroke.search02,
                    onTap: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        context.read<SeriesCubit>().search('');
                      }
                    }),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showSearch
                  ? Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: SearchField(
                  controller: _searchController,
                  hint: 'Search series...',
                  onChanged: (v) => context.read<SeriesCubit>().search(v),
                ),
              )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 15.sp, letterSpacing: 1, fontFamily: 'Cairo'),
                  children: [
                    TextSpan(
                      text: 'ALL ',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w300),
                    ),
                    TextSpan(
                      text: 'SERIES',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
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
                  label: 'All',
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
            message: 'No series found',
          )
              : GridView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
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

class _IconBtn extends StatelessWidget {
  final SDGAIconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Center(
          child: SDGAIcon(icon, color: Colors.white, size: 18.sp),
        ),
      ),
    );
  }
}

// ============ SERIES DETAILS (BULL-style from reference) ============
class SeriesDetailsScreen extends StatefulWidget {
  final Series series;
  const SeriesDetailsScreen({super.key, required this.series});

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> {
  int _selectedSeason = 1;
  bool _plotExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.series;
    return BlocProvider(
      create: (ctx) => SeriesDetailsCubit(
        getSeriesInfoUseCase: GetSeriesInfoUseCase(ctx.read<IptvRepository>()),
      )..loadSeriesInfo(s.seriesId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Blurred backdrop
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: s.cover.isEmpty
                    ? Container(color: AppColors.cardLight)
                    : CachedNetworkImage(
                  imageUrl: s.cover,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.cardLight),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withOpacity(0.5),
                      AppColors.background.withOpacity(0.9),
                      AppColors.background,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top nav
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                      child: Row(
                        children: [
                          _CircleBtn(
                            icon: SDGAIconsStroke.arrowRight02,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            'Series',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          BlocBuilder<FavoritesCubit, FavoritesState>(
                            builder: (ctx, _) {
                              final cubit = ctx.read<FavoritesCubit>();
                              final isFav = cubit.isFavorite(s.seriesId, FavoriteType.series);
                              return _CircleBtn(
                                icon: isFav
                                    ? SDGAIconsBulk.favourite
                                    : SDGAIconsStroke.favourite,
                                color: isFav ? AppColors.error : Colors.white,
                                onTap: () => cubit.toggle(FavoriteItem(
                                  id: s.seriesId,
                                  name: s.name,
                                  image: s.cover,
                                  type: FavoriteType.series,
                                )),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Poster + Title + Buttons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120.w,
                            height: 170.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: s.cover.isEmpty
                                  ? Container(color: AppColors.cardLight)
                                  : CachedNetworkImage(
                                imageUrl: s.cover,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    Container(color: AppColors.cardLight),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                if (s.genre.isNotEmpty)
                                  Text(
                                    s.genre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                SizedBox(height: 14.h),
                                // Play + Trailer
                                BlocBuilder<SeriesDetailsCubit, SeriesState>(
                                  builder: (ctx, state) {
                                    Episode? firstEp;
                                    if (state is SeriesDetailsLoaded) {
                                      final keys = state.episodesBySeason.keys.toList()..sort();
                                      if (keys.isNotEmpty) {
                                        final eps = state.episodesBySeason[keys.first] ?? [];
                                        if (eps.isNotEmpty) firstEp = eps.first;
                                      }
                                    }
                                    return SizedBox(
                                      width: double.infinity,
                                      child: _PillBtn(
                                        label: 'Play',
                                        icon: SDGAIconsBulk.play,
                                        primary: true,
                                        onTap: firstEp == null
                                            ? null
                                            : () {
                                          final repo = ctx.read<IptvRepository>();
                                          final url = repo.buildSeriesStreamUrl(
                                            int.tryParse(firstEp!.id) ?? 0,
                                            firstEp.containerExtension,
                                          );
                                          Navigator.push(
                                            ctx,
                                            MaterialPageRoute(
                                              builder: (_) => VideoPlayerScreen(
                                                url: url,
                                                title: '${s.name} - ${firstEp?.title}',
                                                isLive: false,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Meta columns
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          if (s.releaseDate.isNotEmpty)
                            Expanded(
                              child: _MetaColumn(
                                label: 'Release Date',
                                value: s.releaseDate,
                              ),
                            ),
                          if (s.director.isNotEmpty)
                            Expanded(
                              child: _MetaColumn(
                                label: 'Director',
                                value: s.director,
                              ),
                            ),
                          if (s.rating > 0)
                            Expanded(
                              child: _MetaColumn(
                                label: 'Rating',
                                value: '⭐ ${s.rating.toStringAsFixed(1)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(height: 1, color: AppColors.border),
                    ),
                    SizedBox(height: 20.h),

                    // Cast chips
                    if (s.cast.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Cast',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: s.cast
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .take(8)
                              .map((name) => _CastChip(name: name))
                              .toList(),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // Plot
                    if (s.plot.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Plot',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _plotExpanded = !_plotExpanded),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.sp,
                                height: 1.7,
                                fontFamily: 'Cairo',
                              ),
                              children: [
                                TextSpan(
                                  text: _plotExpanded
                                      ? s.plot
                                      : (s.plot.length > 180
                                      ? '${s.plot.substring(0, 180)}… '
                                      : s.plot),
                                ),
                                if (s.plot.length > 180)
                                  TextSpan(
                                    text: _plotExpanded ? ' show less' : 'more',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // Seasons pills + episodes list
                    BlocBuilder<SeriesDetailsCubit, SeriesState>(
                      builder: (ctx, state) {
                        if (state is SeriesDetailsLoading) {
                          return Padding(
                            padding: EdgeInsets.all(32.h),
                            child: const AppLoadingIndicator(),
                          );
                        }
                        if (state is SeriesDetailsLoaded) {
                          final keys = state.episodesBySeason.keys.toList()..sort();
                          if (keys.isEmpty) return const SizedBox.shrink();

                          if (!keys.contains(_selectedSeason)) {
                            _selectedSeason = keys.first;
                          }
                          final episodes = state.episodesBySeason[_selectedSeason] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 40.h,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  itemCount: keys.length,
                                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                                  itemBuilder: (_, i) {
                                    final season = keys[i];
                                    final active = _selectedSeason == season;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedSeason = season),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColors.cardLight
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(100.r),
                                          border: Border.all(
                                            color: active
                                                ? Colors.transparent
                                                : AppColors.border.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          'Season $season',
                                          style: TextStyle(
                                            color: active
                                                ? Colors.white
                                                : AppColors.textMuted,
                                            fontSize: 12.sp,
                                            fontWeight:
                                            active ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Column(
                                  children: episodes
                                      .map((ep) => _EpisodeRow(
                                    episode: ep,
                                    series: s,
                                  ))
                                      .toList(),
                                ),
                              ),
                              SizedBox(height: 100.h),
                            ],
                          );
                        }
                        return SizedBox(height: 100.h);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final SDGAIconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Center(
          child: SDGAIcon(icon, color: color, size: 18.sp),
        ),
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final String label;
  final SDGAIconData? icon;
  final bool primary;
  final VoidCallback? onTap;

  const _PillBtn({
    required this.label,
    this.icon,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: primary
          ? ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              SDGAIcon(icon!, color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      )
          : OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final String label;
  final String value;
  const _MetaColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CastChip extends StatelessWidget {
  final String name;
  const _CastChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
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
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
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
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(10.r),
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
                    SizedBox(height: 3.h),
                    Text(
                      episode.duration!,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SDGAIcon(
                  SDGAIconsBulk.play,
                  color: Colors.white,
                  size: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
