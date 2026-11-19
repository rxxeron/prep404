import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Svg, { Circle } from 'react-native-svg';
import { PREP404_COLORS, TYPE_FONTS } from '../theme/colors';

interface ProgressRingProps {
  percent: number;
  size?: number;
  strokeWidth?: number;
  color?: string;
  trackColor?: string;
  textColor?: string;
  labelColor?: string;
  label?: string;
}

export const ProgressRing: React.FC<ProgressRingProps> = ({
  percent,
  size = 76,
  strokeWidth = 7,
  color = PREP404_COLORS.tangerine,
  trackColor = '#E2E8F0',
  textColor = '#0F172A',
  labelColor,
  label,
}) => {
  const clamped = Math.max(0, Math.min(100, Math.round(percent)));
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const dashOffset = circumference * (1 - clamped / 100);

  return (
    <View style={[styles.wrap, { width: size, height: size }]}>
      <Svg width={size} height={size} style={styles.svg}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={trackColor}
          strokeWidth={strokeWidth}
          fill="none"
        />
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={color}
          strokeWidth={strokeWidth}
          strokeDasharray={`${circumference} ${circumference}`}
          strokeDashoffset={dashOffset}
          strokeLinecap="round"
          fill="none"
          rotation="-90"
          origin={`${size / 2}, ${size / 2}`}
        />
      </Svg>
      <View style={styles.center}>
        <Text style={[styles.value, { color: textColor, fontSize: Math.round(size * 0.22) }]}>
          {clamped}%
        </Text>
        {label ? (
          <Text
            style={[styles.label, { color: labelColor || textColor }]}
            numberOfLines={1}
          >
            {label}
          </Text>
        ) : null}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrap: { position: 'relative', alignItems: 'center', justifyContent: 'center' },
  svg: { position: 'absolute', top: 0, left: 0 },
  center: { alignItems: 'center', justifyContent: 'center' },
  value: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  label: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 9.5,
    fontWeight: '600',
    opacity: 0.8,
  },
});
