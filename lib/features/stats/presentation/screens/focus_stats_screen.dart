import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/features/stats/presentation/providers/focus_stats_provider.dart';
import 'package:studiq/features/timer/presentation/providers/pomodoro_provider.dart';

class FocusStatsScreen extends ConsumerStatefulWidget {
  const FocusStatsScreen({super.key});

  @override
  ConsumerState<FocusStatsScreen> createState() => _FocusStatsScreenState();
}

class _FocusStatsScreenState extends ConsumerState<FocusStatsScreen> {
  int _period = 0; // 0=Day 1=Week 2=Month

  static const _labels = ['Day', 'Week', 'Month'];
  static const _days = [1, 7, 30];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final focusMinutes = ref.watch(pomodoroProvider).focusMinutes;
    final statsAsync = ref.watch(focusStatsProvider(_days[_period]));

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  4, AppSpacing.sm, AppSpacing.margin, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: cs.onSurface, size: 20),
                  ),
                  Text('Focus Report',
                      style: AppTextStyles.h2(color: cs.onSurface)),
                ],
              ),
            ),

            // ── Period selector ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin, vertical: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.lightSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  children: List.generate(_labels.length, (i) {
                    final sel = _period == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _period = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? cs.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(
                            _labels[i],
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSm(
                                color: sel
                                    ? cs.primary
                                    : cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: statsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error: $e')),
                data: (stats) => _PeriodContent(
                  stats: stats,
                  period: _period,
                  focusMinutes: focusMinutes,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period content ─────────────────────────────────────────────────────────────

class _PeriodContent extends ConsumerWidget {
  final List<DayStat> stats;
  final int period;
  final int focusMinutes;
  final bool isDark;

  const _PeriodContent({
    required this.stats,
    required this.period,
    required this.focusMinutes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final totalSessions = stats.fold(0, (s, d) => s + d.sessions);
    final totalMinutes = totalSessions * focusMinutes;

    final String periodLabel;
    if (period == 0) {
      periodLabel = DateFormat('EEEE, MMMM d').format(now);
    } else if (period == 1) {
      final start = now.subtract(const Duration(days: 6));
      periodLabel =
          '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(now)}';
    } else {
      periodLabel = DateFormat('MMMM yyyy').format(now);
    }

    DayStat? bestDay;
    if (period > 0 && totalSessions > 0) {
      bestDay =
          stats.reduce((a, b) => a.sessions >= b.sessions ? a : b);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin, 0, AppSpacing.margin, 120),
      children: [
        Text(periodLabel,
            style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),

        // ── Summary cards ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Sessions',
                value: '$totalSessions',
                icon: Icons.timer_rounded,
                color: cs.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'Focus Time',
                value: _fmtDuration(totalMinutes),
                icon: Icons.access_time_rounded,
                color: cs.tertiary,
                isDark: isDark,
              ),
            ),
          ],
        ),

        // ── Day-specific ───────────────────────────────────────────────
        if (period == 0) ...[
          const SizedBox(height: AppSpacing.lg),
          _StreakCard(isDark: isDark),
          if (totalSessions > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            _SessionDots(sessions: totalSessions, color: cs.primary),
          ],
        ],

        // ── Week / Month ───────────────────────────────────────────────
        if (period > 0) ...[
          const SizedBox(height: AppSpacing.xl),
          _BarChart(
            stats: stats,
            color: cs.primary,
            trackColor: cs.primary.withValues(alpha: 0.12),
            period: period,
          ),
          if (bestDay != null && bestDay.sessions > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 16, color: cs.tertiary),
                const SizedBox(width: 6),
                Text(
                  'Best: ${DateFormat('EEEE').format(bestDay.date)} · ${bestDay.sessions} session${bestDay.sessions == 1 ? '' : 's'}',
                  style: AppTextStyles.labelMd(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
          if (period == 2 && totalSessions > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Daily avg: ${(totalSessions / 30).toStringAsFixed(1)} sessions',
                  style: AppTextStyles.labelMd(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],

        const SizedBox(height: AppSpacing.xl),
        _AiInsightsCard(isDark: isDark),
      ],
    );
  }

  String _fmtDuration(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.lightSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.softShadowDark
                : AppColors.softShadowLight,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTextStyles.h1(color: cs.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Streak card ────────────────────────────────────────────────────────────────

class _StreakCard extends ConsumerWidget {
  final bool isDark;
  const _StreakCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return ref.watch(streakProvider).when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (streak) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.lightSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak == 0 ? 'No streak yet' : '$streak day streak',
                      style: AppTextStyles.labelMd(color: cs.onSurface),
                    ),
                    Text(
                      streak == 0
                          ? 'Complete a session to start'
                          : streak == 1
                              ? 'Great start!'
                              : 'Keep it going!',
                      style:
                          AppTextStyles.labelSm(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}

// ── Session dots (day view) ────────────────────────────────────────────────────

class _SessionDots extends StatelessWidget {
  final int sessions;
  final Color color;
  const _SessionDots({required this.sessions, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(sessions.clamp(0, 20), (_) {
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Icon(Icons.timer_rounded,
              size: 14, color: Colors.white),
        );
      }),
    );
  }
}

// ── Bar chart ──────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<DayStat> stats;
  final Color color;
  final Color trackColor;
  final int period;

  const _BarChart({
    required this.stats,
    required this.color,
    required this.trackColor,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxSessions =
        stats.fold(0, (m, s) => s.sessions > m ? s.sessions : m);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SESSIONS PER DAY',
            style: AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.asMap().entries.map((e) {
              final s = e.value;
              final fraction =
                  maxSessions > 0 ? s.sessions / maxSessions : 0.0;
              final isToday = s.date.isAtSameMomentAs(today);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (s.sessions > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '${s.sessions}',
                            style: TextStyle(
                              fontSize: period == 2 ? 7.5 : 9,
                              color: isToday ? color : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: math.max(4.0, 100.0 * fraction),
                        decoration: BoxDecoration(
                          color: isToday
                              ? color
                              : (s.sessions > 0
                                  ? color.withValues(alpha: 0.6)
                                  : trackColor),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _label(s.date),
                        style: TextStyle(
                          fontSize: period == 2 ? 7.5 : 9,
                          color: isToday ? color : cs.onSurfaceVariant,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _label(DateTime date) {
    if (period == 1) {
      const abbr = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      return abbr[date.weekday - 1];
    } else {
      if (date.day == 1 || date.day % 5 == 0) return '${date.day}';
      return '';
    }
  }
}

// ── AI Insights card ───────────────────────────────────────────────────────────

class _AiInsightsCard extends StatelessWidget {
  final bool isDark;
  const _AiInsightsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: isDark ? 0.18 : 0.08),
            cs.tertiary.withValues(alpha: isDark ? 0.12 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: cs.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: cs.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('AI Insights',
                  style: AppTextStyles.labelMd(color: cs.onSurface)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Get personalized analysis of your study patterns, peak focus hours, and weekly productivity trends — powered by AI.',
            style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
