import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/isar_service.dart';
import 'auth_provider.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('IsarService must be initialized in main()');
});

final userIdProvider = Provider<String>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  return authUser?.uid ?? 'local_user';
});
