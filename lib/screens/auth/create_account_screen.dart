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

  /// Track if fields have been touched for validation display
  bool _usernameTouched  = false;
  bool _fullNameTouched  = false;
  bool _emailTouched     = false;
  bool _passwordTouched  = false;

  /// Organisation type options matching the backend enum expectation.
  static const _orgTypes = [
    'School',
    'Company',
    'NGO',
    'Government',
    'Hospital',
    'Other',
  ];

  // ── Validation helpers ────────────────────────────────────────────────────

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)*\.[a-zA-Z]{2,}$');

  String? get _usernameError {
    if (!_usernameTouched) return null;
    final v = _usernameController.text.trim();
    if (v.isEmpty) return 'Username is required';
    if (v.length < 3) return 'Username must be at least 3 characters';
    if (v.length > 20) return 'Username must be at most 20 characters';
    return null;
  }
  String? get _fullNameError {
    if (!_fullNameTouched) return null;
    final v = _fullNameController.text.trim();
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 2) return 'Full name must be at least 2 characters';
    return null;
  }

  String? get _emailError {
    if (!_emailTouched) return null;
    final v = _emailController.text.trim();
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? get _passwordError {
    if (!_passwordTouched) return null;
    final v = _passwordController.text;
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Password must contain a lowercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    return null;
  }

  /// Primary CTA enabled only when all required fields are filled + terms accepted + valid.
  bool get _canSubmit =>
      _usernameController.text.isNotEmpty    &&
      _fullNameController.text.isNotEmpty    &&
      _emailController.text.isNotEmpty       &&
      _passwordController.text.isNotEmpty    &&
      _organizationType.isNotEmpty           &&
      _agreedToTerms                         &&
      _usernameError == null                 &&
      _fullNameError == null                 &&
      _emailError == null                    &&
      _passwordError == null;

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
    // Mark all fields as touched to show validation errors
    setState(() {
      _usernameTouched = true;
      _fullNameTouched = true;
      _emailTouched    = true;
      _passwordTouched = true;
    });

    if (!_canSubmit) return;
    final success = await auth.createAccount(
      username:         _usernameController.text.trim(),
      fullName:         _fullNameController.text.trim(),
      email:            _emailController.text.trim(),
      password:         _passwordController.text,
      organizationType: _organizationType,
    );
    if (success && mounted) {
      Navigator.of(context).pushNamed(AppRoutes.home);
    }
  }

  Future<void> _signUpWithGoogle() async {
    final auth    = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    }
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
                    onChanged:  (_) => setState(() => _usernameTouched = true),                  ),
                  if (_usernameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_usernameError!, style: tt.bodySmall?.copyWith(color: AppColors.riskHighFg)),
                    ),
                  const SizedBox(height: 16),

                  // ── Full Name ─────────────────────────────────────────
                  const FieldLabel('Full Name'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:       'e.g. John Doe',
                    controller: _fullNameController,
                    onChanged:  (_) { if (!_fullNameTouched) setState(() => _fullNameTouched = true); },
                  ),
                  if (_fullNameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_fullNameError!, style: tt.bodySmall?.copyWith(color: AppColors.riskHighFg)),
                    ),
                  const SizedBox(height: 16),

                  // ── Email ─────────────────────────────────────────────
                  const FieldLabel('Email'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:         'Enter your email',
                    controller:   _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged:    (_) { if (!_emailTouched) setState(() => _emailTouched = true); },
                  ),
                  if (_emailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_emailError!, style: tt.bodySmall?.copyWith(color: AppColors.riskHighFg)),
                    ),
                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────────────────
                  const FieldLabel('Password'),
                  const SizedBox(height: 8),
                  AppTextField(
                    hint:       '••••••••',
                    controller: _passwordController,
                    isPassword: true,
                    onChanged:  (_) { if (!_passwordTouched) setState(() => _passwordTouched = true); },
                  ),
                  if (_passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_passwordError!, style: tt.bodySmall?.copyWith(color: AppColors.riskHighFg)),
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
