// filepath: lib/features/home/widgets/hero_slider.dart
// MIZAN CORE: RESILIENT HERO SLIDER (V2026.4)

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:mizan_web/core/l10n/app_localizations.dart';

class HeroSlider extends StatelessWidget {
  const HeroSlider({super.key});

  static final List<String> sliderImages = [
    'assets/images/hero_poultry.jpg',
    'assets/images/hero_dairy.jpg',
    'assets/images/hero_legacy.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final List<Map<String, String>> localizedSlides = [
      {
        'image': sliderImages[0],
        'title': l10n.appTitle,
        'subtitle': l10n.heroSubtitleMarket,
        'button': l10n.navProducts,
        'path': '/marketplace',
        'badge': l10n.officialPlatform,
      },
      {
        'image': sliderImages[1],
        'title': l10n.heroTitleFeed,
        'subtitle': l10n.heroSubtitleFeed,
        'button': l10n.shopFeed,
        'path': '/marketplace',
        'badge': l10n.officialPlatform,
      },
      {
        'image': sliderImages[2],
        'title': l10n.aiExpertAdvisor,
        'subtitle': l10n.heroSubtitleAI,
        'button': l10n.askExpert,
        'path': '/expert-advisors',
        'badge': l10n.officialPlatform,
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: isMobile ? 220.0 : 450.0,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 7),
      ),
      items: localizedSlides.map((data) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () => context.go(data['path']!),
              child: Stack(
                fit: StackFit.expand, // Ensures gradient covers full area
                children: [
                  Image.asset(data['image']!, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.black87],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SingleChildScrollView(
                        // FIX: Prevents 4px Overflow
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBadge(data['badge']!),
                            const SizedBox(height: 12),
                            Text(
                              data['title']!.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile
                                    ? 20
                                    : 40, // Reduced for mobile safety
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: isMobile
                                  ? screenWidth * 0.85
                                  : screenWidth * 0.5,
                              child: Text(
                                data['subtitle']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isMobile
                                      ? 12
                                      : 16, // Adjusted for mobile
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 40,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => context.go(data['path']!),
                              child: Text(
                                data['button']!.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
