import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';

class CategoryFilterModal extends ConsumerWidget {
  const CategoryFilterModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategoryFilterModal(),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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

          // Modal Header Row
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedCategoryId != null)
                TextButton(
                  onPressed: () {
                    ref.read(selectedCategoryIdProvider.notifier).state = null;
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Filter'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Categories List
          categoriesAsync.when(
            data: (categories) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // All Categories Option
                    _buildCategoryOption(
                      context: context,
                      title: 'All Categories',
                      isSelected: selectedCategoryId == null,
                      leading: Icon(
                        Icons.all_inclusive_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      onTap: () {
                        ref.read(selectedCategoryIdProvider.notifier).state =
                            null;
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),

                    // Specific Category Options
                    ...categories.map((category) {
                      final isSelected = selectedCategoryId == category.id;
                      final catColor = _parseColor(category.colorHex);

                      return _buildCategoryOption(
                        context: context,
                        title: category.name,
                        isSelected: isSelected,
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () {
                          ref.read(selectedCategoryIdProvider.notifier).state =
                              category.id;
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading categories: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
