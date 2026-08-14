import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/shared_content_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/content_card.dart';
import 'categories_screen.dart';
import 'category_filter_modal.dart';
import 'share_receiver_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription? _intentDataStreamSubscription;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    // For sharing text/url while app is running in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (value) {
            if (value.isNotEmpty && value.first.path.isNotEmpty) {
              _handleSharedUrl(value.first.path);
            }
          },
          onError: (err) {
            debugPrint("Sharing intent stream error: $err");
          },
        );

    // For sharing text/url when app is closed / launched from share
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        _handleSharedUrl(value.first.path);
      }
    });
  }

  void _handleSharedUrl(String text) {
    if (text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShareReceiverBottomSheet.show(context, text);
      });
    }
  }

  void _showManualAddDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Content Link'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Paste social media URL here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final url = textController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.pop(context);
                  ShareReceiverBottomSheet.show(context, url);
                }
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
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
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(sharedContentNotifierProvider);
    final unsyncedCountAsync = ref.watch(unsyncedCountProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    Category? selectedCategory;
    if (selectedCategoryId != null) {
      categoriesAsync.whenData((categories) {
        try {
          selectedCategory = categories.firstWhere(
            (c) => c.id == selectedCategoryId,
          );
        } catch (_) {}
      });
    }

    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Socia Save'),
            actions: [
              // Category Filter Modal Button (To the left of Sync button)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      selectedCategoryId != null
                          ? Icons.filter_list_alt
                          : Icons.filter_list_rounded,
                      color: selectedCategoryId != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: selectedCategory != null
                        ? 'Filter: ${selectedCategory!.name}'
                        : 'Filter by Category',
                    onPressed: () => CategoryFilterModal.show(context),
                  ),
                  if (selectedCategoryId != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),

              // Sync Button with Unsynced Badge
              unsyncedCountAsync.when(
                data: (count) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: syncState.status == SyncStatus.syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_sync_rounded),
                        tooltip: 'Sync with Cloud',
                        onPressed: syncState.status == SyncStatus.syncing
                            ? null
                            : () async {
                                await ref
                                    .read(syncNotifierProvider.notifier)
                                    .triggerSync();
                                final state = ref.read(syncNotifierProvider);
                                if (context.mounted && state.message != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(state.message!)),
                                  );
                                }
                              },
                      ),
                      if (count > 0 && syncState.status != SyncStatus.syncing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Master Categories Screen Navigation Button
              IconButton(
                icon: const Icon(Icons.category_outlined),
                tooltip: 'Master Categories',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search saved links or titles...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
              ),

              // Active Category Filter Indicator Chip
              if (selectedCategoryId != null && selectedCategory != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Row(
                    children: [
                      InputChip(
                        avatar: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _parseColor(selectedCategory!.colorHex),
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: Text(
                          selectedCategory!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          ref.read(selectedCategoryIdProvider.notifier).state =
                              null;
                        },
                        onPressed: () => CategoryFilterModal.show(context),
                      ),
                    ],
                  ),
                ),
              ],

              // Index Content List
              Expanded(
                child: contentAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_border_rounded,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No saved items found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Share a link from Instagram, Facebook, or Threads, or tap + to add manually.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(sharedContentNotifierProvider.notifier)
                            .loadContent();
                      },
                      child: ListView.builder(
                        itemCount: items.length,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemBuilder: (context, index) {
                          return ContentCard(item: items[index]);
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text('Error loading contents: $e')),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showManualAddDialog,
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Add Link'),
          ),
        ),
      ),
    );
  }
}
