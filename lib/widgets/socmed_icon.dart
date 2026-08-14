import 'package:flutter/material.dart';

class SocmedIcon extends StatelessWidget {
  final String source;
  final double size;

  const SocmedIcon({super.key, required this.source, this.size = 20});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (source.toLowerCase()) {
      case 'instagram':
        iconData = Icons.camera_alt_rounded;
        iconColor = const Color(0xFFE4405F);
        break;
      case 'facebook':
        iconData = Icons.facebook_rounded;
        iconColor = const Color(0xFF1877F2);
        break;
      case 'threads':
        iconData = Icons.alternate_email_rounded;
        iconColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
        break;
      case 'tiktok':
        iconData = Icons.music_note_rounded;
        iconColor = const Color(0xFFEE1D52);
        break;
      case 'youtube':
        iconData = Icons.play_circle_fill_rounded;
        iconColor = const Color(0xFFFF0000);
        break;
      case 'x' || 'twitter':
        iconData = Icons.tag_rounded;
        iconColor = const Color(0xFF1DA1F2);
        break;
      default:
        iconData = Icons.link_rounded;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: size, color: iconColor),
    );
  }
}
