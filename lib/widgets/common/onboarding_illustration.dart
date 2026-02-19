import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Teal blobs background
          Positioned(
            left: -20,
            top: 20,
            child: _blob(80, AppColors.mintLight),
          ),
          Positioned(
            right: -10,
            bottom: 0,
            child: _blob(70, AppColors.pinkLight),
          ),
          // Floating cards
          Positioned(
            top: 10,
            left: 60,
            child: _card(
              hasImage: false,
              color: AppColors.mint,
              dotColor: AppColors.teal,
              lineColor: AppColors.dotMaroon,
            ),
          ),
          Positioned(
            top: 75,
            left: 30,
            child: _card(
              hasImage: true,
              imageAsset: 'circuit',
              color: AppColors.mint,
              dotColor: AppColors.teal,
              lineColor: AppColors.dotMaroon,
            ),
          ),
          Positioned(
            top: 75,
            right: 20,
            child: _roundImage(size: 58),
          ),
          Positioned(
            top: 140,
            left: 80,
            child: _card(
              hasImage: true,
              imageAsset: 'factory',
              color: AppColors.mint,
              dotColor: AppColors.teal,
              lineColor: AppColors.dotMaroon,
            ),
          ),
          // Decorative dots
          Positioned(
            top: 5,
            left: 105,
            child: _dot(8, AppColors.dotMaroon),
          ),
          Positioned(
            top: 120,
            left: 22,
            child: _dot(10, AppColors.dotGreen),
          ),
          Positioned(
            bottom: 30,
            right: 50,
            child: _dot(10, AppColors.dotMaroon),
          ),
          Positioned(
            top: 35,
            right: 100,
            child: _dot(6, AppColors.pinkLight),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _roundImage({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.borderColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
      ),
      child: const Icon(Icons.settings, color: AppColors.textGrey, size: 24),
    );
  }

  Widget _card({
    required bool hasImage,
    String? imageAsset,
    required Color color,
    required Color dotColor,
    required Color lineColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: Icon(
                imageAsset == 'circuit' ? Icons.memory : Icons.factory,
                color: AppColors.textGrey,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.white, size: 12),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 6,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}