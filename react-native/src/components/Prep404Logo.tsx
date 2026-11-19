import React from 'react';
import { Image, Platform, StyleSheet, View } from 'react-native';

export const PREP404_WORDMARK_URI =
  '/assets/aistudio/prep404_wordmark_separate_transparent_31271426.png';
export const PREP404_SQUARE_LOGO_URI =
  '/assets/aistudio/prep404_square_logo_cream__1__5c2788d6.png';

interface Prep404LogoProps {
  compact?: boolean;
  isDark?: boolean;
  size?: 'sm' | 'md' | 'lg';
}

export const Prep404Logo: React.FC<Prep404LogoProps> = ({
  compact = false,
  isDark = false,
  size,
}) => {
  const tier = size ?? (compact ? 'sm' : 'md');
  const frameW = tier === 'sm' ? 132 : tier === 'lg' ? 216 : 182;

  // Source PNG is 1376x768:
  // Wordmark + rays + swoosh sit in x:[110..1266] (w=1156), y:[202..514] (h=312).
  // Tagline sits below y=525 and is excluded completely.
  const scale = frameW / 1156;
  const frameH = Math.round(312 * scale);
  const imgW = Math.round(1376 * scale);
  const imgH = Math.round(768 * scale);
  const offsetLeft = -Math.round(110 * scale);
  const offsetTop = -Math.round(202 * scale);

  const webImageStyle =
    Platform.OS === 'web'
      ? ({
          clipPath: 'inset(0% 0% 33.1% 0%)',
          ...(isDark
            ? {
                filter:
                  'brightness(1.22) drop-shadow(0 0 0.75px rgba(255, 255, 255, 0.92))',
              }
            : {}),
        } as unknown as Record<string, string>)
      : undefined;

  return (
    <View
      style={[
        styles.wordmarkFrame,
        {
          width: frameW,
          height: frameH,
        },
      ]}
    >
      <Image
        source={{ uri: PREP404_WORDMARK_URI }}
        resizeMode="stretch"
        accessibilityLabel="Prep404 logo"
        style={[
          {
            position: 'absolute',
            left: offsetLeft,
            top: offsetTop,
            width: imgW,
            height: imgH,
          },
          webImageStyle,
        ]}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  wordmarkFrame: {
    overflow: 'hidden',
    position: 'relative',
    backgroundColor: 'transparent',
  },
});
