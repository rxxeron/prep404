import React from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleProp,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ViewStyle,
} from 'react-native';
import Animated, {
  cancelAnimation,
  ReduceMotion,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { useApp } from '../context/AppContext';
import { RADII, TYPE_FONTS } from '../theme/colors';
import { useReducedMotion } from '../utils/useReducedMotion';

interface ScalePressableProps {
  children: React.ReactNode;
  onPress?: () => void;
  disabled?: boolean;
  style?: StyleProp<ViewStyle>;
  containerStyle?: StyleProp<ViewStyle>;
  accessibilityLabel?: string;
  accessibilityRole?: 'button' | 'tab';
  accessibilityState?: { selected?: boolean; disabled?: boolean };
  testID?: string;
}

/**
 * Tactile Pressable powered by Reanimated `withSpring`.
 * Automatically respects reduced-motion settings and never blocks `onPress`.
 */
export const ScalePressable: React.FC<ScalePressableProps> = ({
  children,
  onPress,
  disabled = false,
  style,
  containerStyle,
  accessibilityLabel,
  accessibilityRole = 'button',
  accessibilityState,
  testID,
}) => {
  const scale = useSharedValue(1);
  const motion = useReducedMotion();

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }), [scale]);

  const handlePressIn = () => {
    if (disabled) return;
    cancelAnimation(scale);
    if (motion.reduceMotion) {
      scale.value = 1;
      return;
    }
    scale.value = withSpring(motion.pressedScale, {
      damping: motion.springPress.damping,
      stiffness: motion.springPress.stiffness,
      mass: motion.springPress.mass,
      reduceMotion: ReduceMotion.System,
    });
  };

  const handlePressOut = () => {
    cancelAnimation(scale);
    if (motion.reduceMotion) {
      scale.value = 1;
      return;
    }
    scale.value = withSpring(1, {
      damping: motion.springRelease.damping,
      stiffness: motion.springRelease.stiffness,
      mass: motion.springRelease.mass,
      reduceMotion: ReduceMotion.System,
    });
  };

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      accessibilityRole={accessibilityRole}
      accessibilityLabel={accessibilityLabel}
      accessibilityState={accessibilityState}
      testID={testID}
      style={[containerStyle, disabled ? { opacity: 0.45 } : undefined]}
    >
      <Animated.View style={[style, animatedStyle]}>{children}</Animated.View>
    </Pressable>
  );
};

interface ScreenTransitionContainerProps {
  routeKey: string;
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
}

/**
 * Reanimated transition wrapper for screen navigation.
 * Collapses to an instant static swap when reduced-motion is enabled.
 */
export const ScreenTransitionContainer: React.FC<ScreenTransitionContainerProps> = ({
  routeKey,
  children,
  style,
}) => {
  const motion = useReducedMotion();
  const opacity = useSharedValue(
    motion.reduceMotion || !motion.enableScreenLayoutTransition ? 1 : 0.92
  );

  React.useEffect(() => {
    if (motion.reduceMotion || !motion.enableScreenLayoutTransition) {
      opacity.value = 1;
      return;
    }
    opacity.value = 0.92;
    opacity.value = withTiming(1, {
      duration: motion.screenEnterDuration,
      reduceMotion: ReduceMotion.System,
    });
  }, [
    routeKey,
    motion.reduceMotion,
    motion.enableScreenLayoutTransition,
    motion.screenEnterDuration,
    opacity,
  ]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }), [opacity]);

  if (motion.reduceMotion || !motion.enableScreenLayoutTransition) {
    return (
      <View key={routeKey} style={[styles.screenTransition, style]}>
        {children}
      </View>
    );
  }

  return (
    <Animated.View
      key={routeKey}
      style={[styles.screenTransition, animatedStyle, style]}
    >
      {children}
    </Animated.View>
  );
};

export interface SegmentedOption<T extends string> {
  id: T;
  label: string;
}

interface SegmentedControlProps<T extends string> {
  options: readonly SegmentedOption<T>[];
  value: T;
  onChange: (next: T) => void;
  style?: StyleProp<ViewStyle>;
}

export function SegmentedControl<T extends string>({
  options,
  value,
  onChange,
  style,
}: SegmentedControlProps<T>) {
  const { palette } = useApp();
  return (
    <View
      accessibilityRole="tablist"
      style={[
        styles.segTrack,
        { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
        style,
      ]}
    >
      {options.map((opt) => {
        const active = value === opt.id;
        return (
          <TouchableOpacity
            key={opt.id}
            onPress={() => onChange(opt.id)}
            accessibilityRole="tab"
            accessibilityState={{ selected: active }}
            style={[
              styles.segBtn,
              active && [
                {
                  backgroundColor: palette.surface,
                  borderColor: palette.border,
                },
                palette.elevation.raised,
              ],
            ]}
          >
            <Text
              numberOfLines={1}
              style={[
                styles.segLabel,
                {
                  color: active ? palette.text : palette.textMuted,
                  fontWeight: active ? '700' : '600',
                },
              ]}
            >
              {opt.label}
            </Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

interface EditorialCardProps {
  children: React.ReactNode;
  style?: StyleProp<ViewStyle>;
  highlighted?: boolean;
}

export const EditorialCard: React.FC<EditorialCardProps> = ({
  children,
  style,
  highlighted = false,
}) => {
  const { palette } = useApp();
  return (
    <View
      style={[
        styles.card,
        highlighted ? palette.elevation.raised : palette.elevation.card,
        {
          backgroundColor: palette.surface,
          borderColor: highlighted ? palette.primary : palette.border,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
};

interface HairlineRowProps {
  left: React.ReactNode;
  right?: React.ReactNode;
  onPress?: () => void;
  isLast?: boolean;
  accessibilityLabel?: string;
  highlightedBg?: string;
}

export const HairlineRow: React.FC<HairlineRowProps> = ({
  left,
  right,
  onPress,
  isLast = false,
  accessibilityLabel,
  highlightedBg,
}) => {
  const { palette } = useApp();
  const content = (
    <View
      style={[
        styles.hairlineRow,
        !isLast && { borderBottomWidth: 1, borderBottomColor: palette.border },
        highlightedBg
          ? { backgroundColor: highlightedBg, borderRadius: 10, paddingHorizontal: 10 }
          : null,
      ]}
    >
      <View style={styles.hairlineLeft}>{left}</View>
      {right ? <View style={styles.hairlineRight}>{right}</View> : null}
    </View>
  );

  if (onPress) {
    return (
      <TouchableOpacity
        onPress={onPress}
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel}
        activeOpacity={0.75}
      >
        {content}
      </TouchableOpacity>
    );
  }
  return content;
};

interface BottomSheetModalProps {
  visible: boolean;
  onClose: () => void;
  title?: string;
  subtitle?: string;
  children: React.ReactNode;
}

export const BottomSheetModal: React.FC<BottomSheetModalProps> = ({
  visible,
  onClose,
  title,
  subtitle,
  children,
}) => {
  const { palette } = useApp();
  const motion = useReducedMotion();
  return (
    <Modal
      visible={visible}
      transparent
      animationType={motion.modalAnimationType}
      onRequestClose={onClose}
    >
      <View style={styles.sheetBackdrop}>
        <Pressable
          style={StyleSheet.absoluteFill}
          accessibilityLabel="Close dialog"
          onPress={onClose}
        />
        <View
          style={[
            styles.sheetCard,
            palette.elevation.overlay,
            { backgroundColor: palette.surface, borderColor: palette.border },
          ]}
        >
          <View style={[styles.grabHandle, { backgroundColor: palette.borderStrong }]} />
          {title ? (
            <View style={styles.sheetHead}>
              <Text style={[styles.sheetTitle, { color: palette.text }]}>{title}</Text>
              {subtitle ? (
                <Text style={[styles.sheetSub, { color: palette.textMuted }]}>{subtitle}</Text>
              ) : null}
            </View>
          ) : null}
          <ScrollView
            showsVerticalScrollIndicator={false}
            style={styles.sheetScroll}
            contentContainerStyle={styles.sheetBody}
          >
            {children}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  screenTransition: {
    flex: 1,
    width: '100%',
  },
  segTrack: {
    flexDirection: 'row',
    padding: 4,
    borderRadius: RADII.md,
    borderWidth: 1,
    gap: 4,
  },
  segBtn: {
    flex: 1,
    minHeight: 38,
    borderRadius: 9,
    borderWidth: 1,
    borderColor: 'transparent',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
  segLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
  },
  card: {
    borderRadius: RADII.lg,
    borderWidth: 1,
    padding: 16,
    gap: 12,
  },
  hairlineRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 13,
    minHeight: 48,
    gap: 12,
  },
  hairlineLeft: {
    flex: 1,
    gap: 2,
  },
  hairlineRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  sheetBackdrop: {
    flex: 1,
    width: '100%',
    height: '100%',
    backgroundColor: 'rgba(15, 23, 42, 0.52)',
    justifyContent: 'flex-end',
  },
  sheetCard: {
    borderTopLeftRadius: RADII.sheet,
    borderTopRightRadius: RADII.sheet,
    borderTopWidth: 1,
    paddingHorizontal: 18,
    paddingTop: 12,
    paddingBottom: 24,
    maxHeight: '85%',
    maxWidth: 640,
    width: '100%',
    alignSelf: 'center',
  },
  grabHandle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: 14,
  },
  sheetHead: {
    marginBottom: 12,
    gap: 4,
  },
  sheetTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 18,
    fontWeight: '700',
  },
  sheetSub: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    lineHeight: 19,
  },
  sheetScroll: {
    flexGrow: 0,
    flexShrink: 1,
    flexBasis: 'auto',
    maxHeight: 520,
  },
  sheetBody: {
    gap: 12,
    paddingBottom: 8,
  },
});
