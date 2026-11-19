import React from 'react';
import {
  ActivityIndicator,
  AppState,
  Image,
  Platform,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppProvider, useApp } from './src/context/AppContext';
import { AppShell } from './src/components/AppShell';
import { AuthScreen } from './src/screens/AuthScreen';
import { OnboardingScreen } from './src/screens/OnboardingScreen';
import { HomeDashboardScreen } from './src/screens/HomeDashboardScreen';
import { RoadmapScreen } from './src/screens/RoadmapScreen';
import {
  ModelTestCatalogScreen,
  QuestionBankScreen,
  SubjectDirectoryScreen,
  UniversityDetailScreen,
} from './src/screens/QuestionBankScreens';
import { PracticeScreen } from './src/screens/PracticeScreen';
import {
  DailyExamArenaScreen,
  LiveModelTestScreen,
} from './src/screens/ExamScreens';
import { BattleArenaScreen } from './src/screens/BattleArenaScreen';
import {
  ExamHistoryScreen,
  ExamScriptReviewScreen,
  MistakeVaultScreen,
  StudyStreakDetailScreen,
} from './src/screens/AnalyticsScreens';
import {
  AboutUsScreen,
  AccountInfoScreen,
  CommunityLinksScreen,
  LearnerSupportScreen,
  NotificationCenterScreen,
  NotificationSettingsScreen,
  ProfileSettingsScreen,
  ReportedQuestionsScreen,
  SubscriptionScreen,
  UpgradeScreen,
} from './src/screens/ProfileScreens';
import { KnowledgeProfileScreen } from './src/screens/KnowledgeProfileScreen';
import {
  ServerGatewayScreen,
  SocraticAITutorScreen,
} from './src/screens/AITutorScreens';
import { ReducedMotionConfig, ReduceMotion } from 'react-native-reanimated';
import { PREP404_COLORS } from './src/theme/colors';
import { ScreenTransitionContainer } from './src/components/DesignPrimitives';
import { useReducedMotion } from './src/utils/useReducedMotion';
import { initCandidateFocusMonitor } from './src/services/telemetryService';

const RootRouter: React.FC = () => {
  const {
    hydrated,
    isAuthenticated,
    isProfileSyncing,
    cachedBasicUserInfo,
    profile,
    activeRoute,
    goBack,
    palette,
  } = useApp();
  const motion = useReducedMotion();

  React.useEffect(() => {
    initCandidateFocusMonitor(AppState, Platform.OS);
  }, []);

  if (!hydrated || (isAuthenticated && !profile && isProfileSyncing)) {
    const displayName = cachedBasicUserInfo?.name || '';
    const displayEmail = cachedBasicUserInfo?.email || '';
    const avatarUrl = cachedBasicUserInfo?.avatarUrl;
    const initial = (displayName || displayEmail || 'P').charAt(0).toUpperCase();

    return (
      <View style={[styles.splash, { backgroundColor: palette.bg }]}>
        {cachedBasicUserInfo ? (
          <View style={styles.splashIdentity}>
            {avatarUrl ? (
              <Image source={{ uri: avatarUrl }} style={styles.splashAvatar} />
            ) : (
              <View
                style={[
                  styles.splashAvatarFallback,
                  { backgroundColor: PREP404_COLORS.tangerine },
                ]}
              >
                <Text style={styles.splashAvatarText}>{initial}</Text>
              </View>
            )}
            {displayName ? (
              <Text style={[styles.splashName, { color: palette.text }]}>
                {displayName}
              </Text>
            ) : null}
            {displayEmail ? (
              <Text style={[styles.splashEmail, { color: palette.textMuted }]}>
                {displayEmail}
              </Text>
            ) : null}
          </View>
        ) : null}
        <ActivityIndicator size="large" color={PREP404_COLORS.tangerine} />
      </View>
    );
  }

  if (!isAuthenticated) {
    return (
      <ScreenTransitionContainer routeKey="auth">
        <ReducedMotionConfig
          mode={motion.reduceMotion ? ReduceMotion.Always : ReduceMotion.System}
        />
        <AuthScreen />
      </ScreenTransitionContainer>
    );
  }

  if (!profile) {
    return (
      <ScreenTransitionContainer routeKey="onboarding">
        <ReducedMotionConfig
          mode={motion.reduceMotion ? ReduceMotion.Always : ReduceMotion.System}
        />
        <OnboardingScreen />
      </ScreenTransitionContainer>
    );
  }

  const renderRoute = () => {
    switch (activeRoute.name) {
      case 'dashboard': {
        switch (activeRoute.tab) {
          case 'home':
            return <HomeDashboardScreen />;
          case 'plan':
            return <RoadmapScreen />;
          case 'questionBank':
            return <QuestionBankScreen />;
          case 'dailyTest':
            return <DailyExamArenaScreen />;
          case 'history':
            return <ExamHistoryScreen />;
        }
        break;
      }
      case 'battle':
        return <BattleArenaScreen />;
      case 'practice':
        return (
          <PracticeScreen
            initialSubjectId={activeRoute.subjectId}
            initialTopicId={activeRoute.topicId}
            title={activeRoute.title}
          />
        );
      case 'liveExam':
        return (
          <LiveModelTestScreen
            slug={activeRoute.slug}
            title={activeRoute.title}
            durationMinutes={activeRoute.durationMinutes}
            negativeMark={activeRoute.negativeMark}
            isPracticeMode={activeRoute.isPracticeMode}
            initialQuestions={activeRoute.questions}
          />
        );
      case 'knowledgeProfile':
        return (
          <KnowledgeProfileScreen
            initialUniversityCode={activeRoute.initialUniversityCode}
            initialSubjectId={activeRoute.initialSubjectId}
          />
        );
      case 'aiTutor':
        return (
          <SocraticAITutorScreen
            questionId={activeRoute.questionId}
            topicId={activeRoute.topicId}
            subjectId={activeRoute.subjectId}
            threadId={activeRoute.threadId}
            initialMode={activeRoute.initialMode}
          />
        );
      case 'serverGateway':
        return <ServerGatewayScreen />;
      case 'universityDetail':
        return <UniversityDetailScreen universityCode={activeRoute.universityCode} />;
      case 'subjectDirectory':
        return (
          <SubjectDirectoryScreen
            subjectSlug={activeRoute.subjectSlug}
            subjectTitle={activeRoute.subjectTitle}
          />
        );
      case 'modelTestCatalog':
        return <ModelTestCatalogScreen />;
      case 'mistakeVault':
        return <MistakeVaultScreen />;
      case 'streakDetail':
        return <StudyStreakDetailScreen />;
      case 'examReview':
        return <ExamScriptReviewScreen historyId={activeRoute.historyId} />;
      case 'notifications':
        return <NotificationCenterScreen />;
      case 'profile':
        return <ProfileSettingsScreen />;
      case 'accountInfo':
        return <AccountInfoScreen />;
      case 'notificationSettings':
        return <NotificationSettingsScreen />;
      case 'learnerSupport':
        return <LearnerSupportScreen />;
      case 'reportedQuestions':
        return <ReportedQuestionsScreen />;
      case 'aboutUs':
        return <AboutUsScreen />;
      case 'communityLinks':
        return <CommunityLinksScreen />;
      case 'upgrade':
        return <UpgradeScreen />;
      case 'subscription':
        return <SubscriptionScreen />;
      case 'editProfile':
        return (
          <OnboardingScreen
            isEditMode
            initialStep={activeRoute.initialStep ?? 0}
            onDone={goBack}
          />
        );
    }
    return <HomeDashboardScreen />;
  };

  return (
    <AppShell>
      <ReducedMotionConfig
        mode={motion.reduceMotion ? ReduceMotion.Always : ReduceMotion.System}
      />
      {renderRoute()}
    </AppShell>
  );
};

const DEFAULT_SAFE_AREA_METRICS = {
  frame: { x: 0, y: 0, width: 390, height: 844 },
  insets: { top: 0, left: 0, right: 0, bottom: 0 },
};

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={DEFAULT_SAFE_AREA_METRICS}>
      <AppProvider>
        <RootRouter />
      </AppProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  splash: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    gap: 16,
  },
  splashIdentity: {
    alignItems: 'center',
    gap: 6,
  },
  splashAvatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    marginBottom: 4,
  },
  splashAvatarFallback: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  splashAvatarText: {
    color: '#FFFFFF',
    fontSize: 22,
    fontWeight: '700',
  },
  splashName: {
    fontSize: 18,
    fontWeight: '700',
  },
  splashEmail: {
    fontSize: 13,
  },
});
