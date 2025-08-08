import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../theme_data.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = AppThemes.availableThemes.indexOf(AppThemes.currentTheme);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: AppThemes.currentThemeNotifier,
      builder: (context, currentTheme, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Themes',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: Container(
            decoration: BoxDecoration(gradient: currentTheme.mainGradient),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16), // Reduced from 20
                  // Theme Name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      AppThemes.availableThemes[_currentIndex].name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16), // Reduced from 20
                  // Theme Preview Carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: AppThemes.availableThemes.length,
                      itemBuilder: (context, index) {
                        final theme = AppThemes.availableThemes[index];
                        return _buildThemePreview(theme, index);
                      },
                    ),
                  ),
                  // In Use Section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16, // Reduced from 20
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentTheme ==
                                  AppThemes.availableThemes[_currentIndex]
                              ? 'In Use'
                              : 'Apply Theme',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppThemes
                                    .availableThemes[_currentIndex]
                                    .primaryColor
                                    .withOpacity(0.8),
                                AppThemes
                                    .availableThemes[_currentIndex]
                                    .secondaryColor
                                    .withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final selectedTheme =
                                    AppThemes.availableThemes[_currentIndex];
                                if (currentTheme != selectedTheme) {
                                  await AppThemes.setCurrentTheme(
                                    selectedTheme,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Theme "${selectedTheme.name}" applied successfully!',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        backgroundColor:
                                            selectedTheme.primaryColor,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Center(
                                child: Text(
                                  currentTheme ==
                                          AppThemes
                                              .availableThemes[_currentIndex]
                                      ? 'In Use'
                                      : 'Apply Theme',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemePreview(AppTheme theme, int index) {
    final isSelected = index == _currentIndex;
    final scale = isSelected ? 1.0 : 0.85;
    final opacity = isSelected ? 1.0 : 0.6;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: theme.mainGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildThemePreviewContent(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemePreviewContent(AppTheme theme) {
    return Container(
      height: 420, // Final optimized height to prevent overflow
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Bar
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.backgroundColor.withOpacity(0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '9:40',
                  style: GoogleFonts.poppins(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.textColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.wifi, color: theme.textColor, size: 12),
                    const SizedBox(width: 4),
                    Icon(Icons.battery_full, color: theme.textColor, size: 12),
                  ],
                ),
              ],
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.surfaceColor.withOpacity(0.8),
            ),
            child: Row(
              children: [
                Text(
                  'Media Player',
                  style: GoogleFonts.poppins(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.search, color: theme.textColor, size: 20),
              ],
            ),
          ),
          // Video Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceColor.withOpacity(0.6),
            ),
            child: Row(
              children: [
                Text(
                  '20 Videos',
                  style: GoogleFonts.poppins(
                    color: theme.mutedTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Video List
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                itemCount: 3, // Further reduced to prevent overflow
                itemBuilder: (context, index) {
                  return _buildVideoCard(theme, index);
                },
              ),
            ),
          ),
          // Bottom Navigation
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceColor.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(theme, 'assets/video.png', 'Video'),
                _buildNavItem(theme, 'assets/music.png', 'Music'),
                _buildNavItem(theme, 'assets/settings.png', 'Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(AppTheme theme, int index) {
    final titles = [
      'Rural Vietnam Stream',
      'National Women\'s Hockey',
      'Sri Lankan Girl\'s Ambuluwawa Tower Hike',
    ];
    final subtitles = ['Today', 'Yesterday', '2 days ago'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: theme.cardGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.movie, color: theme.textColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[index],
                  style: GoogleFonts.poppins(
                    color: theme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[index],
                  style: GoogleFonts.poppins(
                    color: theme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Icons
          Row(
            children: [
              Icon(Icons.star_border, color: theme.textColor, size: 20),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: theme.textColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(AppTheme theme, String assetPath, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: 24,
          height: 24,
          // Removed color parameter to use original colors
        ),
        const SizedBox(height: 2), // Reduced from 4
        Text(
          label,
          style: GoogleFonts.poppins(
            color: theme.textColor,
            fontSize: 11, // Reduced from 12
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
