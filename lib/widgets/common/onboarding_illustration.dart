import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// The decorative illustration shown on onboarding pages 1–3.
///
/// Visually matches the design: three teal/mint pill-shaped sensor cards
/// with circular photo thumbnails, floating over coloured blob shapes.
/// All sizes and positions are derived from [illustrationHeight] so it
/// scales cleanly on different screen widths.
class OnboardingIllustration extends StatelessWidget {
  /// Total height of the illustration area.
  final double illustrationHeight;

  const OnboardingIllustration({
    super.key,
    this.illustrationHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      height: illustrationHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background blobs ──────────────────────────────────────────

          /// Mint blob — bottom-left corner
          Positioned(
            left: -24,
            bottom: 10,
            child: _Blob(size: 90, color: const Color(0xFFB2F5EA)),
          ),

          /// Pink blob — bottom-right corner
          Positioned(
            right: -16,
            bottom: -10,
            child: _Blob(size: 75, color: const Color(0xFFFCE7F3)),
          ),

          // ── Decorative scatter dots ───────────────────────────────────

          /// Dark-maroon dot — top-centre-left
          Positioned(
            top: 18,
            left: w * 0.28,
            child: const _Dot(size: 9, color: Color(0xFF7F1D1D)),
          ),

          /// Small pink dot — upper-middle
          Positioned(
            top: 58,
            left: w * 0.44,
            child: _Dot(size: 7, color: AppColors.pinkLight),
          ),

          /// Green dot — left edge mid
          Positioned(
            top: illustrationHeight * 0.52,
            left: 10,
            child: const _Dot(size: 11, color: Color(0xFF10B981)),
          ),

          /// Dark-maroon dot — right mid-low
          Positioned(
            top: illustrationHeight * 0.55,
            right: w * 0.12,
            child: const _Dot(size: 10, color: Color(0xFF7F1D1D)),
          ),

          // ── Sensor cards ─────────────────────────────────────────────

          /// Card 1 — top-centre, no photo thumbnail
          Positioned(
            top: 10,
            left: w * 0.30,
            child: const _SensorCard(showThumbnail: false),
          ),

          /// Card 2 — middle-left, circuit-board photo thumbnail
          Positioned(
            top: illustrationHeight * 0.28,
            left: w * 0.04,
            child: const _SensorCard(
              showThumbnail: true,
              thumbnailIcon: Icons.memory,
            ),
          ),

          /// Standalone circular photo — middle-right (camera / settings icon)
          Positioned(
            top: illustrationHeight * 0.22,
            right: w * 0.08,
            child: const _CircularThumbnail(size: 58, icon: Icons.settings),
          ),

          /// Card 3 — lower-centre, factory / pipeline photo thumbnail
          Positioned(
            top: illustrationHeight * 0.50,
            left: w * 0.18,
            child: const _SensorCard(
              showThumbnail: true,
              thumbnailIcon: Icons.factory,
              thumbnailSize: 64,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// A solid-coloured circular blob used as background decoration.
class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// A small filled circle used as a scatter dot in the illustration.
class _Dot extends StatelessWidget {
  final double size;
  final Color color;

  const _Dot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// A circular image thumbnail — represents a sensor / equipment photo.
class _CircularThumbnail extends StatelessWidget {
  final double size;
  final IconData icon;

  const _CircularThumbnail({
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Light grey fill simulates a photo placeholder
        color: const Color(0xFFD1D5DB),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2.5),
      ),
      child: Icon(icon, color: const Color(0xFF6B7280), size: size * 0.4),
    );
  }
}

/// A teal/mint pill-shaped card that resembles a sensor-reading result row.
///
/// Optionally shows a [_CircularThumbnail] on the left side.
/// Always shows a teal check-circle and two placeholder line bars on the right.
class _SensorCard extends StatelessWidget {
  /// Whether to show a circular photo thumbnail on the left.
  final bool showThumbnail;

  /// Icon used inside the thumbnail (ignored when [showThumbnail] is false).
  final IconData thumbnailIcon;

  /// Diameter of the thumbnail circle.
  final double thumbnailSize;

  const _SensorCard({
    this.showThumbnail = false,
    this.thumbnailIcon = Icons.memory,
    this.thumbnailSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        // Matches the mint/teal pill colour in the designs
        color: const Color(0xFFB2F5EA),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Optional left thumbnail ──────────────────────────────────
          if (showThumbnail) ...[
            _CircularThumbnail(size: thumbnailSize, icon: thumbnailIcon),
            const SizedBox(width: 8),
          ],

          // ── Teal check indicator ─────────────────────────────────────
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.white, size: 13),
          ),
          const SizedBox(width: 8),

          // ── Placeholder data bars ────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary bar — teal/dark
              Container(
                width: 70,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 5),
              // Secondary bar — maroon, shorter
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
