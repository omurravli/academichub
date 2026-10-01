import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/presentation/providers/project_providers.dart';

class AddEditProjectScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const AddEditProjectScreen({super.key, this.projectId});

  @override
  ConsumerState<AddEditProjectScreen> createState() =>
      _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends ConsumerState<AddEditProjectScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ProjectStatus _status = ProjectStatus.planning;
  DateTime? _dueDate;
  Color _selectedColor = AppColors.lightPrimary;
  bool _saving = false;

  static const _colorOptions = [
    Color(0xFF0058BE),
    Color(0xFF006C49),
    Color(0xFF6B38D4),
    Color(0xFFBA1A1A),
    Color(0xFFE67E22),
    Color(0xFF1ABC9C),
  ];

  bool get isEditing => widget.projectId != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title')),
      );
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final project = Project(
      id: const Uuid().v4(),
      title: title,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      color: _selectedColor,
      status: _status,
      dueDate: _dueDate,
      progress: 0.0,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(projectRepositoryProvider).create(project);
      ref.invalidate(projectsProvider);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/projects');
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/projects');
            }
          },
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          isEditing ? 'Edit Project' : 'New Project',
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
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: AppTextStyles.labelMd(color: cs.primary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Project Title *',
                hintText: 'e.g. Senior Thesis',
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
                hintText: 'What is this project about?',
              ),
              style: AppTextStyles.bodyMd(),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Color',
                style: AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: _colorOptions.map((c) {
                final selected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 40 : 32,
                    height: selected ? 40 : 32,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: cs.onSurface, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 12)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Status',
                style: AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ProjectStatus.values.map((s) {
                final selected = _status == s;
                return ChoiceChip(
                  label: Text(s.name),
                  selected: selected,
                  onSelected: (_) => setState(() => _status = s),
                  labelStyle: TextStyle(
                      color: selected ? cs.onPrimary : cs.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Due date picker
            Text('Due Date',
                style: AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.lightSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _dueDate != null
                        ? cs.primary.withOpacity(0.4)
                        : cs.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded,
                        size: 18,
                        color: _dueDate != null
                            ? cs.primary
                            : cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Due Date (optional)',
                        style:
                            AppTextStyles.bodyMd(color: cs.onSurfaceVariant)),
                    const Spacer(),
                    if (_dueDate != null) ...[
                      Text(
                        '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: AppTextStyles.labelMd(color: cs.onSurface),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                      ),
                    ] else
                      Text('Select',
                          style: AppTextStyles.labelMd(color: cs.outline)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(isEditing ? 'Update Project' : 'Create Project'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}