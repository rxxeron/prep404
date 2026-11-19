import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { UNIVERSITY_MONOGRAMS } from '../data/universities';
import { TYPE_FONTS } from '../theme/colors';

interface UniversityLogoProps {
  code: string;
  size?: 'sm' | 'md' | 'lg';
}

export const UniversityLogo: React.FC<UniversityLogoProps> = ({ code, size = 'md' }) => {
  const mono = UNIVERSITY_MONOGRAMS[code.toLowerCase()] || {
    abbr: code.toUpperCase().slice(0, 5),
    bg: '#45204F',
    fg: '#FFFFFF',
  };

  const dim = size === 'sm' ? 32 : size === 'lg' ? 48 : 40;
  const fontSize = size === 'sm' ? 9 : size === 'lg' ? 12 : 10.5;

  return (
    <View
      style={[
        styles.box,
        {
          width: dim,
          height: dim,
          borderRadius: size === 'sm' ? 8 : 11,
          backgroundColor: mono.bg,
        },
      ]}
    >
      <Text style={[styles.text, { color: mono.fg, fontSize }]} numberOfLines={1}>
        {mono.abbr}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  box: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    fontFamily: TYPE_FONTS.display,
    fontWeight: '800',
    letterSpacing: -0.2,
  },
});
