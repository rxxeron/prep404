import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Card for entering OTP and verifying mobile number
class OtpVerificationCard extends StatelessWidget {
  final String phone;
  final TextEditingController otpController;
  final bool isLoading;
  final AppStrings strings;
  final AppLanguage language;
  final VoidCallback onChangePhone;
  final VoidCallback onVerify;

  const OtpVerificationCard({
    super.key,
    required this.phone,
    required this.otpController,
    required this.isLoading,
    required this.strings,
    required this.language,
    required this.onChangePhone,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  phone,
                  style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: onChangePhone,
                child: Text(
                  'Change',
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: otpController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            labelText: strings.otpInputLabel,
            labelStyle: TextStyle(color: colors.textSecondary),
            hintText: '4044',
            hintStyle: TextStyle(color: colors.textMuted),
            prefixIcon: Icon(Icons.lock_clock_outlined, color: colors.primary, size: 20),
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
              : Text(
                  strings.verifyOtpBtn,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
        ),
      ],
    );
  }
}
