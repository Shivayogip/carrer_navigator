import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "INITIALIZE_SYSTEM",
      description:
          "Welcome to AI Navigator. Your companion for algorithmic career growth and neural networking.",
      image: Icons.terminal,
      color: const Color(0xFF2EA44F),
    ),
    OnboardingPage(
      title: "RESUME_OPTIMIZER",
      description:
          "Upload source code (resume) for instant diagnostic analysis and performance scoring.",
      image: Icons.psychology,
      color: const Color(0xFF58A6FF),
    ),
    OnboardingPage(
      title: "PATH_FINDER",
      description:
          "Generate career trajectories and identify missing dependency protocols to achieve target goals.",
      image: Icons.route,
      color: const Color(0xFFBC8CFF),
    ),
  ];

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPageWidget(page: _pages[index]);
              },
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[_currentPage].color
                              : theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('onboarding_completed', true);
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          child: Text(
                            "SKIP_AUTH",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? "EXEC --START"
                                : "EXEC --NEXT",
                          ),
                        ),
                      ],
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

class OnboardingPage {
  final String title;
  final String description;
  final IconData image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.image,
            size: 120,
            color: page.color,
          ).animate().scale(duration: 600.ms).shake(delay: 200.ms),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}
