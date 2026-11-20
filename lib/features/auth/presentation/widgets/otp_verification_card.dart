import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Card for entering 6-digit OTP and verifying email or mobile number
class OtpVerificationCard extends StatelessWidget {
  final String destination;
  final bool isEmail;
  final TextEditingController otpController;
  final bool isLoading;
  final AppStrings strings;
  final AppLanguage language;
  final VoidCallback onChangeDestination;
  final VoidCallback onVerify;

  const OtpVerificationCard({
    super.key,
    required this.destination,
    this.isEmail = true,
    required this.otpController,
    required this.isLoading,
    required this.strings,
    required this.language,
    required this.onChangeDestination,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEmail ? Icons.mark_email_read_outlined : Icons.sms_outlined,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmail ? 'Verification code sent to' : 'SMS code sent to',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChangeDestination,
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            labelText: '6-Digit Verification Code',
            labelStyle: TextStyle(color: colors.textSecondary, letterSpacing: 0),
            hintText: '• • • • • •',
            hintStyle: TextStyle(color: colors.textMuted, letterSpacing: 6),
            prefixIcon: Icon(Icons.key_rounded, color: colors.primary, size: 20),
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
          ),
        ),
        const SizedBox(height: 18),

        ElevatedButton(
          onPressed: isLoading ? null : onVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentEmerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
            shadowColor: colors.accentEmerald.withValues(alpha: 0.3),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Verify & Continue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }
}
