import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/favorites_cubit.dart';
import '../cubits/live_cubit.dart';
import '../widgets/common_widgets.dart';
import '../widgets/epg_widget.dart';
import 'video_player_screen.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  final _searchController = TextEditingController();

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
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'القنوات المباشرة',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  SearchField(
                    controller: _searchController,
                    hint: 'ابحث عن قناة...',
                    onChanged: (v) => context.read<LiveCubit>().searchStreams(v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<LiveCubit, LiveState>(
                builder: (context, state) {
                  if (state is LiveLoading || state is LiveInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (state is LiveError) {
                    return _ErrorState(
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
        // Categories
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
        SizedBox(height: 12.h),
        Expanded(
          child: state.filteredStreams.isEmpty
              ? _EmptyState(message: 'لا توجد قنوات')
              : ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                    SizedBox(width: 8.w),
                    BlocBuilder<FavoritesCubit, FavoritesState>(
                      builder: (ctx, _) {
                        final cubit = ctx.read<FavoritesCubit>();
                        final isFav = cubit.isFavorite(stream.streamId, FavoriteType.live);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.error : AppColors.textMuted,
                            size: 22.sp,
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

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 56.sp),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 56.sp),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontSize: 13.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
