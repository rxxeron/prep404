import { useEffect, useMemo, useState } from 'react';
import { AccessibilityInfo, Platform } from 'react-native';
import { useReducedMotion as useReanimatedReducedMotion } from 'react-native-reanimated';
import { ResolvedMotionConfig, resolveMotionConfig } from '../theme/motion';

function getInitialReducedMotion(): boolean {
  if (
    Platform.OS === 'web' &&
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function'
  ) {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }
  return false;
}

/**
 * Subscribes to system-level reduced-motion preferences via Reanimated's
 * `useReducedMotion`, React Native's `AccessibilityInfo`, and Web's
 * `prefers-reduced-motion: reduce` media query, returning the resolved
 * Reanimated motion configuration.
 */
export function useReducedMotion(): ResolvedMotionConfig {
  const reanimatedReduced = useReanimatedReducedMotion();
  const [systemReduced, setSystemReduced] = useState<boolean>(getInitialReducedMotion);

  useEffect(() => {
    let mounted = true;

    AccessibilityInfo.isReduceMotionEnabled()
      .then((enabled) => {
        if (mounted && typeof enabled === 'boolean') {
          setSystemReduced((prev) => prev || enabled);
        }
      })
      .catch(() => {
        // Ignore on platforms where AccessibilityInfo is unavailable
      });

    const nativeSub = AccessibilityInfo.addEventListener(
      'reduceMotionChanged',
      (enabled) => {
        if (mounted) {
          setSystemReduced(Boolean(enabled));
        }
      }
    );

    let mediaQuery: MediaQueryList | null = null;
    const handleMediaChange = (event: MediaQueryListEvent) => {
      if (mounted) {
        setSystemReduced(event.matches);
      }
    };

    if (
      Platform.OS === 'web' &&
      typeof window !== 'undefined' &&
      typeof window.matchMedia === 'function'
    ) {
      mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
      setSystemReduced(mediaQuery.matches);
      if (typeof mediaQuery.addEventListener === 'function') {
        mediaQuery.addEventListener('change', handleMediaChange);
      }
    }

    return () => {
      mounted = false;
      nativeSub.remove();
      if (mediaQuery && typeof mediaQuery.removeEventListener === 'function') {
        mediaQuery.removeEventListener('change', handleMediaChange);
      }
    };
  }, []);

  const effectiveReduced = Boolean(reanimatedReduced || systemReduced);
  return useMemo(() => resolveMotionConfig(effectiveReduced), [effectiveReduced]);
}
