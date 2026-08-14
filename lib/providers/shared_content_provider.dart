import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_content.dart';
import 'category_provider.dart';
import 'database_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class SharedContentNotifier
    extends StateNotifier<AsyncValue<List<SharedContent>>> {
  final Ref ref;

  SharedContentNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadContent();
  }

  Future<void> loadContent() async {
    state = const AsyncValue.loading();
    try {
      final isarService = ref.read(isarServiceProvider);
      final userId = ref.read(userIdProvider);
      final selectedCategory = ref.watch(selectedCategoryIdProvider);
      final searchQuery = ref.watch(searchQueryProvider);

      final items = await isarService.getSharedContent(
        userId: userId,
        categoryId: selectedCategory,
        searchQuery: searchQuery,
      );
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSharedContent({
    required String rawUrl,
    required String title,
    String? thumbnailUrl,
    required String socmedSource,
    required int categoryId,
  }) async {
    try {
      final isarService = ref.read(isarServiceProvider);
      final userId = ref.read(userIdProvider);

      final newContent = SharedContent.create(
        userId: userId,
        rawUrl: rawUrl,
        title: title,
        thumbnailUrl: thumbnailUrl,
        socmedSource: socmedSource,
        categoryId: categoryId,
      );

      await isarService.addSharedContent(newContent);
      await loadContent();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContent(int id) async {
    try {
      final isarService = ref.read(isarServiceProvider);
      await isarService.deleteSharedContent(id);
      await loadContent();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateContent(SharedContent item) async {
    try {
      final isarService = ref.read(isarServiceProvider);
      await isarService.updateSharedContent(item);
      await loadContent();
    } catch (e) {
      rethrow;
    }
  }
}

final sharedContentNotifierProvider = StateNotifierProvider<
    SharedContentNotifier, AsyncValue<List<SharedContent>>>((ref) {
  // Watch filter parameters to auto-reload list
  ref.watch(selectedCategoryIdProvider);
  ref.watch(searchQueryProvider);
  return SharedContentNotifier(ref);
});

final unsyncedCountProvider = FutureProvider<int>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  final userId = ref.watch(userIdProvider);
  ref.watch(sharedContentNotifierProvider);
  return isarService.getUnsyncedCount(userId);
});
