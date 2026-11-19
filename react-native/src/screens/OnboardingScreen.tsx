import React, { useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CaretRight, Check } from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import {
  BANGLADESH_DISTRICTS,
  BANGLADESH_DIVISIONS,
  ENGLISH_MEDIUM_INSTS,
  NCTB_COLLEGES,
  NCTB_SCHOOLS,
  UNIVERSITY_CATALOG,
} from '../data/universities';
import {
  EnglishCurriculum,
  NctbVersion,
  StudentMedium,
  UserProfile,
} from '../types';
import { RADII, TYPE_FONTS } from '../theme/colors';
import { UniversityLogo } from '../components/UniversityLogo';
import {
  BottomSheetModal,
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';

interface OnboardingScreenProps {
  isEditMode?: boolean;
  initialStep?: number;
  onDone?: () => void;
}

export const OnboardingScreen: React.FC<OnboardingScreenProps> = ({
  isEditMode = false,
  initialStep = 0,
  onDone,
}) => {
  const {
    profile,
    pendingIdentity,
    palette,
    strings,
    completeOnboarding,
    updateProfile,
    goBack,
  } = useApp();

  const [step, setStep] = useState(initialStep);
  const [medium, setMedium] = useState<StudentMedium>(profile?.medium || 'bangla');
  const [nctbVersion, setNctbVersion] = useState<NctbVersion>(
    profile?.nctbVersion || 'bangla'
  );
  const [englishCurriculum, setEnglishCurriculum] = useState<EnglishCurriculum>(
    profile?.englishCurriculum || 'cambridge'
  );

  const [name, setName] = useState(profile?.name || pendingIdentity?.name || '');
  const [phone, setPhone] = useState(profile?.phone || pendingIdentity?.phone || '');
  const [gender, setGender] = useState<'male' | 'female' | 'other'>(
    profile?.gender || 'male'
  );
  const [divisionId, setDivisionId] = useState(profile?.divisionId || 'dhaka');
  const [districtId, setDistrictId] = useState(profile?.districtId || 'dhaka_dist');
  const [sscGpa, setSscGpa] = useState(profile?.sscGpa || '5.00');
  const [hscBatch, setHscBatch] = useState(profile?.hscBatch || "HSC '25");
  const [hscGpa, setHscGpa] = useState(profile?.hscGpa || '5.00');
  const [institution, setInstitution] = useState(
    profile?.institutionName || 'Notre Dame College, Dhaka'
  );
  const [instModalOpen, setInstModalOpen] = useState(false);
  const [instQuery, setInstQuery] = useState('');

  const [targetSelections, setTargetSelections] = useState<Record<string, string[]>>(
    profile?.targetSelections && Object.keys(profile.targetSelections).length > 0
      ? profile.targetSelections
      : { brac: ['brac_cse'], nsu: ['nsu_cse'] }
  );
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const districts = useMemo(
    () => BANGLADESH_DISTRICTS.filter((d) => d.divisionId === divisionId),
    [divisionId]
  );

  const instPool = useMemo(() => {
    const base =
      medium === 'english'
        ? ENGLISH_MEDIUM_INSTS
        : [...NCTB_COLLEGES, ...NCTB_SCHOOLS];
    const q = instQuery.trim().toLowerCase();
    if (!q) return base;
    return base.filter(
      (i) =>
        i.nameEn.toLowerCase().includes(q) || i.eiin.toLowerCase().includes(q)
    );
  }, [medium, instQuery]);

  const toggleDiscipline = (uniId: string, discId: string) => {
    setTargetSelections((prev) => {
      const cur = prev[uniId] || [];
      const next = cur.includes(discId)
        ? cur.filter((x) => x !== discId)
        : [...cur, discId];
      const copy = { ...prev };
      if (next.length === 0) delete copy[uniId];
      else copy[uniId] = next;
      return copy;
    });
  };

  const handleNext = () => {
    setErrorMsg(null);
    if (step === 1) {
      if (!name.trim()) {
        setErrorMsg('Please enter your name.');
        return;
      }
      const cleanedPhone = phone.replace(/\s|-/g, '');
      const isGoogleSignUp = pendingIdentity?.authProvider === 'google';
      if ((!isGoogleSignUp || cleanedPhone.length > 0) && !/^01[3-9]\d{8}$/.test(cleanedPhone)) {
        setErrorMsg(strings.invalidPhoneMsg);
        return;
      }
    }
    setStep((s) => Math.min(2, s + 1));
  };

  const handleFinish = () => {
    const total = Object.values(targetSelections).reduce((a, b) => a + b.length, 0);
    if (total === 0) {
      setErrorMsg(strings.missingTargetUniMsg);
      return;
    }
    const divObj = BANGLADESH_DIVISIONS.find((d) => d.id === divisionId);
    const distObj = BANGLADESH_DISTRICTS.find((d) => d.id === districtId);

    const nextProfile: UserProfile = {
      id: profile?.id || pendingIdentity?.userId || `usr_${Date.now()}`,
      name: name.trim() || 'Candidate',
      phone: phone.trim(),
      email: profile?.email || pendingIdentity?.email,
      avatarUrl: profile?.avatarUrl || pendingIdentity?.avatarUrl,
      authProvider: profile?.authProvider || pendingIdentity?.authProvider || 'phone',
      gender,
      divisionId,
      divisionName: divObj?.nameEn || 'Dhaka',
      districtId,
      districtName: distObj?.nameEn || 'Dhaka',
      medium,
      nctbVersion: medium === 'bangla' ? nctbVersion : null,
      englishCurriculum: medium === 'english' ? englishCurriculum : null,
      academicBatch: medium === 'bangla' ? hscBatch : 'A-Level 2025',
      institutionName: institution || 'Dhaka College',
      sscGpa,
      hscGpa,
      hscBatch,
      studyStreakDays: profile?.studyStreakDays ?? 0,
      targetSelections,
    };

    if (isEditMode) {
      updateProfile(nextProfile);
      if (onDone) onDone();
      else goBack();
    } else {
      completeOnboarding(nextProfile);
    }
  };

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: palette.bg }]}>
      <ScrollView
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.frame}>
          {/* Progress Header */}
          <View style={styles.stepHeader}>
            <View style={styles.headerRow}>
              <Text style={[styles.title, { color: palette.text }]}>
                {isEditMode ? strings.editAdmissionProfile : strings.onboardingTitle}
              </Text>
              <Text style={[styles.stepMeta, { color: palette.primary }]}>
                Step {step + 1} of 3
              </Text>
            </View>
            <View style={[styles.progressTrack, { backgroundColor: palette.surfaceMuted }]}>
              <View
                style={[
                  styles.progressFill,
                  {
                    width: `${((step + 1) / 3) * 100}%`,
                    backgroundColor: palette.primary,
                  },
                ]}
              />
            </View>
          </View>

          <SegmentedControl
            value={String(step) as '0' | '1' | '2'}
            onChange={(val) => {
              const target = Number(val);
              if (target <= step || isEditMode) setStep(target);
            }}
            options={[
              { id: '0', label: strings.step1Title },
              { id: '1', label: strings.step2Title },
              { id: '2', label: strings.step3Title },
            ]}
          />

          <EditorialCard>
            {step === 0 && (
              <View style={styles.section}>
                <Text style={[styles.h2, { color: palette.text }]}>
                  {strings.chooseMediumTitle}
                </Text>
                {(
                  [
                    {
                      id: 'bangla' as StudentMedium,
                      title: strings.banglaMediumTitle,
                      sub: strings.banglaMediumSubtitle,
                    },
                    {
                      id: 'english' as StudentMedium,
                      title: strings.englishMediumTitle,
                      sub: strings.englishMediumSubtitle,
                    },
                  ] as const
                ).map((m) => {
                  const selected = medium === m.id;
                  return (
                    <TouchableOpacity
                      key={m.id}
                      onPress={() => setMedium(m.id)}
                      accessibilityRole="button"
                      style={[
                        styles.choiceCard,
                        {
                          borderColor: selected ? palette.primary : palette.border,
                          backgroundColor: selected
                            ? palette.creamTint
                            : palette.surface,
                        },
                      ]}
                    >
                      <View style={{ flex: 1, gap: 2 }}>
                        <Text style={[styles.choiceTitle, { color: palette.text }]}>
                          {m.title}
                        </Text>
                        <Text style={[styles.choiceSub, { color: palette.textMuted }]}>
                          {m.sub}
                        </Text>
                      </View>
                      <View
                        style={[
                          styles.checkCircle,
                          {
                            borderColor: selected ? palette.primary : palette.borderStrong,
                            backgroundColor: selected ? palette.primary : 'transparent',
                          },
                        ]}
                      >
                        {selected && <Check size={14} color={palette.primaryInk} weight="bold" />}
                      </View>
                    </TouchableOpacity>
                  );
                })}

                {medium === 'bangla' ? (
                  <SegmentedControl
                    value={nctbVersion}
                    onChange={setNctbVersion}
                    options={[
                      { id: 'bangla', label: strings.banglaVersionTitle },
                      { id: 'english', label: strings.englishVersionTitle },
                    ]}
                  />
                ) : (
                  <SegmentedControl
                    value={englishCurriculum}
                    onChange={setEnglishCurriculum}
                    options={[
                      { id: 'cambridge', label: 'Cambridge (CAIE)' },
                      { id: 'edexcel', label: 'Pearson Edexcel' },
                    ]}
                  />
                )}
              </View>
            )}

            {step === 1 && (
              <View style={styles.section}>
                <Text style={[styles.h2, { color: palette.text }]}>
                  {strings.academicInfoTitle}
                </Text>
                {(profile?.email || pendingIdentity?.email) ? (
                  <Text style={[styles.smallLabel, { color: palette.primary }]}>
                    Google Account: {profile?.email || pendingIdentity?.email}
                  </Text>
                ) : null}
                <TextInput
                  value={name}
                  onChangeText={setName}
                  placeholder={strings.candidateNameHint}
                  placeholderTextColor={palette.textSubtle}
                  style={[
                    styles.input,
                    { color: palette.text, borderColor: palette.border, backgroundColor: palette.surfaceMuted },
                  ]}
                />
                <TextInput
                  value={phone}
                  onChangeText={setPhone}
                  keyboardType="phone-pad"
                  placeholder={
                    pendingIdentity?.authProvider === 'google'
                      ? `${strings.confirmMobileHint} (Optional)`
                      : strings.confirmMobileHint
                  }
                  placeholderTextColor={palette.textSubtle}
                  style={[
                    styles.input,
                    { color: palette.text, borderColor: palette.border, backgroundColor: palette.surfaceMuted },
                  ]}
                />

                <SegmentedControl
                  value={gender}
                  onChange={setGender}
                  options={[
                    { id: 'male', label: strings.maleGender },
                    { id: 'female', label: strings.femaleGender },
                    { id: 'other', label: strings.otherGender },
                  ]}
                />

                <Text style={[styles.smallLabel, { color: palette.textMuted }]}>
                  {strings.divisionLabel}
                </Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                  <View style={styles.chipWrap}>
                    {BANGLADESH_DIVISIONS.map((d) => {
                      const active = divisionId === d.id;
                      return (
                        <TouchableOpacity
                          key={d.id}
                          onPress={() => {
                            setDivisionId(d.id);
                            const first = BANGLADESH_DISTRICTS.find(
                              (x) => x.divisionId === d.id
                            );
                            if (first) setDistrictId(first.id);
                          }}
                          style={[
                            styles.chip,
                            {
                              borderColor: active ? palette.primary : palette.border,
                              backgroundColor: active ? palette.creamTint : palette.surface,
                            },
                          ]}
                        >
                          <Text
                            style={{
                              color: active ? palette.primary : palette.text,
                              fontSize: 12.5,
                              fontWeight: '700',
                            }}
                          >
                            {d.nameEn}
                          </Text>
                        </TouchableOpacity>
                      );
                    })}
                  </View>
                </ScrollView>

                <Text style={[styles.smallLabel, { color: palette.textMuted }]}>
                  {strings.districtLabel}
                </Text>
                <View style={styles.chipWrap}>
                  {districts.map((dist) => {
                    const active = districtId === dist.id;
                    return (
                      <TouchableOpacity
                        key={dist.id}
                        onPress={() => setDistrictId(dist.id)}
                        style={[
                          styles.chip,
                          {
                            borderColor: active ? palette.primary : palette.border,
                            backgroundColor: active ? palette.creamTint : palette.surface,
                          },
                        ]}
                      >
                        <Text
                          style={{
                            color: active ? palette.primary : palette.text,
                            fontSize: 12.5,
                            fontWeight: '700',
                          }}
                        >
                          {dist.nameEn}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                <View style={styles.rowGap}>
                  <TextInput
                    value={sscGpa}
                    onChangeText={setSscGpa}
                    placeholder="SSC GPA (5.00)"
                    placeholderTextColor={palette.textSubtle}
                    style={[
                      styles.input,
                      {
                        flex: 1,
                        color: palette.text,
                        borderColor: palette.border,
                        backgroundColor: palette.surfaceMuted,
                      },
                    ]}
                  />
                  <TextInput
                    value={hscGpa}
                    onChangeText={setHscGpa}
                    placeholder="HSC GPA"
                    placeholderTextColor={palette.textSubtle}
                    style={[
                      styles.input,
                      {
                        flex: 1,
                        color: palette.text,
                        borderColor: palette.border,
                        backgroundColor: palette.surfaceMuted,
                      },
                    ]}
                  />
                </View>

                <TextInput
                  value={hscBatch}
                  onChangeText={setHscBatch}
                  placeholder="Batch (HSC '25)"
                  placeholderTextColor={palette.textSubtle}
                  style={[
                    styles.input,
                    { color: palette.text, borderColor: palette.border, backgroundColor: palette.surfaceMuted },
                  ]}
                />

                <TouchableOpacity
                  onPress={() => setInstModalOpen(true)}
                  style={[
                    styles.selectTrigger,
                    { borderColor: palette.border, backgroundColor: palette.surfaceMuted },
                  ]}
                >
                  <Text
                    style={{ color: palette.text, fontSize: 13.5, fontWeight: '600', flex: 1 }}
                    numberOfLines={1}
                  >
                    {institution || strings.selectCollegeHint}
                  </Text>
                  <CaretRight size={18} color={palette.textMuted} weight="bold" />
                </TouchableOpacity>
              </View>
            )}

            {step === 2 && (
              <View style={styles.section}>
                <Text style={[styles.h2, { color: palette.text }]}>
                  {strings.targetUniTitle}
                </Text>
                {UNIVERSITY_CATALOG.map((uni) => {
                  const picked = targetSelections[uni.id] || [];
                  return (
                    <View
                      key={uni.id}
                      style={[
                        styles.uniBox,
                        {
                          borderColor:
                            picked.length > 0 ? palette.primary : palette.border,
                          backgroundColor: palette.surface,
                        },
                      ]}
                    >
                      <View style={styles.uniHeader}>
                        <UniversityLogo code={uni.code} size="sm" />
                        <View style={{ flex: 1 }}>
                          <Text style={[styles.choiceTitle, { color: palette.text }]}>
                            {uni.code} · {uni.fullName}
                          </Text>
                          <Text style={[styles.choiceSub, { color: palette.textMuted }]}>
                            {uni.examPatternSummary}
                          </Text>
                        </View>
                      </View>
                      <View style={styles.chipWrap}>
                        {uni.disciplines.map((d) => {
                          const active = picked.includes(d.id);
                          return (
                            <TouchableOpacity
                              key={d.id}
                              onPress={() => toggleDiscipline(uni.id, d.id)}
                              style={[
                                styles.chip,
                                {
                                  backgroundColor: active
                                    ? palette.primary
                                    : palette.surfaceMuted,
                                  borderColor: active
                                    ? palette.primary
                                    : palette.border,
                                },
                              ]}
                            >
                              <Text
                                style={{
                                  color: active ? palette.primaryInk : palette.text,
                                  fontSize: 11.5,
                                  fontWeight: '700',
                                }}
                              >
                                {d.name}
                              </Text>
                            </TouchableOpacity>
                          );
                        })}
                      </View>
                    </View>
                  );
                })}
              </View>
            )}

            {errorMsg && (
              <Text style={[styles.errorText, { color: palette.danger }]}>{errorMsg}</Text>
            )}

            <View style={styles.footerRow}>
              <TouchableOpacity
                disabled={step === 0}
                onPress={() => setStep((s) => Math.max(0, s - 1))}
                style={[
                  styles.outlineBtn,
                  {
                    borderColor: palette.borderStrong,
                    opacity: step === 0 ? 0.4 : 1,
                  },
                ]}
              >
                <Text style={{ color: palette.text, fontWeight: '700', fontSize: 13.5 }}>
                  {strings.prevBtn}
                </Text>
              </TouchableOpacity>

              <ScalePressable
                onPress={step < 2 ? handleNext : handleFinish}
                style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
              >
                <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
                  {step < 2
                    ? strings.nextBtn
                    : isEditMode
                      ? strings.saveChanges
                      : strings.startPrepBtn}
                </Text>
              </ScalePressable>
            </View>
          </EditorialCard>
        </View>
      </ScrollView>

      <BottomSheetModal
        visible={instModalOpen}
        onClose={() => setInstModalOpen(false)}
        title="Select Institution"
        subtitle="Search NCTB colleges, schools, or English medium campuses"
      >
        <TextInput
          value={instQuery}
          onChangeText={setInstQuery}
          placeholder="Search college, school, or EIIN..."
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
        <View style={{ marginTop: 4 }}>
          {instPool.map((item, idx) => (
            <HairlineRow
              key={item.id}
              isLast={idx === instPool.length - 1}
              onPress={() => {
                setInstitution(item.nameEn);
                setInstModalOpen(false);
              }}
              left={
                <>
                  <Text style={{ color: palette.text, fontWeight: '700', fontSize: 13.5 }}>
                    {item.nameEn}
                  </Text>
                  <Text style={{ color: palette.textMuted, fontSize: 11.5 }}>
                    EIIN: {item.eiin} {item.area ? `· ${item.area}` : ''}
                  </Text>
                </>
              }
              right={<CaretRight size={16} color={palette.textMuted} weight="bold" />}
            />
          ))}
        </View>
      </BottomSheetModal>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: { flex: 1 },
  container: { padding: 16, paddingBottom: 32 },
  frame: { width: '100%', maxWidth: 680, alignSelf: 'center', gap: 14 },
  stepHeader: { gap: 8 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  title: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 18,
    fontWeight: '700',
    flex: 1,
  },
  stepMeta: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontSize: 12.5,
    fontVariant: ['tabular-nums'],
  },
  progressTrack: { height: 6, borderRadius: 3, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 3 },
  section: { gap: 12 },
  h2: { fontFamily: TYPE_FONTS.display, fontSize: 16.5, fontWeight: '700' },
  choiceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderWidth: 1.5,
    borderRadius: RADII.lg,
    padding: 14,
    minHeight: 64,
  },
  choiceTitle: { fontFamily: TYPE_FONTS.display, fontSize: 14, fontWeight: '700' },
  choiceSub: { fontSize: 12.5, lineHeight: 17 },
  checkCircle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowGap: { flexDirection: 'row', gap: 10 },
  smallLabel: { fontSize: 12, fontWeight: '600', marginTop: 2 },
  input: {
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    height: 46,
    fontSize: 13.5,
  },
  selectTrigger: {
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    height: 46,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
  },
  chipWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    minHeight: 38,
    justifyContent: 'center',
  },
  uniBox: { borderWidth: 1, borderRadius: RADII.lg, padding: 14, gap: 10 },
  uniHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  errorText: { fontSize: 12.5, fontWeight: '600' },
  footerRow: { flexDirection: 'row', gap: 10, marginTop: 4 },
  outlineBtn: {
    flex: 1,
    borderWidth: 1,
    borderRadius: RADII.md,
    height: 46,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryBtn: {
    flex: 1.4,
    borderRadius: RADII.md,
    height: 46,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryBtnText: { fontFamily: TYPE_FONTS.display, fontWeight: '700', fontSize: 14 },
});
