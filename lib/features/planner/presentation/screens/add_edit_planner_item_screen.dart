import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/app.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/data/services/notification_service.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';

class AddEditPlannerItemScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const AddEditPlannerItemScreen({super.key, this.itemId});

  @override
  ConsumerState<AddEditPlannerItemScreen> createState() =>
      _AddEditPlannerItemScreenState();
}

class _AddEditPlannerItemScreenState
    extends ConsumerState<AddEditPlannerItemScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  PlannerItemType _type = PlannerItemType.task;
  PlannerItemPriority _priority = PlannerItemPriority.medium;
  PlannerItemStatus _status = PlannerItemStatus.todo;
  DateTime? _dueDate;
  DateTime? _startDateTime;
  int _reminderMinutes = -1; // -1 = no reminder
  bool _saving = false;
  bool _loaded = false;

  static const _reminderOptions = [
    (-1, 'No reminder'),
    (0, 'At event time'),
    (5, '5 min before'),
    (15, '15 min before'),
    (30, '30 min before'),
    (60, '1 hour before'),
    (120, '2 hours before'),
    (1440, '1 day before'),
  ];

  bool get isEditing => widget.itemId != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    if (_loaded || !isEditing) return;
    final item =
        await ref.read(plannerRepositoryProvider).getById(widget.itemId!);
    if (item != null && mounted) {
      setState(() {
        _titleCtrl.text = item.title;
        _descCtrl.text = item.description ?? '';
        _type = item.type;
        _priority = item.priority;
        _status = item.status;
        _dueDate = item.dueDate;
        _startDateTime = item.startDateTime;
        _reminderMinutes =
            (item.reminder != null && item.reminder!.enabled)
                ? item.reminder!.minutesBefore
                : -1;
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();

    final reminder = _reminderMinutes >= 0
        ? ReminderConfig(minutesBefore: _reminderMinutes, enabled: true)
        : null;

    try {
      PlannerItem savedItem;
      if (isEditing) {
        final existing =
            await ref.read(plannerRepositoryProvider).getById(widget.itemId!);
        if (existing != null) {
          final updated = existing.copyWith(
            title: title,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            type: _type,
            priority: _priority,
            status: _status,
            dueDate: _dueDate,
            startDateTime: _startDateTime,
            reminder: reminder,
            updatedAt: now,
          );
          savedItem = await ref.read(plannerRepositoryProvider).update(updated);
        } else {
          if (mounted) setState(() => _saving = false);
          return;
        }
      } else {
        final item = PlannerItem(
          id: const Uuid().v4(),
          title: title,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          type: _type,
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          startDateTime: _startDateTime,
          reminder: reminder,
          createdAt: now,
          updatedAt: now,
        );
        savedItem = await ref.read(plannerRepositoryProvider).create(item);
      }

      // Schedule or cancel notification
      final notifEnabled = ref.read(notificationsEnabledProvider);
      if (reminder != null && notifEnabled) {
        await NotificationService.instance.scheduleItemReminder(savedItem);
      } else {
        await NotificationService.instance.cancelItemReminder(savedItem.id);
      }

      ref.invalidate(plannerItemsProvider);
      ref.invalidate(todayItemsProvider);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/planner');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickStartDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime ?? DateTime.now()),
    );
    if (pickedTime != null) {
      setState(() {
        _startDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEditing && !_loaded) {
      _loadItem();
    }

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('d MMM yyyy');
    final dtFormat = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/planner');
            }
          },
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          isEditing ? 'Edit Item' : 'New Item',
          style: AppTextStyles.h3(color: cs.onSurface),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save', style: AppTextStyles.labelMd(color: cs.primary)),
            ),
        ],
      ),
      body: (isEditing && !_loaded)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    autofocus: !isEditing,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Study for exam',
                    ),
                    style: AppTextStyles.bodyMd(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Add details...',
                    ),
                    style: AppTextStyles.bodyMd(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Type',
                      style:
                          AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: PlannerItemType.values.map((t) {
                      final selected = _type == t;
                      return ChoiceChip(
                        label: Text(t.name),
                        selected: selected,
                        onSelected: (_) => setState(() => _type = t),
                        labelStyle: TextStyle(
                            color: selected
                                ? cs.onPrimary
                                : cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Priority',
                      style:
                          AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: PlannerItemPriority.values.map((p) {
                      final selected = _priority == p;
                      return ChoiceChip(
                        label: Text(p.name),
                        selected: selected,
                        onSelected: (_) => setState(() => _priority = p),
                        labelStyle: TextStyle(
                            color: selected
                                ? cs.onPrimary
                                : cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Status',
                      style:
                          AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: PlannerItemStatus.values.map((s) {
                      final selected = _status == s;
                      return ChoiceChip(
                        label: Text(s.name),
                        selected: selected,
                        onSelected: (_) => setState(() => _status = s),
                        labelStyle: TextStyle(
                            color: selected
                                ? cs.onPrimary
                                : cs.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Start Date & Time',
                      style:
                          AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  _DatePickerTile(
                    isDark: isDark,
                    label: 'Start (optional)',
                    value: _startDateTime != null
                        ? dtFormat.format(_startDateTime!)
                        : null,
                    onTap: _pickStartDateTime,
                    onClear: () => setState(() => _startDateTime = null),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Due Date',
                      style:
                          AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  _DatePickerTile(
                    isDark: isDark,
                    label: 'Due date (optional)',
                    value:
                        _dueDate != null ? dateFormat.format(_dueDate!) : null,
                    onTap: _pickDueDate,
                    onClear: () => setState(() => _dueDate = null),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text('Reminder',
                      style: AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.sm),
                  _ReminderTile(
                    isDark: isDark,
                    selectedMinutes: _reminderMinutes,
                    options: _reminderOptions,
                    onChanged: (v) => setState(() => _reminderMinutes = v),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(isEditing ? 'Update' : 'Create'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final bool isDark;
  final int selectedMinutes;
  final List<(int, String)> options;
  final ValueChanged<int> onChanged;

  const _ReminderTile({
    required this.isDark,
    required this.selectedMinutes,
    required this.options,
    required this.onChanged,
  });

  String get _label =>
      options.firstWhere((o) => o.$1 == selectedMinutes,
          orElse: () => options.first).$2;

  void _showSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            ...options.map((o) => RadioListTile<int>(
                  title: Text(o.$2,
                      style: AppTextStyles.bodyMd(color: cs.onSurface)),
                  value: o.$1,
                  groupValue: selectedMinutes,
                  activeColor: cs.primary,
                  onChanged: (v) {
                    if (v != null) {
                      onChanged(v);
                      Navigator.pop(ctx);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasReminder = selectedMinutes >= 0;
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.lightSurfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: hasReminder
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasReminder
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 18,
              color: hasReminder ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(_label,
                style: AppTextStyles.bodyMd(
                    color:
                        hasReminder ? cs.onSurface : cs.onSurfaceVariant)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final bool isDark;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DatePickerTile({
    required this.isDark,
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.lightSurfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: value != null ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded,
                size: 18,
                color: value != null ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant)),
            const Spacer(),
            if (value != null) ...[
              Text(value!, style: AppTextStyles.labelMd(color: cs.onSurface)),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 16, color: cs.onSurfaceVariant),
              ),
            ] else
              Text('Select', style: AppTextStyles.labelMd(color: cs.outline)),
          ],
        ),
      ),
    );
  }
}
