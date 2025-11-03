import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class TPromoSlider extends StatefulWidget {
  const TPromoSlider({
    super.key,
    required this.banners,
    required this.height,
    this.autoPlay = true,
    this.autoPlayInterval = 4000,
  });

  final List<String> banners;
  final double height;
  final bool autoPlay;
  final int autoPlayInterval;

  @override
  State<TPromoSlider> createState() => _TPromoSliderState();
}

class _TPromoSliderState extends State<TPromoSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    if (widget.autoPlay && widget.banners.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(Duration(milliseconds: widget.autoPlayInterval),
        (timer) {
      if (_currentPage < widget.banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    if (_currentPage < widget.banners.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    _resetAutoPlay();
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        widget.banners.length - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    _resetAutoPlay();
  }

  void _resetAutoPlay() {
    if (widget.autoPlay) {
      _timer?.cancel();
      _startAutoPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dark = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
        /// Banner Slider avec boutons de navigation
        SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// PageView principal
              PageView.builder(
                controller: _pageController,
                itemCount: widget.banners.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, index) {
                  return _buildBannerItem(
                      widget.banners[index], screenWidth, dark);
                },
              ),

              /// Bouton de navigation gauche - seulement s'il y a plus d'une image
              if (widget.banners.length > 1)
                Positioned(
                  left: 8,
                  child: _buildNavigationButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _goToPreviousPage,
                  ),
                ),

              /// Bouton de navigation droite - seulement s'il y a plus d'une image
              if (widget.banners.length > 1)
                Positioned(
                  right: 8,
                  child: _buildNavigationButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _goToNextPage,
                  ),
                ),
            ],
          ),
        ),

        /// Indicateurs de points
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppSizes.spaceBtwItems),
          _buildDotIndicators(),
        ],
      ],
    );
  }

  Widget _buildBannerItem(String banner, double screenWidth, bool dark) {
    return Padding(
      padding: _getBannerPadding(screenWidth),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: _getBannerBorderRadius(screenWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _getBannerBorderRadius(screenWidth),
          child: Stack(
            children: [
              /// Image de fond avec fit optimisé
              Image.asset(
                banner,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover, // Utilise cover pour remplir l'espace
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.white, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Image non trouvée',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              /// Overlay gradient pour améliorer la lisibilité
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < widget.banners.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == i ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  _currentPage == i ? AppColors.primary : Colors.grey.shade400,
              boxShadow: _currentPage == i
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
      ],
    );
  }

  /// Détermine le padding du banner selon la largeur de l'écran
  EdgeInsets _getBannerPadding(double screenWidth) {
    if (screenWidth < 480) {
      return const EdgeInsets.symmetric(horizontal: 4); // Réduit le padding
    } else if (screenWidth < 768) {
      return const EdgeInsets.symmetric(horizontal: 6);
    } else if (screenWidth < 1024) {
      return const EdgeInsets.symmetric(horizontal: 8);
    } else {
      return const EdgeInsets.symmetric(horizontal: 10);
    }
  }

  /// Détermine le border radius selon la largeur de l'écran
  BorderRadius _getBannerBorderRadius(double screenWidth) {
    if (screenWidth < 480) {
      return BorderRadius.circular(16);
    } else if (screenWidth < 768) {
      return BorderRadius.circular(20);
    } else {
      return BorderRadius.circular(24);
    }
  }
}
