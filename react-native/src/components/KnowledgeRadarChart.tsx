import React, { useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import Svg, {
  Circle,
  G,
  Line,
  Polygon,
  Text as SvgText,
} from 'react-native-svg';
import { useApp } from '../context/AppContext';
import { SubjectRadarDataPoint } from '../services/knowledgeProfileService';
import { PREP404_COLORS, TYPE_FONTS } from '../theme/colors';

interface KnowledgeRadarChartProps {
  data: SubjectRadarDataPoint[];
  universityCode: string;
  height?: number;
}

/**
 * Pure React Native 360° Spider-Web Radar Chart built with `react-native` + `react-native-svg`.
 * Runs identically across Android (primary launch target), iOS, and Web without any React-Web DOM dependencies.
 */
export const KnowledgeRadarChart: React.FC<KnowledgeRadarChartProps> = ({
  data,
  universityCode,
  height = 290,
}) => {
  const { palette, isDark } = useApp();
  const [selectedIdx, setSelectedIdx] = useState<number>(0);

  const size = Math.min(height, 300);
  const cx = size / 2;
  const cy = size / 2;
  const radius = size * 0.34;
  const count = Math.max(3, data.length);
  const levels = [25, 50, 75, 100];

  const getCoords = (index: number, valuePercent: number, scale = 1) => {
    const angle = (Math.PI * 2 * index) / count - Math.PI / 2;
    const r = (Math.max(0, Math.min(100, valuePercent)) / 100) * radius * scale;
    return {
      x: cx + r * Math.cos(angle),
      y: cy + r * Math.sin(angle),
    };
  };

  const buildPolygonPoints = (key: keyof SubjectRadarDataPoint) =>
    data
      .map((item, idx) => {
        const val = Number(item[key] ?? 0);
        const pt = getCoords(idx, val);
        return `${pt.x.toFixed(1)},${pt.y.toFixed(1)}`;
      })
      .join(' ');

  const activePoint = data[selectedIdx] || data[0];

  return (
    <View style={styles.wrap}>
      <View style={[styles.svgContainer, { height: size }]}>
        <Svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          {/* Concentric spider-web rings */}
          {levels.map((lvl) => {
            const pts = data
              .map((_, i) => {
                const c = getCoords(i, lvl);
                return `${c.x.toFixed(1)},${c.y.toFixed(1)}`;
              })
              .join(' ');
            return (
              <Polygon
                key={`ring_${lvl}`}
                points={pts}
                fill="none"
                stroke={palette.borderStrong}
                strokeWidth={1}
                strokeDasharray={lvl === 100 ? undefined : '3,3'}
              />
            );
          })}

          {/* Radial spokes & interactive subject vertex labels */}
          {data.map((d, i) => {
            const outer = getCoords(i, 100);
            const labelPos = getCoords(i, 126);
            const isSelected = i === selectedIdx;
            return (
              <G key={d.subjectId}>
                <Line
                  x1={cx}
                  y1={cy}
                  x2={outer.x}
                  y2={outer.y}
                  stroke={palette.borderStrong}
                  strokeWidth={1}
                />
                <SvgText
                  x={labelPos.x}
                  y={labelPos.y}
                  fill={isSelected ? palette.primary : palette.text}
                  fontSize={11}
                  fontWeight="700"
                  fontFamily={TYPE_FONTS.display}
                  textAnchor="middle"
                  alignmentBaseline="middle"
                  onPress={() => setSelectedIdx(i)}
                >
                  {d.subject}
                </SvgText>
              </G>
            );
          })}

          {/* Layer 1: University Cut-Off Target Polygon */}
          <Polygon
            points={buildPolygonPoints('targetGoal')}
            fill={PREP404_COLORS.plum}
            fillOpacity={isDark ? 0.16 : 0.08}
            stroke={PREP404_COLORS.plum}
            strokeWidth={1.75}
            strokeDasharray="5,4"
          />

          {/* Layer 2: FSRS-4.5 Memory Retrievability Polygon */}
          <Polygon
            points={buildPolygonPoints('fsrsRetention')}
            fill="#10B981"
            fillOpacity={0.11}
            stroke="#10B981"
            strokeWidth={1.75}
          />

          {/* Layer 3: Current Learner Mastery Polygon */}
          <Polygon
            points={buildPolygonPoints('currentMastery')}
            fill={PREP404_COLORS.tangerine}
            fillOpacity={0.28}
            stroke={PREP404_COLORS.tangerine}
            strokeWidth={2.5}
          />

          {/* Vertex nodes for Current Mastery */}
          {data.map((d, i) => {
            const pt = getCoords(i, d.currentMastery);
            const isSelected = i === selectedIdx;
            return (
              <Circle
                key={`dot_${d.subjectId}`}
                cx={pt.x}
                cy={pt.y}
                r={isSelected ? 5.5 : 4}
                fill={PREP404_COLORS.tangerine}
                stroke={palette.surface}
                strokeWidth={1.5}
                onPress={() => setSelectedIdx(i)}
              />
            );
          })}
        </Svg>
      </View>

      {/* Interactive Subject Selector Pills (React Native TouchableOpacity) */}
      <View style={styles.subjectChipRow}>
        {data.map((item, idx) => {
          const active = idx === selectedIdx;
          return (
            <TouchableOpacity
              key={item.subjectId}
              onPress={() => setSelectedIdx(idx)}
              accessibilityRole="button"
              accessibilityLabel={`Inspect ${item.subject} radar metrics`}
              style={[
                styles.subjectChip,
                {
                  borderColor: active ? palette.primary : palette.border,
                  backgroundColor: active ? palette.creamTint : palette.surfaceMuted,
                },
              ]}
            >
              <Text
                style={{
                  fontFamily: TYPE_FONTS.mono,
                  fontSize: 11,
                  fontWeight: '700',
                  color: active ? palette.primary : palette.textMuted,
                }}
              >
                {item.subject}: {item.currentMastery}%
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Active Subject Readout Card */}
      {activePoint && (
        <View
          style={[
            styles.inspectorBar,
            {
              backgroundColor: palette.surfaceMuted,
              borderColor: palette.border,
            },
          ]}
        >
          <Text style={[styles.inspectorTitle, { color: palette.text }]}>
            {activePoint.subject} ({universityCode})
          </Text>
          <View style={styles.inspectorMetrics}>
            <Text style={[styles.inspectorMono, { color: PREP404_COLORS.tangerine }]}>
              Mastery {activePoint.currentMastery}%
            </Text>
            <Text style={[styles.inspectorMono, { color: PREP404_COLORS.plum }]}>
              Target {activePoint.targetGoal}%
            </Text>
            <Text style={[styles.inspectorMono, { color: '#10B981' }]}>
              FSRS {activePoint.fsrsRetention}%
            </Text>
          </View>
        </View>
      )}

      {/* Legend Bar */}
      <View style={styles.legendRow}>
        <View style={styles.legendItem}>
          <View
            style={[
              styles.legendDot,
              { backgroundColor: PREP404_COLORS.tangerine },
            ]}
          />
          <Text style={[styles.legendLabel, { color: palette.text }]}>
            Current Mastery
          </Text>
        </View>
        <View style={styles.legendItem}>
          <View
            style={[
              styles.legendDot,
              {
                backgroundColor: 'transparent',
                borderWidth: 2,
                borderColor: PREP404_COLORS.plum,
              },
            ]}
          />
          <Text style={[styles.legendLabel, { color: palette.textMuted }]}>
            {universityCode} Target
          </Text>
        </View>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: '#10B981' }]} />
          <Text style={[styles.legendLabel, { color: palette.textMuted }]}>
            FSRS Retention
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  wrap: {
    width: '100%',
    alignItems: 'center',
    gap: 10,
  },
  svgContainer: {
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
  },
  subjectChipRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 6,
  },
  subjectChip: {
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 8,
    borderWidth: 1,
  },
  inspectorBar: {
    width: '100%',
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
    borderWidth: 1,
    gap: 6,
  },
  inspectorTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 12.5,
    fontWeight: '700',
  },
  inspectorMetrics: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  inspectorMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
  },
  legendRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 14,
    paddingTop: 2,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  legendDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  legendLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    fontWeight: '600',
  },
});
