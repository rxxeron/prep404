import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_language_menu_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_state_views.dart';
import '../../../../core/animations/prep_animations.dart';
import '../../../../core/widgets/prep_shake_error.dart';
import '../../../../core/widgets/prep_bounce_tap.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_sign_in_buttons.dart';
import '../widgets/otp_verification_card.dart';

enum AuthMode { login, register }

/// Modern Adaptable Login & Registration Screen for Prep404
/// Supports:
/// 1. Direct Side-by-Side Google & Facebook OAuth buttons.
/// 2. Sign In and Sign Up segmented toggle.
/// 3. Manual Email & Password registration/login with 6-digit code verification.
/// 4. Optional Phone OTP (+880 SMS) authentication.
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
  bool _usePhoneAuth = false;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _authSuccessHandled = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _shakeTrigger = 0;

  String? _pendingName;
  String? _pendingEmail;
  StreamSubscription<AuthState>? _authSubscription;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    final tokenToSave = session ?? 'token';
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
            'email':
                user?.email ?? _pendingEmail ?? _emailController.text.trim(),
          },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _shakeTrigger++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 1. Direct Google Sign-In
  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await SupabaseService().signInWithGoogle();
      if (!success) {
        _showError('Google sign-in was cancelled or could not be completed.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Direct Facebook Sign-In
  void _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await SupabaseService().signInWithFacebook();
      if (!success) {
        _showError('Facebook sign-in was cancelled or could not be completed.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Manual Email & Password Submission (Sign Up / Sign In)
  void _handleManualSubmit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid student email address');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (_mode == AuthMode.register) {
      final nameErr = PrepFormValidator.validateFullName(_nameController.text);
      if (nameErr != null) {
        _showError(nameErr);
        return;
      }

      final confirm = _confirmPasswordController.text;
      if (password != confirm) {
        _showError('Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);
      try {
        _pendingName = _nameController.text.trim();
        _pendingEmail = email;

        final result = await SupabaseService().signUpWithPassword(
          email: email,
          password: password,
          fullName: _pendingName,
        );

        if (!result.success) {
          _showError(result.errorMessage ?? 'Registration failed. Try again.');
          return;
        }

        if (result.needsVerification) {
          setState(() {
            _isOtpSent = true;
          });
          _showSuccess('6-digit verification code sent to $email');
        } else if (result.token != null) {
          _completeAuthenticatedSignIn(overrideToken: result.token);
        }
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Login Mode
      setState(() => _isLoading = true);
      try {
        _pendingEmail = email;
        final result = await SupabaseService().signInWithPassword(
          email: email,
          password: password,
        );

        if (result.needsVerification) {
          setState(() {
            _isOtpSent = true;
          });
          _showSuccess(
              result.errorMessage ?? 'Verification code sent to $email');
          return;
        }

        if (!result.success) {
          _showError(result.errorMessage ?? 'Invalid email or password');
          return;
        }

        if (result.token != null) {
          _completeAuthenticatedSignIn(overrideToken: result.token);
        }
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 4. Send Phone SMS OTP
  void _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();

    if (_mode == AuthMode.register) {
      final nameErr = PrepFormValidator.validateFullName(_nameController.text);
      if (nameErr != null) {
        _showError(nameErr);
        return;
      }
    }

    final phoneErr = PrepFormValidator.validatePhone(phone);
    if (phoneErr != null) {
      _showError(phoneErr);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final sent = await SupabaseService().sendOtp(phone);
      if (!sent) {
        _showError('Could not send SMS OTP. Check phone number.');
        return;
      }
      if (mounted) {
        setState(() => _isOtpSent = true);
        _showSuccess('SMS verification code sent to $phone');
      }
    } catch (_) {
      _showError('SMS OTP delivery failed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 5. Verify 6-Digit Code (Email or SMS)
  void _verifyOtpAndProceed() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showError('Please enter the full 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_usePhoneAuth) {
        final phone = _phoneController.text.trim();
        _pendingName = _nameController.text.trim();
        final token = await SupabaseService().verifyOtp(phone, otp);
        if (token != null) {
          _completeAuthenticatedSignIn(overrideToken: token);
        } else {
          _showError('Invalid SMS OTP. Please check the code and retry.');
        }
      } else {
        final email = _emailController.text.trim().toLowerCase();
        final token = await SupabaseService()
            .verifyEmailOtp(email: email, token: otp);
        if (token != null) {
          _completeAuthenticatedSignIn(overrideToken: token);
        } else {
          _showError('Invalid or expired 6-digit code. Please retry.');
        }
      }
    } catch (e) {
      _showError('Verification failed: $e');
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required AppColors colors,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
        prefixIcon:
            Icon(Icons.lock_outline_rounded, color: colors.primary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: colors.textMuted,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
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
          constraints: const BoxConstraints(minHeight: 44),
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
      body: AuroraShaderBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Pinned Top Action Bar
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

                  // Fluid Body
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
                                    const SizedBox(height: 18),

                                    // Card Container with Damped Recoil & Tactile Transitions
                                    PrepShakeError(
                                      shakeTrigger: _shakeTrigger,
                                      child: Container(
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: colors.surface,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                            color: colors.border,
                                          ),
                                          boxShadow: colors.cardShadow,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // Interactive Prep404 Companion Mascot
                                            Center(
                                              child: PrepRive(
                                                width: 58,
                                                height: 58,
                                                fallback: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 240),
                                                  width: 58,
                                                  height: 58,
                                                  decoration: BoxDecoration(
                                                    color: colors.primary
                                                        .withValues(
                                                            alpha: 0.12),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: colors.primary
                                                          .withValues(
                                                              alpha: 0.28),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      _obscurePassword
                                                          ? Icons
                                                              .psychology_rounded
                                                          : Icons
                                                              .visibility_rounded,
                                                      color: colors.primary,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),

                                            // 1. Sign In / Sign Up Segmented Switcher
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
                                                    title: 'Sign In',
                                                    isActive: _mode ==
                                                        AuthMode.login,
                                                    onTap: () => setState(() {
                                                      _mode = AuthMode.login;
                                                      _isOtpSent = false;
                                                    }),
                                                    colors: colors,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _buildSegmentButton(
                                                    title: 'Sign Up',
                                                    isActive: _mode ==
                                                        AuthMode.register,
                                                    onTap: () => setState(() {
                                                      _mode =
                                                          AuthMode.register;
                                                      _isOtpSent = false;
                                                    }),
                                                    colors: colors,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          // 2. Direct Social OAuth (Side by Side: Google | Facebook)
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
                                                        horizontal: 10),
                                                child: Text(
                                                  _usePhoneAuth
                                                      ? 'or mobile sms'
                                                      : 'or email & password',
                                                  style: TextStyle(
                                                    color:
                                                        colors.textSecondary,
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

                                          // 3. Verification State or Input Form
                                          if (_isOtpSent) ...[
                                            OtpVerificationCard(
                                              destination: _usePhoneAuth
                                                  ? _phoneController.text.trim()
                                                  : _emailController.text
                                                      .trim(),
                                              isEmail: !_usePhoneAuth,
                                              otpController: _otpController,
                                              isLoading: _isLoading,
                                              strings: strings,
                                              language: _language,
                                              onChangeDestination: () =>
                                                  setState(() =>
                                                      _isOtpSent = false),
                                              onVerify: _verifyOtpAndProceed,
                                            ),
                                          ] else if (!_usePhoneAuth) ...[
                                            // Manual Email & Password Flow
                                            if (_mode ==
                                                AuthMode.register) ...[
                                              _buildInputField(
                                                controller: _nameController,
                                                label: strings.fullNameLabel,
                                                hint: strings.fullNameHint,
                                                icon: Icons.person_outline,
                                                colors: colors,
                                              ),
                                              const SizedBox(height: 12),
                                            ],

                                            _buildInputField(
                                              controller: _emailController,
                                              label: 'Email Address',
                                              hint: 'student@example.com',
                                              icon: Icons.mail_outline_rounded,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              colors: colors,
                                            ),
                                            const SizedBox(height: 12),

                                            _buildPasswordField(
                                              controller: _passwordController,
                                              label: 'Password',
                                              hint: 'At least 6 characters',
                                              obscure: _obscurePassword,
                                              onToggleObscure: () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword),
                                              colors: colors,
                                            ),
                                            const SizedBox(height: 12),

                                            if (_mode ==
                                                AuthMode.register) ...[
                                              _buildPasswordField(
                                                controller:
                                                    _confirmPasswordController,
                                                label: 'Confirm Password',
                                                hint: 'Re-enter your password',
                                                obscure:
                                                    _obscureConfirmPassword,
                                                onToggleObscure: () => setState(
                                                    () =>
                                                        _obscureConfirmPassword =
                                                            !_obscureConfirmPassword),
                                                colors: colors,
                                              ),
                                              const SizedBox(height: 12),
                                            ],

                                            const SizedBox(height: 6),
                                            PrepBounceTap(
                                              onTap: _isLoading
                                                  ? null
                                                  : _handleManualSubmit,
                                              child: ElevatedButton(
                                                onPressed: _isLoading
                                                    ? null
                                                    : _handleManualSubmit,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      colors.primary,
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
                                                        _mode == AuthMode.register
                                                            ? 'Create Account'
                                                            : 'Sign In',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ] else ...[
                                            // Phone SMS OTP Flow
                                            if (_mode ==
                                                AuthMode.register) ...[
                                              _buildInputField(
                                                controller: _nameController,
                                                label: strings.fullNameLabel,
                                                hint: strings.fullNameHint,
                                                icon: Icons.person_outline,
                                                colors: colors,
                                              ),
                                              const SizedBox(height: 12),
                                            ],

                                            _buildInputField(
                                              controller: _phoneController,
                                              label: strings.phoneLabel,
                                              hint: strings.phoneHint,
                                              icon:
                                                  Icons.phone_android_outlined,
                                              keyboardType:
                                                  TextInputType.phone,
                                              colors: colors,
                                            ),
                                            const SizedBox(height: 16),

                                            ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _sendPhoneOtp,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    colors.primary,
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
                                          ],

                                          // Toggle between Email & Phone
                                          if (!_isOtpSent) ...[
                                            const SizedBox(height: 12),
                                            Center(
                                              child: TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _usePhoneAuth =
                                                        !_usePhoneAuth;
                                                  });
                                                },
                                                child: Text(
                                                  _usePhoneAuth
                                                      ? 'Sign in with Email & Password'
                                                      : 'Prefer Mobile SMS? Sign in with Phone',
                                                  style: TextStyle(
                                                    color: colors.primary,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(
                                          duration: const Duration(
                                              milliseconds: 380),
                                          curve: Curves.easeOutCubic,
                                        )
                                        .slideY(
                                          begin: 0.04,
                                          end: 0,
                                          duration: const Duration(
                                              milliseconds: 380),
                                          curve: Curves.easeOutCubic,
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
