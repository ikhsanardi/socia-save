import 'package:flutter/material.dart';

/// Standardized modal header component for dialogs and bottom sheets.
///
/// Ensures uniform icon sizing (20px), icon-to-title spacing (8px),
/// text truncation (ellipsis) across narrow screens, and provides
/// standard AlertDialog padding presets.
class AppModalHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final Widget? trailing;

  const AppModalHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleStyle,
    this.trailing,
  });

  /// Standard insetPadding for application Alert dialogs
  static const EdgeInsets dialogInsetPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 24);

  /// Standard titlePadding for application Alert dialogs
  static const EdgeInsets dialogTitlePadding =
      EdgeInsets.fromLTRB(18, 16, 18, 0);

  /// Standard contentPadding for application Alert dialogs
  static const EdgeInsets dialogContentPadding =
      EdgeInsets.fromLTRB(18, 14, 18, 8);

  /// Standard actionsPadding for application Alert dialogs
  static const EdgeInsets dialogActionsPadding =
      EdgeInsets.fromLTRB(18, 0, 18, 12);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
