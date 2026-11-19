import { ActiveRoute } from '../types';

export interface SpringTokenConfig {
  damping: number;
  stiffness: number;
  mass: number;
}

export const MOTION_TOKENS = {
  duration: {
    instant: 0,
    press: 110,
    state: 160,
    screenEnter: 210,
    screenExit: 130,
    modal: 220,
    progress: 260,
  },
  scale: {
    pressed: 0.97,
    resting: 1,
  },
  spring: {
    buttonPress: {
      damping: 18,
      stiffness: 340,
      mass: 0.75,
    } as SpringTokenConfig,
    buttonRelease: {
      damping: 16,
      stiffness: 280,
      mass: 0.8,
    } as SpringTokenConfig,
    layoutTransition: {
      damping: 22,
      stiffness: 240,
      mass: 0.9,
    } as SpringTokenConfig,
  },
} as const;

export interface ResolvedMotionConfig {
  reduceMotion: boolean;
  pressDuration: number;
  stateDuration: number;
  screenEnterDuration: number;
  screenExitDuration: number;
  modalDuration: number;
  progressDuration: number;
  pressedScale: number;
  modalAnimationType: 'none' | 'fade';
  enableScreenLayoutTransition: boolean;
  springPress: SpringTokenConfig;
  springRelease: SpringTokenConfig;
  springLayout: SpringTokenConfig;
}

/**
 * Resolves accessible Reanimated motion tokens.
 * When OS/browser reduced-motion is enabled, durations collapse to 0ms,
 * spring scale transforms stay at 1.0, layout transitions are disabled,
 * and modal transitions use 'none'.
 */
export function resolveMotionConfig(reduceMotion: boolean): ResolvedMotionConfig {
  if (reduceMotion) {
    return {
      reduceMotion: true,
      pressDuration: MOTION_TOKENS.duration.instant,
      stateDuration: MOTION_TOKENS.duration.instant,
      screenEnterDuration: MOTION_TOKENS.duration.instant,
      screenExitDuration: MOTION_TOKENS.duration.instant,
      modalDuration: MOTION_TOKENS.duration.instant,
      progressDuration: MOTION_TOKENS.duration.instant,
      pressedScale: MOTION_TOKENS.scale.resting,
      modalAnimationType: 'none',
      enableScreenLayoutTransition: false,
      springPress: MOTION_TOKENS.spring.buttonPress,
      springRelease: MOTION_TOKENS.spring.buttonRelease,
      springLayout: MOTION_TOKENS.spring.layoutTransition,
    };
  }

  return {
    reduceMotion: false,
    pressDuration: MOTION_TOKENS.duration.press,
    stateDuration: MOTION_TOKENS.duration.state,
    screenEnterDuration: MOTION_TOKENS.duration.screenEnter,
    screenExitDuration: MOTION_TOKENS.duration.screenExit,
    modalDuration: MOTION_TOKENS.duration.modal,
    progressDuration: MOTION_TOKENS.duration.progress,
    pressedScale: MOTION_TOKENS.scale.pressed,
    modalAnimationType: 'fade',
    enableScreenLayoutTransition: true,
    springPress: MOTION_TOKENS.spring.buttonPress,
    springRelease: MOTION_TOKENS.spring.buttonRelease,
    springLayout: MOTION_TOKENS.spring.layoutTransition,
  };
}

/**
 * Computes a deterministic route key for Reanimated screen navigation transitions.
 */
export function getRouteTransitionKey(route: ActiveRoute): string {
  switch (route.name) {
    case 'dashboard':
      return `dashboard:${route.tab}`;
    case 'liveExam':
      return `liveExam:${route.slug}`;
    case 'practice':
      return `practice:${route.subjectId || 'all'}:${route.topicId || 'all'}`;
    case 'knowledgeProfile':
      return `knowledgeProfile:${route.initialUniversityCode || 'all'}`;
    case 'aiTutor':
      return `aiTutor:${route.threadId || route.questionId || route.topicId || 'default'}`;
    case 'serverGateway':
      return 'serverGateway';
    case 'universityDetail':
      return `universityDetail:${route.universityCode}`;
    case 'subjectDirectory':
      return `subjectDirectory:${route.subjectSlug}`;
    case 'examReview':
      return `examReview:${route.historyId}`;
    default:
      return route.name;
  }
}
