import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_language_menu_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/animated_bubble_background.dart';
import '../../../../core/widgets/prep_state_views.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_sign_in_buttons.dart';
import '../widgets/otp_verification_card.dart';

enum AuthMode { login, register }

/// Modern Adaptable Login & Registration Screen for Prep404
class AuthScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage>? onLanguageChanged;
  final Function(String token, Map<String, dynamic> user) onAuthSuccess;

  const AuthScreen({
    super.key,
    this.language = AppLanguage.english,
    this.onLanguageChanged,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AppLanguage _language;
  AuthMode _mode = AuthMode.register;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _authSuccessHandled = false;
  String? _pendingName;
  StreamSubscription<AuthState>? _authSubscription;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _language = widget.language;
    if (SupabaseService().isInitialized) {
      _authSubscription = SupabaseService().authStateChanges.listen((state) {
        if (state.event == AuthChangeEvent.signedIn && state.session != null) {
          _completeAuthenticatedSignIn();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.language != oldWidget.language) _language = widget.language;
  }

  void _changeLanguage(AppLanguage language) {
    setState(() => _language = language);
    widget.onLanguageChanged?.call(language);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _completeAuthenticatedSignIn({
    String? overrideToken,
    Map<String, dynamic>? overrideUser,
  }) {
    if (_authSuccessHandled) return;
    final session = overrideToken ?? SupabaseService().currentAccessToken;
    final user = SupabaseService().currentUser;
    if (session == null && overrideUser == null) return;
    _authSuccessHandled = true;
    final tokenToSave = session ?? 'demo-token';
    CacheService().write('auth_token', tokenToSave);
    widget.onAuthSuccess(
      tokenToSave,
      overrideUser ??
          {
            'id': user?.id ?? 'candidate-id',
            'name': (_pendingName?.isNotEmpty ?? false)
                ? _pendingName
                : user?.userMetadata?['full_name'] ??
                    user?.userMetadata?['name'] ??
                    'Candidate',
            'phone': user?.phone ?? _phoneController.text.trim(),
            'email': user?.email,
            'is_demo_guest': false,
          },
    );
  }

  void _showSignInError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Sign-in could not be completed. Check your connection and try again.'),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await SupabaseService().signInWithGoogle();
      if (!success) _showSignInError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await SupabaseService().signInWithFacebook();
      if (!success) _showSignInError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    final strings = AppStrings(_language);

    if (_mode == AuthMode.register) {
      final nameErr = PrepFormValidator.validateFullName(_nameController.text);
      if (nameErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nameErr),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    final phoneErr = PrepFormValidator.validatePhone(phone);
    if (phoneErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneErr),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sent = await SupabaseService().sendOtp(phone);
      if (!sent) {
        _showSignInError();
        return;
      }
      if (mounted) {
        setState(() => _isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.otpSentSuccess),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showSignInError();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtpAndProceed() async {
    final otp = _otpController.text.trim();
    final phone = _phoneController.text.trim();
    _pendingName = _nameController.text.trim();
    final strings = AppStrings(_language);

    final otpErr = PrepFormValidator.validateOtp(otp);
    if (otpErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpErr),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // No local OTP bypass: a fake 'demo-' user has no Supabase session and
      // every server call fails. Use Supabase Auth test phone numbers instead.
      final token = await SupabaseService().verifyOtp(phone, otp);
      if (token != null) {
        _completeAuthenticatedSignIn();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.invalidOtpError),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (_) {
      _showSignInError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppColors colors,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: colors.primary, size: 20),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : colors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_language);
    final colors = context.colors;

    return Scaffold(
      body: AnimatedBubbleBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Pinned Top Action Bar (Clean zero-gap top edge)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ThemeToggleIconButton(),
                        AppLanguageMenuButton(
                          language: _language,
                          onChanged: _changeLanguage,
                        ),
                      ],
                    ),
                  ),

                  // Fluid Adaptable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 60)
                              .clamp(0.0, double.infinity),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 8),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Spacer(flex: 1),
                                    const SizedBox(height: 8),

                                    // Brand Header
                                    AuthHeader(
                                      language: _language,
                                      strings: strings,
                                      showControls: false,
                                    ),
                                    const SizedBox(height: 20),

                                    // Card Container
                                    Container(
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: colors.border,
                                        ),
                                        boxShadow: colors.cardShadow,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Mode Switcher
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: colors.surfaceElevated,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                  color: colors.borderSubtle),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _buildSegmentButton(
                                                    title: strings.signUpTab,
                                                    isActive: _mode ==
                                                        AuthMode.register,
                                                    onTap: () => setState(() {
                                                      _mode = AuthMode.register;
                                                      _isOtpSent = false;
                                                    }),
                                                    colors: colors,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _buildSegmentButton(
                                                    title: strings.signInTab,
                                                    isActive:
                                                        _mode == AuthMode.login,
                                                    onTap: () => setState(() {
                                                      _mode = AuthMode.login;
                                                      _isOtpSent = false;
                                                    }),
                                                    colors: colors,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          // Google & Facebook Social Auth
                                          SocialSignInButtons(
                                            strings: strings,
                                            isLoading: _isLoading,
                                            onGoogleSignIn: _handleGoogleSignIn,
                                            onFacebookSignIn:
                                                _handleFacebookSignIn,
                                          ),
                                          const SizedBox(height: 16),

                                          // Divider
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: Divider(
                                                      color: colors.border)),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                child: Text(
                                                  strings.orMobile,
                                                  style: TextStyle(
                                                    color: colors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                  child: Divider(
                                                      color: colors.border)),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          if (_mode == AuthMode.register &&
                                              !_isOtpSent) ...[
                                            _buildInputField(
                                              controller: _nameController,
                                              label: strings.fullNameLabel,
                                              hint: strings.fullNameHint,
                                              icon: Icons.person_outline,
                                              colors: colors,
                                            ),
                                            const SizedBox(height: 12),
                                          ],

                                          if (!_isOtpSent) ...[
                                            _buildInputField(
                                              controller: _phoneController,
                                              label: strings.phoneLabel,
                                              hint: strings.phoneHint,
                                              icon:
                                                  Icons.phone_android_outlined,
                                              keyboardType: TextInputType.phone,
                                              colors: colors,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed:
                                                  _isLoading ? null : _sendOtp,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: colors.primary,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                elevation: 3,
                                                shadowColor: colors.primary
                                                    .withValues(alpha: 0.35),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Text(
                                                      strings.sendOtpBtn,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                            ),
                                          ] else ...[
                                            OtpVerificationCard(
                                              phone:
                                                  _phoneController.text.trim(),
                                              otpController: _otpController,
                                              isLoading: _isLoading,
                                              strings: strings,
                                              language: _language,
                                              onChangePhone: () => setState(
                                                  () => _isOtpSent = false),
                                              onVerify: _verifyOtpAndProceed,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          _completeAuthenticatedSignIn(
                                            overrideToken:
                                                'guest-token-${DateTime.now().millisecondsSinceEpoch}',
                                            overrideUser: {
                                              'id':
                                                  'guest-${DateTime.now().millisecondsSinceEpoch}',
                                              'name': 'Guest Candidate',
                                              'phone': '',
                                              'is_demo_guest': true,
                                            },
                                          );
                                        },
                                        icon: Icon(Icons.explore_outlined,
                                            size: 16,
                                            color: colors.textSecondary),
                                        label: Text(
                                          strings.demoLoginBtn,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(flex: 2),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
