import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/favorites_cubit.dart';
import '../cubits/live_cubit.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_logo.dart';
import '../widgets/common_widgets.dart';
import '../widgets/epg_widget.dart';
import 'home_screen.dart';
import 'video_player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<LiveCubit>().state is LiveInitial) {
        context.read<LiveCubit>().loadData();
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
            // Top bar: menu + logo + actions
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.live.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(color: AppColors.live.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: AppColors.live,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.live,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _IconBtn(
                    icon: _showSearch ? SDGAIconsStroke.cancel01 : SDGAIconsStroke.search02,
                    onTap: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        context.read<LiveCubit>().searchStreams('');
                      }
                    }),
                  ),
                ],
              ),
            ),

            // Collapsible search
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _showSearch
                  ? Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: SearchField(
                  controller: _searchController,
                  hint: 'Search channels...',
                  onChanged: (v) => context.read<LiveCubit>().searchStreams(v),
                ),
              )
                  : const SizedBox.shrink(),
            ),

            // Section title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 15.sp, letterSpacing: 1, fontFamily: 'Cairo'),
                  children: [
                    TextSpan(
                      text: 'LIVE ',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w300),
                    ),
                    TextSpan(
                      text: 'CHANNELS',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),

            Expanded(
              child: BlocBuilder<LiveCubit, LiveState>(
                builder: (context, state) {
                  if (state is LiveLoading || state is LiveInitial) {
                    return const AppLoadingIndicator();
                  }
                  if (state is LiveError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => context.read<LiveCubit>().loadData(),
                    );
                  }
                  if (state is LiveLoaded) {
                    return _LiveContent(state: state);
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

class _LiveContent extends StatelessWidget {
  final LiveLoaded state;
  const _LiveContent({required this.state});

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
                  onTap: () => context.read<LiveCubit>().selectCategory(null),
                );
              }
              final cat = state.categories[i - 1];
              return CategoryChip(
                label: cat.categoryName,
                selected: state.selectedCategoryId == cat.categoryId,
                onTap: () => context.read<LiveCubit>().selectCategory(cat.categoryId),
              );
            },
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: state.filteredStreams.isEmpty
              ? const EmptyStateWidget(
            icon: SDGAIconsBulk.tv01,
            message: 'No channels found',
            subtitle: 'Try a different category or search',
          )
              : ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
            itemCount: state.filteredStreams.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (_, i) {
              final stream = state.filteredStreams[i];
              final epg = state.epgCache[stream.streamId];
              final now = DateTime.now();
              final currentProgramme = epg?.firstWhere(
                    (p) => now.isAfter(p.start) && now.isBefore(p.end),
                orElse: () => epg.first,
              );

              return GestureDetector(
                onLongPress: () {
                  context.read<LiveCubit>().loadEpgFor(stream.streamId);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (!context.mounted) return;
                    final latest = context.read<LiveCubit>().state;
                    if (latest is! LiveLoaded) return;
                    final list = latest.epgCache[stream.streamId] ?? [];
                    EpgBottomSheet.show(
                      context,
                      channelName: stream.name,
                      programmes: list,
                    );
                  });
                },
                child: Row(
                  children: [
                    Expanded(
                      child: LiveStreamCard(
                        name: stream.name,
                        icon: stream.streamIcon,
                        currentProgramme: currentProgramme?.title,
                        onTap: () {
                          final repo = context.read<IptvRepository>();
                          final url = repo.buildLiveStreamUrl(stream.streamId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                url: url,
                                title: stream.name,
                                isLive: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 4.w),
                    BlocBuilder<FavoritesCubit, FavoritesState>(
                      builder: (ctx, _) {
                        final cubit = ctx.read<FavoritesCubit>();
                        final isFav = cubit.isFavorite(stream.streamId, FavoriteType.live);
                        return IconButton(
                          icon: SDGAIcon(
                            isFav
                                ? SDGAIconsBulk.favourite
                                : SDGAIconsStroke.favourite,
                            color: isFav ? AppColors.error : AppColors.textMuted,
                            size: 20.sp,
                          ),
                          onPressed: () => cubit.toggle(FavoriteItem(
                            id: stream.streamId,
                            name: stream.name,
                            image: stream.streamIcon,
                            type: FavoriteType.live,
                          )),
                        );
                      },
                    ),
                  ],
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
