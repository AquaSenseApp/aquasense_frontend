import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_footer_link.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/field_label.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Create Account screen.
///
/// Collects all fields required by POST /api/users/register:
///   username, full_name, email, password, organization_type
///
/// On submit → [AuthProvider.createAccount] calls the real API,
/// then this screen pushes [AppRoutes.emailVerification] for OTP entry.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _usernameController     = TextEditingController();
  final _fullNameController     = TextEditingController();
  final _emailController        = TextEditingController();
  final _passwordController     = TextEditingController();
  String _organizationType      = '';
  bool   _agreedToTerms         = false;

  /// Organisation type options matching the backend enum expectation.
  static const _orgTypes = [
    'School',
    'Company',
    'NGO',
    'Government',
    'Hospital',
    'Other',
  ];

  /// Primary CTA enabled only when all required fields are filled + terms accepted.
  bool get _canSubmit =>
      _usernameController.text.isNotEmpty    &&
      _fullNameController.text.isNotEmpty    &&
      _emailController.text.isNotEmpty       &&
      _passwordController.text.isNotEmpty    &&
      _organizationType.isNotEmpty           &&
      _agreedToTerms;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Calls [AuthProvider.createAccount] then navigates to OTP verification.
  Future<void> _submit(AuthProvider auth) async {
    if (!_canSubmit) return;
    final success = await auth.createAccount(
      username:         _usernameController.text.trim(),
      fullName:         _fullNameController.text.trim(),
      email:            _emailController.text.trim(),
      password:         _passwordController.text,
      organizationType: _organizationType,
    );
    if (success && mounted) {
      Navigator.of(context).pushNamed(AppRoutes.emailVerification);
    }
  }

  void _signUpWithGoogle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-up coming soon')),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ── Logo + title ─────────────────────────────────────
                  AuthHeader(
                    title:    'Create Account',
                    subtitle: 'Sign up to get started on the platform',
                    onBack:   () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 24),

                  // ── Username ──────────────────────────────────────────
                  const FieldLabel('Username'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:       'e.g. JohnDoe99',
                    controller: _usernameController,
                    onChanged:  (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // ── Full Name ─────────────────────────────────────────
                  const FieldLabel('Full Name'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:       'e.g. John Doe',
                    controller: _fullNameController,
                    onChanged:  (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // ── Email ─────────────────────────────────────────────
                  const FieldLabel('Email'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:         'Enter your email',
                    controller:   _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged:    (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────────────────
                  const FieldLabel('Password'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:       '••••••••',
                    controller: _passwordController,
                    isPassword: true,
                    onChanged:  (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // ── Organisation Type ─────────────────────────────────
                  const FieldLabel('Organisation Type'),
                  const SizedBox(height: 8),
                  _OrgTypeDropdown(
                    value:     _organizationType,
                    items:     _orgTypes,
                    onChanged: (v) => setState(() => _organizationType = v ?? ''),
                  ),
                  const SizedBox(height: 16),

                  // ── Terms checkbox ────────────────────────────────────
                  _TermsCheckbox(
                    value:     _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v),
                  ),
                  const SizedBox(height: 24),

                  // ── Error message ─────────────────────────────────────
                  if (auth.errorMessage != null) ...[
                    Text(
                      auth.errorMessage!,
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(color: AppColors.riskHighFg),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Primary CTA ───────────────────────────────────────
                  AppButton(
                    label:     'Create Account',
                    enabled:   _canSubmit,
                    isLoading: auth.status == AuthStatus.loading,
                    onPressed: () => _submit(auth),
                  ),
                  const SizedBox(height: 14),

                  // ── Google sign-up ────────────────────────────────────
                  GoogleSignInButton(
                    label: 'Sign up with Google',
                    onTap: _signUpWithGoogle,
                  ),
                  const SizedBox(height: 24),

                  // ── Sign-in link ──────────────────────────────────────
                  AuthFooterLink(
                    prefixText: 'Already have an account?  ',
                    linkText:   'Sign in',
                    onTap: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.signIn),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Dropdown for organisation type — inherits theme decoration.
class _OrgTypeDropdown extends StatelessWidget {
  final String            value;
  final List<String>      items;
  final ValueChanged<String?> onChanged;

  const _OrgTypeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:        AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:      value.isEmpty ? null : value,
          hint:       Text('Select Organisation Type', style: tt.bodyMedium),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textGrey),
          items: items.map((t) => DropdownMenuItem(
            value: t,
            child: Text(t, style: tt.bodyLarge),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// "I agree to terms of service and privacy policy" checkbox row.
class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18, margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color:  value ? AppColors.teal.withValues(alpha: 0.12) : AppColors.white,
              border: Border.all(
                color: value ? AppColors.teal : AppColors.borderColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: value
                ? const Icon(Icons.check, size: 12, color: AppColors.teal)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text:  'I agree to the ',
                style: tt.bodySmall,
                children: [
                  TextSpan(
                    text:  'terms of service',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.teal, fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' and ', style: tt.bodySmall),
                  TextSpan(
                    text:  'privacy policy',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.teal, fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
