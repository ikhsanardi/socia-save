import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const Color _maroonColor = Color(0xFF881337);

  final List<String> _colors = [
    '6366F1', // Indigo
    'EF4444', // Red
    'F97316', // Orange
    'F59E0B', // Amber
    'EAB308', // Yellow
    '84CC16', // Lime
    '10B981', // Emerald
    '14B8A6', // Teal
    '06B6D4', // Cyan
    '0EA5E9', // Sky
    '3B82F6', // Blue
    '8B5CF6', // Purple
    'A855F7', // Violet
    'D946EF', // Fuchsia
    'EC4899', // Pink
    'F43F5E', // Rose
    '78716C', // Stone
    '64748B', // Slate
  ];

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }

  Future<String?> _showColorPickerDialog(
    BuildContext context,
    String initialHex,
  ) async {
    Color currentColor = _parseColor(initialHex);
    HSVColor currentHsv = HSVColor.fromColor(currentColor);
    final hexTextController =
        TextEditingController(text: _colorToHex(currentColor));

    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setPickerState) {
          final hexCode = _colorToHex(currentColor);

          void updateFromHsv(HSVColor newHsv) {
            setPickerState(() {
              currentHsv = newHsv;
              currentColor = newHsv.toColor();
              hexTextController.text = _colorToHex(currentColor);
            });
          }

          void updateFromColor(Color newColor) {
            setPickerState(() {
              currentColor = newColor;
              currentHsv = HSVColor.fromColor(newColor);
              hexTextController.text = _colorToHex(newColor);
            });
          }

          const paletteSwatches = [
            'F43F5E',
            'E11D48',
            'EA580C',
            'D97706',
            'EAB308',
            '84CC16',
            '10B981',
            '06B6D4',
            '0EA5E9',
            '3B82F6',
            '6366F1',
            '8B5CF6',
            'A855F7',
            'D946EF',
            'EC4899',
            '64748B',
          ];

          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            title: const Row(
              children: [
                Icon(Icons.palette_outlined, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom Color Picker',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color Preview & Hex Display Box
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: currentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentColor.withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 0.8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: hexTextController,
                            decoration: InputDecoration(
                              prefixText: '#',
                              labelText: 'Hex Code',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (val) {
                              final clean = val.replaceAll('#', '').trim();
                              if (clean.length == 6) {
                                try {
                                  final parsed = _parseColor(clean);
                                  setPickerState(() {
                                    currentColor = parsed;
                                    currentHsv = HSVColor.fromColor(parsed);
                                  });
                                } catch (_) {}
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Hue Slider
                    Text(
                      'Hue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 12,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9,
                          elevation: 2,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF0000),
                                  Color(0xFFFFFF00),
                                  Color(0xFF00FF00),
                                  Color(0xFF00FFFF),
                                  Color(0xFF0000FF),
                                  Color(0xFFFF00FF),
                                  Color(0xFFFF0000),
                                ],
                              ),
                            ),
                          ),
                          Slider(
                            value: currentHsv.hue,
                            min: 0.0,
                            max: 360.0,
                            onChanged: (val) {
                              updateFromHsv(currentHsv.withHue(val));
                            },
                          ),
                        ],
                      ),
                    ),

                    // Saturation Slider
                    const SizedBox(height: 6),
                    Text(
                      'Saturation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 1,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: currentHsv.saturation,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          updateFromHsv(currentHsv.withSaturation(val));
                        },
                      ),
                    ),

                    // Brightness Slider
                    Text(
                      'Brightness',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          elevation: 1,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: currentHsv.value,
                        min: 0.15,
                        max: 1.0,
                        onChanged: (val) {
                          updateFromHsv(currentHsv.withValue(val));
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Palette Presets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: paletteSwatches.map((hex) {
                        final c = _parseColor(hex);
                        final isCurrent = hexCode == hex;
                        return GestureDetector(
                          onTap: () => updateFromColor(c),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.onSurface,
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, hexCode),
                child: const Text('Select Color'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog() {
    final textController = TextEditingController();
    String selectedColor = _colors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              title: const Row(
                children: [
                  Icon(Icons.category_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add Master Category',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Category Name (e.g. Recipes, Tech)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Category Color',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ..._colors.map((colorHex) {
                          final isSelected = selectedColor == colorHex;
                          final color = _parseColor(colorHex);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setDialogState(() {
                                selectedColor = colorHex;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          width: 2.0,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.5)
                                          : Colors.black.withValues(alpha: 0.08),
                                      blurRadius: isSelected ? 5 : 2,
                                      spreadRadius: isSelected ? 0.8 : 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        // Custom color swatch if chosen color is outside default _colors
                        if (!_colors.contains(selectedColor))
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setDialogState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: _parseColor(selectedColor),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _parseColor(selectedColor)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 5,
                                      spreadRadius: 0.8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Custom Color Picker Button
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final pickedHex = await _showColorPickerDialog(
                              context,
                              selectedColor,
                            );
                            if (pickedHex != null && pickedHex.isNotEmpty) {
                              setDialogState(() {
                                selectedColor = pickedHex;
                              });
                            }
                          },
                          child: Tooltip(
                            message: 'Custom Color Picker',
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: !_colors.contains(selectedColor)
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                    width:
                                        !_colors.contains(selectedColor) ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.colorize_rounded,
                                  size: 13,
                                  color: !_colors.contains(selectedColor)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final name = textController.text.trim();
                  if (name.isNotEmpty) {
                    await ref
                        .read(categoryNotifierProvider.notifier)
                        .addCategory(name, selectedColor);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: _maroonColor,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Category',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _maroonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await ref
                  .read(categoryNotifierProvider.notifier)
                  .deleteCategory(category.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Category "${category.name}" deleted'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Categories Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create custom categories to organize and filter your saved links.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Category'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = _parseColor(category.colorHex);

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      // Compact color display with glow effect matching category selection
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 5,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _maroonColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: _maroonColor,
                            size: 16,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete Category',
                        onPressed: () => _showDeleteCategoryDialog(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
      ),
    );
  }
}
