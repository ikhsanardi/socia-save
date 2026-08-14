import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/opengraph_service.dart';
import '../providers/category_provider.dart';
import '../providers/shared_content_provider.dart';
import '../widgets/socmed_icon.dart';

class ShareReceiverBottomSheet extends ConsumerStatefulWidget {
  final String sharedText;

  const ShareReceiverBottomSheet({
    super.key,
    required this.sharedText,
  });

  static Future<void> show(BuildContext context, String sharedText) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareReceiverBottomSheet(sharedText: sharedText),
    );
  }

  @override
  ConsumerState<ShareReceiverBottomSheet> createState() =>
      _ShareReceiverBottomSheetState();
}

class _ShareReceiverBottomSheetState
    extends ConsumerState<ShareReceiverBottomSheet> {
  final _titleController = TextEditingController();
  bool _isLoading = true;
  OpenGraphData? _ogData;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    final ogData = await OpenGraphService.fetchMetadata(widget.sharedText);
    if (mounted) {
      setState(() {
        _ogData = ogData;
        _titleController.text = ogData.title;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
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

          // Title Header
          Row(
            children: [
              const Text(
                'Save Shared Content',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_ogData != null) SocmedIcon(source: _ogData!.socmedSource),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Fetching metadata from link...'),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Thumbnail preview if extracted
            if (_ogData?.thumbnailUrl != null &&
                _ogData!.thumbnailUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _ogData!.thumbnailUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Editable Title Field
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

            // Master Category Selector Dropdown
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text(
                    'No categories available. Create one in Master Categories.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                _selectedCategoryId ??= categories.first.id;

                return DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Select Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error loading categories: $e'),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: (_selectedCategoryId == null)
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        if (title.isNotEmpty && _ogData != null) {
                          await ref
                              .read(sharedContentNotifierProvider.notifier)
                              .addSharedContent(
                                rawUrl: _ogData!.rawUrl,
                                title: title,
                                thumbnailUrl: _ogData!.thumbnailUrl,
                                socmedSource: _ogData!.socmedSource,
                                categoryId: _selectedCategoryId!,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Content saved successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Save to Collection'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
