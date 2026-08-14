import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('IsarService must be initialized in main()');
});

final userIdProvider = StateProvider<String>((ref) {
  return 'local_user';
});
