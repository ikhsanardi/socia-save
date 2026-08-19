import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'shared_content_provider.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthController {
  final Ref ref;

  AuthController(this.ref);

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Clean state before requesting sign-in
      try {
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled or dismissed the account picker
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception(
          'Google authentication token was empty. Please verify SHA-1 fingerprint is registered in Firebase Console.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      final previousUserId = currentUser?.uid ?? 'local_user';
      UserCredential userCredential;

      // If already signed in anonymously, link the account so existing local data stays with this user
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          userCredential = await currentUser.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'provider-already-linked') {
            userCredential =
                await FirebaseAuth.instance.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final isarService = ref.read(isarServiceProvider);

        // Migrate guest records to the authenticated Google user account
        if (previousUserId != user.uid) {
          await isarService.migrateUserRecords(
            fromUserId: previousUserId,
            toUserId: user.uid,
          );
        }
        await isarService.migrateUserRecords(
          fromUserId: 'local_user',
          toUserId: user.uid,
        );

        // Hold data in local storage first (do not auto sync to cloud)
        // Refresh providers to reflect authenticated state and show unsynced counter
        ref.invalidate(categoryNotifierProvider);
        ref.invalidate(sharedContentNotifierProvider);
        ref.invalidate(unsyncedCountProvider);
      }

      return userCredential;
    } catch (e, stack) {
      debugPrint('Google Sign-In Exception: $e\n$stack');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();

      // Refresh providers for guest state
      ref.invalidate(categoryNotifierProvider);
      ref.invalidate(sharedContentNotifierProvider);
      ref.invalidate(unsyncedCountProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});
