import React from 'react';
import { StyleProp, Text, TextStyle } from 'react-native';

interface MathTextProps {
  text: string;
  style?: StyleProp<TextStyle>;
}

function formatLatexForNative(raw: string): string {
  return raw
    .replace(/\$\$/g, '')
    .replace(/\$/g, '')
    .replace(/\\frac\{([^}]+)\}\{([^}]+)\}/g, '($1)/($2)')
    .replace(/\\sqrt\{([^}]+)\}/g, '√($1)')
    .replace(/\\lim_\{([^}]+)\}/g, 'lim[$1]')
    .replace(/\\int_([^ ]+)\\^([^ ]+)/g, '∫[$1..$2]')
    .replace(/\\int/g, '∫')
    .replace(/\\to/g, '→')
    .replace(/\\implies/g, '⇒')
    .replace(/\\cdot/g, '·')
    .replace(/\\times/g, '×')
    .replace(/\\pi/g, 'π')
    .replace(/\\theta/g, 'θ')
    .replace(/\\alpha/g, 'α')
    .replace(/\\beta/g, 'β')
    .replace(/\\Delta/g, 'Δ')
    .replace(/\\Omega/g, 'Ω')
    .replace(/\\approx/g, '≈')
    .replace(/\\le/g, '≤')
    .replace(/\\ge/g, '≥')
    .replace(/\\neq/g, '≠')
    .replace(/\\vec\{([^}]+)\}/g, '$1⃗')
    .replace(/\\hat\{([^}]+)\}/g, '$1̂')
    .replace(/\\ln/g, 'ln')
    .replace(/\\sin/g, 'sin')
    .replace(/\\cos/g, 'cos')
    .replace(/\\tan/g, 'tan')
    .replace(/\\det/g, 'det')
    .replace(/\\begin\{pmatrix\}([\s\S]*?)\\end\{pmatrix\}/g, '[$1]')
    .replace(/\\\\/g, '; ')
    .replace(/\\,/g, ' ')
    .replace(/\\/g, '');
}

export const MathText: React.FC<MathTextProps> = ({ text, style }) => {
  return <Text style={style}>{formatLatexForNative(text)}</Text>;
};
