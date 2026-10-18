import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/content_selection_provider.dart';
import '../providers/shared_content_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/user_avatar.dart';
import 'account_bottom_sheet.dart';
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

  void _showBatchDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    List<int> idsToDelete,
  ) {
    final count = idsToDelete.length;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Items'),
        content: Text(
          'Are you sure you want to delete $count saved ${count == 1 ? 'item' : 'items'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(sharedContentNotifierProvider.notifier)
                    .deleteMultiple(idsToDelete);
                ref.read(contentSelectionProvider.notifier).clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$count ${count == 1 ? 'item' : 'items'} deleted',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete items: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
    final selectedContentIds = ref.watch(contentSelectionProvider);
    final isSelectionMode = selectedContentIds.isNotEmpty;

    // Clear selection if category filter or search query changes
    ref.listen<int?>(selectedCategoryIdProvider, (prev, next) {
      if (prev != next) {
        ref.read(contentSelectionProvider.notifier).clear();
      }
    });
    ref.listen<String>(searchQueryProvider, (prev, next) {
      if (prev != next) {
        ref.read(contentSelectionProvider.notifier).clear();
      }
    });

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
      canPop: !isSelectionMode && !_searchFocusNode.hasFocus,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (isSelectionMode) {
            ref.read(contentSelectionProvider.notifier).clear();
          } else if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
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
          appBar: isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cancel selection',
                    onPressed: () {
                      ref.read(contentSelectionProvider.notifier).clear();
                    },
                  ),
                  title: Text(
                    '${selectedContentIds.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.checklist_rounded),
                      tooltip: contentAsync.valueOrNull != null &&
                              contentAsync.valueOrNull!.isNotEmpty &&
                              contentAsync.valueOrNull!.every(
                                (item) =>
                                    selectedContentIds.contains(item.id),
                              )
                          ? 'Deselect All'
                          : 'Select All',
                      onPressed: () {
                        final visibleItems = contentAsync.valueOrNull ?? [];
                        final visibleIds =
                            visibleItems.map((e) => e.id).toList();
                        ref
                            .read(contentSelectionProvider.notifier)
                            .selectAll(visibleIds);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      tooltip: 'Delete selected',
                      onPressed: () => _showBatchDeleteDialog(
                        context,
                        ref,
                        selectedContentIds.toList(),
                      ),
                    ),
                  ],
                )
              : AppBar(
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
                  return Badge(
                    label: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    isLabelVisible:
                        count > 0 && syncState.status != SyncStatus.syncing,
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                    textColor:
                        Theme.of(context).colorScheme.onTertiaryContainer,
                    offset: const Offset(-4, 4),
                    child: IconButton(
                      icon: syncState.status == SyncStatus.syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_sync_rounded),
                      tooltip: count > 0
                          ? 'Sync with Cloud ($count unsynced)'
                          : 'Sync with Cloud',
                      onPressed: syncState.status == SyncStatus.syncing
                          ? null
                          : () async {
                              final authUser =
                                  ref.read(authStateProvider).valueOrNull;
                              final isAnonymous =
                                  authUser == null || authUser.isAnonymous;

                              if (isAnonymous) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      count > 0
                                          ? 'You have $count unsynced bookmark${count > 1 ? 's' : ''}. Sign in with Google to sync them to the cloud.'
                                          : 'Sign in with Google to sync bookmarks across devices.',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Sign In',
                                      onPressed: () =>
                                          AccountBottomSheet.show(context),
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                return;
                              }

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
                  );
                },
                loading: () => const IconButton(
                  icon: Icon(Icons.cloud_sync_rounded),
                  onPressed: null,
                ),
                error: (_, _) => const IconButton(
                  icon: Icon(Icons.cloud_sync_rounded),
                  onPressed: null,
                ),
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

              // Account & Cloud Backup Profile Button
              Consumer(
                builder: (context, ref, child) {
                  final authUser = ref.watch(authStateProvider).valueOrNull;
                  final isAnonymous = authUser == null || authUser.isAnonymous;
                  return IconButton(
                    icon: UserAvatar.fromUser(
                      user: authUser,
                      radius: 13,
                    ),
                    tooltip: isAnonymous
                        ? 'Account & Cloud Backup'
                        : 'Account: ${UserAvatar.extractDisplayName(authUser) ?? UserAvatar.extractEmail(authUser) ?? 'User'}',
                    onPressed: () => AccountBottomSheet.show(context),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
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
                      borderRadius: BorderRadius.circular(14),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                                'Share a link from any social media, or tap + to add manually.',
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
                            'Failed to load bookmarks',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                ref.refresh(sharedContentNotifierProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: isSelectionMode
              ? null
              : FloatingActionButton.extended(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: _showManualAddDialog,
                  icon: const Icon(Icons.add_link_rounded),
                  label: const Text('Add Link'),
                ),
        ),
      ),
    );
  }
}
