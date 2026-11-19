import React, { useState } from 'react';
import {
  Linking,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';
import { CaretRight } from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { COMMUNITY_LINKS } from '../data/universities';
import { storageService } from '../services/storageService';
import { RADII, TYPE_FONTS } from '../theme/colors';
import { AppLanguage, SupportRequest } from '../types';
import {
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';
import { Prep404Logo } from '../components/Prep404Logo';

function getInitials(name?: string): string {
  const parts = (name || 'Candidate').trim().split(/\s+/);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
  }
  return parts[0].slice(0, 2).toUpperCase();
}

export const ProfileSettingsScreen: React.FC = () => {
  const {
    profile,
    isDark,
    palette,
    toggleTheme,
    language,
    setLanguage,
    strings,
    navigate,
    logout,
    deleteAccount,
  } = useApp();
  const sub = storageService.getSubscription();
  const appearanceValue = isDark ? 'dark' : 'light';

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <View style={styles.identityRow}>
          <View
            style={[
              styles.avatarBadge,
              { backgroundColor: palette.plumAnchorBg },
            ]}
          >
            <Text style={[styles.avatarText, { color: palette.plumAnchorText }]}>
              {getInitials(profile?.name)}
            </Text>
          </View>
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              {sub.planName.toUpperCase()}
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              {profile?.name || 'Candidate'}
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              {profile?.academicBatch || 'HSC'} ·{' '}
              {profile?.institutionName || 'Prep404 Scholar'}
            </Text>
          </View>
        </View>
        <ScalePressable
          onPress={() => navigate({ name: 'upgrade' })}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Upgrade Pass
          </Text>
        </ScalePressable>
      </EditorialCard>

      <View style={styles.sectionBlock}>
        <Text style={[styles.sectionKicker, { color: palette.textMuted }]}>
          PREFERENCES
        </Text>
        <EditorialCard>
          <View style={styles.prefGroup}>
            <Text style={[styles.prefLabel, { color: palette.text }]}>
              Appearance
            </Text>
            <SegmentedControl<'light' | 'dark'>
              value={appearanceValue}
              onChange={(next) => {
                if ((next === 'dark') !== isDark) {
                  toggleTheme();
                }
              }}
              options={[
                { id: 'light', label: 'Light' },
                { id: 'dark', label: 'Dark' },
              ]}
            />
          </View>

          <View style={[styles.divider, { backgroundColor: palette.border }]} />

          <View style={styles.prefGroup}>
            <Text style={[styles.prefLabel, { color: palette.text }]}>
              {strings.appLanguageLabel}
            </Text>
            <SegmentedControl<AppLanguage>
              value={language}
              onChange={setLanguage}
              options={[
                { id: 'english', label: 'English' },
                { id: 'bangla', label: 'বাংলা' },
              ]}
            />
          </View>
        </EditorialCard>
      </View>

      <View style={styles.sectionBlock}>
        <Text style={[styles.sectionKicker, { color: palette.textMuted }]}>
          AI CLUSTER & KNOWLEDGE ARCHITECTURE
        </Text>
        <EditorialCard style={{ paddingVertical: 4 }}>
          {[
            {
              label: '360° Knowledge & Mastery Profile',
              onPress: () => navigate({ name: 'knowledgeProfile' }),
            },
            {
              label: 'AETHER AI Engine & Telemetry Vault',
              onPress: () => navigate({ name: 'aiTutor' }),
            },
            {
              label: 'Cloudflare Tunnel & prep404_server Gateway',
              onPress: () => navigate({ name: 'serverGateway' }),
            },
          ].map((row, idx, arr) => (
            <HairlineRow
              key={row.label}
              isLast={idx === arr.length - 1}
              onPress={row.onPress}
              left={
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  {row.label}
                </Text>
              }
              right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
            />
          ))}
        </EditorialCard>
      </View>

      <View style={styles.sectionBlock}>
        <Text style={[styles.sectionKicker, { color: palette.textMuted }]}>
          ACCOUNT & TARGETS
        </Text>
        <EditorialCard style={{ paddingVertical: 4 }}>
          {[
            {
              label: 'Edit Admission Profile',
              onPress: () => navigate({ name: 'editProfile', initialStep: 0 }),
            },
            {
              label: 'Account Info',
              onPress: () => navigate({ name: 'accountInfo' }),
            },
            {
              label: 'My Subscription',
              onPress: () => navigate({ name: 'subscription' }),
            },
            {
              label: 'Reminder Settings',
              onPress: () => navigate({ name: 'notificationSettings' }),
            },
          ].map((row, idx, arr) => (
            <HairlineRow
              key={row.label}
              isLast={idx === arr.length - 1}
              onPress={row.onPress}
              left={
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  {row.label}
                </Text>
              }
              right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
            />
          ))}
        </EditorialCard>
      </View>

      <View style={styles.sectionBlock}>
        <Text style={[styles.sectionKicker, { color: palette.textMuted }]}>
          SUPPORT & COMMUNITY
        </Text>
        <EditorialCard style={{ paddingVertical: 4 }}>
          {[
            {
              label: strings.learnerSupport,
              onPress: () => navigate({ name: 'learnerSupport' }),
            },
            {
              label: 'Reported Questions',
              onPress: () => navigate({ name: 'reportedQuestions' }),
            },
            {
              label: 'Community Links',
              onPress: () => navigate({ name: 'communityLinks' }),
            },
            {
              label: 'About Prep404',
              onPress: () => navigate({ name: 'aboutUs' }),
            },
          ].map((row, idx, arr) => (
            <HairlineRow
              key={row.label}
              isLast={idx === arr.length - 1}
              onPress={row.onPress}
              left={
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  {row.label}
                </Text>
              }
              right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
            />
          ))}
        </EditorialCard>
      </View>

      <View style={styles.sessionStack}>
        <ScalePressable
          onPress={logout}
          style={[
            styles.outlineBtn,
            { borderColor: palette.borderStrong, backgroundColor: palette.surface },
          ]}
        >
          <Text style={[styles.outlineBtnText, { color: palette.text }]}>
            {strings.signOut}
          </Text>
        </ScalePressable>
        <ScalePressable
          onPress={deleteAccount}
          style={[
            styles.outlineBtn,
            { borderColor: palette.danger, backgroundColor: palette.dangerSoft },
          ]}
        >
          <Text style={[styles.outlineBtnText, { color: palette.danger }]}>
            Delete Account Data
          </Text>
        </ScalePressable>
      </View>
    </ScrollView>
  );
};

export const NotificationCenterScreen: React.FC = () => {
  const {
    notifications,
    palette,
    markNotificationRead,
    markAllNotificationsRead,
    setMainTab,
  } = useApp();

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.topActionRow}>
        <Text style={[styles.sectionKicker, { color: palette.textMuted }]}>
          INBOX ({notifications.filter((n) => !n.isRead).length} UNREAD)
        </Text>
        <ScalePressable onPress={markAllNotificationsRead}>
          <Text style={[styles.linkAction, { color: palette.primary }]}>
            Mark All Read
          </Text>
        </ScalePressable>
      </View>

      <EditorialCard style={{ paddingVertical: 4 }}>
        {notifications.map((n, idx) => (
          <HairlineRow
            key={n.id}
            isLast={idx === notifications.length - 1}
            highlightedBg={n.isRead ? undefined : palette.creamTint}
            onPress={() => {
              markNotificationRead(n.id);
              if (n.targetTab) setMainTab(n.targetTab);
            }}
            left={
              <View style={{ gap: 3 }}>
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  {n.title}
                </Text>
                <Text style={[styles.subText, { color: palette.textMuted }]}>
                  {n.body}
                </Text>
              </View>
            }
            right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
          />
        ))}
      </EditorialCard>
    </ScrollView>
  );
};

export const AccountInfoScreen: React.FC = () => {
  const { profile, userMetadata, authProvider, palette } = useApp();
  const providerLabel =
    authProvider === 'google'
      ? 'Google (Supabase Auth)'
      : authProvider === 'phone'
        ? 'Phone OTP'
        : 'Guest Preview';
  const rows = [
    ['Candidate Name', profile?.name || '—'],
    ['Sign-In Method', providerLabel],
    ...(profile?.email ? [['Google Email', profile.email]] : []),
    ['Preferred Track', userMetadata?.preferredUniversityTrack || '—'],
    ['Academic Level', userMetadata?.currentAcademicLevel || '—'],
    ['Phone Number', profile?.phone || '—'],
    ['Academic Batch', profile?.academicBatch || '—'],
    ['Institution', profile?.institutionName || '—'],
    ['Study Medium', profile?.medium || '—'],
  ];

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard style={{ paddingVertical: 6 }}>
        {rows.map(([label, val], idx) => (
          <HairlineRow
            key={label}
            isLast={idx === rows.length - 1}
            left={
              <Text style={[styles.subText, { color: palette.textMuted }]}>
                {label}
              </Text>
            }
            right={
              <Text style={[styles.rowTitle, { color: palette.text }]}>
                {val}
              </Text>
            }
          />
        ))}
      </EditorialCard>
    </ScrollView>
  );
};

export const NotificationSettingsScreen: React.FC = () => {
  const { palette, showToast } = useApp();
  const [prefs, setPrefs] = useState(() => storageService.getReminderPrefs());
  const update = (patch: Partial<typeof prefs>) => {
    const next = { ...prefs, ...patch };
    setPrefs(next);
    storageService.setReminderPrefs(next);
    showToast('Preferences saved');
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard style={{ paddingVertical: 4 }}>
        <HairlineRow
          left={
            <View style={{ gap: 2 }}>
              <Text style={[styles.rowTitle, { color: palette.text }]}>
                Practice Reminders
              </Text>
              <Text style={[styles.subText, { color: palette.textMuted }]}>
                Daily FSRS review prompts for due cards
              </Text>
            </View>
          }
          right={
            <Switch
              value={prefs.practiceReminders}
              onValueChange={(v) => update({ practiceReminders: v })}
            />
          }
        />
        <HairlineRow
          isLast
          left={
            <View style={{ gap: 2 }}>
              <Text style={[styles.rowTitle, { color: palette.text }]}>
                Daily Live 10 AM Alert
              </Text>
              <Text style={[styles.subText, { color: palette.textMuted }]}>
                Ranked live exam window notification
              </Text>
            </View>
          }
          right={
            <Switch
              value={prefs.dailyLiveAlert}
              onValueChange={(v) => update({ dailyLiveAlert: v })}
            />
          }
        />
      </EditorialCard>
    </ScrollView>
  );
};

export const LearnerSupportScreen: React.FC = () => {
  const { palette, showToast } = useApp();
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [requests, setRequests] = useState(() =>
    storageService.getSupportRequests()
  );

  const submit = () => {
    if (!subject.trim() || !message.trim()) return;
    const req: SupportRequest = {
      id: `sup_${Date.now()}`,
      category: 'learning_progress',
      subject: subject.trim(),
      message: message.trim(),
      status: 'open',
      createdAt: new Date().toISOString(),
    };
    storageService.addSupportRequest(req);
    setRequests(storageService.getSupportRequests());
    setSubject('');
    setMessage('');
    showToast('Support ticket sent!');
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <Text style={[styles.title, { color: palette.text }]}>
          Submit Support Request
        </Text>
        <TextInput
          value={subject}
          onChangeText={setSubject}
          placeholder="Subject"
          placeholderTextColor={palette.textMuted}
          style={[
            styles.input,
            {
              color: palette.text,
              borderColor: palette.borderStrong,
              backgroundColor: palette.surfaceMuted,
            },
          ]}
        />
        <TextInput
          value={message}
          onChangeText={setMessage}
          placeholder="Describe your issue..."
          placeholderTextColor={palette.textMuted}
          multiline
          style={[
            styles.input,
            styles.textArea,
            {
              color: palette.text,
              borderColor: palette.borderStrong,
              backgroundColor: palette.surfaceMuted,
            },
          ]}
        />
        <ScalePressable
          onPress={submit}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Send Request
          </Text>
        </ScalePressable>
      </EditorialCard>

      {requests.length > 0 && (
        <EditorialCard style={{ paddingVertical: 4 }}>
          {requests.map((r, idx) => (
            <HairlineRow
              key={r.id}
              isLast={idx === requests.length - 1}
              left={
                <View style={{ gap: 2 }}>
                  <Text style={[styles.rowTitle, { color: palette.text }]}>
                    {r.subject}
                  </Text>
                  <Text style={[styles.subText, { color: palette.textMuted }]}>
                    {r.message}
                  </Text>
                </View>
              }
              right={
                <Text style={[styles.kicker, { color: palette.primary }]}>
                  {r.status.toUpperCase()}
                </Text>
              }
            />
          ))}
        </EditorialCard>
      )}
    </ScrollView>
  );
};

export const ReportedQuestionsScreen: React.FC = () => {
  const { palette } = useApp();
  const reports = storageService.getReportedQuestions();
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {reports.length === 0 ? (
        <EditorialCard>
          <Text style={[styles.emptyText, { color: palette.textMuted }]}>
            No reported questions yet.
          </Text>
        </EditorialCard>
      ) : (
        <EditorialCard style={{ paddingVertical: 4 }}>
          {reports.map((r, idx) => (
            <HairlineRow
              key={r.id}
              isLast={idx === reports.length - 1}
              left={
                <View style={{ gap: 3 }}>
                  <Text style={[styles.kicker, { color: palette.primary }]}>
                    {r.reason}
                  </Text>
                  <Text style={[styles.subText, { color: palette.text }]}>
                    {r.questionPreview}
                  </Text>
                </View>
              }
            />
          ))}
        </EditorialCard>
      )}
    </ScrollView>
  );
};

export const CommunityLinksScreen: React.FC = () => {
  const { palette } = useApp();
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard style={{ paddingVertical: 4 }}>
        {COMMUNITY_LINKS.map((c, idx) => (
          <HairlineRow
            key={c.id}
            isLast={idx === COMMUNITY_LINKS.length - 1}
            onPress={() => Linking.openURL(c.url).catch(() => undefined)}
            left={
              <View style={{ gap: 2 }}>
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  {c.title}
                </Text>
                <Text style={[styles.subText, { color: palette.textMuted }]}>
                  {c.description}
                </Text>
              </View>
            }
            right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
          />
        ))}
      </EditorialCard>
    </ScrollView>
  );
};

export const AboutUsScreen: React.FC = () => {
  const { palette, isDark } = useApp();
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <View style={{ alignItems: 'flex-start', gap: 8 }}>
          <Prep404Logo size="lg" isDark={isDark} />
          <View style={{ gap: 4 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              PREP404 PLATFORM
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              Failure Not Found
            </Text>
          </View>
        </View>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Bangladeshi Private University Admission Preparation Platform featuring
          FSRS-4.5 adaptive recall, Software OMR Bubble Simulation, and 8
          University Blueprints.
        </Text>
      </EditorialCard>
    </ScrollView>
  );
};

export const UpgradeScreen: React.FC = () => {
  const { palette, navigate, showToast } = useApp();
  const activate = (tier: 'pro' | 'elite', name: string, price: number) => {
    storageService.setSubscription(tier, name, price, 'bKash');
    showToast(`${name} activated!`);
    navigate({ name: 'subscription' });
  };
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard highlighted>
        <Text style={[styles.kicker, { color: palette.primary }]}>
          RECOMMENDED PASS
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          Prep404 Pro Pass — ৳1,499
        </Text>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Full model test bank, OMR simulations, and FSRS unlimited scheduling.
        </Text>
        <ScalePressable
          onPress={() => activate('pro', 'Prep404 Pro Pass', 1499)}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Activate Pro
          </Text>
        </ScalePressable>
      </EditorialCard>

      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.secondary }]}>
          ALL-ACCESS TIER
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          Varsity Elite Pass — ৳2,499
        </Text>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Includes 1-on-1 university blueprint analytics & priority drills.
        </Text>
        <ScalePressable
          onPress={() => activate('elite', 'Varsity Elite Pass', 2499)}
          style={[styles.primaryBtn, { backgroundColor: palette.plumAnchorBg }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.plumAnchorText }]}>
            Activate Elite
          </Text>
        </ScalePressable>
      </EditorialCard>
    </ScrollView>
  );
};

export const SubscriptionScreen: React.FC = () => {
  const { palette, navigate } = useApp();
  const sub = storageService.getSubscription();
  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.primary }]}>
          CURRENT MEMBERSHIP
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          {sub.planName}
        </Text>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Method: {sub.method} · Date: {sub.date} · ৳{sub.price}
        </Text>
        <ScalePressable
          onPress={() => navigate({ name: 'upgrade' })}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Change Plan
          </Text>
        </ScalePressable>
      </EditorialCard>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 36 },
  identityRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  avatarBadge: {
    width: 52,
    height: 52,
    borderRadius: RADII.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 18,
    fontWeight: '800',
  },
  kicker: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.4,
  },
  sectionKicker: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  title: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 19,
    fontWeight: '800',
  },
  subText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    lineHeight: 19,
  },
  sectionBlock: { gap: 8 },
  prefGroup: { gap: 8 },
  prefLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13.5,
    fontWeight: '700',
  },
  divider: { height: 1, marginVertical: 2 },
  rowTitle: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 14,
    fontWeight: '700',
  },
  primaryBtn: {
    borderRadius: RADII.md,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  primaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontWeight: '700',
    fontSize: 14.5,
  },
  sessionStack: { gap: 10, marginTop: 4 },
  outlineBtn: {
    borderWidth: 1.5,
    borderRadius: RADII.md,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  outlineBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontWeight: '700',
    fontSize: 14,
  },
  topActionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  linkAction: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13,
    fontWeight: '700',
  },
  input: {
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    paddingVertical: 12,
    minHeight: 46,
    fontFamily: TYPE_FONTS.body,
    fontSize: 14,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  emptyText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    textAlign: 'center',
    paddingVertical: 16,
  },
});
