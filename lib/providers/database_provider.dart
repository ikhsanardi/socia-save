import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/isar_service.dart';

final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('IsarService must be initialized in main()');
});

final userIdProvider = StateProvider<String>((ref) {
  final authUser = FirebaseAuth.instance.currentUser;
  return authUser?.uid ?? 'local_user';
});
