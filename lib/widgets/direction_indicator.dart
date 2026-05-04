import 'package:flutter/material.dart';
import '../ml/detection.dart';
import '../app_theme.dart';

class DirectionIndicator extends StatelessWidget {
  final NavigationCommand command;

  const DirectionIndicator({super.key, required this.command});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildIndicator(command),
    );
  }

  Widget _buildIndicator(NavigationCommand cmd) {
    switch (cmd) {
      case NavigationCommand.stop:
        return _IndicatorWidget(
          key: const ValueKey('stop'),
          icon: Icons.block_rounded,
          color: AppColors.error,
          label: 'STOP',
        );
      case NavigationCommand.moveLeft:
        return _IndicatorWidget(
          key: const ValueKey('left'),
          icon: Icons.arrow_back_rounded,
          color: const Color(0xFF9E3D00),
          label: 'MOVE LEFT',
        );
      case NavigationCommand.moveRight:
        return _IndicatorWidget(
          key: const ValueKey('right'),
          icon: Icons.arrow_forward_rounded,
          color: const Color(0xFF9E3D00),
          label: 'MOVE RIGHT',
        );
      case NavigationCommand.moveForward:
        return _IndicatorWidget(
          key: const ValueKey('forward'),
          icon: Icons.arrow_upward_rounded,
          color: AppColors.secondary,
          label: 'MOVE FORWARD',
        );
      case NavigationCommand.clear:
        return _IndicatorWidget(
          key: const ValueKey('clear'),
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.secondary,
          label: 'PATH CLEAR',
        );
    }
  }
}

class _IndicatorWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _IndicatorWidget({super.key, required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(icon, color: color, size: 72),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Lexend',
          ),
        ),
      ],
    );
  }
}
