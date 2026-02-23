import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/alert_model.dart';

/// A single alert row with a 4px left accent bar coloured by [AlertType].
///
/// Layout:
///   ┌─[colour bar]─┬──────────────────────────────┐
///   │  4 px        │ Title (bold)                  │
///   │              │ Description                   │
///   │              │ Reading | Safe: range  ← tinted│
///   │              │ Timestamp                     │
///   └──────────────┴──────────────────────────────┘
class AlertListTile extends StatelessWidget {
  final AlertModel   alert;
  final VoidCallback? onTap;

  const AlertListTile({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Full-width white row — divider comes from the grouped list spacing
        color: AppColors.white,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Coloured accent bar ───────────────────────────────
              Container(width: 4, color: _accentColor),

              // ── Text content ──────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title, style: tt.labelLarge),
                      const SizedBox(height: 2),
                      Text(alert.description, style: tt.bodySmall),
                      const SizedBox(height: 2),
                      // Reading line uses the accent colour for emphasis
                      Text(
                        alert.readingLine,
                        style: tt.bodySmall?.copyWith(color: _accentColor),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatTimestamp(alert.timestamp), style: tt.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Left bar and reading-line colour keyed to [AlertType].
  /// Uses semantic [AppColors] tokens — no raw hex here.
  Color get _accentColor {
    switch (alert.type) {
      case AlertType.alert:          return AppColors.riskHighFg;
      case AlertType.anomaly:        return AppColors.teal;
      case AlertType.compliance:     return AppColors.riskMediumFg;
      case AlertType.recommendation: return AppColors.riskLowFg;
    }
  }

  /// Formats as "12:24 PM. May 14, 2019"
  String _formatTimestamp(DateTime t) {
    final h  = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m  = t.minute.toString().padLeft(2, '0');
    final ap = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap. ${_month(t.month)} ${t.day}, ${t.year}';
  }

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];
}
