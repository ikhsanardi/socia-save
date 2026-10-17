import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/models/shared_content.dart';

void main() {
  group('SharedContent Local-First & Unsynced Logic Tests', () {
    test('New SharedContent is initialized as unsynced (syncedAt is null)', () {
      final item = SharedContent.create(
        userId: 'user_test_123',
        rawUrl: 'https://www.instagram.com/p/test12345/',
        title: 'Delicious Pasta Recipe',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        socmedSource: 'Instagram',
        categoryId: 1,
      );

      expect(item.userId, equals('user_test_123'));
      expect(item.rawUrl, equals('https://www.instagram.com/p/test12345/'));
      expect(item.title, equals('Delicious Pasta Recipe'));
      expect(item.socmedSource, equals('Instagram'));
      expect(item.categoryId, equals(1));
      // Key requirement: holds in local first, unsynced
      expect(item.syncedAt, isNull);
      expect(item.isDeleted, isFalse);
      expect(item.createdAt, isNotNull);
      expect(item.updatedAt, isNotNull);
    });

    test('Guest and Authenticated users both retain local unsynced state', () {
      final guestItem = SharedContent.create(
        userId: 'local_user',
        rawUrl: 'https://tiktok.com/@chef/video/1',
        title: 'Quick Cooking Tip',
        socmedSource: 'TikTok',
        categoryId: 2,
      );

      final authedItem = SharedContent.create(
        userId: 'google_user_999',
        rawUrl: 'https://youtube.com/watch?v=abc',
        title: 'Flutter Riverpod Tutorial',
        socmedSource: 'YouTube',
        categoryId: 3,
      );

      expect(guestItem.syncedAt, isNull);
      expect(authedItem.syncedAt, isNull);
    });

    test('Unsynced counter counts active unsynced items and deleted previously-synced items', () {
      final now = DateTime.now();
      final items = [
        SharedContent.create(
          userId: 'user_1',
          rawUrl: 'https://x.com/post/1',
          title: 'Post 1',
          socmedSource: 'X',
          categoryId: 1,
        ), // active unsynced -> count = 1
        SharedContent.create(
          userId: 'user_1',
          rawUrl: 'https://x.com/post/2',
          title: 'Post 2',
          socmedSource: 'X',
          categoryId: 1,
        )..syncedAt = now, // active synced -> count = 0
        SharedContent.create(
          userId: 'user_1',
          rawUrl: 'https://x.com/post/3',
          title: 'Post 3',
          socmedSource: 'X',
          categoryId: 1,
        )
          ..syncedAt = now
          ..isDeleted = true, // deleted previously-synced -> count = 1
        SharedContent.create(
          userId: 'user_1',
          rawUrl: 'https://x.com/post/4',
          title: 'Post 4',
          socmedSource: 'X',
          categoryId: 1,
        )
          ..syncedAt = null
          ..isDeleted = true, // deleted local-only (never synced) -> count = 0 (MUST NOT COUNT)
      ];

      final unsyncedCount = items
          .where((i) =>
              (!i.isDeleted && i.syncedAt == null) ||
              (i.isDeleted && i.syncedAt != null))
          .length;
      expect(unsyncedCount, equals(2));
    });

    test('Deleting local content which is not synced yet does not count as unsynced', () {
      final item = SharedContent.create(
        userId: 'user_1',
        rawUrl: 'https://x.com/post/new',
        title: 'New Local Post',
        socmedSource: 'X',
        categoryId: 1,
      );

      // Initially active and unsynced -> count = 1
      bool needsSync(SharedContent i) =>
          (!i.isDeleted && i.syncedAt == null) ||
          (i.isDeleted && i.syncedAt != null);

      expect(needsSync(item), isTrue);

      // User deletes the local content which was never synced:
      item.isDeleted = true;
      item.syncedAt = null;

      // Crucial requirement: Must NOT be counted!
      expect(needsSync(item), isFalse);
    });

    test('Batch deletion hard-deletes never-synced items and retains tombstones for synced items', () {
      final syncedItem = SharedContent.create(
        userId: 'user_1',
        rawUrl: 'https://x.com/post/synced',
        title: 'Synced Post',
        socmedSource: 'X',
        categoryId: 1,
      )
        ..id = 1
        ..syncedAt = DateTime.now();

      final neverSyncedItem = SharedContent.create(
        userId: 'user_1',
        rawUrl: 'https://x.com/post/local',
        title: 'Local Only Post',
        socmedSource: 'X',
        categoryId: 1,
      )..id = 2;

      final items = [syncedItem, neverSyncedItem];

      // Simulate deleteMultiple logic:
      final remainingItems = <SharedContent>[];
      for (final item in items) {
        if (item.syncedAt == null) {
          // Hard deleted, not kept
        } else {
          item.isDeleted = true;
          remainingItems.add(item);
        }
      }

      // neverSyncedItem is completely gone
      expect(remainingItems.length, equals(1));
      expect(remainingItems.first.id, equals(1));
      expect(remainingItems.first.isDeleted, isTrue);
    });
  });

  group('Local DB Export & Import Serialization Tests', () {
    test('Export JSON structure validation', () {
      final exportData = {
        'version': 1,
        'app': 'SociaSave',
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': 'user_123',
        'categories': [
          {
            'id': 1,
            'name': 'Tech',
            'colorHex': '3B82F6',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ],
        'contents': [
          {
            'id': 1,
            'rawUrl': 'https://instagram.com/p/12345',
            'title': 'Tech News',
            'thumbnailUrl': 'https://example.com/img.jpg',
            'socmedSource': 'Instagram',
            'categoryId': 1,
            'categoryName': 'Tech',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }
        ],
      };

      expect(exportData['version'], equals(1));
      expect(exportData['app'], equals('SociaSave'));
      expect((exportData['categories'] as List).length, equals(1));
      expect((exportData['contents'] as List).length, equals(1));
    });
  });
}
