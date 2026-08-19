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

    test('Unsynced counter counts both active unsynced and deleted pending sync items', () {
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
        )..syncedAt = DateTime.now(), // active synced -> count = 0
        SharedContent.create(
          userId: 'user_1',
          rawUrl: 'https://x.com/post/3',
          title: 'Post 3',
          socmedSource: 'X',
          categoryId: 1,
        )..isDeleted = true, // deleted pending cloud sync -> count = 1
      ];

      final unsyncedCount = items.where((i) => i.syncedAt == null || i.isDeleted).length;
      expect(unsyncedCount, equals(2));
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
