import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'database_provider.dart';

final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final Ref ref;

  CategoryNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final isarService = ref.read(isarServiceProvider);
      final userId = ref.read(userIdProvider);
      
      // Only seed default categories for guest / local_user mode
      if (userId == 'local_user') {
        await isarService.seedDefaultCategoriesIfNeeded(userId);
      }

      final categories = await isarService.getAllCategories(userId);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCategory(String name, String colorHex) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      final isarService = ref.read(isarServiceProvider);
      final userId = ref.read(userIdProvider);
      final newCategory = Category.create(
        userId: userId,
        name: trimmed,
        colorHex: colorHex,
      );
      await isarService.addCategory(newCategory);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final isarService = ref.read(isarServiceProvider);
      await isarService.updateCategory(category);
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      final isarService = ref.read(isarServiceProvider);
      await isarService.deleteCategory(categoryId);
      if (ref.read(selectedCategoryIdProvider) == categoryId) {
        ref.read(selectedCategoryIdProvider.notifier).state = null;
      }
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>((ref) {
  // Watch userIdProvider so categories reload automatically when user switches
  ref.watch(userIdProvider);
  return CategoryNotifier(ref);
});
