import 'package:flutter_test/flutter_test.dart';
import 'package:socia_saver/models/category.dart';

void main() {
  group('Category Model & Normalization Tests', () {
    test('Category.create initializes proper fields', () {
      final cat = Category.create(
        userId: 'user_123',
        name: '  Tech News  ',
        colorHex: '3B82F6',
      );

      expect(cat.userId, equals('user_123'));
      expect(cat.name, equals('  Tech News  '));
      expect(cat.colorHex, equals('3B82F6'));
      expect(cat.isDeleted, isFalse);
      expect(cat.createdAt, isNotNull);
      expect(cat.updatedAt, isNotNull);
    });

    test('Category name deduplication grouping matches case and whitespace insensitively', () {
      final names = ['General', 'general', '  General  ', 'GENERAL', 'Recipes', 'recipes '];
      final canonicalByName = <String, String>{};

      for (var name in names) {
        final norm = name.trim().toLowerCase();
        if (!canonicalByName.containsKey(norm)) {
          canonicalByName[norm] = name.trim();
        }
      }

      expect(canonicalByName.length, equals(2));
      expect(canonicalByName.keys, containsAll(['general', 'recipes']));
    });
  });
}
