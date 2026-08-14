import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_content.dart';
import '../providers/category_provider.dart';
import '../providers/shared_content_provider.dart';
import '../widgets/socmed_icon.dart';

class EditContentBottomSheet extends ConsumerStatefulWidget {
  final SharedContent item;

  const EditContentBottomSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, SharedContent item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditContentBottomSheet(item: item),
    );
  }

  @override
  ConsumerState<EditContentBottomSheet> createState() =>
      _EditContentBottomSheetState();
}

class _EditContentBottomSheetState
    extends ConsumerState<EditContentBottomSheet> {
  late final TextEditingController _titleController;
  late int _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _selectedCategoryId = widget.item.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  Future<void> _saveChanges() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedItem = widget.item
        ..title = newTitle
        ..categoryId = _selectedCategoryId;

      await ref
          .read(sharedContentNotifierProvider.notifier)
          .updateContent(updatedItem);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update content: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Title & Socmed Icon
          Row(
            children: [
              const Text(
                'Edit Saved Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SocmedIcon(source: widget.item.socmedSource),
            ],
          ),
          const SizedBox(height: 16),

          // Thumbnail preview if available
          if (widget.item.thumbnailUrl != null &&
              widget.item.thumbnailUrl!.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.item.thumbnailUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Content Title Input
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Content Title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title_rounded),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Category Selector Dropdown
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Text(
                  'No categories available. Create one in Master Categories.',
                  style: TextStyle(color: Colors.red),
                );
              }

              // Verify selected category exists, otherwise fallback to first
              final hasSelected =
                  categories.any((c) => c.id == _selectedCategoryId);
              if (!hasSelected && categories.isNotEmpty) {
                _selectedCategoryId = categories.first.id;
              }

              return DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: categories.map((cat) {
                  final color = _parseColor(cat.colorHex);
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  }
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error loading categories: $e'),
          ),

          const SizedBox(height: 20),

          // Action Buttons: Cancel and Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
