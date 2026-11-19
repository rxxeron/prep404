import React, { useState } from 'react';
import {
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Svg, { Path } from 'react-native-svg';
import { Moon, Sun } from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import { Prep404Logo } from '../components/Prep404Logo';
import {
  EditorialCard,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';

const GoogleMark: React.FC<{ size?: number }> = ({ size = 18 }) => (
  <Svg width={size} height={size} viewBox="0 0 24 24">
    <Path
      fill="#4285F4"
      d="M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z"
    />
    <Path
      fill="#34A853"
      d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09C3.26 21.3 7.31 24 12 24z"
    />
    <Path
      fill="#FBBC05"
      d="M5.27 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62H1.29C.47 8.24 0 10.06 0 12s.47 3.76 1.29 5.38l3.98-3.09z"
    />
    <Path
      fill="#EA4335"
      d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.62l3.98 3.09c.95-2.85 3.6-4.96 6.73-4.96z"
    />
  </Svg>
);

export const AuthScreen: React.FC = () => {
  const {
    isDark,
    palette,
    toggleTheme,
    language,
    setLanguage,
    strings,
    loginAsGuest,
    loginWithPhone,
    loginWithGoogle,
    isGoogleAuthLoading,
    authCallbackError,
    clearAuthCallbackError,
    showToast,
  } = useApp();

  const [mode, setMode] = useState<'signup' | 'signin'>('signup');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [otpCode, setOtpCode] = useState('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [oauthNotice, setOauthNotice] = useState<string | null>(null);

  const bdPhoneRegex = /^01[3-9]\d{8}$/;

  const handleGoogleAuth = async () => {
    setErrorMsg(null);
    setOauthNotice(null);
    clearAuthCallbackError();
    const result = await loginWithGoogle();
    if (!result.ok && result.error) {
      if (result.notConfigured) {
        setOauthNotice(
          `${result.error}${result.callbackUrl ? ` Callback URL: ${result.callbackUrl}` : ''}`
        );
      } else {
        setOauthNotice(result.error);
      }
    }
  };

  const handleSendOtp = () => {
    setErrorMsg(null);
    setOauthNotice(null);
    const cleaned = phone.replace(/\s|-/g, '');
    if (!bdPhoneRegex.test(cleaned)) {
      setErrorMsg(strings.invalidPhoneMsg);
      return;
    }
    setPhone(cleaned);
    setOtpSent(true);
    showToast(strings.otpSentMsg(cleaned));
  };

  const handleVerifyOtp = () => {
    setErrorMsg(null);
    if (otpCode.trim() !== '1234') {
      setErrorMsg(strings.invalidOtpMsg);
      return;
    }
    loginWithPhone(fullName.trim() || 'Candidate', phone.trim());
  };

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: palette.bg }]}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.frame}>
          {/* Quiet Header Row */}
          <View style={styles.topRow}>
            <Prep404Logo isDark={isDark} />
            <View style={styles.topControls}>
              <TouchableOpacity
                onPress={() => setLanguage(language === 'english' ? 'bangla' : 'english')}
                accessibilityRole="button"
                accessibilityLabel="Switch language"
                style={[
                  styles.utilBtn,
                  { borderColor: palette.border, backgroundColor: palette.surface },
                ]}
              >
                <Text style={[styles.utilBtnText, { color: palette.text }]}>
                  {language === 'english' ? 'বাংলা' : 'EN'}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={toggleTheme}
                accessibilityRole="button"
                accessibilityLabel="Toggle color theme"
                style={[
                  styles.utilBtn,
                  { borderColor: palette.border, backgroundColor: palette.surface },
                ]}
              >
                {isDark ? (
                  <Sun size={16} color={palette.amber} weight="fill" />
                ) : (
                  <Moon size={16} color={palette.text} weight="fill" />
                )}
              </TouchableOpacity>
            </View>
          </View>

          {/* Editorial Headline */}
          <View style={styles.heroCopy}>
            <Text style={[styles.heroTitle, { color: palette.text }]}>
              {strings.isBangla
                ? 'NSU, BRACU, AUST ও AIUB ভর্তির পূর্ণাঙ্গ প্রস্তুতি'
                : 'Crack your target private university test.'}
            </Text>
            <Text style={[styles.heroSub, { color: palette.textMuted }]}>
              {strings.isBangla
                ? 'দৈনিক লাইভ মডেল টেস্ট, সফটওয়্যার OMR ও FSRS স্পেসড রিপিটেশন।'
                : 'Daily ranked model tests, authentic Software OMR sheets, and adaptive FSRS practice.'}
            </Text>
          </View>

          {/* Primary Auth Surface */}
          <EditorialCard>
            {/* Primary Real Google OAuth (Supabase Auth) */}
            <View style={styles.googleBlock}>
              <ScalePressable
                onPress={handleGoogleAuth}
                disabled={isGoogleAuthLoading}
                accessibilityLabel="Continue with Google"
                style={[
                  styles.googleBtn,
                  {
                    borderColor: palette.borderStrong,
                    backgroundColor: palette.surface,
                    opacity: isGoogleAuthLoading ? 0.72 : 1,
                  },
                ]}
              >
                {isGoogleAuthLoading ? (
                  <ActivityIndicator size="small" color={palette.primary} />
                ) : (
                  <GoogleMark size={18} />
                )}
                <Text style={[styles.googleBtnText, { color: palette.text }]}>
                  {isGoogleAuthLoading
                    ? strings.isBangla
                      ? 'Google দিয়ে সংযুক্ত হচ্ছে...'
                      : 'Connecting with Google...'
                    : strings.isBangla
                      ? 'Google অ্যাকাউন্ট দিয়ে চালিয়ে যান'
                      : 'Continue with Google'}
                </Text>
              </ScalePressable>

              {(oauthNotice || authCallbackError) ? (
                <Text
                  style={[
                    styles.notice,
                    { color: palette.textMuted, backgroundColor: palette.warningSoft },
                  ]}
                >
                  {oauthNotice || authCallbackError}
                </Text>
              ) : null}
            </View>

            <View style={styles.orRow}>
              <View style={[styles.orLine, { backgroundColor: palette.border }]} />
              <Text style={[styles.orText, { color: palette.textSubtle }]}>
                {strings.isBangla ? 'অথবা মোবাইল নম্বর' : 'OR CONTINUE WITH PHONE'}
              </Text>
              <View style={[styles.orLine, { backgroundColor: palette.border }]} />
            </View>

            <SegmentedControl
              value={mode}
              onChange={(m) => {
                setMode(m);
                setErrorMsg(null);
              }}
              options={[
                { id: 'signup', label: strings.signUpTab },
                { id: 'signin', label: strings.signInTab },
              ]}
            />

            {!otpSent ? (
              <View style={styles.form}>
                {mode === 'signup' && (
                  <View style={styles.fieldGroup}>
                    <Text style={[styles.label, { color: palette.textMuted }]}>
                      {strings.fullNameLabel}
                    </Text>
                    <TextInput
                      value={fullName}
                      onChangeText={setFullName}
                      placeholder={strings.fullNameHint}
                      placeholderTextColor={palette.textSubtle}
                      style={[
                        styles.input,
                        {
                          color: palette.text,
                          borderColor: palette.border,
                          backgroundColor: palette.surfaceMuted,
                        },
                      ]}
                    />
                  </View>
                )}

                <View style={styles.fieldGroup}>
                  <Text style={[styles.label, { color: palette.textMuted }]}>
                    {strings.phoneLabel}
                  </Text>
                  <TextInput
                    value={phone}
                    onChangeText={setPhone}
                    keyboardType="phone-pad"
                    placeholder={strings.phoneHint}
                    placeholderTextColor={palette.textSubtle}
                    style={[
                      styles.input,
                      styles.monoInput,
                      {
                        color: palette.text,
                        borderColor: palette.border,
                        backgroundColor: palette.surfaceMuted,
                      },
                    ]}
                  />
                </View>

                {errorMsg && (
                  <Text style={[styles.errorText, { color: palette.danger }]}>
                    {errorMsg}
                  </Text>
                )}

                <ScalePressable
                  onPress={handleSendOtp}
                  accessibilityLabel={strings.sendOtpBtn}
                  style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
                >
                  <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
                    {strings.sendOtpBtn}
                  </Text>
                </ScalePressable>
              </View>
            ) : (
              <View style={styles.form}>
                <Text style={[styles.label, { color: palette.textMuted }]}>
                  OTP → {phone} (Preview code: 1234)
                </Text>
                <TextInput
                  value={otpCode}
                  onChangeText={setOtpCode}
                  maxLength={4}
                  keyboardType="number-pad"
                  placeholder="1234"
                  placeholderTextColor={palette.textSubtle}
                  style={[
                    styles.input,
                    styles.otpInput,
                    {
                      color: palette.text,
                      borderColor: palette.border,
                      backgroundColor: palette.surfaceMuted,
                    },
                  ]}
                />
                {errorMsg && (
                  <Text style={[styles.errorText, { color: palette.danger }]}>
                    {errorMsg}
                  </Text>
                )}
                <ScalePressable
                  onPress={handleVerifyOtp}
                  accessibilityLabel={strings.verifyOtpBtn}
                  style={[styles.primaryBtn, { backgroundColor: PREP404_COLORS.plum }]}
                >
                  <Text style={[styles.primaryBtnText, { color: '#FFFFFF' }]}>
                    {strings.verifyOtpBtn}
                  </Text>
                </ScalePressable>
                <TouchableOpacity
                  onPress={() => setOtpSent(false)}
                  style={styles.changeTouch}
                >
                  <Text style={[styles.changeLink, { color: palette.primary }]}>
                    Change Phone Number
                  </Text>
                </TouchableOpacity>
              </View>
            )}

            <View style={[styles.dividerRow, { borderTopColor: palette.border }]}>
              <ScalePressable
                onPress={loginAsGuest}
                accessibilityLabel={strings.demoLoginBtn}
                style={[
                  styles.guestBtn,
                  { borderColor: palette.borderStrong, backgroundColor: palette.surface },
                ]}
              >
                <Text style={[styles.guestBtnText, { color: palette.text }]}>
                  {strings.demoLoginBtn}
                </Text>
              </ScalePressable>
            </View>
          </EditorialCard>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: 18,
    paddingVertical: 20,
    justifyContent: 'center',
  },
  frame: {
    width: '100%',
    maxWidth: 480,
    alignSelf: 'center',
    gap: 18,
  },
  topRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  topControls: { flexDirection: 'row', gap: 8 },
  utilBtn: {
    minWidth: 44,
    height: 40,
    paddingHorizontal: 12,
    borderRadius: 10,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  utilBtnText: { fontFamily: TYPE_FONTS.body, fontSize: 12.5, fontWeight: '700' },
  heroCopy: { gap: 8, paddingTop: 4 },
  heroTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 28,
    fontWeight: '800',
    lineHeight: 34,
    letterSpacing: -0.4,
  },
  heroSub: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 14,
    lineHeight: 21,
  },
  googleBlock: { gap: 10 },
  googleBtn: {
    height: 48,
    borderRadius: RADII.md,
    borderWidth: 1.5,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    paddingHorizontal: 16,
  },
  googleBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 14.5,
    fontWeight: '700',
  },
  orRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginVertical: 2,
  },
  orLine: { flex: 1, height: 1 },
  orText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.6,
  },
  form: { gap: 12 },
  fieldGroup: { gap: 6 },
  label: { fontFamily: TYPE_FONTS.body, fontSize: 12.5, fontWeight: '600' },
  input: {
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    height: 48,
    fontFamily: TYPE_FONTS.body,
    fontSize: 14.5,
  },
  monoInput: {
    fontFamily: TYPE_FONTS.mono,
    fontVariant: ['tabular-nums'],
  },
  otpInput: {
    fontFamily: TYPE_FONTS.mono,
    textAlign: 'center',
    fontSize: 22,
    fontWeight: '700',
    letterSpacing: 10,
  },
  errorText: { fontSize: 12.5, fontWeight: '600' },
  primaryBtn: {
    height: 48,
    borderRadius: RADII.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  primaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 14.5,
    fontWeight: '700',
  },
  changeTouch: { minHeight: 40, justifyContent: 'center', alignItems: 'center' },
  changeLink: { fontSize: 13, fontWeight: '700' },
  dividerRow: {
    borderTopWidth: 1,
    paddingTop: 14,
    gap: 10,
  },
  notice: {
    fontSize: 12,
    padding: 10,
    borderRadius: 10,
    lineHeight: 17,
  },
  guestBtn: {
    borderWidth: 1,
    borderRadius: RADII.md,
    height: 46,
    alignItems: 'center',
    justifyContent: 'center',
  },
  guestBtnText: { fontSize: 13.5, fontWeight: '700' },
});
