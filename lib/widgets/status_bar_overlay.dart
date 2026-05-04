import 'package:flutter/material.dart';

class StatusBarOverlay extends StatelessWidget {
  final Color color;
  const StatusBarOverlay({super.key, this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).padding.top,
      child: Container(color: color),
    );
  }
}
