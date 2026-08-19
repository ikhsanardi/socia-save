import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  @Index()
  late String name;

  late String colorHex;
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? syncedAt;
  late bool isDeleted;

  Category();

  factory Category.create({
    required String userId,
    required String name,
    required String colorHex,
  }) {
    final now = DateTime.now();
    return Category()
      ..userId = userId
      ..name = name
      ..colorHex = colorHex
      ..createdAt = now
      ..updatedAt = now
      ..syncedAt = null
      ..isDeleted = false;
  }
}
