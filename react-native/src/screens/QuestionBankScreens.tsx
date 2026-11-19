import React, { useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { BookmarkSimple, CaretRight, MagnifyingGlass } from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { getUniversityBlueprint, UNIVERSITY_CATALOG } from '../data/universities';
import { getChaptersForSubject, MODEL_TESTS_CATALOG } from '../data/questionBank';
import { storageService } from '../services/storageService';
import { RADII, TYPE_FONTS } from '../theme/colors';
import { UniversityLogo } from '../components/UniversityLogo';
import {
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';

const SUBJECTS = [
  { slug: 'higher_math', title: 'Higher Mathematics', color: '#F28C28', tag: 'HM' },
  { slug: 'quant_math', title: 'Quantitative Aptitude', color: '#45204F', tag: 'QA' },
  { slug: 'physics', title: 'Physics', color: '#2563EB', tag: 'PH' },
  { slug: 'chemistry', title: 'Chemistry', color: '#059669', tag: 'CH' },
  { slug: 'biology', title: 'Biology', color: '#7C3AED', tag: 'BI' },
  { slug: 'english', title: 'English & Verbal', color: '#D97706', tag: 'EN' },
];

export const QuestionBankScreen: React.FC = () => {
  const { palette, strings, navigate } = useApp();
  const [tab, setTab] = useState<'uni' | 'subject' | 'mock'>('uni');
  const [query, setQuery] = useState('');
  const bookmarksCount = storageService.getBookmarks().length;

  const q = query.trim().toLowerCase();
  const unis = UNIVERSITY_CATALOG.filter(
    (u) =>
      !q ||
      u.code.toLowerCase().includes(q) ||
      u.fullName.toLowerCase().includes(q)
  );
  const subs = SUBJECTS.filter((s) => !q || s.title.toLowerCase().includes(q));
  const mocks = MODEL_TESTS_CATALOG.filter(
    (m) => !q || m.title.toLowerCase().includes(q) || m.track.toLowerCase().includes(q)
  );

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.rowBetween}>
        <Text style={[styles.h1, { color: palette.text }]}>
          {strings.navQuestionBank}
        </Text>
        <TouchableOpacity
          onPress={() => navigate({ name: 'practice', subjectId: 'bookmarked' })}
          accessibilityRole="button"
          accessibilityLabel={`Saved bookmarks, ${bookmarksCount}`}
          style={[
            styles.bookmarkBtn,
            { borderColor: palette.border, backgroundColor: palette.surface },
          ]}
        >
          <BookmarkSimple size={14} color={palette.primary} weight="fill" />
          <Text style={[styles.bookmarkText, { color: palette.text }]}>
            Saved ({bookmarksCount})
          </Text>
        </TouchableOpacity>
      </View>

      <View
        style={[
          styles.searchWrap,
          { borderColor: palette.border, backgroundColor: palette.surface },
        ]}
      >
        <MagnifyingGlass size={17} color={palette.textMuted} weight="regular" />
        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Search university, subject or mock..."
          placeholderTextColor={palette.textSubtle}
          style={[styles.searchInput, { color: palette.text }]}
        />
      </View>

      <SegmentedControl
        value={tab}
        onChange={setTab}
        options={[
          { id: 'uni', label: 'Universities' },
          { id: 'subject', label: 'Subjects' },
          { id: 'mock', label: 'Model Tests' },
        ]}
      />

      {tab === 'uni' && (
        <EditorialCard style={styles.listCard}>
          {unis.map((u, idx) => (
            <HairlineRow
              key={u.id}
              isLast={idx === unis.length - 1}
              onPress={() =>
                navigate({ name: 'universityDetail', universityCode: u.code })
              }
              accessibilityLabel={`${u.code} ${u.fullName}`}
              left={
                <View style={styles.rowLead}>
                  <UniversityLogo code={u.code} size="md" />
                  <View style={{ flex: 1, gap: 2 }}>
                    <Text style={[styles.cardTitle, { color: palette.text }]}>
                      {u.code} · {u.fullName}
                    </Text>
                    <Text
                      style={{ color: palette.textMuted, fontSize: 12 }}
                      numberOfLines={1}
                    >
                      {u.examPatternSummary}
                    </Text>
                  </View>
                </View>
              }
              right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
            />
          ))}
        </EditorialCard>
      )}

      {tab === 'subject' && (
        <EditorialCard style={styles.listCard}>
          {subs.map((s, idx) => (
            <HairlineRow
              key={s.slug}
              isLast={idx === subs.length - 1}
              onPress={() =>
                navigate({
                  name: 'subjectDirectory',
                  subjectSlug: s.slug,
                  subjectTitle: s.title,
                })
              }
              accessibilityLabel={s.title}
              left={
                <View style={styles.rowLead}>
                  <View style={[styles.monogram, { backgroundColor: s.color }]}>
                    <Text style={{ color: '#FFFFFF', fontWeight: '800', fontSize: 12 }}>
                      {s.tag}
                    </Text>
                  </View>
                  <View style={{ flex: 1, gap: 2 }}>
                    <Text style={[styles.cardTitle, { color: palette.text }]}>
                      {s.title}
                    </Text>
                    <Text style={{ color: palette.textMuted, fontSize: 12 }}>
                      Browse chapters & FSRS practice drills
                    </Text>
                  </View>
                </View>
              }
              right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
            />
          ))}
        </EditorialCard>
      )}

      {tab === 'mock' && (
        <View style={styles.mockList}>
          {mocks.map((m) => (
            <EditorialCard key={m.id}>
              <View style={{ gap: 4 }}>
                <Text style={[styles.cardTitle, { color: palette.text }]}>
                  {m.title}
                </Text>
                <Text style={[styles.monoSub, { color: palette.textMuted }]}>
                  {m.track} · {m.questionCount} Qs · {m.durationMinutes} min · Neg {m.negativeMark}
                </Text>
              </View>
              <ScalePressable
                onPress={() =>
                  navigate({
                    name: 'liveExam',
                    slug: m.slug,
                    title: m.title,
                    durationMinutes: m.durationMinutes,
                    negativeMark: m.negativeMark,
                  })
                }
                style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
              >
                <Text style={[styles.btnText, { color: palette.primaryInk }]}>
                  {strings.launchModelTest}
                </Text>
              </ScalePressable>
            </EditorialCard>
          ))}
        </View>
      )}
    </ScrollView>
  );
};

export const UniversityDetailScreen: React.FC<{ universityCode: string }> = ({
  universityCode,
}) => {
  const { palette, strings, navigate } = useApp();
  const uni =
    UNIVERSITY_CATALOG.find(
      (u) => u.code.toUpperCase() === universityCode.toUpperCase()
    ) || UNIVERSITY_CATALOG[0];
  const [discIdx, setDiscIdx] = useState(0);
  const disc = uni.disciplines[discIdx] || uni.disciplines[0];
  const blueprint = getUniversityBlueprint(uni.code, disc.category);

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <View style={styles.rowLead}>
          <UniversityLogo code={uni.code} size="lg" />
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.h1, { color: palette.text }]}>
              {uni.code} · {uni.fullName}
            </Text>
            <Text style={[styles.monoSub, { color: palette.textMuted }]}>
              {blueprint.totalQuestions} MCQs · {blueprint.durationMinutes} min · Neg {blueprint.negativeMarking}
            </Text>
          </View>
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={styles.chipRow}>
            {uni.disciplines.map((d, i) => {
              const active = i === discIdx;
              return (
                <TouchableOpacity
                  key={d.id}
                  onPress={() => setDiscIdx(i)}
                  style={[
                    styles.chipBtn,
                    {
                      backgroundColor: active ? palette.creamTint : palette.surfaceMuted,
                      borderColor: active ? palette.primary : palette.border,
                    },
                  ]}
                >
                  <Text
                    style={{
                      color: active ? palette.primary : palette.text,
                      fontSize: 12,
                      fontWeight: '700',
                    }}
                  >
                    {d.name}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </ScrollView>

        <ScalePressable
          onPress={() =>
            navigate({
              name: 'liveExam',
              slug: `${uni.code.toLowerCase()}-${disc.id}-mock`,
              title: `${uni.code} ${disc.name} Blueprint Mock`,
              durationMinutes: 35,
              negativeMark: blueprint.negativeMarking,
            })
          }
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.btnText, { color: palette.primaryInk }]}>
            {strings.launchModelTest}
          </Text>
        </ScalePressable>
      </EditorialCard>

      <EditorialCard style={styles.listCard}>
        {blueprint.sections.map((sec, idx) => (
          <HairlineRow
            key={sec.name}
            isLast={idx === blueprint.sections.length - 1}
            onPress={() =>
              navigate({
                name: 'practice',
                subjectId: sec.name.split(' ')[0],
                title: `${uni.code}: ${sec.name}`,
              })
            }
            left={
              <View style={{ gap: 3 }}>
                <Text style={[styles.cardTitle, { color: palette.text }]}>
                  {sec.name}
                </Text>
                <Text style={[styles.monoSub, { color: palette.textMuted }]}>
                  {sec.questionCount} MCQs · {sec.marks} Marks · {sec.weightPercent}%
                </Text>
              </View>
            }
            right={
              <Text style={[styles.accentLink, { color: palette.primary }]}>
                Practice →
              </Text>
            }
          />
        ))}
      </EditorialCard>
    </ScrollView>
  );
};

export const SubjectDirectoryScreen: React.FC<{
  subjectSlug: string;
  subjectTitle: string;
}> = ({ subjectSlug, subjectTitle }) => {
  const { palette, navigate } = useApp();
  const chapters = useMemo(() => getChaptersForSubject(subjectSlug), [subjectSlug]);

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <Text style={[styles.h1, { color: palette.text }]}>{subjectTitle}</Text>
      <ScalePressable
        onPress={() =>
          navigate({ name: 'practice', subjectId: subjectSlug, title: subjectTitle })
        }
        style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
      >
        <Text style={[styles.btnText, { color: palette.primaryInk }]}>
          Start Full {subjectTitle} Practice
        </Text>
      </ScalePressable>

      {chapters.map((ch) => (
        <EditorialCard key={ch.title}>
          <Text style={[styles.cardTitle, { color: palette.text }]}>{ch.title}</Text>
          <View style={styles.chipWrap}>
            {ch.topics.map((t) => (
              <TouchableOpacity
                key={t}
                onPress={() =>
                  navigate({ name: 'practice', subjectId: subjectSlug, title: t })
                }
                style={[
                  styles.chipBtn,
                  { borderColor: palette.border, backgroundColor: palette.surfaceMuted },
                ]}
              >
                <Text style={{ color: palette.text, fontSize: 12.5, fontWeight: '600' }}>
                  {t}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </EditorialCard>
      ))}
    </ScrollView>
  );
};

export const ModelTestCatalogScreen: React.FC = () => {
  const { palette, strings, navigate } = useApp();
  const [uni, setUni] = useState('ALL');
  const filtered = MODEL_TESTS_CATALOG.filter(
    (m) => uni === 'ALL' || m.track.toUpperCase() === uni
  );

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <Text style={[styles.h1, { color: palette.text }]}>{strings.navMockTest}</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.chipRow}>
          {['ALL', 'NSU', 'BRACU', 'AUST', 'AIUB', 'EWU', 'IUB', 'UIU', 'UAP'].map((u) => {
            const active = uni === u;
            return (
              <TouchableOpacity
                key={u}
                onPress={() => setUni(u)}
                style={[
                  styles.chipBtn,
                  {
                    borderColor: active ? palette.primary : palette.border,
                    backgroundColor: active ? palette.primary : palette.surface,
                  },
                ]}
              >
                <Text
                  style={{
                    color: active ? palette.primaryInk : palette.text,
                    fontSize: 12,
                    fontWeight: '700',
                  }}
                >
                  {u}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>

      {filtered.map((m) => (
        <EditorialCard key={m.id}>
          <Text style={[styles.cardTitle, { color: palette.text }]}>{m.title}</Text>
          <Text style={[styles.monoSub, { color: palette.textMuted }]}>
            {m.questionCount} Qs · {m.durationMinutes} min · Neg: {m.negativeMark}
          </Text>
          <ScalePressable
            onPress={() =>
              navigate({
                name: 'liveExam',
                slug: m.slug,
                title: m.title,
                durationMinutes: m.durationMinutes,
                negativeMark: m.negativeMark,
              })
            }
            style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
          >
            <Text style={[styles.btnText, { color: palette.primaryInk }]}>
              {strings.launchModelTest}
            </Text>
          </ScalePressable>
        </EditorialCard>
      ))}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 32 },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  h1: { fontFamily: TYPE_FONTS.display, fontSize: 20, fontWeight: '800' },
  bookmarkBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    minHeight: 40,
  },
  bookmarkText: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontSize: 12,
    fontVariant: ['tabular-nums'],
  },
  searchWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    height: 46,
  },
  searchInput: { flex: 1, fontSize: 14 },
  listCard: { paddingVertical: 6 },
  rowLead: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  monogram: {
    width: 40,
    height: 40,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  mockList: { gap: 12 },
  cardTitle: { fontFamily: TYPE_FONTS.display, fontSize: 15, fontWeight: '700' },
  monoSub: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontVariant: ['tabular-nums'],
  },
  accentLink: { fontSize: 12.5, fontWeight: '700' },
  primaryBtn: {
    borderRadius: RADII.md,
    height: 46,
    alignItems: 'center',
    justifyContent: 'center',
  },
  btnText: { fontFamily: TYPE_FONTS.display, fontWeight: '700', fontSize: 14 },
  chipRow: { flexDirection: 'row', gap: 8 },
  chipWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chipBtn: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    minHeight: 38,
    justifyContent: 'center',
  },
});
