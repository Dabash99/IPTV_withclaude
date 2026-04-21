import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Cinematic blurred poster collage - used as background for welcome/login screens.
/// Takes a list of poster URLs (from movies cubit), arranges them in a grid,
/// applies blur + gradient overlay for readable foreground content.
class PosterBackdrop extends StatelessWidget {
  final List<String> posters;
  final double blurSigma;
  final double overlayOpacity;

  const PosterBackdrop({
    super.key,
    required this.posters,
    this.blurSigma = 25,
    this.overlayOpacity = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    // Use placeholder if no posters available
    final displayPosters = posters.isEmpty
        ? List.generate(9, (_) => '')
        : List.generate(9, (i) => posters[i % posters.length]);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Poster grid
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 0.65,
          children: displayPosters.map((url) {
            if (url.isEmpty) {
              return Container(color: AppColors.cardLight);
            }
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.cardLight),
              errorWidget: (_, __, ___) => Container(color: AppColors.cardLight),
            );
          }).toList(),
        ),
        // Blur layer
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(color: Colors.black.withOpacity(0.1)),
        ),
        // Gradient overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withOpacity(overlayOpacity * 0.6),
                AppColors.background.withOpacity(overlayOpacity),
                AppColors.background,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Primary color wash
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                AppColors.primary.withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
