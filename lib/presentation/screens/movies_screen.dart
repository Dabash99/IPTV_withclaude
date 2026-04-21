import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../cubits/movies_cubit.dart';
import '../widgets/common_widgets.dart';
import 'movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _searchController = TextEditingController();

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
                    'الأفلام',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SearchField(
                    controller: _searchController,
                    hint: 'ابحث عن فيلم...',
                    onChanged: (v) => context.read<MoviesCubit>().search(v),
                  ),
                ],
              ),
            ),
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
                  label: 'الكل',
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
            message: 'لا توجد أفلام',
          )
              : GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
