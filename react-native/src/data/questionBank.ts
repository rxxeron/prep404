import { DailyExamDetails, LeaderboardEntry, Question } from '../types';

export const QUESTION_BANK: Question[] = [
  // ================= HIGHER MATHEMATICS =================
  {
    id: 'q_hm_01',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'calculus_limits',
    topicName: 'Limits & Continuity',
    universityTags: ['BRACU', 'NSU', 'AUST', 'IUB'],
    text: 'Evaluate the limit: $\\lim_{x \\to 0} \\frac{\\sin(5x)}{\\tan(3x)}$',
    options: [
      { id: 'A', text: '$\\frac{5}{3}$', isCorrect: true },
      { id: 'B', text: '$\\frac{3}{5}$' },
      { id: 'C', text: '$1$' },
      { id: 'D', text: '$0$' },
    ],
    correctOptionId: 'A',
    explanation:
      'Using standard trigonometric limits $\\lim_{u \\to 0} \\frac{\\sin u}{u} = 1$ and $\\lim_{v \\to 0} \\frac{\\tan v}{v} = 1$:\n$\\lim_{x \\to 0} \\frac{\\sin(5x)}{5x} \\cdot \\frac{3x}{\\tan(3x)} \\cdot \\frac{5}{3} = 1 \\cdot 1 \\cdot \\frac{5}{3} = \\frac{5}{3}$.',
    hints: [
      'Rewrite the fraction by multiplying numerator and denominator by $5x$ and $3x$.',
      'Recall that for small angles $\\theta \\to 0$, both $\\sin(k\\theta) \\approx k\\theta$ and $\\tan(k\\theta) \\approx k\\theta$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_hm_02',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'calculus_diff',
    topicName: 'Differentiation & Tangents',
    universityTags: ['BRACU', 'NSU', 'AUST', 'EWU'],
    text: 'If $y = e^{2x} \\ln(x)$, what is $\\frac{dy}{dx}$ at $x = 1$?',
    options: [
      { id: 'A', text: '$2e^2$' },
      { id: 'B', text: '$e^2$', isCorrect: true },
      { id: 'C', text: '$3e^2$' },
      { id: 'D', text: '$e$' },
    ],
    correctOptionId: 'B',
    explanation:
      'Apply the product rule: $\\frac{dy}{dx} = 2e^{2x}\\ln(x) + e^{2x} \\cdot \\frac{1}{x}$.\nEvaluating at $x = 1$: since $\\ln(1) = 0$, we get $2e^2(0) + e^2(1) = e^2$.',
    hints: [
      'Use the product rule $(uv)\' = u\'v + uv\'$ with $u = e^{2x}$ and $v = \\ln(x)$.',
      'What is the exact value of $\\ln(1)$? Substitute $x = 1$ carefully.',
    ],
    hasMath: true,
    difficulty: 'medium',
  },
  {
    id: 'q_hm_03',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'calculus_int',
    topicName: 'Definite & Indefinite Integrals',
    universityTags: ['BRACU', 'AUST', 'UIU'],
    text: 'Evaluate the definite integral: $\\int_0^{\\pi/2} \\sin(x) \\cos(x)\\,dx$',
    options: [
      { id: 'A', text: '$1$' },
      { id: 'B', text: '$\\frac{1}{4}$' },
      { id: 'C', text: '$\\frac{1}{2}$', isCorrect: true },
      { id: 'D', text: '$\\frac{\\pi}{4}$' },
    ],
    correctOptionId: 'C',
    explanation:
      'Substitute $u = \\sin(x)$, so $du = \\cos(x)\\,dx$. Limits change from $x=0 \\implies u=0$ to $x=\\pi/2 \\implies u=1$.\n$\\int_0^1 u\\,du = \\left[\\frac{u^2}{2}\\right]_0^1 = \\frac{1}{2}$.',
    hints: [
      'Notice that $\\cos(x)$ is the derivative of $\\sin(x)$, or use $\\sin(2x) = 2\\sin x\\cos x$.',
      'Integrate $\\frac{1}{2}\\sin(2x)$ over $[0, \\pi/2]$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_hm_04',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'matrices',
    topicName: 'Matrices & Determinants',
    universityTags: ['NSU', 'BRACU', 'AUST', 'AIUB'],
    text: 'For what value of $k$ is the matrix $A = \\begin{pmatrix} k & 4 \\\\ 3 & 6 \\end{pmatrix}$ singular (non-invertible)?',
    options: [
      { id: 'A', text: '$k = 2$', isCorrect: true },
      { id: 'B', text: '$k = 3$' },
      { id: 'C', text: '$k = -2$' },
      { id: 'D', text: '$k = 8$' },
    ],
    correctOptionId: 'A',
    explanation:
      'A matrix is singular when its determinant $\\det(A) = 0$.\n$\\det(A) = 6k - (4)(3) = 6k - 12 = 0 \\implies k = 2$.',
    hints: [
      'A square matrix has no inverse precisely when $\\det(A) = ad - bc = 0$.',
      'Set $6k - 12 = 0$ and solve for $k$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_hm_05',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'vectors',
    topicName: 'Vectors: Dot & Cross Product',
    universityTags: ['AUST', 'BRACU', 'AIUB', 'UIU'],
    text: 'If $\\vec{a} = 2\\hat{i} + 3\\hat{j} - \\hat{k}$ and $\\vec{b} = \\hat{i} - 2\\hat{j} + m\\hat{k}$ are perpendicular, find $m$.',
    options: [
      { id: 'A', text: '$m = -4$', isCorrect: true },
      { id: 'B', text: '$m = 4$' },
      { id: 'C', text: '$m = -2$' },
      { id: 'D', text: '$m = 8$' },
    ],
    correctOptionId: 'A',
    explanation:
      'Two non-zero vectors are perpendicular when their dot product is zero: $\\vec{a} \\cdot \\vec{b} = 0$.\n$(2)(1) + (3)(-2) + (-1)(m) = 2 - 6 - m = 0 \\implies m = -4$.',
    hints: [
      'Orthogonal vectors satisfy $\\vec{a} \\cdot \\vec{b} = a_x b_x + a_y b_y + a_z b_z = 0$.',
      'Compute $2(1) + 3(-2) - 1(m) = 0$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_hm_06',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'conics',
    topicName: 'Coordinate Geometry & Conics',
    universityTags: ['AUST', 'BRACU', 'NSU'],
    text: 'Find the radius of the circle $x^2 + y^2 - 6x + 8y - 11 = 0$.',
    options: [
      { id: 'A', text: '$4$' },
      { id: 'B', text: '$5$' },
      { id: 'C', text: '$6$', isCorrect: true },
      { id: 'D', text: '$\\sqrt{14}$' },
    ],
    correctOptionId: 'C',
    explanation:
      'Compare with $x^2 + y^2 + 2gx + 2fy + c = 0$: $g = -3$, $f = 4$, $c = -11$.\nRadius $r = \\sqrt{g^2 + f^2 - c} = \\sqrt{(-3)^2 + 4^2 - (-11)} = \\sqrt{9 + 16 + 11} = \\sqrt{36} = 6$.',
    hints: [
      'Complete the square for both $x$ and $y$, or use $r = \\sqrt{g^2 + f^2 - c}$.',
      'Be careful with the sign of $c = -11$ when subtracting $c$.',
    ],
    hasMath: true,
    difficulty: 'medium',
  },
  {
    id: 'q_hm_07',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'complex_numbers',
    topicName: 'Complex Numbers & Quadratics',
    universityTags: ['BRACU', 'AUST', 'EWU'],
    text: 'What is the modulus of the complex number $z = \\frac{3 + 4i}{1 - 2i}$?',
    options: [
      { id: 'A', text: '$\\sqrt{5}$', isCorrect: true },
      { id: 'B', text: '$5$' },
      { id: 'C', text: '$\\frac{5}{3}$' },
      { id: 'D', text: '$\\sqrt{3}$' },
    ],
    correctOptionId: 'A',
    explanation:
      'Use $|z_1 / z_2| = |z_1| / |z_2|$.\n$|3 + 4i| = \\sqrt{3^2 + 4^2} = 5$ and $|1 - 2i| = \\sqrt{1^2 + (-2)^2} = \\sqrt{5}$.\nThus $|z| = \\frac{5}{\\sqrt{5}} = \\sqrt{5}$.',
    hints: [
      'You do not need to rationalize first — modulus distributes over division!',
      'Compute $\\frac{|3+4i|}{|1-2i|}$.',
    ],
    hasMath: true,
    difficulty: 'medium',
  },
  {
    id: 'q_hm_08',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    topicId: 'trigonometry',
    topicName: 'Trigonometric Identities',
    universityTags: ['NSU', 'AUST', 'EWU', 'UAP'],
    text: 'If $\\sin\\theta + \\cos\\theta = \\sqrt{2}\\cos\\theta$, what is the value of $\\tan\\theta$?',
    options: [
      { id: 'A', text: '$\\sqrt{2} + 1$' },
      { id: 'B', text: '$\\sqrt{2} - 1$', isCorrect: true },
      { id: 'C', text: '$1$' },
      { id: 'D', text: '$\\frac{1}{\\sqrt{2}}$' },
    ],
    correctOptionId: 'B',
    explanation:
      'Divide both sides by $\\cos\\theta$ (assuming $\\cos\\theta \\neq 0$):\n$\\tan\\theta + 1 = \\sqrt{2} \\implies \\tan\\theta = \\sqrt{2} - 1$.',
    hints: [
      'Divide the entire equation by $\\cos\\theta$ to introduce $\\tan\\theta$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },

  // ================= GENERAL / QUANTITATIVE MATH =================
  {
    id: 'q_qm_01',
    subjectId: 'quant_math',
    subjectName: 'General Mathematics',
    topicId: 'algebra_quant',
    topicName: 'Algebra & Percentages',
    universityTags: ['NSU', 'BRACU', 'IUB', 'AIUB', 'UIU'],
    text: 'A laptop price is increased by $20\\%$ and then decreased by $20\\%$ during a campus sale. What is the net percentage change from the original price?',
    options: [
      { id: 'A', text: '$0\\%$ (No change)' },
      { id: 'B', text: '$4\\%$ increase' },
      { id: 'C', text: '$4\\%$ decrease', isCorrect: true },
      { id: 'D', text: '$2\\%$ decrease' },
    ],
    correctOptionId: 'C',
    explanation:
      'Start with $100$. After a $20\\%$ increase: $100 \\times 1.2 = 120$.\nAfter a $20\\%$ decrease on $120$: $120 \\times 0.8 = 96$.\nNet change: $96 - 100 = -4\\%$, a $4\\%$ decrease.',
    hints: [
      'Pick an easy starting price like $100$ BDT.',
      'The second $20\\%$ applies to the *new* higher price, not the original $100$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_qm_02',
    subjectId: 'quant_math',
    subjectName: 'General Mathematics',
    topicId: 'exponents_logs',
    topicName: 'Exponents & Logarithms',
    universityTags: ['NSU', 'BRACU', 'IUB', 'EWU'],
    text: 'If $\\log_2(x) + \\log_2(x - 2) = 3$, find the value of $x$.',
    options: [
      { id: 'A', text: '$4$', isCorrect: true },
      { id: 'B', text: '$2$' },
      { id: 'C', text: '$-2$' },
      { id: 'D', text: '$6$' },
    ],
    correctOptionId: 'A',
    explanation:
      'Combine logs: $\\log_2(x(x - 2)) = 3 \\implies x(x - 2) = 2^3 = 8$.\n$x^2 - 2x - 8 = 0 \\implies (x - 4)(x + 2) = 0$.\nSince logarithms require positive arguments ($x - 2 > 0$), $x = 4$.',
    hints: [
      'Use the product rule $\\log_b(A) + \\log_b(B) = \\log_b(AB)$.',
      'Remember to discard negative roots that make $\\log_2(x)$ undefined.',
    ],
    hasMath: true,
    difficulty: 'medium',
  },
  {
    id: 'q_qm_03',
    subjectId: 'quant_math',
    subjectName: 'General Mathematics',
    topicId: 'permutation',
    topicName: 'Permutation & Probability',
    universityTags: ['NSU', 'IUB', 'BRACU', 'UIU'],
    text: 'In how many distinct ways can the letters of the word **BANGLA** be arranged?',
    options: [
      { id: 'A', text: '$720$' },
      { id: 'B', text: '$360$', isCorrect: true },
      { id: 'C', text: '$120$' },
      { id: 'D', text: '$180$' },
    ],
    correctOptionId: 'B',
    explanation:
      'BANGLA has $6$ letters total, with the letter $A$ repeated $2$ times.\nDistinct permutations $= \\frac{6!}{2!} = \\frac{720}{2} = 360$.',
    hints: [
      'Count total letters in BANGLA and check which letters repeat.',
      'Divide $n!$ by the factorial of each repeated letter count.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_qm_04',
    subjectId: 'quant_math',
    subjectName: 'General Mathematics',
    topicId: 'geometry_mensuration',
    topicName: 'Geometry & Mensuration',
    universityTags: ['NSU', 'IUB', 'AIUB', 'UAP'],
    text: 'A right circular cylinder has radius $r = 3\\text{ cm}$ and height $h = 7\\text{ cm}$. What is its total surface area in terms of $\\pi$?',
    options: [
      { id: 'A', text: '$42\\pi\\text{ cm}^2$' },
      { id: 'B', text: '$60\\pi\\text{ cm}^2$', isCorrect: true },
      { id: 'C', text: '$63\\pi\\text{ cm}^2$' },
      { id: 'D', text: '$51\\pi\\text{ cm}^2$' },
    ],
    correctOptionId: 'B',
    explanation:
      'Total Surface Area $= 2\\pi r(r + h) = 2\\pi(3)(3 + 7) = 6\\pi(10) = 60\\pi\\text{ cm}^2$.',
    hints: [
      'Include both circular end caps ($2\\pi r^2$) and the curved lateral area ($2\\pi rh$).',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_qm_05',
    subjectId: 'quant_math',
    subjectName: 'General Mathematics',
    topicId: 'word_problems',
    topicName: 'Rates, Ratios & Work',
    universityTags: ['NSU', 'IUB', 'BRACU', 'EWU'],
    text: 'Pipe A can fill a tank in $6$ hours and Pipe B can fill it in $4$ hours. If both pipes are opened together, how long will it take to fill the tank?',
    options: [
      { id: 'A', text: '$2.4\\text{ hours}$', isCorrect: true },
      { id: 'B', text: '$2.5\\text{ hours}$' },
      { id: 'C', text: '$5.0\\text{ hours}$' },
      { id: 'D', text: '$3.2\\text{ hours}$' },
    ],
    correctOptionId: 'A',
    explanation:
      'Combined rate $= \\frac{1}{6} + \\frac{1}{4} = \\frac{2 + 3}{12} = \\frac{5}{12}$ tank/hour.\nTime $= \\frac{12}{5} = 2.4\\text{ hours}$ ($2$ hours $24$ minutes).',
    hints: [
      'Add their hourly work rates $\\frac{1}{6} + \\frac{1}{4}$ and take the reciprocal.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_qm_06',
    subjectId: 'quant_math',
    subjectName: 'General Mathematics',
    topicId: 'data_prob',
    topicName: 'Data & Probability',
    universityTags: ['NSU', 'IUB', 'AIUB'],
    text: 'Two fair six-sided dice are rolled simultaneously. What is the probability that the sum of the two faces is $9$?',
    options: [
      { id: 'A', text: '$\\frac{1}{6}$' },
      { id: 'B', text: '$\\frac{1}{9}$', isCorrect: true },
      { id: 'C', text: '$\\frac{1}{12}$' },
      { id: 'D', text: '$\\frac{5}{36}$' },
    ],
    correctOptionId: 'B',
    explanation:
      'Total outcomes $= 6 \\times 6 = 36$. Pairs summing to $9$: $(3,6), (4,5), (5,4), (6,3)$ — $4$ outcomes.\nProbability $= \\frac{4}{36} = \\frac{1}{9}$.',
    hints: [
      'List all ordered pairs $(a, b)$ with $1 \\le a, b \\le 6$ such that $a + b = 9$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },

  // ================= PHYSICS =================
  {
    id: 'q_phy_01',
    subjectId: 'physics',
    subjectName: 'Physics',
    topicId: 'kinematics',
    topicName: 'Kinematics & Projectiles',
    universityTags: ['BRACU', 'AUST', 'AIUB', 'EWU', 'UIU'],
    text: 'A projectile is launched with speed $v_0 = 20\\text{ m/s}$ at an angle of $30^\\circ$ above the horizontal. Taking $g = 10\\text{ m/s}^2$, what is the maximum height reached?',
    options: [
      { id: 'A', text: '$5\\text{ m}$', isCorrect: true },
      { id: 'B', text: '$10\\text{ m}$' },
      { id: 'C', text: '$15\\text{ m}$' },
      { id: 'D', text: '$20\\text{ m}$' },
    ],
    correctOptionId: 'A',
    explanation:
      '$H_{\\max} = \\frac{v_0^2 \\sin^2\\theta}{2g} = \\frac{20^2 \\times (0.5)^2}{2 \\times 10} = \\frac{400 \\times 0.25}{20} = \\frac{100}{20} = 5\\text{ m}$.',
    hints: [
      'Use only the vertical component of initial velocity: $v_{0y} = v_0 \\sin(30^\\circ)$.',
      'At maximum height $v_y = 0$, so $H = \\frac{v_{0y}^2}{2g}$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_phy_02',
    subjectId: 'physics',
    subjectName: 'Physics',
    topicId: 'electricity',
    topicName: 'Current Electricity & Circuits',
    universityTags: ['BRACU', 'AUST', 'AIUB', 'UIU', 'UAP'],
    text: 'Three resistors of $6\\,\\Omega$ each are connected in parallel across a $12\\text{ V}$ battery. What total current flows from the battery?',
    options: [
      { id: 'A', text: '$2\\text{ A}$' },
      { id: 'B', text: '$4\\text{ A}$' },
      { id: 'C', text: '$6\\text{ A}$', isCorrect: true },
      { id: 'D', text: '$0.67\\text{ A}$' },
    ],
    correctOptionId: 'C',
    explanation:
      'Equivalent resistance $R_{\\text{eq}} = \\frac{6}{3} = 2\\,\\Omega$.\nBy Ohm\'s Law, $I = \\frac{V}{R_{\\text{eq}}} = \\frac{12}{2} = 6\\text{ A}$.',
    hints: [
      'For $n$ identical resistors $R$ in parallel, $R_{\\text{eq}} = R / n$.',
      'Apply $I = V / R_{\\text{eq}}$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_phy_03',
    subjectId: 'physics',
    subjectName: 'Physics',
    topicId: 'shm_waves',
    topicName: 'Simple Harmonic Motion',
    universityTags: ['AUST', 'BRACU', 'EWU', 'IUB'],
    text: 'If the length of a simple pendulum is quadrupled ($L\' = 4L$), how does its time period $T$ change?',
    options: [
      { id: 'A', text: 'Doubles ($2T$)', isCorrect: true },
      { id: 'B', text: 'Quadruples ($4T$)' },
      { id: 'C', text: 'Halves ($T/2$)' },
      { id: 'D', text: 'Remains unchanged' },
    ],
    correctOptionId: 'A',
    explanation:
      'Time period of a simple pendulum is $T = 2\\pi\\sqrt{\\frac{L}{g}} \\propto \\sqrt{L}$.\nWhen $L$ becomes $4L$, $T\' = \\sqrt{4}\\,T = 2T$.',
    hints: [
      'Recall $T = 2\\pi \\sqrt{L / g}$. Notice $T$ scales with the square root of length.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_phy_04',
    subjectId: 'physics',
    subjectName: 'Physics',
    topicId: 'modern_physics',
    topicName: 'Photoelectric Effect',
    universityTags: ['AUST', 'BRACU', 'EWU'],
    text: 'In a photoelectric experiment, photons of energy $4.5\\text{ eV}$ strike a metal surface with work function $\\phi = 2.1\\text{ eV}$. What is the maximum kinetic energy of the emitted photoelectrons?',
    options: [
      { id: 'A', text: '$6.6\\text{ eV}$' },
      { id: 'B', text: '$2.4\\text{ eV}$', isCorrect: true },
      { id: 'C', text: '$2.1\\text{ eV}$' },
      { id: 'D', text: '$1.8\\text{ eV}$' },
    ],
    correctOptionId: 'B',
    explanation:
      'By Einstein\'s photoelectric equation: $K_{\\max} = E_{\\text{photon}} - \\phi = 4.5 - 2.1 = 2.4\\text{ eV}$.',
    hints: [
      'Use Einstein\'s equation: $K_{\\max} = hf - \\phi$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_phy_05',
    subjectId: 'physics',
    subjectName: 'Physics',
    topicId: 'work_energy',
    topicName: 'Work, Power & Momentum',
    universityTags: ['BRACU', 'AIUB', 'UIU', 'AUST'],
    text: 'A $2\\text{ kg}$ block moving at $6\\text{ m/s}$ collides and sticks to a stationary $4\\text{ kg}$ block on a frictionless track. What is their common velocity after collision?',
    options: [
      { id: 'A', text: '$2\\text{ m/s}$', isCorrect: true },
      { id: 'B', text: '$3\\text{ m/s}$' },
      { id: 'C', text: '$4\\text{ m/s}$' },
      { id: 'D', text: '$1.5\\text{ m/s}$' },
    ],
    correctOptionId: 'A',
    explanation:
      'By conservation of linear momentum: $m_1 v_1 + m_2 v_2 = (m_1 + m_2) v_f$.\n$2(6) + 4(0) = (2 + 4)v_f \\implies 12 = 6v_f \\implies v_f = 2\\text{ m/s}$.',
    hints: [
      'In a perfectly inelastic collision, kinetic energy is not conserved, but total momentum always is.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_phy_06',
    subjectId: 'physics',
    subjectName: 'Physics',
    topicId: 'optics',
    topicName: 'Geometrical & Physical Optics',
    universityTags: ['AUST', 'EWU', 'UAP'],
    text: 'In Young\'s double-slit experiment, if the distance between the slits is halved and the distance to the screen is doubled, what happens to the fringe width $\\beta$?',
    options: [
      { id: 'A', text: 'Increases by 2 times' },
      { id: 'B', text: 'Increases by 4 times', isCorrect: true },
      { id: 'C', text: 'Decreases by 4 times' },
      { id: 'D', text: 'Remains the same' },
    ],
    correctOptionId: 'B',
    explanation:
      'Fringe width $\\beta = \\frac{\\lambda D}{d}$.\nWith $D\' = 2D$ and $d\' = d/2$: $\\beta\' = \\frac{\\lambda (2D)}{d/2} = 4\\frac{\\lambda D}{d} = 4\\beta$.',
    hints: [
      'Recall the fringe spacing formula $\\beta = \\lambda D / d$.',
    ],
    hasMath: true,
    difficulty: 'medium',
  },

  // ================= CHEMISTRY =================
  {
    id: 'q_chem_01',
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    topicId: 'bonding',
    topicName: 'Hybridization & Bonding',
    universityTags: ['AUST', 'EWU', 'NSU', 'BRACU'],
    text: 'What is the hybridization of the central carbon atom in ethyne ($\\text{C}_2\\text{H}_2$) and its $\\text{H}-\\text{C}-\\text{C}$ bond angle?',
    options: [
      { id: 'A', text: '$sp^3$, $109.5^\\circ$' },
      { id: 'B', text: '$sp^2$, $120^\\circ$' },
      { id: 'C', text: '$sp$, $180^\\circ$', isCorrect: true },
      { id: 'D', text: '$sp^3d$, $90^\\circ$' },
    ],
    correctOptionId: 'C',
    explanation:
      'In ethyne ($\\text{H}-\\text{C}\\equiv\\text{C}-\\text{H}$), each carbon forms $2$ sigma bonds and $2$ pi bonds, giving steric number $2 \\implies sp$ hybridization and linear geometry ($180^\\circ$).',
    hints: [
      'Count the sigma bonds around each carbon in a triple-bonded alkyne.',
      'Steric number 2 corresponds to linear geometry.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_chem_02',
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    topicId: 'equilibrium',
    topicName: 'pH & Acid-Base Equilibrium',
    universityTags: ['AUST', 'NSU', 'EWU', 'IUB'],
    text: 'What is the pH of a $0.005\\text{ M}$ aqueous solution of $\\text{H}_2\\text{SO}_4$ assuming complete dissociation?',
    options: [
      { id: 'A', text: '$2.0$', isCorrect: true },
      { id: 'B', text: '$2.3$' },
      { id: 'C', text: '$3.0$' },
      { id: 'D', text: '$1.7$' },
    ],
    correctOptionId: 'A',
    explanation:
      'Sulfuric acid is diprotic: $[\\text{H}^+] = 2 \\times 0.005 = 0.01\\text{ M} = 10^{-2}\\text{ M}$.\n$\\text{pH} = -\\log_{10}(10^{-2}) = 2.0$.',
    hints: [
      'Each mole of $\\text{H}_2\\text{SO}_4$ produces 2 moles of $\\text{H}^+$ ions upon complete dissociation.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_chem_03',
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    topicId: 'organic',
    topicName: 'Organic Chemistry & IUPAC',
    universityTags: ['AUST', 'EWU', 'NSU', 'BRACU'],
    text: 'Which reagent distinguishes an aldehyde from a ketone by forming a silver mirror on the test tube wall?',
    options: [
      { id: 'A', text: 'Lucas reagent' },
      { id: 'B', text: 'Tollens\' reagent ($[\\text{Ag}(\\text{NH}_3)_2]^+$)', isCorrect: true },
      { id: 'C', text: 'Grignard reagent' },
      { id: 'D', text: '2,4-DNP reagent' },
    ],
    correctOptionId: 'B',
    explanation:
      'Tollens\' reagent (ammoniacal silver nitrate) selectively oxidizes aldehydes to carboxylate ions while reducing $\\text{Ag}^+$ to metallic silver mirror; ketones do not react.',
    hints: [
      '2,4-DNP reacts with *both* aldehydes and ketones. Think of the silver mirror test.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },
  {
    id: 'q_chem_04',
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    topicId: 'gas_laws',
    topicName: 'Gas Laws & Stoichiometry',
    universityTags: ['AUST', 'EWU', 'AIUB'],
    text: 'According to Graham\'s law, the rate of diffusion of $\\text{H}_2$ gas ($M=2$) compared to $\\text{O}_2$ gas ($M=32$) at the same temperature and pressure is:',
    options: [
      { id: 'A', text: '$2$ times faster' },
      { id: 'B', text: '$4$ times faster', isCorrect: true },
      { id: 'C', text: '$8$ times faster' },
      { id: 'D', text: '$16$ times faster' },
    ],
    correctOptionId: 'B',
    explanation:
      '$\\frac{r_{\\text{H}_2}}{r_{\\text{O}_2}} = \\sqrt{\\frac{M_{\\text{O}_2}}{M_{\\text{H}_2}}} = \\sqrt{\\frac{32}{2}} = \\sqrt{16} = 4$.',
    hints: [
      'Graham\'s Law states $r \\propto 1 / \\sqrt{M}$.',
    ],
    hasMath: true,
    difficulty: 'easy',
  },

  // ================= BIOLOGY (PHARMACY & BIO SCIENCES) =================
  {
    id: 'q_bio_01',
    subjectId: 'biology',
    subjectName: 'Biology',
    topicId: 'cell_biology',
    topicName: 'Cell Organelles & Division',
    universityTags: ['NSU', 'BRACU', 'EWU', 'IUB', 'UAP'],
    text: 'During which stage of meiosis does crossing over (genetic recombination between homologous chromosomes) occur?',
    options: [
      { id: 'A', text: 'Pachytene of Prophase I', isCorrect: true },
      { id: 'B', text: 'Metaphase I' },
      { id: 'C', text: 'Anaphase II' },
      { id: 'D', text: 'Telophase I' },
    ],
    correctOptionId: 'A',
    explanation:
      'Crossing over occurs between non-sister chromatids of homologous chromosomes during the **Pachytene** substage of Prophase I, forming chiasmata.',
    hints: [
      'Genetic exchange happens in Prophase I after synapsis (Zygotene).',
    ],
    hasMath: false,
    difficulty: 'medium',
  },
  {
    id: 'q_bio_02',
    subjectId: 'biology',
    subjectName: 'Biology',
    topicId: 'physiology',
    topicName: 'Human & Plant Physiology',
    universityTags: ['NSU', 'BRACU', 'EWU', 'AIUB'],
    text: 'Which enzyme in human pancreatic juice hydrolyzes dietary triglycerides (fats) into fatty acids and glycerol?',
    options: [
      { id: 'A', text: 'Trypsin' },
      { id: 'B', text: 'Amylase' },
      { id: 'C', text: 'Pancreatic Lipase', isCorrect: true },
      { id: 'D', text: 'Pepsin' },
    ],
    correctOptionId: 'C',
    explanation:
      'Pancreatic lipase digests emulsified fats (triglycerides) into monoglycerides, fatty acids, and glycerol in the duodenum.',
    hints: [
      'Look at the substrate name: lipids are broken down by *lip*-ases.',
    ],
    hasMath: false,
    difficulty: 'easy',
  },
  {
    id: 'q_bio_03',
    subjectId: 'biology',
    subjectName: 'Biology',
    topicId: 'genetics',
    topicName: 'Molecular Genetics',
    universityTags: ['NSU', 'BRACU', 'EWU'],
    text: 'In the genetic code, which mRNA codon serves as the universal start codon encoding Methionine in eukaryotes?',
    options: [
      { id: 'A', text: 'UAA' },
      { id: 'B', text: 'AUG', isCorrect: true },
      { id: 'C', text: 'UGA' },
      { id: 'D', text: 'UAG' },
    ],
    correctOptionId: 'B',
    explanation:
      '**AUG** is the start codon initiating protein translation and codes for Methionine, whereas UAA, UAG, and UGA are stop (nonsense) codons.',
    hints: [
      'Three of the four options are stop codons.',
    ],
    hasMath: false,
    difficulty: 'easy',
  },

  // ================= ENGLISH LANGUAGE =================
  {
    id: 'q_eng_01',
    subjectId: 'english',
    subjectName: 'English Language',
    topicId: 'grammar',
    topicName: 'Subject-Verb Agreement & Syntax',
    universityTags: ['NSU', 'BRACU', 'IUB', 'AIUB', 'EWU', 'UIU'],
    text: 'Neither the department chair nor the senior lecturers ____ able to attend the orientation seminar yesterday.',
    options: [
      { id: 'A', text: 'was' },
      { id: 'B', text: 'were', isCorrect: true },
      { id: 'C', text: 'has been' },
      { id: 'D', text: 'is' },
    ],
    correctOptionId: 'B',
    explanation:
      'With **neither ... nor**, the verb agrees with the closer subject ("the senior lecturers", plural) and the time marker "yesterday" requires past tense: **were**.',
    hints: [
      'Identify the noun closest to the blank ("senior lecturers") and check the tense cue ("yesterday").',
    ],
    hasMath: false,
    difficulty: 'easy',
  },
  {
    id: 'q_eng_02',
    subjectId: 'english',
    subjectName: 'English Language',
    topicId: 'grammar',
    topicName: 'Conditionals & Subjunctive',
    universityTags: ['NSU', 'BRACU', 'IUB', 'EWU'],
    text: 'Had the candidate reviewed the past model tests thoroughly, she ____ a much higher percentile.',
    options: [
      { id: 'A', text: 'would achieve' },
      { id: 'B', text: 'will have achieved' },
      { id: 'C', text: 'would have achieved', isCorrect: true },
      { id: 'D', text: 'had achieved' },
    ],
    correctOptionId: 'C',
    explanation:
      'Inverted third conditional ("Had she reviewed..." = "If she had reviewed...") requires **would have + past participle** in the main clause.',
    hints: [
      '"Had the candidate reviewed" is an inverted past-perfect conditional referring to an unreal past.',
    ],
    hasMath: false,
    difficulty: 'medium',
  },
  {
    id: 'q_eng_03',
    subjectId: 'english',
    subjectName: 'English Language',
    topicId: 'vocabulary',
    topicName: 'Vocabulary & Contextual Usage',
    universityTags: ['NSU', 'BRACU', 'IUB', 'AIUB'],
    text: 'Despite the professor\'s **terse** feedback on the draft, the students found the remarks surprisingly insightful.',
    contextSnippet: 'Choose the word closest in meaning to "terse".',
    options: [
      { id: 'A', text: 'Verbose' },
      { id: 'B', text: 'Concise', isCorrect: true },
      { id: 'C', text: 'Ambiguous' },
      { id: 'D', text: 'Hostile' },
    ],
    correctOptionId: 'B',
    explanation:
      '**Terse** means sparing in the use of words; brief and to the point (**concise**). "Verbose" is its antonym.',
    hints: [
      'Notice the contrast signaled by "Despite... surprisingly insightful."',
    ],
    hasMath: false,
    difficulty: 'easy',
  },
  {
    id: 'q_eng_04',
    subjectId: 'english',
    subjectName: 'English Language',
    topicId: 'reading',
    topicName: 'Reading Comprehension',
    universityTags: ['NSU', 'BRACU', 'IUB'],
    passage:
      'Urban heat islands in rapidly growing South Asian megacities amplify nighttime temperatures by up to 4°C compared with surrounding rural wetlands. While reflective rooftop coatings offer immediate relief at relatively low municipal cost, hydrologists caution that cooling strategies remain incomplete unless permeable pavements and restored urban canals replenish local evapotranspiration.',
    text: 'Based on the passage, what is the author\'s primary argument regarding urban cooling strategies?',
    options: [
      { id: 'A', text: 'Reflective roofs are too expensive for municipal budgets.' },
      {
        id: 'B',
        text: 'Surface reflectivity alone should be paired with water-permeable infrastructure.',
        isCorrect: true,
      },
      { id: 'C', text: 'Rural wetlands experience higher nighttime temperatures than cities.' },
      { id: 'D', text: 'Evapotranspiration accelerates the urban heat island effect.' },
    ],
    correctOptionId: 'B',
    explanation:
      'The passage states reflective coatings offer low-cost relief but remain "incomplete unless permeable pavements and restored urban canals replenish local evapotranspiration."',
    hints: [
      'Re-read the second sentence carefully: what makes cooling strategies "complete"?',
    ],
    hasMath: false,
    difficulty: 'medium',
  },
  {
    id: 'q_eng_05',
    subjectId: 'english',
    subjectName: 'English Language',
    topicId: 'grammar',
    topicName: 'Prepositions & Idioms',
    universityTags: ['NSU', 'BRACU', 'AIUB', 'UIU', 'UAP'],
    text: 'The new scholarship curriculum is entirely consistent ____ the university\'s international accreditation standards.',
    options: [
      { id: 'A', text: 'to' },
      { id: 'B', text: 'with', isCorrect: true },
      { id: 'C', text: 'for' },
      { id: 'D', text: 'upon' },
    ],
    correctOptionId: 'B',
    explanation:
      'The adjective "consistent" takes the preposition **with** when indicating agreement or compatibility with standards or principles.',
    hints: [
      'Which preposition collocates with "consistent" when meaning "in agreement with"?',
    ],
    hasMath: false,
    difficulty: 'easy',
  },
  {
    id: 'q_eng_06',
    subjectId: 'english',
    subjectName: 'English Language',
    topicId: 'vocabulary',
    topicName: 'Analogy & Logical Reasoning',
    universityTags: ['NSU', 'IUB', 'BRACU'],
    text: 'CARTOGRAPHER : MAP :: CHOREOGRAPHER : ____',
    options: [
      { id: 'A', text: 'Canvas' },
      { id: 'B', text: 'Ballet', isCorrect: true },
      { id: 'C', text: 'Compass' },
      { id: 'D', text: 'Blueprint' },
    ],
    correctOptionId: 'B',
    explanation:
      'A cartographer designs maps; similarly, a choreographer designs dance/ballet sequences.',
    hints: [
      'Identify the creator-to-creation relationship.',
    ],
    hasMath: false,
    difficulty: 'easy',
  },
];

export interface SubjectChapterGroup {
  title: string;
  questionCount: number;
  topics: string[];
}

export function getChaptersForSubject(subjectSlug: string): SubjectChapterGroup[] {
  const s = subjectSlug.toLowerCase();
  if (s.includes('higher')) {
    return [
      {
        title: 'Differential & Integral Calculus',
        questionCount: 180,
        topics: [
          'Limits & Continuity',
          'Differentiation & Tangents',
          'Definite & Indefinite Integrals',
          'Applications & Area Under Curves',
        ],
      },
      {
        title: 'Vectors & Coordinate Geometry',
        questionCount: 160,
        topics: [
          'Vectors: Dot & Cross Product',
          'Straight Lines & Slope Form',
          'Circle Equations & Tangents',
          'Conics: Parabola, Ellipse, Hyperbola',
        ],
      },
      {
        title: 'Algebra, Matrices & Trigonometry',
        questionCount: 150,
        topics: [
          "Matrices & Determinants (Cramer's Rule)",
          'Quadratic Equations & Roots',
          'Trigonometric Functions & Identities',
          'Complex Numbers & Polar Form',
        ],
      },
    ];
  }
  if (s.includes('math') || s.includes('quant')) {
    return [
      {
        title: 'Algebra & Quantitative Reasoning',
        questionCount: 220,
        topics: [
          'Linear & Quadratic Equations',
          'Exponents & Logarithms',
          'Arithmetic & Geometric Progressions',
          'Permutation & Combination',
        ],
      },
      {
        title: 'Geometry & Mensuration',
        questionCount: 150,
        topics: ['Triangles & Polygons', 'Circles, Chords & Tangents', '3D Shapes & Solid Mensuration'],
      },
      {
        title: 'Commercial Arithmetic & Statistics',
        questionCount: 140,
        topics: ['Ratio, Proportion & Percentages', 'Profit, Loss & Simple Interest', 'Data Interpretation & Probability'],
      },
    ];
  }
  if (s.includes('phy')) {
    return [
      {
        title: 'Mechanics & Dynamics',
        questionCount: 190,
        topics: ['Kinematics & Projectile Motion', "Newton's Laws & Momentum", 'Work, Power & Energy', 'Gravitation & Circular Motion'],
      },
      {
        title: 'Waves, Optics & Modern Physics',
        questionCount: 160,
        topics: ['Simple Harmonic Motion (SHM)', 'Wave Motion & Sound Waves', 'Geometrical & Physical Optics', 'Atomic Structure & Photoelectric Effect'],
      },
      {
        title: 'Electricity & Magnetism',
        questionCount: 175,
        topics: ['Electrostatics & Capacitance', "Current Electricity & Ohm's Law", 'Magnetic Field & Biot-Savart Law', 'Electromagnetic Induction & AC'],
      },
    ];
  }
  if (s.includes('chem')) {
    return [
      {
        title: 'Physical Chemistry & Gas Laws',
        questionCount: 160,
        topics: ['Ideal & Real Gas Laws (Van der Waals)', 'Chemical Equilibrium & Le Chatelier', 'Thermochemistry & Enthalpy', 'Electrochemistry & Nernst Equation'],
      },
      {
        title: 'Inorganic Chemistry & Periodic Table',
        questionCount: 140,
        topics: ['Periodic Trends & Ionization Energy', 'Chemical Bonding & Hybridization', 'Coordination Compounds & Ligands', 's, p, d, f Block Elements'],
      },
      {
        title: 'Organic Chemistry & Reaction Mechanisms',
        questionCount: 210,
        topics: ['IUPAC Nomenclature & Isomerism', 'Hydrocarbons (Alkanes, Alkenes, Alkynes)', 'Alcohols, Phenols & Carbonyls', 'Carboxylic Acids & Biomolecules'],
      },
    ];
  }
  if (s.includes('bio')) {
    return [
      {
        title: 'Cell Biology & Genetics',
        questionCount: 180,
        topics: ['Cell Structure & Organelles', 'Cell Division (Mitosis & Meiosis)', 'DNA Replication & Protein Synthesis', 'Mendelian Inheritance & Mutations'],
      },
      {
        title: 'Plant & Human Physiology',
        questionCount: 190,
        topics: ['Photosynthesis & Plant Respiration', 'Digestive & Circulatory Systems', 'Respiratory & Excretory Systems', 'Nervous System & Endocrine Hormones'],
      },
    ];
  }
  return [
    {
      title: 'Grammar & Sentence Syntax',
      questionCount: 240,
      topics: ['Subject-Verb Agreement', 'Tenses & Conditionals', 'Prepositions & Phrasal Verbs', 'Sentence Correction (SAT Style)'],
    },
    {
      title: 'Vocabulary & Analogies',
      questionCount: 210,
      topics: ['Contextual Vocabulary & Usage', 'Synonyms & Antonyms', 'Word Analogy & Logical Relationship'],
    },
    {
      title: 'Reading Comprehension',
      questionCount: 150,
      topics: ['Critical Passage Reading', 'Main Idea & Inferences', 'Tone & Author Attitude'],
    },
  ];
}

export function pickQuestionsForExam(
  track: string,
  count = 15,
  subjectFilter?: string
): Question[] {
  const upperTrack = track.toUpperCase();
  let pool = QUESTION_BANK;

  if (subjectFilter && subjectFilter !== 'all') {
    const subLower = subjectFilter.toLowerCase();
    const bySubject = pool.filter(
      (q) =>
        q.subjectId.toLowerCase().includes(subLower) ||
        q.subjectName.toLowerCase().includes(subLower) ||
        q.universityTags.some((t) => t.toUpperCase() === subLower.toUpperCase())
    );
    if (bySubject.length > 0) pool = bySubject;
  } else if (upperTrack && upperTrack !== 'ALL' && upperTrack !== 'GENERAL') {
    const tagged = pool.filter((q) => q.universityTags.includes(upperTrack));
    const rest = pool.filter((q) => !q.universityTags.includes(upperTrack));
    pool = [...tagged, ...rest];
  }

  // Deterministically mix so every test feels substantive
  const selected = pool.slice(0, Math.min(count, pool.length));
  return selected;
}

export const MODEL_TESTS_CATALOG: Omit<DailyExamDetails, 'questions' | 'shareableUrl'>[] = [
  {
    id: 'mt_nsu_grand_1',
    slug: 'nsu-seps-grand-model-1',
    title: 'NSU SEPS (CSE/EEE) Grand Model Test #1',
    track: 'NSU',
    examType: 'model_test',
    durationMinutes: 45,
    totalMarks: 20,
    negativeMark: 0.0,
    questionCount: 20,
    isLiveNow: true,
    activeCandidates: 1840,
  },
  {
    id: 'mt_bracu_grand_1',
    slug: 'bracu-eng-grand-model-1',
    title: 'BRACU Engineering & Computing Simulation #1',
    track: 'BRACU',
    examType: 'model_test',
    durationMinutes: 40,
    totalMarks: 18,
    negativeMark: 0.0,
    questionCount: 18,
    isLiveNow: true,
    activeCandidates: 1520,
  },
  {
    id: 'mt_aust_grand_1',
    slug: 'aust-eng-grand-model-1',
    title: 'AUST Engineering Merit Mock Test #1',
    track: 'AUST',
    examType: 'model_test',
    durationMinutes: 40,
    totalMarks: 18,
    negativeMark: 0.0,
    questionCount: 18,
    isLiveNow: false,
    activeCandidates: 1120,
  },
  {
    id: 'mt_aiub_fst_1',
    slug: 'aiub-fst-model-1',
    title: 'AIUB FST (CSE/EEE) Admission Mock #1',
    track: 'AIUB',
    examType: 'model_test',
    durationMinutes: 35,
    totalMarks: 15,
    negativeMark: 0.0,
    questionCount: 15,
    isLiveNow: true,
    activeCandidates: 980,
  },
  {
    id: 'mt_ewu_fse_1',
    slug: 'ewu-fse-model-1',
    title: 'EWU Sciences & Engineering Mock Test #1',
    track: 'EWU',
    examType: 'model_test',
    durationMinutes: 35,
    totalMarks: 15,
    negativeMark: 0.0,
    questionCount: 15,
    isLiveNow: false,
    activeCandidates: 760,
  },
  {
    id: 'mt_iub_sets_1',
    slug: 'iub-sets-model-1',
    title: 'IUB SETS & SBE Quantitative Mock #1',
    track: 'IUB',
    examType: 'model_test',
    durationMinutes: 30,
    totalMarks: 15,
    negativeMark: 0.0,
    questionCount: 15,
    isLiveNow: false,
    activeCandidates: 640,
  },
  {
    id: 'mt_uiu_sose_1',
    slug: 'uiu-sose-model-1',
    title: 'UIU School of Science & Engineering Mock',
    track: 'UIU',
    examType: 'model_test',
    durationMinutes: 30,
    totalMarks: 15,
    negativeMark: 0.0,
    questionCount: 15,
    isLiveNow: false,
    activeCandidates: 590,
  },
  {
    id: 'mt_uap_eng_1',
    slug: 'uap-eng-model-1',
    title: 'UAP Engineering & Architecture Prep Mock',
    track: 'UAP',
    examType: 'model_test',
    durationMinutes: 30,
    totalMarks: 15,
    negativeMark: 0.0,
    questionCount: 15,
    isLiveNow: false,
    activeCandidates: 430,
  },
  // Past Papers
  {
    id: 'pp_nsu_2025',
    slug: 'nsu-spring-2025-paper',
    title: 'NSU Spring 2025 Official Question Paper',
    track: 'NSU',
    examType: 'uni_exam',
    durationMinutes: 35,
    totalMarks: 18,
    negativeMark: 0.0,
    questionCount: 18,
    activeCandidates: 2450,
  },
  {
    id: 'pp_bracu_2025',
    slug: 'bracu-fall-2025-paper',
    title: 'BRACU Fall 2025 Solved Admission Paper',
    track: 'BRACU',
    examType: 'uni_exam',
    durationMinutes: 35,
    totalMarks: 16,
    negativeMark: 0.0,
    questionCount: 16,
    activeCandidates: 2110,
  },
  {
    id: 'pp_aust_2025',
    slug: 'aust-fall-2025-paper',
    title: 'AUST Engineering 2025 Official Archive',
    track: 'AUST',
    examType: 'uni_exam',
    durationMinutes: 35,
    totalMarks: 16,
    negativeMark: 0.0,
    questionCount: 16,
    activeCandidates: 1640,
  },
  // Section Drills
  {
    id: 'sec_calculus_drill',
    slug: 'sec-higher-math-calculus',
    title: 'Section Drill: Higher Math & Calculus',
    track: 'BRACU',
    examType: 'section_exam',
    durationMinutes: 15,
    totalMarks: 8,
    negativeMark: 0.0,
    questionCount: 8,
    activeCandidates: 1320,
  },
  {
    id: 'sec_sat_quant',
    slug: 'sec-quant-aptitude-nsu',
    title: 'Section Drill: SAT Quantitative Math',
    track: 'NSU',
    examType: 'section_exam',
    durationMinutes: 15,
    totalMarks: 6,
    negativeMark: 0.0,
    questionCount: 6,
    activeCandidates: 1410,
  },
  {
    id: 'sec_english_syntax',
    slug: 'sec-english-comprehension',
    title: 'Section Drill: English Grammar & Comprehension',
    track: 'IUB',
    examType: 'section_exam',
    durationMinutes: 15,
    totalMarks: 6,
    negativeMark: 0.0,
    questionCount: 6,
    activeCandidates: 980,
  },
];

export const DEFAULT_LEADERBOARD: LeaderboardEntry[] = [
  { rank: 1, name: 'Nafisa Tabassum', college: 'Viqarunnisa Noon College', universityTrack: 'BRACU', score: 19.5, totalMarks: 20, timeTakenSeconds: 742, xp: 4820 },
  { rank: 2, name: 'Zayan Mahmud', college: 'Notre Dame College', universityTrack: 'NSU', score: 19.0, totalMarks: 20, timeTakenSeconds: 815, xp: 4590 },
  { rank: 3, name: 'Farhan Sadik', college: 'Dhaka Residential Model College', universityTrack: 'AUST', score: 18.5, totalMarks: 20, timeTakenSeconds: 890, xp: 4310 },
  { rank: 4, name: 'Anika Rahman', college: 'Holy Cross College', universityTrack: 'BRACU', score: 17.75, totalMarks: 20, timeTakenSeconds: 924, xp: 4100 },
  { rank: 5, name: 'Tasnimul Hasan', college: 'Rajuk Uttara Model College', universityTrack: 'NSU', score: 17.0, totalMarks: 20, timeTakenSeconds: 960, xp: 3880 },
  { rank: 6, name: 'Rohan Chowdhury', college: 'Scholastica', universityTrack: 'IUB', score: 16.5, totalMarks: 20, timeTakenSeconds: 1012, xp: 3640 },
  { rank: 7, name: 'Samira Karim', college: 'Sunbeams School', universityTrack: 'AIUB', score: 16.0, totalMarks: 20, timeTakenSeconds: 1045, xp: 3420 },
  { rank: 8, name: 'Sajid Alom', college: 'Adamjee Cantonment College', universityTrack: 'EWU', score: 15.25, totalMarks: 20, timeTakenSeconds: 1105, xp: 3190 },
];
