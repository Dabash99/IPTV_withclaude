import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../cubits/movies_cubit.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_logo.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _searchController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<MoviesCubit>().state is MoviesInitial) {
        context.read<MoviesCubit>().loadData();
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
                        context.read<MoviesCubit>().search('');
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
                  hint: 'Search movies...',
                  onChanged: (v) => context.read<MoviesCubit>().search(v),
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
                      text: 'MOVIES',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: BlocBuilder<MoviesCubit, MoviesState>(
                builder: (context, state) {
                  if (state is MoviesLoading || state is MoviesInitial) {
                    return const AppLoadingIndicator();
                  }
                  if (state is MoviesError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => context.read<MoviesCubit>().loadData(),
                    );
                  }
                  if (state is MoviesLoaded) {
                    return _MoviesContent(state: state);
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

class _MoviesContent extends StatelessWidget {
  final MoviesLoaded state;
  const _MoviesContent({required this.state});

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
                  onTap: () => context.read<MoviesCubit>().selectCategory(null),
                );
              }
              final cat = state.categories[i - 1];
              return CategoryChip(
                label: cat.categoryName,
                selected: state.selectedCategoryId == cat.categoryId,
                onTap: () => context.read<MoviesCubit>().selectCategory(cat.categoryId),
              );
            },
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: state.filteredMovies.isEmpty
              ? const EmptyStateWidget(
            icon: SDGAIconsBulk.video01,
            message: 'No movies found',
          )
              : GridView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.6,
            ),
            itemCount: state.filteredMovies.length,
            itemBuilder: (_, i) {
              final movie = state.filteredMovies[i];
              return PosterCard(
                name: movie.name,
                image: movie.streamIcon,
                rating: movie.rating,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsScreen(movie: movie),
                    ),
                  );
                },
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
