import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studiq/app/app.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/app/router/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.today_rounded,
      title: 'Welcome to Study Sanctuary',
      subtitle:
          'Your personal command center for academic excellence. Calm, organized, and always in flow.',
    ),
    _OnboardingPage(
      icon: Icons.checklist_rounded,
      title: 'Plan Everything in One Place',
      subtitle:
          'Tasks, exams, meetings, and deadlines — tracked beautifully with smart reminders.',
    ),
    _OnboardingPage(
      icon: Icons.folder_open_rounded,
      title: 'Track Your Projects',
      subtitle:
          'Organize assignments and long-term projects with milestones and progress tracking.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } else {
      ref.read(onboardingSeenProvider.notifier).markSeen();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: () {
                    ref.read(onboardingSeenProvider.notifier).markSeen();
                    context.go(AppRoutes.login);
                  },
                  child: Text('Skip',
                      style:
                          AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) =>
                    _OnboardingPageWidget(page: _pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? cs.primary
                              : cs.outlineVariant,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isLast ? 'Get Started' : 'Continue'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
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

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardingPage(
      {required this.icon, required this.title, required this.subtitle});
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerHigh
                  : AppColors.lightSurfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 60, color: cs.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            page.title,
            style: AppTextStyles.h2(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.subtitle,
            style: AppTextStyles.bodyLg(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
