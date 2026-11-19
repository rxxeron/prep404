import { Platform, ViewStyle } from 'react-native';
import { ThemeMode } from '../types';

export const PREP404_COLORS = {
  tangerine: '#F28C28',
  tangerineBright: '#FF9A3C',
  tangerineDark: '#D97316',
  plum: '#45204F',
  plumDeep: '#24102B',
  plumBright: '#C084FC',
  cream: '#FFF5E9',
  gold: '#F59E0B',
  amberDark: '#D97706',
  emerald: '#059669',
  emeraldBright: '#10B981',
  danger: '#DC2626',
  dangerBright: '#F87171',
  info: '#2563EB',
  infoBright: '#60A5FA',
  purple: '#7C3AED',
};

export const TYPE_FONTS = {
  display: Platform.select({
    web: '"Plus Jakarta Sans", "DM Sans", -apple-system, BlinkMacSystemFont, sans-serif',
    default: undefined,
  }),
  body: Platform.select({
    web: '"DM Sans", -apple-system, BlinkMacSystemFont, sans-serif',
    default: undefined,
  }),
  mono: Platform.select({
    web: '"JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
    default: undefined,
  }),
};

export const SPACE = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 28,
} as const;

export const RADII = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  sheet: 24,
} as const;

export type ElevationLevel = 'none' | 'card' | 'raised' | 'overlay';

export type ElevationScale = Record<ElevationLevel, ViewStyle>;

export function getElevation(theme: ThemeMode): ElevationScale {
  const isDark = theme === 'dark';
  return {
    none: Platform.select({
      web: { boxShadow: 'none' } as ViewStyle,
      default: { elevation: 0 },
    }) as ViewStyle,
    card: Platform.select({
      web: {
        boxShadow: isDark
          ? '0 1px 2px rgba(0, 0, 0, 0.22)'
          : '0 1px 2px rgba(15, 23, 42, 0.04)',
      } as ViewStyle,
      default: { elevation: isDark ? 0 : 1 },
    }) as ViewStyle,
    raised: Platform.select({
      web: {
        boxShadow: isDark
          ? '0 2px 8px rgba(0, 0, 0, 0.32)'
          : '0 2px 6px rgba(15, 23, 42, 0.06)',
      } as ViewStyle,
      default: { elevation: isDark ? 1 : 2 },
    }) as ViewStyle,
    overlay: Platform.select({
      web: {
        boxShadow: isDark
          ? '0 8px 24px rgba(0, 0, 0, 0.45)'
          : '0 6px 20px rgba(15, 23, 42, 0.09)',
      } as ViewStyle,
      default: { elevation: isDark ? 3 : 4 },
    }) as ViewStyle,
  };
}

export interface AppPalette {
  bg: string;
  surface: string;
  surfaceMuted: string;
  border: string;
  borderStrong: string;
  text: string;
  textMuted: string;
  textSubtle: string;
  primary: string;
  primaryInk: string;
  amber: string;
  secondary: string;
  secondarySoft: string;
  creamTint: string;
  success: string;
  successSoft: string;
  danger: string;
  dangerSoft: string;
  info: string;
  infoSoft: string;
  warningSoft: string;
  plumAnchorBg: string;
  plumAnchorText: string;
  plumAnchorMuted: string;
  elevation: ElevationScale;
}

export function getPalette(theme: ThemeMode): AppPalette {
  const elevation = getElevation(theme);
  if (theme === 'dark') {
    return {
      bg: '#0B0F17',
      surface: '#131A24',
      surfaceMuted: '#1B2432',
      border: 'rgba(255, 255, 255, 0.09)',
      borderStrong: 'rgba(255, 255, 255, 0.16)',
      text: '#F8FAFC',
      textMuted: '#94A3B8',
      textSubtle: '#64748B',
      primary: '#FF9A3C',
      primaryInk: '#0B0F17',
      amber: '#F59E0B',
      secondary: '#C084FC',
      secondarySoft: 'rgba(192, 132, 252, 0.14)',
      creamTint: 'rgba(255, 154, 60, 0.14)',
      success: '#10B981',
      successSoft: 'rgba(16, 185, 129, 0.15)',
      danger: '#F87171',
      dangerSoft: 'rgba(248, 113, 113, 0.14)',
      info: '#60A5FA',
      infoSoft: 'rgba(96, 165, 250, 0.15)',
      warningSoft: 'rgba(245, 158, 11, 0.15)',
      plumAnchorBg: '#24102B',
      plumAnchorText: '#F8FAFC',
      plumAnchorMuted: '#CBD5E1',
      elevation,
    };
  }
  return {
    bg: '#F8FAFC',
    surface: '#FFFFFF',
    surfaceMuted: '#F1F5F9',
    border: '#E2E8F0',
    borderStrong: '#CBD5E1',
    text: '#0F172A',
    textMuted: '#475569',
    textSubtle: '#64748B',
    primary: '#F28C28',
    primaryInk: '#FFFFFF',
    amber: '#D97706',
    secondary: '#45204F',
    secondarySoft: 'rgba(69, 32, 79, 0.08)',
    creamTint: 'rgba(242, 140, 40, 0.12)',
    success: '#059669',
    successSoft: 'rgba(5, 150, 105, 0.11)',
    danger: '#DC2626',
    dangerSoft: 'rgba(220, 38, 38, 0.10)',
    info: '#2563EB',
    infoSoft: 'rgba(37, 99, 235, 0.10)',
    warningSoft: '#FFFBEB',
    plumAnchorBg: '#45204F',
    plumAnchorText: '#FFFFFF',
    plumAnchorMuted: 'rgba(255, 255, 255, 0.78)',
    elevation,
  };
}
