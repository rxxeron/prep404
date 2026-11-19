import React, { useEffect, useMemo, useState } from 'react';
import {
  LayoutChangeEvent,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import Svg, {
  Circle,
  Defs,
  G,
  Line,
  LinearGradient,
  Path,
  Stop,
  Text as SvgText,
} from 'react-native-svg';
import { useApp } from '../context/AppContext';
import {
  computeD3TrendGeometry,
  PerformanceTrendDataset,
  SubjectTrendSeries,
} from '../services/performanceTrendService';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';

interface SubjectAccuracyTrendChartProps {
  dataset: PerformanceTrendDataset;
  height?: number;
}

/**
 * Pure React Native D3 Performance Trend Chart (`d3-scale`, `d3-shape`, `d3-array` + `react-native-svg`).
 * Tracks real accuracy percentages (0-100%) over chronological sessions across all subjects
 * with interactive subject isolation, multi-subject comparison, and point inspection.
 */
export const SubjectAccuracyTrendChart: React.FC<SubjectAccuracyTrendChartProps> = ({
  dataset,
  height = 236,
}) => {
  const { palette, isDark } = useApp();
  const [chartWidth, setChartWidth] = useState<number>(340);
  const [selectedFilter, setSelectedFilter] = useState<string>('compare');
  const [selectedSessionKey, setSelectedSessionKey] = useState<string | null>(
    null
  );

  // Determine available filter tabs: Compare All (when >= 2 subjects), All Subjects, + each real subject
  const filterOptions = useMemo(() => {
    const opts: { id: string; label: string; color: string; latest?: number }[] = [];
    if (dataset.subjectSeries.length >= 2) {
      opts.push({
        id: 'compare',
        label: 'Compare Subjects',
        color: palette.primary,
      });
    }
    opts.push({
      id: 'all',
      label: 'All Subjects',
      color: dataset.overallSeries.color,
      latest: dataset.overallSeries.latestAccuracy,
    });
    for (const s of dataset.subjectSeries) {
      opts.push({
        id: s.subjectId,
        label: s.shortLabel,
        color: s.color,
        latest: s.latestAccuracy,
      });
    }
    return opts;
  }, [dataset, palette.primary]);

  // Keep selectedFilter valid when dataset changes
  useEffect(() => {
    const valid = filterOptions.some((o) => o.id === selectedFilter);
    if (!valid) {
      setSelectedFilter(
        dataset.subjectSeries.length >= 2 ? 'compare' : 'all'
      );
    }
  }, [filterOptions, selectedFilter, dataset.subjectSeries.length]);

  const activeSeriesList: SubjectTrendSeries[] = useMemo(() => {
    if (!dataset.hasData) return [];
    if (selectedFilter === 'compare') {
      return dataset.subjectSeries.slice(0, 5);
    }
    if (selectedFilter === 'all') {
      return [dataset.overallSeries];
    }
    const found = dataset.subjectSeries.find(
      (s) => s.subjectId === selectedFilter
    );
    return found ? [found] : [dataset.overallSeries];
  }, [dataset, selectedFilter]);

  const primarySeries: SubjectTrendSeries | undefined = useMemo(() => {
    if (!dataset.hasData) return undefined;
    if (selectedFilter === 'compare' || selectedFilter === 'all') {
      return dataset.overallSeries;
    }
    return (
      dataset.subjectSeries.find((s) => s.subjectId === selectedFilter) ||
      dataset.overallSeries
    );
  }, [dataset, selectedFilter]);

  // Default inspected checkpoint to the most recent session
  const activeSessionKey = useMemo(() => {
    if (dataset.timelineKeys.length === 0) return null;
    if (
      selectedSessionKey &&
      dataset.timelineKeys.includes(selectedSessionKey)
    ) {
      return selectedSessionKey;
    }
    return dataset.timelineKeys[dataset.timelineKeys.length - 1];
  }, [dataset.timelineKeys, selectedSessionKey]);

  const geometry = useMemo(
    () =>
      computeD3TrendGeometry({
        seriesList: activeSeriesList,
        timelineKeys: dataset.timelineKeys,
        timelineLabels: dataset.timelineLabels,
        width: chartWidth,
        height,
      }),
    [
      activeSeriesList,
      dataset.timelineKeys,
      dataset.timelineLabels,
      chartWidth,
      height,
    ]
  );

  const handleLayout = (event: LayoutChangeEvent) => {
    const nextWidth = Math.floor(event.nativeEvent.layout.width);
    if (nextWidth > 200 && Math.abs(nextWidth - chartWidth) > 4) {
      setChartWidth(nextWidth);
    }
  };

  const activeCrosshairX = useMemo(() => {
    if (!activeSessionKey) return null;
    const match = geometry.xTicks.find((t) => t.key === activeSessionKey);
    return match ? match.x : null;
  }, [activeSessionKey, geometry.xTicks]);

  const inspectedRows = useMemo(() => {
    if (!activeSessionKey) return [];
    const targetList =
      selectedFilter === 'compare' ? dataset.subjectSeries : activeSeriesList;
    return targetList
      .map((s) => {
        const pt = s.points.find((p) => p.sessionKey === activeSessionKey);
        return pt ? { series: s, point: pt } : null;
      })
      .filter(
        (x): x is { series: SubjectTrendSeries; point: SubjectTrendSeries['points'][number] } =>
          Boolean(x)
      );
  }, [activeSessionKey, selectedFilter, dataset.subjectSeries, activeSeriesList]);

  const inspectedDateLabel =
    inspectedRows[0]?.point.fullDateLabel ||
    (activeSessionKey ? dataset.timelineLabels[activeSessionKey] : '');

  const showAreaFill = activeSeriesList.length === 1;

  const formatDelta = (delta: number): string => {
    if (delta > 0) return `+${delta}%`;
    if (delta < 0) return `${delta}%`;
    return '0%';
  };

  return (
    <View style={styles.container} onLayout={handleLayout}>
      {/* Header & Unboxed Metadata Summary */}
      <View style={styles.headerBlock}>
        <View style={styles.headerRow}>
          <Text style={[styles.kicker, { color: palette.primary }]}>
            D3 ACCURACY ANALYTICS
          </Text>
          {primarySeries && (
            <Text
              style={[
                styles.deltaMono,
                {
                  color:
                    primarySeries.deltaPercent > 0
                      ? palette.success
                      : primarySeries.deltaPercent < 0
                        ? palette.danger
                        : palette.textMuted,
                },
              ]}
            >
              {primarySeries.points.length >= 2
                ? `${formatDelta(primarySeries.deltaPercent)} trend`
                : '1 checkpoint'}
            </Text>
          )}
        </View>

        <Text style={[styles.heading, { color: palette.text }]}>
          Subject Accuracy Trends Over Time
        </Text>

        {dataset.hasData && primarySeries ? (
          <Text style={[styles.metaLine, { color: palette.textMuted }]}>
            {primarySeries.subjectName} · Latest {primarySeries.latestAccuracy}% ·
            Avg {primarySeries.averageAccuracy}% · {primarySeries.totalAttempts}{' '}
            attempts · {primarySeries.totalWrong} mistakes
          </Text>
        ) : (
          <Text style={[styles.metaLine, { color: palette.textMuted }]}>
            0 attempts logged · Accuracy curves plot automatically from real
            exams, practice drills, and telemetry locks
          </Text>
        )}
      </View>

      {/* Interactive Subject Filter Bar */}
      {dataset.hasData && (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.filterBar}
        >
          {filterOptions.map((opt) => {
            const isActive = opt.id === selectedFilter;
            return (
              <TouchableOpacity
                key={opt.id}
                onPress={() => setSelectedFilter(opt.id)}
                accessibilityRole="button"
                accessibilityState={{ selected: isActive }}
                accessibilityLabel={`Filter accuracy trend by ${opt.label}`}
                style={[
                  styles.filterBtn,
                  {
                    backgroundColor: isActive
                      ? isDark
                        ? palette.surfaceMuted
                        : '#0F172A'
                      : palette.surfaceMuted,
                    borderColor: isActive ? opt.color : palette.border,
                  },
                ]}
              >
                <View
                  style={[styles.swatchLine, { backgroundColor: opt.color }]}
                />
                <Text
                  numberOfLines={1}
                  style={[
                    styles.filterBtnText,
                    {
                      color: isActive
                        ? '#FFFFFF'
                        : palette.text,
                    },
                  ]}
                >
                  {opt.label}
                  {opt.latest !== undefined ? ` ${opt.latest}%` : ''}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      )}

      {/* D3 SVG Trend Canvas */}
      <View
        style={[
          styles.chartCanvasWrap,
          {
            backgroundColor: isDark ? '#0F1622' : '#F8FAFC',
            borderColor: palette.border,
          },
        ]}
      >
        <Svg
          width={geometry.width}
          height={geometry.height}
          viewBox={`0 0 ${geometry.width} ${geometry.height}`}
        >
          <Defs>
            {geometry.renderedSeries.map((s) => (
              <LinearGradient
                key={`grad_${s.subjectId}`}
                id={`d3_area_${s.subjectId}`}
                x1="0"
                y1="0"
                x2="0"
                y2="1"
              >
                <Stop
                  offset="0%"
                  stopColor={s.color}
                  stopOpacity={isDark ? 0.34 : 0.22}
                />
                <Stop offset="100%" stopColor={s.color} stopOpacity={0.01} />
              </LinearGradient>
            ))}
          </Defs>

          <G
            transform={`translate(${geometry.margin.left}, ${geometry.margin.top})`}
          >
            {/* D3 Y-Axis Gridlines & Labels (0% - 100%) */}
            {geometry.yTicks.map((tick) => (
              <G key={`y_${tick.value}`}>
                <Line
                  x1={0}
                  y1={tick.y}
                  x2={geometry.innerWidth}
                  y2={tick.y}
                  stroke={palette.border}
                  strokeWidth={1}
                  strokeDasharray={tick.value === 0 ? undefined : '3,3'}
                />
                <SvgText
                  x={-8}
                  y={tick.y + 3.5}
                  fill={palette.textSubtle}
                  fontSize={10}
                  fontFamily={TYPE_FONTS.mono}
                  textAnchor="end"
                >
                  {tick.label}
                </SvgText>
              </G>
            ))}

            {/* 80% Private University Target Benchmark Line */}
            <Line
              x1={0}
              y1={geometry.targetLineY}
              x2={geometry.innerWidth}
              y2={geometry.targetLineY}
              stroke={PREP404_COLORS.emerald}
              strokeOpacity={0.55}
              strokeWidth={1.2}
              strokeDasharray="5,4"
            />
            <SvgText
              x={geometry.innerWidth - 2}
              y={geometry.targetLineY - 5}
              fill={PREP404_COLORS.emerald}
              fontSize={9.5}
              fontWeight="700"
              fontFamily={TYPE_FONTS.mono}
              textAnchor="end"
            >
              80% target
            </SvgText>

            {/* Active Session Vertical Crosshair */}
            {dataset.hasData && activeCrosshairX !== null && (
              <Line
                x1={activeCrosshairX}
                y1={0}
                x2={activeCrosshairX}
                y2={geometry.innerHeight}
                stroke={palette.borderStrong}
                strokeWidth={1.2}
                strokeDasharray="2,2"
              />
            )}

            {/* D3 Area Fill (single series focus mode) */}
            {showAreaFill &&
              geometry.renderedSeries.map((s) =>
                s.areaPath ? (
                  <Path
                    key={`area_${s.subjectId}`}
                    d={s.areaPath}
                    fill={`url(#d3_area_${s.subjectId})`}
                  />
                ) : null
              )}

            {/* D3 Line Curves (curveMonotoneX) */}
            {geometry.renderedSeries.map((s) =>
              s.linePath ? (
                <Path
                  key={`line_${s.subjectId}`}
                  d={s.linePath}
                  fill="none"
                  stroke={s.color}
                  strokeWidth={selectedFilter === 'compare' ? 2.25 : 2.75}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              ) : null
            )}

            {/* Interactive Data Point Nodes */}
            {geometry.renderedSeries.map((s) =>
              s.plottedPoints.map((pt) => {
                const isSelected = pt.point.sessionKey === activeSessionKey;
                return (
                  <G key={`pt_${s.subjectId}_${pt.point.sessionKey}`}>
                    {isSelected && (
                      <Circle
                        cx={pt.x}
                        cy={pt.y}
                        r={8}
                        fill={s.color}
                        fillOpacity={0.18}
                      />
                    )}
                    <Circle
                      cx={pt.x}
                      cy={pt.y}
                      r={isSelected ? 5 : 3.8}
                      fill={s.color}
                      stroke={palette.surface}
                      strokeWidth={1.8}
                    />
                  </G>
                );
              })
            )}

            {/* D3 X-Axis Chronological Tick Labels */}
            {geometry.xTicks.map((tick, idx) => {
              const showTick =
                geometry.xTicks.length <= 6 ||
                idx === 0 ||
                idx === geometry.xTicks.length - 1 ||
                idx % Math.ceil(geometry.xTicks.length / 5) === 0;
              if (!showTick) return null;
              const isSelected = tick.key === activeSessionKey;
              return (
                <SvgText
                  key={`x_${tick.key}`}
                  x={tick.x}
                  y={geometry.innerHeight + 22}
                  fill={isSelected ? palette.text : palette.textSubtle}
                  fontSize={10}
                  fontWeight={isSelected ? '700' : '500'}
                  fontFamily={TYPE_FONTS.mono}
                  textAnchor="middle"
                >
                  {tick.label}
                </SvgText>
              );
            })}
          </G>
        </Svg>

        {/* Cross-platform React Native touch columns over D3 checkpoints (zero SVG responder warnings) */}
        {dataset.hasData &&
          geometry.xTicks.map((tick) => {
            const leftPos = Math.max(
              0,
              geometry.margin.left + tick.x - 22
            );
            return (
              <Pressable
                key={`hit_${tick.key}`}
                onPress={() => setSelectedSessionKey(tick.key)}
                accessibilityRole="button"
                accessibilityLabel={`Select chart point ${tick.label}`}
                style={{
                  position: 'absolute',
                  top: geometry.margin.top,
                  left: leftPos,
                  width: 44,
                  height: geometry.innerHeight + 28,
                }}
              />
            );
          })}

        {/* Honest Uncalibrated Overlay when 0 real attempts exist */}
        {!dataset.hasData && (
          <View style={styles.emptyOverlay} pointerEvents="none">
            <Text style={[styles.emptyOverlayTitle, { color: palette.text }]}>
              Awaiting Real Attempt Data
            </Text>
            <Text
              style={[styles.emptyOverlayDesc, { color: palette.textMuted }]}
            >
              Complete an adaptive re-test, live exam, or practice session to
              track subject accuracy trends over time.
            </Text>
          </View>
        )}
      </View>

      {/* Accessible Checkpoint Scrubber & Selected Point Readout */}
      {dataset.hasData && (
        <View style={styles.footerSection}>
          {dataset.timelineKeys.length > 1 && (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.sessionRow}
            >
              {dataset.timelineKeys.map((key) => {
                const active = key === activeSessionKey;
                const label = dataset.timelineLabels[key] || key;
                return (
                  <TouchableOpacity
                    key={key}
                    onPress={() => setSelectedSessionKey(key)}
                    accessibilityRole="button"
                    accessibilityState={{ selected: active }}
                    accessibilityLabel={`Inspect checkpoint ${label}`}
                    style={[
                      styles.sessionBtn,
                      {
                        backgroundColor: active
                          ? palette.creamTint
                          : 'transparent',
                        borderColor: active ? palette.primary : palette.border,
                      },
                    ]}
                  >
                    <Text
                      style={[
                        styles.sessionBtnText,
                        {
                          color: active ? palette.primary : palette.textMuted,
                        },
                      ]}
                    >
                      {label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          )}

          {/* Selected Checkpoint Inspector */}
          {inspectedRows.length > 0 && (
            <View
              style={[
                styles.inspectorCard,
                {
                  backgroundColor: palette.surfaceMuted,
                  borderColor: palette.border,
                },
              ]}
            >
              <View style={styles.inspectorHeader}>
                <Text style={[styles.inspectorTitle, { color: palette.text }]}>
                  Checkpoint{' '}
                  {activeSessionKey
                    ? dataset.timelineLabels[activeSessionKey]
                    : ''}
                </Text>
                <Text
                  style={[styles.inspectorDate, { color: palette.textSubtle }]}
                >
                  {inspectedDateLabel}
                </Text>
              </View>
              <View style={styles.inspectorList}>
                {inspectedRows.map(({ series, point }) => (
                  <View
                    key={`insp_${series.subjectId}`}
                    style={styles.inspectorRow}
                  >
                    <View style={styles.inspectorSubject}>
                      <View
                        style={[
                          styles.swatchLine,
                          { backgroundColor: series.color },
                        ]}
                      />
                      <Text
                        style={[styles.inspectorName, { color: palette.text }]}
                      >
                        {series.subjectName}
                      </Text>
                    </View>
                    <Text
                      style={[
                        styles.inspectorMetric,
                        { color: palette.text },
                      ]}
                    >
                      {point.accuracyPercent}% ({point.correctCount}/
                      {point.attemptCount})
                    </Text>
                  </View>
                ))}
              </View>
            </View>
          )}
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    gap: 12,
  },
  headerBlock: {
    gap: 4,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  kicker: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.4,
  },
  deltaMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  heading: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 17,
    fontWeight: '800',
  },
  metaLine: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    lineHeight: 18,
    fontVariant: ['tabular-nums'],
  },
  filterBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 2,
  },
  filterBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 11,
    paddingVertical: 7,
    borderRadius: RADII.sm,
    borderWidth: 1,
    minHeight: 36,
  },
  swatchLine: {
    width: 10,
    height: 3,
    borderRadius: 2,
  },
  filterBtnText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  chartCanvasWrap: {
    width: '100%',
    borderRadius: RADII.md,
    borderWidth: 1,
    overflow: 'hidden',
    position: 'relative',
  },
  emptyOverlay: {
    position: 'absolute',
    top: 22,
    left: 44,
    right: 20,
    bottom: 34,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 14,
    gap: 4,
  },
  emptyOverlayTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 14,
    fontWeight: '700',
    textAlign: 'center',
  },
  emptyOverlayDesc: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    lineHeight: 17,
    textAlign: 'center',
    maxWidth: 320,
  },
  footerSection: {
    gap: 10,
  },
  sessionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  sessionBtn: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: RADII.sm,
    borderWidth: 1,
    minHeight: 30,
    justifyContent: 'center',
  },
  sessionBtnText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
  },
  inspectorCard: {
    borderRadius: RADII.md,
    borderWidth: 1,
    padding: 12,
    gap: 8,
  },
  inspectorHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  inspectorTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13,
    fontWeight: '700',
  },
  inspectorDate: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontVariant: ['tabular-nums'],
  },
  inspectorList: {
    gap: 6,
  },
  inspectorRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  inspectorSubject: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  inspectorName: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    fontWeight: '600',
  },
  inspectorMetric: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
});
