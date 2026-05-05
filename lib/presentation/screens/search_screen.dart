import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/live_cubit.dart';
import '../cubits/movies_cubit.dart';
import '../cubits/series_cubit.dart';
import 'movie_details_screen.dart';
import 'series_screen.dart';
import 'video_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final TabController _tabController;
  String _query = '';

  // Filters
  String? _genreFilter;
  String? _yearFilter;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final moviesState = context.read<MoviesCubit>().state;
      if (moviesState is MoviesInitial) context.read<MoviesCubit>().loadData();
      final seriesState = context.read<SeriesCubit>().state;
      if (seriesState is SeriesInitial) context.read<SeriesCubit>().loadData();
      final liveState = context.read<LiveCubit>().state;
      if (liveState is LiveInitial) context.read<LiveCubit>().loadData();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Movie> _filteredMovies(List<Movie> all) {
    var list = all.where((m) {
      final q = _query.toLowerCase();
      if (q.isNotEmpty && !m.name.toLowerCase().contains(q)) return false;
      if (_genreFilter != null && _genreFilter!.isNotEmpty) {
        if (m.genre?.toLowerCase().contains(_genreFilter!.toLowerCase()) != true) return false;
      }
      if (_yearFilter != null && _yearFilter!.isNotEmpty) {
        if (m.releaseDate?.startsWith(_yearFilter!) != true) return false;
      }
      if (_minRating != null && m.rating < _minRating!) return false;
      return true;
    }).toList();
    return list;
  }

  List<Series> _filteredSeries(List<Series> all) {
    return all.where((s) {
      final q = _query.toLowerCase();
      if (q.isNotEmpty && !s.name.toLowerCase().contains(q)) return false;
      if (_genreFilter != null && _genreFilter!.isNotEmpty) {
        if (!s.genre.toLowerCase().contains(_genreFilter!.toLowerCase())) return false;
      }
      if (_yearFilter != null && _yearFilter!.isNotEmpty) {
        if (!s.releaseDate.startsWith(_yearFilter!)) return false;
      }
      if (_minRating != null && s.rating < _minRating!) return false;
      return true;
    }).toList();
  }

  List<LiveStream> _filteredLive(List<LiveStream> all) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40.w, height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(child: SDGAIcon(SDGAIconsStroke.arrowRight02, color: Colors.white, size: 18.sp)),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Container(
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(100.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: Colors.white, fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: 'search.hint'.tr(),
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
                            suffixIcon: _query.isNotEmpty
                                ? GestureDetector(
                              onTap: () { _controller.clear(); setState(() => _query = ''); },
                              child: Icon(Icons.clear, color: AppColors.textMuted, size: 18.sp),
                            )
                                : SDGAIcon(SDGAIconsStroke.search02, color: AppColors.textMuted, size: 18.sp),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter row (Movies & Series only)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _tabController.index != 1
                    ? const SizedBox.shrink()
                    : Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                  child: _FilterRow(
                    genreFilter: _genreFilter,
                    yearFilter: _yearFilter,
                    minRating: _minRating,
                    onGenreChanged: (v) => setState(() => _genreFilter = v),
                    onYearChanged: (v) => setState(() => _yearFilter = v),
                    onRatingChanged: (v) => setState(() => _minRating = v),
                  ),
                ),
              ),

              // Tab bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
                  onTap: (_) => setState(() {}),
                  tabs: [
                    Tab(text: 'search.live'.tr()),
                    Tab(text: 'search.movies'.tr()),
                    Tab(text: 'search.series'.tr()),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              // Results
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LiveResults(filter: _filteredLive),
                    _MoviesResults(filter: _filteredMovies),
                    _SeriesResults(filter: _filteredSeries),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter Row ─────────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final String? genreFilter;
  final String? yearFilter;
  final double? minRating;
  final ValueChanged<String?> onGenreChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<double?> onRatingChanged;

  const _FilterRow({
    required this.genreFilter,
    required this.yearFilter,
    required this.minRating,
    required this.onGenreChanged,
    required this.onYearChanged,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: genreFilter?.isNotEmpty == true ? genreFilter! : 'search.genre'.tr(),
          active: genreFilter?.isNotEmpty == true,
          onTap: () => _showGenreDialog(context),
        ),
        SizedBox(width: 8.w),
        _FilterChip(
          label: yearFilter?.isNotEmpty == true ? yearFilter! : 'search.year'.tr(),
          active: yearFilter?.isNotEmpty == true,
          onTap: () => _showYearDialog(context),
        ),
        SizedBox(width: 8.w),
        _FilterChip(
          label: minRating != null ? '★ ${minRating!.toStringAsFixed(0)}+' : 'search.rating'.tr(),
          active: minRating != null,
          onTap: () => _showRatingDialog(context),
        ),
        if (genreFilter != null || yearFilter != null || minRating != null) ...[
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              onGenreChanged(null);
              onYearChanged(null);
              onRatingChanged(null);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100.r),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text('common.clear'.tr(), style: TextStyle(color: AppColors.error, fontSize: 11.sp)),
            ),
          ),
        ],
      ],
    );
  }

  void _showGenreDialog(BuildContext context) {
    final genres = ['Action', 'Comedy', 'Drama', 'Horror', 'Romance', 'Sci-Fi', 'Thriller', 'Animation', 'Documentary'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => _PickerSheet(
        title: 'search.genre'.tr(),
        items: genres,
        selected: genreFilter,
        onSelected: (v) { onGenreChanged(v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showYearDialog(BuildContext context) {
    final now = DateTime.now().year;
    final years = List.generate(20, (i) => '${now - i}');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => _PickerSheet(
        title: 'search.year'.tr(),
        items: years,
        selected: yearFilter,
        onSelected: (v) { onYearChanged(v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => _PickerSheet(
        title: 'search.min_rating'.tr(),
        items: ['5', '6', '7', '8', '9'],
        selected: minRating?.toStringAsFixed(0),
        onSelected: (v) { onRatingChanged(double.tryParse(v ?? '')); Navigator.pop(ctx); },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: active ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textMuted,
            fontSize: 11.sp,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const _PickerSheet({required this.title, required this.items, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 12.h),
        Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2.r))),
        SizedBox(height: 16.h),
        Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 12.h),
        ...items.map((item) => ListTile(
          title: Text(item, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp)),
          trailing: selected == item ? Icon(Icons.check, color: AppColors.primary, size: 18.sp) : null,
          onTap: () => onSelected(selected == item ? null : item),
        )),
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ── Live Results ───────────────────────────────────────────────────
class _LiveResults extends StatelessWidget {
  final List<LiveStream> Function(List<LiveStream>) filter;
  const _LiveResults({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveCubit, LiveState>(
      builder: (context, state) {
        if (state is LiveLoading || state is LiveInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is! LiveLoaded) return const SizedBox.shrink();
        final results = filter(state.streams);
        if (results.isEmpty) return _EmptyResult(message: 'search.no_live'.tr());
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: results.length,
          itemBuilder: (_, i) {
            final s = results[i];
            return _SearchTile(
              image: s.streamIcon,
              name: s.name,
              badge: 'LIVE',
              onTap: () {
                final repo = context.read<IptvRepository>();
                final url = repo.buildLiveStreamUrl(s.streamId);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(url: url, title: s.name, isLive: true),
                ));
              },
            );
          },
        );
      },
    );
  }
}

// ── Movies Results ─────────────────────────────────────────────────
class _MoviesResults extends StatelessWidget {
  final List<Movie> Function(List<Movie>) filter;
  const _MoviesResults({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoviesCubit, MoviesState>(
      builder: (context, state) {
        if (state is MoviesLoading || state is MoviesInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is! MoviesLoaded) return const SizedBox.shrink();
        final results = filter(state.movies);
        if (results.isEmpty) return _EmptyResult(message: 'search.no_movies'.tr());
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: results.length,
          itemBuilder: (_, i) {
            final m = results[i];
            return _SearchTile(
              image: m.streamIcon,
              name: m.name,
              subtitle: [
                if (m.genre?.isNotEmpty == true) m.genre!,
                if (m.rating > 0) '★ ${m.rating.toStringAsFixed(1)}',
              ].join(' · '),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MovieDetailsScreen(movie: m),
              )),
            );
          },
        );
      },
    );
  }
}

// ── Series Results ─────────────────────────────────────────────────
class _SeriesResults extends StatelessWidget {
  final List<Series> Function(List<Series>) filter;
  const _SeriesResults({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeriesCubit, SeriesState>(
      builder: (context, state) {
        if (state is SeriesLoading || state is SeriesInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is! SeriesLoaded) return const SizedBox.shrink();
        final results = filter(state.seriesList);
        if (results.isEmpty) return _EmptyResult(message: 'search.no_series'.tr());
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: results.length,
          itemBuilder: (_, i) {
            final s = results[i];
            return _SearchTile(
              image: s.cover,
              name: s.name,
              subtitle: [
                if (s.genre.isNotEmpty) s.genre,
                if (s.rating > 0) '★ ${s.rating.toStringAsFixed(1)}',
              ].join(' · '),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SeriesDetailsScreen(series: s),
              )),
            );
          },
        );
      },
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────
class _SearchTile extends StatelessWidget {
  final String image;
  final String name;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _SearchTile({required this.image, required this.name, required this.onTap, this.subtitle, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: image.isEmpty
                  ? Container(width: 56.w, height: 56.w, color: AppColors.cardLight)
                  : CachedNetworkImage(
                imageUrl: image,
                width: 56.w, height: 56.w,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(width: 56.w, height: 56.w, color: AppColors.cardLight),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  if (subtitle?.isNotEmpty == true) ...[
                    SizedBox(height: 3.h),
                    Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(badge!, style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final String message;
  const _EmptyResult({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SDGAIcon(SDGAIconsStroke.search02, color: AppColors.textMuted, size: 40.sp),
          SizedBox(height: 12.h),
          Text(message, style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp)),
        ],
      ),
    );
  }
}
