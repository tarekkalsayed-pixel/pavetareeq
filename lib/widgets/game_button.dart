import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../theme.dart';

class GameButton extends StatelessWidget {
  const GameButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed == null
            ? null
            : () {
                AudioService.instance.playTap();
                onPressed?.call();
              },
        icon: Icon(icon ?? Icons.play_arrow_rounded),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.white12 : kGlowBlue,
          foregroundColor: Colors.black,
          disabledForegroundColor: Colors.white54,
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: compact ? 12 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: TextStyle(
            fontSize: compact ? 15 : 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
