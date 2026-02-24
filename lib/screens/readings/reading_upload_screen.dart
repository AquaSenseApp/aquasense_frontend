import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sensor_model.dart';
import '../../providers/reading_provider.dart';
import '../../services/reading_service.dart';
import '../../widgets/auth/field_label.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Manual Sensor Reading Upload screen.
///
/// Takes a [SensorModel] as route argument (must have a non-null [apiKey]).
/// On submit calls POST /api/readings/upload via [ReadingProvider] and
/// shows the backend analysis result inline.
///
/// Route:     [AppRoutes.uploadReading]
/// Argument:  [SensorModel] passed via [Navigator.pushNamed] arguments.
class ReadingUploadScreen extends StatelessWidget {
  const ReadingUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! SensorModel) {
      return const Scaffold(
        body: Center(child: Text('Invalid sensor data')),
      );
    }
    final sensor = args;
    return ChangeNotifierProvider(
      create: (_) => ReadingProvider(),
      child:  _ReadingUploadView(sensor: sensor),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _ReadingUploadView extends StatefulWidget {
  final SensorModel sensor;
  const _ReadingUploadView({required this.sensor});

  @override
  State<_ReadingUploadView> createState() => _ReadingUploadViewState();
}

class _ReadingUploadViewState extends State<_ReadingUploadView> {
  final _phCtrl   = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _turbCtrl = TextEditingController();
  final _tdsCtrl  = TextEditingController();
  final _doCtrl   = TextEditingController();

  @override
  void dispose() {
    for (final c in [_phCtrl, _tempCtrl, _turbCtrl, _tdsCtrl, _doCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      _phCtrl.text.isNotEmpty   &&
      _tempCtrl.text.isNotEmpty &&
      _turbCtrl.text.isNotEmpty &&
      _tdsCtrl.text.isNotEmpty  &&
      _doCtrl.text.isNotEmpty;

  Future<void> _submit(ReadingProvider prov) async {
    if (!_canSubmit) return;
    final apiKey = widget.sensor.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensor has no API key. Register it first.')),
      );
      return;
    }
    await prov.upload(ReadingUploadRequest(
      apiKey:          apiKey,
      ph:              double.tryParse(_phCtrl.text)   ?? 0,
      temperature:     double.tryParse(_tempCtrl.text) ?? 0,
      turbidity:       double.tryParse(_turbCtrl.text) ?? 0,
      tds:             double.tryParse(_tdsCtrl.text)  ?? 0,
      dissolvedOxygen: double.tryParse(_doCtrl.text)   ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ReadingProvider>(
          builder: (context, prov, _) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ───────────────────────────────────────
                        Row(
                          children: [
                            const AppBackButton(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Upload Reading', style: tt.headlineSmall),
                                  Text(
                                    widget.sensor.name,
                                    style: tt.bodySmall?.copyWith(color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Result card — visible after successful upload ──
                        if (prov.result != null) ...[
                          _ResultCard(result: prov.result!),
                          const SizedBox(height: 24),
                        ],

                        // ── Error ─────────────────────────────────────────
                        if (prov.errorMessage != null) ...[
                          _ErrorBanner(message: prov.errorMessage!),
                          const SizedBox(height: 16),
                        ],

                        // ── Form ──────────────────────────────────────────
                        Text('Enter Sensor Readings', style: tt.titleSmall),
                        const SizedBox(height: 16),

                        const FieldLabel('pH'),
                        const SizedBox(height: 8),
                        AppTextField(
                          hint:         'e.g. 7.2',
                          controller:   _phCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged:    (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        const FieldLabel('Temperature (°C)'),
                        const SizedBox(height: 8),
                        AppTextField(
                          hint:         'e.g. 24.8',
                          controller:   _tempCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged:    (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        const FieldLabel('Turbidity (NTU)'),
                        const SizedBox(height: 8),
                        AppTextField(
                          hint:         'e.g. 4.0',
                          controller:   _turbCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged:    (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        const FieldLabel('TDS (mg/L)'),
                        const SizedBox(height: 8),
                        AppTextField(
                          hint:         'e.g. 300',
                          controller:   _tdsCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged:    (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        const FieldLabel('Dissolved Oxygen (mg/L)'),
                        const SizedBox(height: 8),
                        AppTextField(
                          hint:         'e.g. 7.2',
                          controller:   _doCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged:    (_) => setState(() {}),
                        ),
                        const SizedBox(height: 28),

                        AppButton(
                          label:     'Upload Reading',
                          enabled:   _canSubmit && !prov.isLoading,
                          isLoading: prov.isLoading,
                          onPressed: () => _submit(prov),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result card
// ─────────────────────────────────────────────────────────────────────────────

/// Shows the analysed reading result returned by the backend.
///
/// Each parameter block from the API is rendered as a [_AnalysisRow].
class _ResultCard extends StatelessWidget {
  final ReadingUploadResponse result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding:      const EdgeInsets.all(16),
      decoration:   BoxDecoration(
        color:        AppColors.mintLight,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.teal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text('Data Analysed & Recorded',
                  style: tt.labelLarge?.copyWith(color: AppColors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          ...result.readings.map((r) => _AnalysisRow(reading: r)),
        ],
      ),
    );
  }
}

/// One row in the result card: "pH — 3.0 — LOW, The water is acidic…"
class _AnalysisRow extends StatelessWidget {
  final AnalysedReading reading;
  const _AnalysisRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${reading.parameter}  ',
                style: tt.labelLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reading.value.toString(),
                  style: tt.bodySmall?.copyWith(color: AppColors.teal, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reading.result, style: tt.bodySmall),
        ],
      ),
    );
  }
}

/// Red error banner shown when the upload fails.
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.riskHighBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.riskHighFg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.riskHighFg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.riskHighFg),
            ),
          ),
        ],
      ),
    );
  }
}
