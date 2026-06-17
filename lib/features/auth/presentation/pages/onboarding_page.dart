import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/injection_container.dart';
import '../../../../core/utils/app_router.dart';

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
  });
}

const _slides = [
  _OnboardingSlide(
    title: 'Find Smart Bins Near You',
    description:
    'Use our interactive map to locate the nearest RecySmart bins in your city and check their available capacity.',
    icon: Icons.map_rounded,
    iconBgColor: AppColors.primaryLight,
  ),
  _OnboardingSlide(
    title: 'Scan to Unlock',
    description:
    'Simply scan the QR code on the physical bin to start your secure recycling session instantly.',
    icon: Icons.qr_code_scanner_rounded,
    iconBgColor: Color(0xFFE8EAF6),
  ),
  _OnboardingSlide(
    title: 'Earn Eco-Rewards',
    description:
    'Drop your plastic bottles, reduce your carbon footprint, and earn points to redeem for exclusive discounts.',
    icon: Icons.card_giftcard_rounded,
    iconBgColor: Color(0xFFFFFBE6),
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  Future<void> _finish() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(AppConstants.onboardingDoneKey, true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 24),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),

            // Indicators + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage == _slides.length - 1)
                    ElevatedButton(
                      onPressed: _finish,
                      child: const Text('Get Started'),
                    )
                  else
                    GestureDetector(
                      onTap: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: slide.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}