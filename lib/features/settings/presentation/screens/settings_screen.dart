import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studiq/app/router/app_router.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/app/app.dart';
import 'package:studiq/core/constants/app_constants.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/data/services/notification_service.dart';
import 'package:studiq/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.margin, vertical: AppSpacing.md),
                child: Text('Settings',
                    style: AppTextStyles.h2(color: cs.onSurface)),
              ),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.md),

                // Profile card
                _ProfileCard(),
                const SizedBox(height: AppSpacing.xl),

                // Appearance
                _SectionLabel('Appearance'),
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (v) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(v ? ThemeMode.dark : ThemeMode.light),
                    activeColor: cs.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Notifications
                _SectionLabel('Notifications'),
                _SettingsTile(
                  icon: notificationsEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  label: 'Enable Notifications',
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (enabled) async {
                      await ref
                          .read(notificationsEnabledProvider.notifier)
                          .setEnabled(enabled);
                      if (!enabled) {
                        await NotificationService.instance.cancelAll();
                      } else {
                        await NotificationService.instance.requestPermissions();
                        // Re-schedule all future reminders
                        final repo = ref.read(plannerRepositoryProvider);
                        final items = await repo.getAll();
                        final now = DateTime.now();
                        for (final item in items) {
                          final r = item.reminder;
                          if (r == null || !r.enabled) continue;
                          final target = item.startDateTime ?? item.dueDate;
                          if (target == null) continue;
                          final fireAt = target.subtract(
                              Duration(minutes: r.minutesBefore));
                          if (fireAt.isAfter(now)) {
                            await NotificationService.instance
                                .scheduleItemReminder(item);
                          }
                        }
                      }
                    },
                    activeColor: cs.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Analytics
                _SectionLabel('Analytics'),
                _SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Focus Report',
                  onTap: () => context.push(AppRoutes.focusStats),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Data
                _SectionLabel('Data'),
                _SettingsTile(
                  icon: Icons.delete_sweep_rounded,
                  label: 'Deleted Plans',
                  onTap: () => context.push(AppRoutes.deletedPlans),
                ),
                _SettingsTile(
                  icon: Icons.folder_off_rounded,
                  label: 'Deleted Projects',
                  onTap: () => context.push(AppRoutes.deletedProjects),
                ),
                // About
                _SectionLabel('About'),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  value: '1.0.0',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Account
                _SectionLabel('Account'),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  dangerous: true,
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  static const _roles = AppConstants.academicRoles;
  bool _uploading = false;

  // ── Photo picker ───────────────────────────────────────────────────────────

  void _showPhotoOptions() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin, AppSpacing.lg, AppSpacing.margin, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Profile Photo', style: AppTextStyles.h3(color: cs.onSurface)),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: cs.primary),
              title: Text('Take Photo',
                  style: AppTextStyles.bodyMd(color: cs.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: cs.primary),
              title: Text('Choose from Gallery',
                  style: AppTextStyles.bodyMd(color: cs.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (ref.read(userProfileProvider).photoUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text('Remove Photo',
                    style: AppTextStyles.bodyMd(color: cs.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      await ref.read(userProfileProvider.notifier).update(photoUrl: base64Str);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save photo. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    await ref.read(userProfileProvider.notifier).update(photoUrl: null);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final initial =
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          // Tappable avatar
          GestureDetector(
            onTap: _uploading ? null : _showPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: _uploading
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : ClipOval(
                          child: profile.photoUrl != null
                              ? Image.memory(
                                  base64Decode(profile.photoUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(initial,
                                        style: AppTextStyles.h3(
                                            color: cs.onPrimary)),
                                  ),
                                )
                              : Center(
                                  child: Text(initial,
                                      style: AppTextStyles.h2(
                                          color: cs.onPrimary)),
                                ),
                        ),
                ),
                // Camera badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 12, color: cs.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: AppTextStyles.h3(color: cs.onPrimary)),
                Text(profile.role,
                    style: AppTextStyles.bodyMd(
                        color: cs.onPrimary.withValues(alpha: 0.8))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileSheet(context, profile),
            icon: Icon(Icons.edit_rounded, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }

  // ── Edit sheet ─────────────────────────────────────────────────────────────

  void _showEditProfileSheet(BuildContext context, UserProfile profile) {
    final nameCtrl = TextEditingController(text: profile.name);
    final cs = Theme.of(context).colorScheme;
    final initialRole =
        _roles.contains(profile.role) ? profile.role : _roles.first;
    String selectedRole = initialRole;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SingleChildScrollView(
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
              Text('Edit Account',
                  style: AppTextStyles.h3(color: cs.onSurface)),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedRole = v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      ref.read(userProfileProvider.notifier).update(
                            name: name,
                            role: selectedRole,
                          );
                    }
                    Navigator.of(ctx).pop();
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
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label.toUpperCase(),
          style: AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dangerous;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.dangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = dangerous ? cs.error : cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.lightSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 20, color: dangerous ? cs.error : cs.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.bodyMd(color: color)),
                ),
                if (value != null)
                  Text(value!,
                      style: AppTextStyles.labelMd(
                          color: cs.onSurfaceVariant)),
                if (trailing != null) trailing!,
                if (onTap != null && trailing == null)
                  Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
