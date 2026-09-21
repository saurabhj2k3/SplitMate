import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/splitmate_button.dart';
import '../../core/widgets/splitmate_text_field.dart';
import '../../providers/group_provider.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a group name.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final group = await ref.read(groupListProvider.notifier).createGroup(
            name: name,
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
          );

      if (mounted) {
        Navigator.of(context).pop(group);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create New Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add expenses and split balances with roommates, friends, or trip members.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: AppColors.negative),
                ),
                const SizedBox(height: 12),
              ],

              SplitMateTextField(
                label: 'Group name',
                hint: 'e.g. Goa Trip, Flatmates, Office Lunch',
                controller: _nameController,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              SplitMateTextField(
                label: 'Description (Optional)',
                hint: 'What is this group for?',
                controller: _descController,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SplitMateButton(
                    label: 'Cancel',
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  SplitMateButton(
                    label: 'Create Group',
                    isLoading: _isLoading,
                    onPressed: _handleCreate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
