import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSettingsPressed;

  const ActionButtons({
    super.key,
    required onSettingsPressed,
  }) : _onSettingsPressed = onSettingsPressed;

  final VoidCallback _onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAreaAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF00E5FF)),
          onPressed: _onSettingsPressed,
        ),
        IconButton(
          icon: const Icon(Icons.play_arrow, color: Color(0xFF00E5FF)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
          onPressed: () {},
        ),
      ],
    );
  }
}
