import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/database_provider.dart';
import '../providers/shared_content_provider.dart';

class AccountBottomSheet extends ConsumerStatefulWidget {
  const AccountBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AccountBottomSheet(),
    );
  }

  @override
  ConsumerState<AccountBottomSheet> createState() => _AccountBottomSheetState();
}

class _AccountBottomSheetState extends ConsumerState<AccountBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCred =
          await ref.read(authControllerProvider).signInWithGoogle();
      if (mounted) {
        if (userCred != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Signed in as ${userCred.user?.displayName ?? userCred.user?.email ?? 'Google User'}',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context);
        } else {
          // User closed account picker without selecting an account
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign in was cancelled.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('10') ||
            errorMsg.contains('ApiException: 10') ||
            errorMsg.contains('DEVELOPER_ERROR')) {
          errorMsg =
              'Google Sign-In configuration error (ApiException 10).\n\nPlease ensure your Android SHA-1 fingerprint is added to Firebase Console under Project Settings.';
        } else if (errorMsg.contains('12500') ||
            errorMsg.contains('ApiException: 12500')) {
          errorMsg =
              'Sign in failed (ApiException 12500).\n\nPlease verify Google Sign-in is enabled in Firebase Console.';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Sign In Error'),
              ],
            ),
            content: Text(
              errorMsg.startsWith('Exception: ')
                  ? errorMsg.replaceFirst('Exception: ', '')
                  : errorMsg,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleExportLocalDb() async {
    setState(() => _isLoading = true);
    try {
      final isarService = ref.read(isarServiceProvider);
      final userId = ref.read(userIdProvider);
      final file = await isarService.exportDatabaseToFile(userId);

      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Socia Save Database Backup',
          text: 'Backup of Socia Save bookmarks and categories.',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database backup exported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleImportLocalDb() async {
    setState(() => _isLoading = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isEmpty || files.first.path == null) {
        // User cancelled picker
        return;
      }

      final file = File(files.first.path!);
      final jsonString = await file.readAsString();

      final isarService = ref.read(isarServiceProvider);
      final userId = ref.read(userIdProvider);

      final counts = await isarService.importDatabaseJson(userId, jsonString);
      final catCount = counts['categories'] ?? 0;
      final contentCount = counts['contents'] ?? 0;

      // Refresh providers to reflect imported items
      ref.invalidate(categoryNotifierProvider);
      ref.invalidate(sharedContentNotifierProvider);
      ref.invalidate(unsyncedCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported $contentCount bookmark${contentCount == 1 ? '' : 's'} and $catCount categor${catCount == 1 ? 'y' : 'ies'} successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your bookmarks will remain safely stored in your Google Cloud account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final unsyncedCountAsync = ref.watch(unsyncedCountProvider);
    final unsyncedCount = unsyncedCountAsync.valueOrNull ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: userAsync.when(
          data: (user) {
            final isAnonymous = user == null || user.isAnonymous;
            final displayName = user?.displayName ?? 'Guest User';
            final email = user?.email ?? 'Guest Session (Offline)';
            final photoUrl = user?.photoURL;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profile Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Icon(
                              isAnonymous
                                  ? Icons.person_outline_rounded
                                  : Icons.person_rounded,
                              size: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAnonymous ? 'Guest Account' : displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isAnonymous)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: unsyncedCount > 0
                              ? Colors.amber.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: unsyncedCount > 0
                                    ? Colors.amber.shade800
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              unsyncedCount > 0
                                  ? '$unsyncedCount Unsynced'
                                  : 'Cloud Synced',
                              style: TextStyle(
                                color: unsyncedCount > 0
                                    ? Colors.amber.shade900
                                    : Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Local DB Backup & Restore info note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAnonymous
                              ? 'Export your local database to keep a JSON backup or import bookmarks anytime. You can also sign in with Google to enable cloud sync.'
                              : 'Export your local database to keep a JSON backup, or import an existing backup file to restore bookmarks.',
                          style: const TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons: Export & Import Local DB
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleExportLocalDb,
                        icon: const Icon(Icons.upload_file_rounded, size: 20),
                        label: const Text(
                          'Export DB',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _handleImportLocalDb,
                        icon: const Icon(Icons.file_download_rounded, size: 20),
                        label: const Text(
                          'Import DB',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Sign in with Google (Guest) or Sign Out (Authenticated)
                if (isAnonymous) ...[
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.account_circle_rounded, size: 22),
                    label: Text(
                      _isLoading ? 'Signing In...' : 'Sign in with Google',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleSignOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Text('Account error: $e'),
          ),
        ),
      ),
    );
  }
}
