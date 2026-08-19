import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/category.dart';
import '../../models/shared_content.dart';

class IsarService {
  late Isar _isar;

  Isar get db => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [CategorySchema, SharedContentSchema],
      directory: dir.path,
      name: 'socmed_share_saver_db',
    );

    // Seed default categories for guest/initial user if needed
    await seedDefaultCategoriesIfNeeded('local_user');
  }

  Future<void> seedDefaultCategoriesIfNeeded(String userId) async {
    final count = await _isar.categorys
        .filter()
        .userIdEqualTo(userId)
        .isDeletedEqualTo(false)
        .count();

    if (count == 0) {
      final defaultCategories = [
        Category.create(userId: userId, name: 'General', colorHex: '6366F1'),
        Category.create(userId: userId, name: 'Recipes', colorHex: 'EF4444'),
        Category.create(userId: userId, name: 'Tech', colorHex: '3B82F6'),
        Category.create(userId: userId, name: 'Travel', colorHex: '10B981'),
        Category.create(userId: userId, name: 'Design', colorHex: '8B5CF6'),
      ];

      await _isar.writeTxn(() async {
        await _isar.categorys.putAll(defaultCategories);
      });
    }
  }

  // --- Category Operations ---
  Future<List<Category>> getAllCategories(String userId) async {
    return await _isar.categorys
        .filter()
        .userIdEqualTo(userId)
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  Future<List<Category>> getAllCategoriesForSync(String userId) async {
    return await _isar.categorys
        .filter()
        .userIdEqualTo(userId)
        .findAll();
  }

  Future<int> addCategory(Category category) async {
    final trimmedName = category.name.trim();
    category.name = trimmedName;
    category.syncedAt = null;

    // Check if category with same name already exists for this user
    final existing = await _isar.categorys
        .filter()
        .userIdEqualTo(category.userId)
        .isDeletedEqualTo(false)
        .nameEqualTo(trimmedName, caseSensitive: false)
        .findFirst();

    if (existing != null) {
      return existing.id;
    }

    final id = await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
    category.id = id;
    return id;
  }

  Future<void> updateCategory(Category category) async {
    category.name = category.name.trim();
    category.syncedAt = null;
    category.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> markCategorySynced(int categoryId, DateTime syncedAt) async {
    await _isar.writeTxn(() async {
      final item = await _isar.categorys.get(categoryId);
      if (item != null) {
        item.syncedAt = syncedAt;
        await _isar.categorys.put(item);
      }
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    final cat = await _isar.categorys.get(categoryId);
    if (cat == null) return;
    cat.isDeleted = true;
    cat.syncedAt = null; // Unsynced deletion
    cat.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.categorys.put(cat);
    });
  }

  Future<void> hardDeleteCategory(int categoryId) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.delete(categoryId);
    });
  }

  // --- SharedContent Operations ---
  Future<List<SharedContent>> getSharedContent({
    required String userId,
    int? categoryId,
    String? searchQuery,
  }) async {
    var query = _isar.sharedContents
        .filter()
        .userIdEqualTo(userId)
        .isDeletedEqualTo(false);

    if (categoryId != null && categoryId > 0) {
      query = query.categoryIdEqualTo(categoryId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = searchQuery.trim().toLowerCase();
      query = query.and().titleContains(term, caseSensitive: false);
    }

    return await query.sortByCreatedAtDesc().findAll();
  }

  Future<List<SharedContent>> getAllSharedContentForSync(String userId) async {
    return await _isar.sharedContents
        .filter()
        .userIdEqualTo(userId)
        .findAll();
  }

  Future<int> addSharedContent(SharedContent content) async {
    content.syncedAt = null;
    final id = await _isar.writeTxn(() async {
      return await _isar.sharedContents.put(content);
    });
    content.id = id;
    return id;
  }

  Future<void> updateSharedContent(
    SharedContent content, {
    bool resetSynced = true,
  }) async {
    content.updatedAt = DateTime.now();
    if (resetSynced) {
      content.syncedAt = null;
    }
    await _isar.writeTxn(() async {
      await _isar.sharedContents.put(content);
    });
  }

  Future<void> markContentSynced(int contentId, DateTime syncedAt) async {
    await _isar.writeTxn(() async {
      final item = await _isar.sharedContents.get(contentId);
      if (item != null) {
        item.syncedAt = syncedAt;
        await _isar.sharedContents.put(item);
      }
    });
  }

  Future<void> deleteSharedContent(int contentId) async {
    final item = await _isar.sharedContents.get(contentId);
    if (item == null) return;

    item.isDeleted = true;
    item.syncedAt = null; // Unsynced deletion
    item.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.sharedContents.put(item);
    });
  }

  Future<void> hardDeleteSharedContent(int contentId) async {
    await _isar.writeTxn(() async {
      await _isar.sharedContents.delete(contentId);
    });
  }

  // --- Unsynced Count for UI Badge ---
  Future<int> getUnsyncedCount(String userId) async {
    final unsyncedContent = await _isar.sharedContents
        .filter()
        .userIdEqualTo(userId)
        .group((q) => q.syncedAtIsNull().or().isDeletedEqualTo(true))
        .count();

    final unsyncedCategories = await _isar.categorys
        .filter()
        .userIdEqualTo(userId)
        .group((q) => q.syncedAtIsNull().or().isDeletedEqualTo(true))
        .count();

    return unsyncedContent + unsyncedCategories;
  }

  // --- User Data Migration (Local Guest -> Authenticated Account) ---
  Future<void> migrateUserRecords({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    // 1. Fetch existing categories for target user to prevent duplicate creations
    final targetCategories = await _isar.categorys
        .filter()
        .userIdEqualTo(toUserId)
        .isDeletedEqualTo(false)
        .findAll();

    final targetCatNameMap = <String, Category>{};
    for (var cat in targetCategories) {
      targetCatNameMap[cat.name.trim().toLowerCase()] = cat;
    }

    // 2. Fetch source categories
    final sourceCategories = await _isar.categorys
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();

    final categoryRemap = <int, int>{};
    final categoriesToDelete = <int>[];
    final categoriesToMigrate = <Category>[];

    for (var cat in sourceCategories) {
      final normName = cat.name.trim().toLowerCase();
      if (normName.isEmpty) {
        categoriesToDelete.add(cat.id);
        continue;
      }

      if (targetCatNameMap.containsKey(normName)) {
        // Target user already has a category with this name -> reuse it
        final targetCat = targetCatNameMap[normName]!;
        categoryRemap[cat.id] = targetCat.id;
        categoriesToDelete.add(cat.id);
      } else {
        // Unique category for target user -> migrate it
        cat.userId = toUserId;
        categoriesToMigrate.add(cat);
        targetCatNameMap[normName] = cat;
      }
    }

    // 3. Migrate and remap shared content items
    final contents = await _isar.sharedContents
        .filter()
        .userIdEqualTo(fromUserId)
        .findAll();

    for (var item in contents) {
      item.userId = toUserId;
      if (categoryRemap.containsKey(item.categoryId)) {
        item.categoryId = categoryRemap[item.categoryId]!;
      }
      item.syncedAt = null; // Mark unsynced so they get pushed to cloud
    }

    // Atomic transaction for all migration updates
    await _isar.writeTxn(() async {
      for (var id in categoriesToDelete) {
        await _isar.categorys.delete(id);
      }
      for (var cat in categoriesToMigrate) {
        await _isar.categorys.put(cat);
      }
      for (var item in contents) {
        await _isar.sharedContents.put(item);
      }
    });
  }

  Future<void> saveSyncedCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> saveSyncedContent(SharedContent content) async {
    await _isar.writeTxn(() async {
      await _isar.sharedContents.put(content);
    });
  }

  // --- Export / Import Local Database ---
  Future<String> exportDatabaseJson(String userId) async {
    final categories = await getAllCategories(userId);
    final contents = await getSharedContent(userId: userId);

    final catMap = {for (var c in categories) c.id: c.name};

    final exportData = {
      'version': 1,
      'app': 'SociaSave',
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
      'categories': categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'colorHex': c.colorHex,
                'createdAt': c.createdAt.toIso8601String(),
                'updatedAt': c.updatedAt.toIso8601String(),
              })
          .toList(),
      'contents': contents
          .map((item) => {
                'id': item.id,
                'rawUrl': item.rawUrl,
                'title': item.title,
                'thumbnailUrl': item.thumbnailUrl,
                'socmedSource': item.socmedSource,
                'categoryId': item.categoryId,
                'categoryName': catMap[item.categoryId] ?? 'General',
                'createdAt': item.createdAt.toIso8601String(),
                'updatedAt': item.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  Future<File> exportDatabaseToFile(String userId) async {
    final jsonString = await exportDatabaseJson(userId);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/socia_save_backup_$timestamp.json');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<Map<String, int>> importDatabaseJson(
    String userId,
    String jsonString,
  ) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON format: root is not an object.');
    }

    final rawCategories = decoded['categories'] as List<dynamic>? ?? [];
    final rawContents = decoded['contents'] as List<dynamic>? ?? [];

    // 1. Process Categories
    final existingCategories = await getAllCategories(userId);
    final existingCatNameMap = <String, Category>{};
    for (var cat in existingCategories) {
      existingCatNameMap[cat.name.trim().toLowerCase()] = cat;
    }

    final Map<int, int> categoryRemap = {};
    int importedCategoriesCount = 0;

    for (var rawCat in rawCategories) {
      if (rawCat is! Map<String, dynamic>) continue;
      final oldId = rawCat['id'] as int? ?? 0;
      final name = (rawCat['name'] as String? ?? '').trim();
      final colorHex = (rawCat['colorHex'] as String? ?? '6366F1');

      if (name.isEmpty) continue;

      final normName = name.toLowerCase();
      if (existingCatNameMap.containsKey(normName)) {
        final existingCat = existingCatNameMap[normName]!;
        if (oldId > 0) {
          categoryRemap[oldId] = existingCat.id;
        }
      } else {
        final newCat = Category.create(
          userId: userId,
          name: name,
          colorHex: colorHex,
        );
        final newId = await addCategory(newCat);
        if (oldId > 0) {
          categoryRemap[oldId] = newId;
        }
        existingCatNameMap[normName] = newCat;
        importedCategoriesCount++;
      }
    }

    // 2. Ensure at least one category exists as fallback
    final allCatsNow = await getAllCategories(userId);
    final defaultCategoryId = allCatsNow.isNotEmpty ? allCatsNow.first.id : 0;

    // 3. Process Shared Contents
    final existingContents = await getSharedContent(userId: userId);
    final existingUrls = existingContents.map((c) => c.rawUrl.trim()).toSet();

    int importedContentsCount = 0;

    for (var rawItem in rawContents) {
      if (rawItem is! Map<String, dynamic>) continue;
      final rawUrl = (rawItem['rawUrl'] as String? ?? '').trim();
      final title = (rawItem['title'] as String? ?? '').trim();
      final thumbnailUrl = rawItem['thumbnailUrl'] as String?;
      final socmedSource =
          (rawItem['socmedSource'] as String? ?? 'Other').trim();
      final rawCatId = rawItem['categoryId'] as int? ?? 0;
      final rawCatName =
          (rawItem['categoryName'] as String? ?? '').trim().toLowerCase();

      if (rawUrl.isEmpty || title.isEmpty) continue;

      // Avoid duplicating identical URLs
      if (existingUrls.contains(rawUrl)) continue;

      // Determine category ID: Remap -> Name match -> default
      int targetCategoryId = defaultCategoryId;
      if (categoryRemap.containsKey(rawCatId)) {
        targetCategoryId = categoryRemap[rawCatId]!;
      } else if (rawCatName.isNotEmpty &&
          existingCatNameMap.containsKey(rawCatName)) {
        targetCategoryId = existingCatNameMap[rawCatName]!.id;
      }

      final newContent = SharedContent.create(
        userId: userId,
        rawUrl: rawUrl,
        title: title,
        thumbnailUrl: thumbnailUrl,
        socmedSource: socmedSource,
        categoryId: targetCategoryId,
      );

      await addSharedContent(newContent);
      existingUrls.add(rawUrl);
      importedContentsCount++;
    }

    return {
      'categories': importedCategoriesCount,
      'contents': importedContentsCount,
    };
  }
}
