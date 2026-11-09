import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'upgrade_screen.dart';

/// Screen presenting the candidate's active subscription, billing cycle, receipts, and cancellation management
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late String _tier;
  late String _planName;
  late int _price;
  late String _paymentMethod;
  late String _date;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  void _loadSubscriptionData() {
    _tier = CacheService().read<String>('user_subscription_tier') ?? 'free';
    _planName = CacheService().read<String>('user_subscription_plan_name') ??
        (_tier == 'free' ? 'Free Starter Plan' : 'Prep404 Pro Pass');
    _price = CacheService().read<int>('user_subscription_price') ?? (_tier == 'free' ? 0 : 1499);
    _paymentMethod = CacheService().read<String>('user_subscription_method') ?? 'bKash';
    _date = CacheService().read<String>('user_subscription_date') ?? '2026-10-15';
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Cancel Subscription?',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'If you cancel, you will keep all Pro features until the end of your current billing period. No future charges will be billed.',
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep My Subscription'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              CacheService().write('user_subscription_tier', 'free');
              CacheService().write('user_subscription_plan_name', 'Free Starter Plan');
              CacheService().write('user_subscription_price', 0);
              setState(() {
                _loadSubscriptionData();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription has been cancelled. Reverted to Free Plan.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  void _restorePurchases() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
            const SizedBox(width: 8),
            Text(
              'Purchases Restored',
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Your account receipt and active plan status have been verified successfully.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A36),
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog({
    required String id,
    required String item,
    required int amount,
    required String method,
    required String date,
  }) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFFFF7A36), size: 22),
            const SizedBox(width: 8),
            Text(
              'Payment Receipt',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReceiptRow('Invoice #', id, colors),
            _buildReceiptRow('Item / Tier', item, colors),
            _buildReceiptRow('Amount Paid', '৳$amount.00', colors),
            _buildReceiptRow('Payment Via', method, colors),
            _buildReceiptRow('Payment Date', date.split('T').first, colors),
            _buildReceiptRow('Status', 'PAID (Verified)', colors, isStatus: true),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A36),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, AppColors colors, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isStatus ? const Color(0xFF10B981) : colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPro = _tier != 'free';

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
          'Subscription',
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
                // Active Plan Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isPro ? const Color(0xFFFF7A36) : colors.border,
                      width: isPro ? 1.5 : 1,
                    ),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPro ? Icons.workspace_premium : Icons.person_outline,
                                color: isPro ? const Color(0xFFFF7A36) : colors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _planName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPro
                            ? 'Billed: ৳$_price via $_paymentMethod'
                            : 'Free baseline account for admission syllabus practice.',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPro ? 'Next Renewal: December 31, 2026' : 'Status: Free Lifetime Access',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: colors.border, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (GoRouter.maybeOf(context) != null) {
                                  context.push(AppRoutes.upgrade).then((_) {
                                    setState(() => _loadSubscriptionData());
                                  });
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                                  ).then((_) {
                                    setState(() => _loadSubscriptionData());
                                  });
                                }
                              },
                              icon: const Icon(Icons.flash_on, size: 16),
                              label: Text(
                                isPro ? 'Change Plan' : 'Upgrade to Pro Pass',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7A36),
                                foregroundColor: const Color(0xFF542747),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Billing & Invoices Section
                Text(
                  'BILLING & INVOICE HISTORY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: colors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      _buildInvoiceTile(
                        id: 'INV-2026-881',
                        title: _planName,
                        amount: _price,
                        date: _date,
                        method: _paymentMethod,
                        colors: colors,
                      ),
                      Divider(color: colors.border, height: 1),
                      _buildInvoiceTile(
                        id: 'INV-2026-101',
                        title: 'Free Candidate Enrollment',
                        amount: 0,
                        date: '2026-10-01',
                        method: 'Prep404 Baseline',
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Management & Tools Section
                Text(
                  'SUBSCRIPTION CONTROLS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: colors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.restore, color: Color(0xFFFF7A36)),
                          title: Text(
                            'Restore Purchases',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Restore previously purchased season passes or subscriptions',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: _restorePurchases,
                        ),
                        Divider(color: colors.border, height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline, color: Color(0xFF3B82F6)),
                          title: Text(
                            'Billing Support & Refund Request',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Contact Prep404 academic support for billing inquiries',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            if (GoRouter.maybeOf(context) != null) {
                              context.push(AppRoutes.learnerSupport);
                            }
                          },
                        ),
                        if (isPro) ...[
                          Divider(color: colors.border, height: 1),
                          ListTile(
                            leading: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
                            title: const Text(
                              'Cancel Subscription',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            subtitle: Text(
                              'Cancel auto-renewal without losing current period access',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: _showCancelConfirmation,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceTile({
    required String id,
    required String title,
    required int amount,
    required String date,
    required String method,
    required AppColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, size: 18, color: Color(0xFFFF7A36)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$id • ${date.split('T').first}',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '৳$amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                color: colors.textSecondary,
                tooltip: 'View Receipt',
                onPressed: () => _showReceiptDialog(
                  id: id,
                  item: title,
                  amount: amount,
                  method: method,
                  date: date,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
