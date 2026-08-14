import 'package:isar/isar.dart';

part 'shared_content.g.dart';

@collection
class SharedContent {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  late String rawUrl;

  @Index(type: IndexType.value)
  late String title;

  String? thumbnailUrl;
  late String socmedSource; // Instagram, Facebook, Threads, TikTok, YouTube, X, Other

  @Index()
  late int categoryId;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;
  DateTime? syncedAt;
  late bool isDeleted;

  SharedContent();

  factory SharedContent.create({
    required String userId,
    required String rawUrl,
    required String title,
    String? thumbnailUrl,
    required String socmedSource,
    required int categoryId,
  }) {
    final now = DateTime.now();
    return SharedContent()
      ..userId = userId
      ..rawUrl = rawUrl
      ..title = title
      ..thumbnailUrl = thumbnailUrl
      ..socmedSource = socmedSource
      ..categoryId = categoryId
      ..createdAt = now
      ..updatedAt = now
      ..syncedAt = null
      ..isDeleted = false;
  }
}
