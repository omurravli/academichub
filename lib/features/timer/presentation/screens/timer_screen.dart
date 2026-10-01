import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/features/timer/presentation/providers/pomodoro_provider.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (lifecycle == AppLifecycleState.resumed &&
        _backgroundedAt != null) {
      final elapsed =
          DateTime.now().difference(_backgroundedAt!).inSeconds;
      _backgroundedAt = null;
      ref.read(pomodoroProvider.notifier).adjustForElapsed(elapsed);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _modeColor(TimerMode mode, ColorScheme cs) => switch (mode) {
        TimerMode.focus => cs.primary,
        TimerMode.shortBreak => cs.tertiary,
        TimerMode.longBreak => cs.secondary,
      };

  String _modeLabel(TimerMode mode) => switch (mode) {
        TimerMode.focus => 'Focus',
        TimerMode.shortBreak => 'Short Break',
        TimerMode.longBreak => 'Long Break',
      };

  // ── Settings sheet ─────────────────────────────────────────────────────────

  void _showSettings(BuildContext context, PomodoroState s) {
    final cs = Theme.of(context).colorScheme;
    int focus = s.focusMinutes;
    int shortBreak = s.shortBreakMinutes;
    int longBreak = s.longBreakMinutes;
    int untilLong = s.pomodorosUntilLong;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.lg,
            AppSpacing.margin,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Timer Settings',
                  style: AppTextStyles.h3(color: cs.onSurface)),
              const SizedBox(height: AppSpacing.lg),
              _SliderRow(
                label: 'Focus',
                value: focus,
                min: 5,
                max: 60,
                unit: 'min',
                color: cs.primary,
                onChanged: (v) => setSheet(() => focus = v),
              ),
              _SliderRow(
                label: 'Short Break',
                value: shortBreak,
                min: 1,
                max: 15,
                unit: 'min',
                color: cs.tertiary,
                onChanged: (v) => setSheet(() => shortBreak = v),
              ),
              _SliderRow(
                label: 'Long Break',
                value: longBreak,
                min: 5,
                max: 30,
                unit: 'min',
                color: cs.secondary,
                onChanged: (v) => setSheet(() => longBreak = v),
              ),
              _SliderRow(
                label: 'Sessions until long break',
                value: untilLong,
                min: 2,
                max: 8,
                unit: '',
                color: cs.onSurfaceVariant,
                onChanged: (v) => setSheet(() => untilLong = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(pomodoroProvider.notifier).updateSettings(
                          focusMinutes: focus,
                          shortBreakMinutes: shortBreak,
                          longBreakMinutes: longBreak,
                          pomodorosUntilLong: untilLong,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modeColor = _modeColor(s.mode, cs);
    final isRunning = s.status == TimerStatus.running;
    final isIdle = s.status == TimerStatus.idle;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.margin, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text('Focus Timer',
                      style: AppTextStyles.h2(color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showSettings(context, s),
                    icon: Icon(Icons.tune_rounded,
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // ── Mode selector ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.lightSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Row(
                  children: TimerMode.values.map((mode) {
                    final selected = s.mode == mode;
                    final color = _modeColor(mode, cs);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => notifier.switchMode(mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(
                            _modeLabel(mode),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelSm(
                              color: selected ? color : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Timer ring ────────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: s.progress,
                        color: modeColor,
                        trackColor: modeColor.withValues(alpha: 0.12),
                        strokeWidth: 14,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.timeString,
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w200,
                                color: cs.onSurface,
                                letterSpacing: 2,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.modeLabel,
                              style: AppTextStyles.labelSm(
                                  color: modeColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Pomodoro dots ───────────────────────────────────────────
                  _PomodoroDotsRow(
                    completed: s.pomodorosCompleted % s.pomodorosUntilLong,
                    total: s.pomodorosUntilLong,
                    color: cs.primary,
                    trackColor: cs.primary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${s.pomodorosCompleted} session${s.pomodorosCompleted == 1 ? '' : 's'} completed',
                    style: AppTextStyles.labelSm(color: cs.onSurfaceVariant),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Start / Pause ───────────────────────────────────────────
                  GestureDetector(
                    onTap: isRunning ? notifier.pause : notifier.start,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 180,
                      height: 56,
                      decoration: BoxDecoration(
                        color: modeColor,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: modeColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isRunning
                                  ? 'PAUSE'
                                  : (isIdle ? 'START' : 'RESUME'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Reset ───────────────────────────────────────────────────
                  TextButton.icon(
                    onPressed: isIdle ? null : notifier.reset,
                    icon: Icon(Icons.refresh_rounded,
                        size: 16,
                        color: isIdle
                            ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                            : cs.onSurfaceVariant),
                    label: Text(
                      'Reset',
                      style: AppTextStyles.labelMd(
                        color: isIdle
                            ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Circular ring painter ──────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Pomodoro dots ──────────────────────────────────────────────────────────────

class _PomodoroDotsRow extends StatelessWidget {
  final int completed;
  final int total;
  final Color color;
  final Color trackColor;

  const _PomodoroDotsRow({
    required this.completed,
    required this.total,
    required this.color,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final done = i < completed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: done ? 10 : 8,
            height: done ? 10 : 8,
            decoration: BoxDecoration(
              color: done ? color : trackColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

// ── Settings slider row ────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final Color color;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: AppTextStyles.bodyMd(color: cs.onSurface)),
              const Spacer(),
              Text(
                unit.isEmpty ? '$value' : '$value $unit',
                style: AppTextStyles.labelMd(color: color),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              overlayColor: color.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
