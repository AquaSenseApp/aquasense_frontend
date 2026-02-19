import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.pinkLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left,
          color: AppColors.textDark,
          size: 22,
        ),
      ),
    );
  }
}