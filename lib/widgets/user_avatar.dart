import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable user avatar that displays a Google profile picture if present,
/// falling back to user initials or a guest icon upon network failure or missing photo.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final String? email;
  final bool isAnonymous;
  final double radius;
  final BoxBorder? border;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.email,
    this.isAnonymous = true,
    this.radius = 14,
    this.border,
  });

  /// Factory constructor to directly bind from a Firebase [User].
  ///
  /// Extracts photo and profile metadata from both root [user] and [user.providerData],
  /// ensuring that Google OAuth details are found even when accounts were linked from anonymous sessions.
  factory UserAvatar.fromUser({
    Key? key,
    required User? user,
    double radius = 14,
    BoxBorder? border,
  }) {
    final photo = extractPhotoUrl(user);
    final name = extractDisplayName(user);
    final mail = extractEmail(user);
    final isAnon = user == null || user.isAnonymous;

    if (kDebugMode && user != null && !user.isAnonymous) {
      debugPrint(
        'UserAvatar.fromUser: uid=${user.uid}, rootPhoto=${user.photoURL}, '
        'providerPhotos=${user.providerData.map((p) => "${p.providerId}:${p.photoURL}").toList()}, '
        'resolvedPhoto=$photo',
      );
    }

    return UserAvatar(
      key: key,
      photoUrl: photo,
      displayName: name,
      email: mail,
      isAnonymous: isAnon,
      radius: radius,
      border: border,
    );
  }

  /// Extracts the best available photo URL from root user or linked provider accounts.
  static String? extractPhotoUrl(User? user) {
    if (user == null) return null;

    // 1. Check root user photoURL
    if (user.photoURL != null && user.photoURL!.trim().isNotEmpty) {
      return _cleanUrl(user.photoURL!.trim());
    }

    // 2. Check providerData for Google account first
    for (final profile in user.providerData) {
      if (profile.providerId == 'google.com' &&
          profile.photoURL != null &&
          profile.photoURL!.trim().isNotEmpty) {
        return _cleanUrl(profile.photoURL!.trim());
      }
    }

    // 3. Fallback to any providerData with photoURL
    for (final profile in user.providerData) {
      if (profile.photoURL != null && profile.photoURL!.trim().isNotEmpty) {
        return _cleanUrl(profile.photoURL!.trim());
      }
    }

    return null;
  }

  /// Extracts the best available display name from root user or linked provider accounts.
  static String? extractDisplayName(User? user) {
    if (user == null) return null;

    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    for (final profile in user.providerData) {
      if (profile.displayName != null &&
          profile.displayName!.trim().isNotEmpty) {
        return profile.displayName!.trim();
      }
    }

    return null;
  }

  /// Extracts the best available email from root user or linked provider accounts.
  static String? extractEmail(User? user) {
    if (user == null) return null;

    if (user.email != null && user.email!.trim().isNotEmpty) {
      return user.email!.trim();
    }

    for (final profile in user.providerData) {
      if (profile.email != null && profile.email!.trim().isNotEmpty) {
        return profile.email!.trim();
      }
    }

    return null;
  }

  static String _cleanUrl(String url) {
    var cleaned = url.trim();
    // Ensure https to comply with platform cleartext HTTP restrictions (e.g. Android 9+)
    if (cleaned.startsWith('http://')) {
      cleaned = cleaned.replaceFirst('http://', 'https://');
    }
    return cleaned;
  }

  String? _getInitial() {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail[0].toUpperCase();
    }
    return null;
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    final initial = _getInitial();

    if (!isAnonymous && initial != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primaryContainer,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.9,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAnonymous
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer,
      ),
      alignment: Alignment.center,
      child: Icon(
        isAnonymous
            ? Icons.person_outline_rounded
            : Icons.account_circle_rounded,
        size: radius * 1.25,
        color: isAnonymous
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    Widget avatarContent = SizedBox(
      width: diameter,
      height: diameter,
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                photoUrl!.trim(),
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildFallback(context);
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                    'UserAvatar: Failed to load image from "$photoUrl": $error',
                  );
                  return _buildFallback(context);
                },
              ),
            )
          : _buildFallback(context),
    );

    if (border != null) {
      avatarContent = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        child: avatarContent,
      );
    }

    return avatarContent;
  }
}
