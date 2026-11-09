import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'subscription_screen.dart';

/// Dedicated Upgrade Screen offering tiers (Free vs Pro vs Elite) for university admission preparation
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isSeasonPass = true; // Season pass (annual/semester) vs monthly
  String _currentTier = 'free';

  @override
  void initState() {
    super.initState();
    _currentTier = CacheService().read<String>('user_subscription_tier') ?? 'free';
  }

  void _upgradeTier(String tierName, int price, String billingPeriod) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String selectedMethod = 'bKash';
        final phoneCtrl = TextEditingController(text: '01700000000');

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final colors = modalContext.colors;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A36).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_cart_checkout, color: Color(0xFFFF7A36), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete Upgrade',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '$tierName • ৳$price / $billingPeriod',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SELECT PAYMENT METHOD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentOption(
                        label: 'bKash',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFFD12053),
                        isSelected: selectedMethod == 'bKash',
                        onTap: () => setModalState(() => selectedMethod = 'bKash'),
                        colors: colors,
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentOption(
                        label: 'Nagad',
                        icon: Icons.send_to_mobile,
                        color: const Color(0xFFF7941D),
                        isSelected: selectedMethod == 'Nagad',
                        onTap: () => setModalState(() => selectedMethod = 'Nagad'),
                        colors: colors,
                      ),
                      const SizedBox(width: 8),
                      _buildPaymentOption(
                        label: 'Card',
                        icon: Icons.credit_card,
                        color: const Color(0xFF2563EB),
                        isSelected: selectedMethod == 'Card',
                        onTap: () => setModalState(() => selectedMethod = 'Card'),
                        colors: colors,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MOBILE / ACCOUNT NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _completePurchase(tierName, price, billingPeriod, selectedMethod);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A36),
                      foregroundColor: const Color(0xFF542747),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: Text(
                      'Pay ৳$price with $selectedMethod',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completePurchase(String tierName, int price, String billingPeriod, String method) {
    final newTierKey = tierName.toLowerCase().contains('elite') ? 'elite' : 'pro';
    CacheService().write('user_subscription_tier', newTierKey);
    CacheService().write('user_subscription_plan_name', tierName);
    CacheService().write('user_subscription_price', price);
    CacheService().write('user_subscription_method', method);
    CacheService().write('user_subscription_date', DateTime.now().toIso8601String());

    setState(() {
      _currentTier = newTierKey;
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Color(0xFF10B981), size: 26),
            const SizedBox(width: 10),
            Text('Upgrade Successful!', style: TextStyle(color: context.colors.textPrimary)),
          ],
        ),
        content: Text(
          'Congratulations! You are now upgraded to $tierName ($billingPeriod). All premium admission features are now active.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A36),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Practicing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final proPrice = _isSeasonPass ? 1499 : 499;
    final elitePrice = _isSeasonPass ? 2499 : 999;
    final periodLabel = _isSeasonPass ? 'Admission Season' : 'Month';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Upgrade Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: const [
          ThemeToggleIconButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7A36), Color(0xFF542747)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Color(0xFFFFD166), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'PREP404 ADMISSION PASS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unlock Every Varsity Blueprint',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Full access to all university model tests, unlimited Socratic AI tutor hints, mistake vault optimizer, and 1v1 PvP duels.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Season vs Monthly billing selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isSeasonPass = false),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSeasonPass ? const Color(0xFFFF7A36) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Monthly Plan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: !_isSeasonPass ? Colors.white : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isSeasonPass = true),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSeasonPass ? const Color(0xFFFF7A36) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Season Pass',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isSeasonPass ? Colors.white : colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SAVE 40%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF542747),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Plan 1: Free Starter
                _buildPlanCard(
                  colors: colors,
                  title: 'Free Starter',
                  subtitle: 'Core admission syllabus orientation',
                  price: '৳0',
                  period: 'Forever Free',
                  badge: _currentTier == 'free' ? 'CURRENT PLAN' : null,
                  badgeColor: const Color(0xFF6B7280),
                  isCurrent: _currentTier == 'free',
                  features: const [
                    'Basic practice mode & questions',
                    '5 1v1 PvP Arena Duels daily',
                    'Standard model tests without script reviews',
                    'Community forum read-only access',
                  ],
                  ctaLabel: _currentTier == 'free' ? 'Active Plan' : 'Free Baseline',
                  onCtaPressed: null,
                ),
                const SizedBox(height: 16),

                // Plan 2: Pro Pass (Recommended)
                _buildPlanCard(
                  colors: colors,
                  title: 'Prep404 Pro Pass',
                  subtitle: 'Everything needed to crack top universities',
                  price: '৳$proPrice',
                  period: periodLabel,
                  badge: 'MOST POPULAR',
                  badgeColor: const Color(0xFFFF7A36),
                  isHighlighted: true,
                  isCurrent: _currentTier == 'pro',
                  features: const [
                    'Unlimited 1v1 PvP Arena Duels (2 to 8 players)',
                    'Unlimited Socratic AI Tutor hints & step-by-step math',
                    'Complete varsity blueprints (BRACU, EWU, NSU, IBA, DU)',
                    'Mistake Vault topic auto-optimizer with live DB re-tests',
                    'Admission readiness probability score & heatmaps',
                    'Verified KaTeX solution keys & ad-free experience',
                  ],
                  ctaLabel: _currentTier == 'pro' ? 'Current Active Plan ✓' : 'Upgrade to Pro Pass ⚡',
                  onCtaPressed: _currentTier == 'pro'
                      ? null
                      : () => _upgradeTier('Prep404 Pro Pass', proPrice, periodLabel),
                ),
                const SizedBox(height: 16),

                // Plan 3: Varsity Elite
                _buildPlanCard(
                  colors: colors,
                  title: 'Varsity Elite Pass',
                  subtitle: 'Pinnacle national admission contender tier',
                  price: '৳$elitePrice',
                  period: periodLabel,
                  badge: 'ELITE TIER',
                  badgeColor: const Color(0xFF8B5CF6),
                  isCurrent: _currentTier == 'elite',
                  features: const [
                    'All Pro Pass features included',
                    '1-on-1 Socratic AI Personalized Study Schedule',
                    'Exclusive Top-Rank Predicted Blueprint Question Banks',
                    'Unlimited Study Streak Freeze Shields',
                    'Priority 24/7 Academic Mentor Response',
                    'Downloadable Model Test PDF question sets',
                  ],
                  ctaLabel: _currentTier == 'elite' ? 'Current Active Plan ✓' : 'Get Varsity Elite 👑',
                  onCtaPressed: _currentTier == 'elite'
                      ? null
                      : () => _upgradeTier('Varsity Elite Pass', elitePrice, periodLabel),
                ),
                const SizedBox(height: 24),

                // Link to Subscription Screen
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      if (GoRouter.maybeOf(context) != null) {
                        context.push(AppRoutes.subscription);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.receipt_long, size: 18, color: Color(0xFFFF7A36)),
                    label: const Text(
                      'Manage Billing & View Invoices in Subscription ➔',
                      style: TextStyle(
                        color: Color(0xFFFF7A36),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Guarantee Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '100% Secure Checkout via SSLCommerz / bKash. Cancel anytime from your Subscription screen.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required AppColors colors,
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? badge,
    Color? badgeColor,
    bool isHighlighted = false,
    bool isCurrent = false,
    required List<String> features,
    required String ctaLabel,
    VoidCallback? onCtaPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFF7A36)
              : (isCurrent ? const Color(0xFF10B981) : colors.border),
          width: isHighlighted || isCurrent ? 2 : 1,
        ),
        boxShadow: isHighlighted ? colors.cardShadow : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFFFF7A36)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor ?? const Color(0xFFFF7A36)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: badgeColor ?? const Color(0xFFFF7A36),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isHighlighted ? const Color(0xFFFF7A36) : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ $period',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onCtaPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighlighted ? const Color(0xFFFF7A36) : colors.surfaceElevated,
              foregroundColor: isHighlighted ? const Color(0xFF542747) : colors.textPrimary,
              disabledBackgroundColor: colors.surfaceElevated,
              disabledForegroundColor: colors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: isHighlighted ? 2 : 0,
            ),
            child: Text(
              ctaLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
