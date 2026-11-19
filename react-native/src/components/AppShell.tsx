import React from 'react';
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  useWindowDimensions,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ArrowLeft,
  Bell,
  BookOpen,
  ChartBar,
  Clock,
  Compass,
  House,
  IconProps,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { MainTab } from '../types';
import { TYPE_FONTS } from '../theme/colors';
import { getRouteTransitionKey } from '../theme/motion';
import { ScalePressable, ScreenTransitionContainer } from './DesignPrimitives';
import { Prep404Logo } from './Prep404Logo';

interface AppShellProps {
  children: React.ReactNode;
}

function getInitials(name?: string): string {
  if (!name) return 'P4';
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }
  return parts[0].slice(0, 2).toUpperCase();
}

export const AppShell: React.FC<AppShellProps> = ({ children }) => {
  const { width } = useWindowDimensions();
  const {
    isDark,
    palette,
    strings,
    profile,
    activeRoute,
    navigate,
    goBack,
    setMainTab,
    unreadCount,
    toast,
  } = useApp();

  const isDashboard = activeRoute.name === 'dashboard';
  const currentTab: MainTab | null = isDashboard ? activeRoute.tab : null;

  // Distraction-free Focus Mode hides bottom navigation during active practice/exam/duel flows
  const isFocusRoute =
    activeRoute.name === 'liveExam' ||
    activeRoute.name === 'practice' ||
    activeRoute.name === 'battle';

  const subTitle = (() => {
    switch (activeRoute.name) {
      case 'practice':
        return activeRoute.title || 'Adaptive Practice';
      case 'liveExam':
        return activeRoute.title || 'Live Model Test';
      case 'battle':
        return '1v1 Quiz Duel';
      case 'universityDetail':
        return `${activeRoute.universityCode} Blueprint`;
      case 'subjectDirectory':
        return activeRoute.subjectTitle;
      case 'modelTestCatalog':
        return strings.navMockTest;
      case 'mistakeVault':
        return 'Mistake Vault';
      case 'streakDetail':
        return 'Study Streak';
      case 'examReview':
        return 'Script Review';
      case 'notifications':
        return 'Notifications';
      case 'profile':
        return strings.profileTitle;
      case 'accountInfo':
        return 'Account Info';
      case 'notificationSettings':
        return 'Reminders';
      case 'learnerSupport':
        return strings.learnerSupport;
      case 'reportedQuestions':
        return 'Reported Questions';
      case 'aboutUs':
        return 'About Prep404';
      case 'communityLinks':
        return 'Community';
      case 'upgrade':
        return 'Upgrade Pass';
      case 'subscription':
        return 'Subscription';
      case 'knowledgeProfile':
        return '360° Knowledge & Telemetry';
      case 'aiTutor':
        return 'AETHER AI Engine';
      case 'serverGateway':
        return 'Cloudflare Tunnel & Server';
      case 'editProfile':
        return strings.editAdmissionProfile;
      default:
        return '';
    }
  })();

  const sideTabs: {
    tab: MainTab;
    label: string;
    Icon: React.ComponentType<IconProps>;
  }[] = [
    { tab: 'home', label: strings.navHome, Icon: House },
    { tab: 'plan', label: strings.navPlan, Icon: Compass },
    { tab: 'questionBank', label: strings.isBangla ? 'ব্যাংক' : 'Bank', Icon: BookOpen },
    { tab: 'history', label: strings.isBangla ? 'বিশ্লেষণ' : 'Stats', Icon: ChartBar },
  ];

  const isWide = width >= 900;
  const routeKey = getRouteTransitionKey(activeRoute);

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: palette.bg }]}>
      {/* Minimal 52px Single-Row Top Bar (Brand/Back + 2 clean utility actions) */}
      <View
        style={[
          styles.header,
          { backgroundColor: palette.surface, borderBottomColor: palette.border },
        ]}
      >
        <View style={[styles.headerInner, isWide && styles.maxFrame]}>
          <View style={styles.headerLeft}>
            {!isDashboard ? (
              <>
                <TouchableOpacity
                  onPress={goBack}
                  accessibilityRole="button"
                  accessibilityLabel="Back"
                  style={styles.backBtn}
                >
                  <ArrowLeft size={20} color={palette.text} weight="bold" />
                </TouchableOpacity>
                <Text
                  style={[styles.subHeaderTitle, { color: palette.text }]}
                  numberOfLines={1}
                >
                  {subTitle}
                </Text>
              </>
            ) : (
              <TouchableOpacity
                onPress={() => setMainTab('home')}
                accessibilityRole="button"
                accessibilityLabel="Prep404 Home"
                style={styles.brandTouch}
              >
                <Prep404Logo compact isDark={isDark} />
              </TouchableOpacity>
            )}
          </View>

          {!isFocusRoute ? (
            <View style={styles.headerRight}>
              <TouchableOpacity
                onPress={() => navigate({ name: 'notifications' })}
                accessibilityRole="button"
                accessibilityLabel={`Notifications${unreadCount > 0 ? `, ${unreadCount} unread` : ''}`}
                style={styles.iconAction}
              >
                <Bell size={20} color={palette.text} weight="regular" />
                {unreadCount > 0 && (
                  <View style={[styles.badgeCount, { backgroundColor: palette.primary }]}>
                    <Text style={styles.badgeCountText}>{unreadCount}</Text>
                  </View>
                )}
              </TouchableOpacity>

              <TouchableOpacity
                onPress={() => navigate({ name: 'profile' })}
                accessibilityRole="button"
                accessibilityLabel="Profile and Settings"
                style={styles.avatarTouch}
              >
                <View
                  style={[
                    styles.avatarBox,
                    {
                      backgroundColor: palette.secondarySoft,
                      borderColor: palette.borderStrong,
                    },
                  ]}
                >
                  <Text style={[styles.avatarText, { color: palette.secondary }]}>
                    {getInitials(profile?.name)}
                  </Text>
                </View>
              </TouchableOpacity>
            </View>
          ) : (
            <View style={styles.focusBadgeWrap}>
              <Text style={[styles.focusBadgeText, { color: palette.textMuted }]}>
                FOCUS MODE
              </Text>
            </View>
          )}
        </View>
      </View>

      {/* Main Content Frame with Reanimated Layout Transition */}
      <View style={styles.body}>
        <View style={[styles.bodyInner, isWide && styles.maxFrame]}>
          <ScreenTransitionContainer routeKey={routeKey}>
            {children}
          </ScreenTransitionContainer>
        </View>
      </View>

      {/* 62px Thumb-Zone Bottom Bar with Center Elevated Live Exam Slot */}
      {!isFocusRoute && (
        <View
          accessibilityRole="tablist"
          style={[
            styles.tabBar,
            { backgroundColor: palette.surface, borderTopColor: palette.border },
          ]}
        >
          <View style={[styles.tabBarInner, isWide && styles.maxFrame]}>
            {sideTabs.slice(0, 2).map(({ tab, label, Icon }) => {
              const active = currentTab === tab;
              const color = active ? palette.primary : palette.textSubtle;
              return (
                <TouchableOpacity
                  key={tab}
                  onPress={() => setMainTab(tab)}
                  accessibilityRole="tab"
                  accessibilityLabel={label}
                  accessibilityState={{ selected: active }}
                  style={styles.tabItem}
                >
                  <Icon size={20} color={color} weight={active ? 'fill' : 'regular'} />
                  <Text
                    style={[
                      styles.tabLabel,
                      { color, fontWeight: active ? '700' : '600' },
                    ]}
                    numberOfLines={1}
                  >
                    {label}
                  </Text>
                </TouchableOpacity>
              );
            })}

            {/* Center Highlighted Live Exam Destination with Reanimated Spring Press */}
            <View style={styles.liveSlotWrap}>
              <ScalePressable
                onPress={() => setMainTab('dailyTest')}
                accessibilityRole="tab"
                accessibilityLabel={strings.navDailyTest}
                accessibilityState={{ selected: currentTab === 'dailyTest' }}
                containerStyle={styles.liveSlotTouch}
                style={[
                  styles.liveSlotBtn,
                  palette.elevation.raised,
                  {
                    backgroundColor: palette.primary,
                    borderColor:
                      currentTab === 'dailyTest' ? palette.text : 'transparent',
                  },
                ]}
              >
                <Clock size={18} color={palette.primaryInk} weight="bold" />
                <Text
                  style={[styles.liveSlotText, { color: palette.primaryInk }]}
                  numberOfLines={1}
                >
                  {strings.isBangla ? 'লাইভ' : 'Live'}
                </Text>
              </ScalePressable>
            </View>

            {sideTabs.slice(2).map(({ tab, label, Icon }) => {
              const active = currentTab === tab;
              const color = active ? palette.primary : palette.textSubtle;
              return (
                <TouchableOpacity
                  key={tab}
                  onPress={() => setMainTab(tab)}
                  accessibilityRole="tab"
                  accessibilityLabel={label}
                  accessibilityState={{ selected: active }}
                  style={styles.tabItem}
                >
                  <Icon size={20} color={color} weight={active ? 'fill' : 'regular'} />
                  <Text
                    style={[
                      styles.tabLabel,
                      { color, fontWeight: active ? '700' : '600' },
                    ]}
                    numberOfLines={1}
                  >
                    {label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
      )}

      {/* Floating Feedback Toast */}
      {toast && (
        <View
          style={[
            styles.toast,
            palette.elevation.overlay,
            {
              backgroundColor: isDark ? '#F8FAFC' : '#0F172A',
              bottom: isFocusRoute ? 24 : 74,
            },
          ]}
        >
          <Text
            style={[
              styles.toastText,
              { color: isDark ? '#0F172A' : '#FFFFFF' },
            ]}
          >
            {toast}
          </Text>
        </View>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: { flex: 1 },
  maxFrame: {
    maxWidth: 960,
    width: '100%',
    alignSelf: 'center',
  },
  header: {
    height: 52,
    borderBottomWidth: 1,
    justifyContent: 'center',
  },
  headerInner: {
    flex: 1,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
    minWidth: 0,
  },
  brandTouch: { minHeight: 44, justifyContent: 'center' },
  backBtn: {
    width: 44,
    height: 44,
    marginLeft: -8,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  subHeaderTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 16,
    fontWeight: '700',
    flex: 1,
  },
  headerRight: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  focusBadgeWrap: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  focusBadgeText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10.5,
    fontWeight: '700',
    letterSpacing: 0.6,
  },
  iconAction: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  badgeCount: {
    position: 'absolute',
    top: 6,
    right: 6,
    borderRadius: 8,
    minWidth: 16,
    height: 16,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 4,
  },
  badgeCountText: {
    fontFamily: TYPE_FONTS.mono,
    color: '#FFFFFF',
    fontSize: 9.5,
    fontWeight: '700',
  },
  avatarTouch: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarBox: {
    width: 34,
    height: 34,
    borderRadius: 10,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 12.5,
    fontWeight: '700',
  },
  body: { flex: 1 },
  bodyInner: { flex: 1, width: '100%' },
  tabBar: {
    height: 62,
    borderTopWidth: 1,
    justifyContent: 'center',
  },
  tabBarInner: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 6,
  },
  tabItem: {
    flex: 1,
    height: 52,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 3,
  },
  tabLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 11,
  },
  liveSlotWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 4,
  },
  liveSlotTouch: {
    width: '100%',
    maxWidth: 74,
  },
  liveSlotBtn: {
    width: '100%',
    maxWidth: 74,
    height: 46,
    borderRadius: 14,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  liveSlotText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 11,
    fontWeight: '700',
  },
  toast: {
    position: 'absolute',
    alignSelf: 'center',
    left: 20,
    right: 20,
    maxWidth: 460,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 12,
  },
  toastText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    fontWeight: '600',
    textAlign: 'center',
  },
});
