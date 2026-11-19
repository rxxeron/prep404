/**
 * FSRS (Free Spaced Repetition Scheduler) v4.5 Algorithm Implementation
 * Ported directly from lib/core/algorithms/fsrs.dart
 */

export enum FSRSRating {
  again = 1,
  hard = 2,
  good = 3,
  easy = 4,
}

export enum FSRSCardStatus {
  newCard = 'new',
  learning = 'learning',
  review = 'review',
  relearning = 'relearning',
}

export interface FSRSCardState {
  stability: number;
  difficulty: number;
  reps: number;
  lapses: number;
  status: FSRSCardStatus;
  lastReview: string; // ISO
  nextReview: string; // ISO
}

const FSRS_WEIGHTS = [
  0.4, 0.6, 2.4, 5.8, // w0..w3: initial stability for Again/Hard/Good/Easy
  4.93, 0.94, 0.86, 0.01,
  1.49, 0.14, 0.94,
  2.18, 0.05, 0.34, 1.26,
  0.29, 2.61,
] as const;

const REQUEST_RETENTION = 0.9;
const DECAY = -0.5;
const FACTOR = Math.pow(0.9, 1.0 / DECAY) - 1.0;

export function createInitialFSRSState(now = new Date()): FSRSCardState {
  const iso = now.toISOString();
  return {
    stability: 0.4,
    difficulty: 5.0,
    reps: 0,
    lapses: 0,
    status: FSRSCardStatus.newCard,
    lastReview: iso,
    nextReview: iso,
  };
}

export function calculateRetrievability(elapsedDays: number, stability: number): number {
  if (stability <= 0) return 0;
  return Math.pow(1.0 + (FACTOR * elapsedDays) / stability, DECAY);
}

export function calculateNextInterval(stability: number): number {
  const raw = (stability / FACTOR) * (Math.pow(REQUEST_RETENTION, 1.0 / DECAY) - 1.0);
  const rounded = Math.round(raw);
  return Math.max(1, Math.min(3650, rounded));
}

function clampDifficulty(d: number): number {
  return Math.max(1.0, Math.min(10.0, d));
}

function initDifficulty(rating: FSRSRating): number {
  const w4 = FSRS_WEIGHTS[4];
  const w5 = FSRS_WEIGHTS[5];
  return clampDifficulty(w4 - (rating - 3) * w5);
}

function nextDifficulty(currentD: number, rating: FSRSRating): number {
  const w6 = FSRS_WEIGHTS[6];
  const w7 = FSRS_WEIGHTS[7];
  const nextD = currentD - w6 * (rating - 3);
  const d0 = initDifficulty(FSRSRating.good);
  return clampDifficulty(w7 * d0 + (1.0 - w7) * nextD);
}

function nextRecallStability(
  d: number,
  s: number,
  r: number,
  rating: FSRSRating
): number {
  const hardPenalty = rating === FSRSRating.hard ? FSRS_WEIGHTS[15] : 1.0;
  const easyBonus = rating === FSRSRating.easy ? FSRS_WEIGHTS[16] : 1.0;
  return (
    s *
    (1.0 +
      Math.exp(FSRS_WEIGHTS[8]) *
        (11.0 - d) *
        Math.pow(s, -FSRS_WEIGHTS[9]) *
        (Math.exp((1.0 - r) * FSRS_WEIGHTS[10]) - 1.0) *
        hardPenalty *
        easyBonus)
  );
}

function nextForgetStability(d: number, s: number, r: number): number {
  return (
    FSRS_WEIGHTS[11] *
    Math.pow(d, -FSRS_WEIGHTS[12]) *
    (Math.pow(s + 1.0, FSRS_WEIGHTS[13]) - 1.0) *
    Math.exp((1.0 - r) * FSRS_WEIGHTS[14])
  );
}

export function reviewFSRSCard(
  current: FSRSCardState,
  rating: FSRSRating,
  now = new Date()
): { state: FSRSCardState; intervalDays: number } {
  const lastDate = new Date(current.lastReview);
  const elapsedDays = Math.max(0, Math.floor((now.getTime() - lastDate.getTime()) / 86400000));

  let newS: number;
  let newD: number;
  let newStatus: FSRSCardStatus;
  let newLapses = current.lapses;

  if (current.status === FSRSCardStatus.newCard) {
    newS = FSRS_WEIGHTS[rating - 1];
    newD = initDifficulty(rating);
    newStatus =
      rating === FSRSRating.again ? FSRSCardStatus.learning : FSRSCardStatus.review;
    if (rating === FSRSRating.again) newLapses++;
  } else {
    const r = calculateRetrievability(elapsedDays, current.stability);
    newD = nextDifficulty(current.difficulty, rating);

    if (rating === FSRSRating.again) {
      newS = nextForgetStability(newD, current.stability, r);
      newStatus = FSRSCardStatus.relearning;
      newLapses++;
    } else {
      newS = nextRecallStability(newD, current.stability, r, rating);
      newStatus = FSRSCardStatus.review;
    }
  }

  const intervalDays =
    rating === FSRSRating.again ? 1 : calculateNextInterval(newS);
  const nextReview = new Date(now.getTime() + intervalDays * 86400000).toISOString();

  return {
    state: {
      stability: newS,
      difficulty: newD,
      reps: current.reps + 1,
      lapses: newLapses,
      status: newStatus,
      lastReview: now.toISOString(),
      nextReview,
    },
    intervalDays,
  };
}
