import 'package:flutter/material.dart';

import 'api_service_new.dart';
import 'widgets/common_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  String _selectedMethod = 'upi';
  bool _loading = false;
  bool _success = false;
  Map<String, dynamic>? _job;
  late AnimationController _successCtrl;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _job = args;
    }
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (_job?['_id'] != null) {
      await _api.completeJob(_job!['_id']);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
    _successCtrl.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final price = _job?['estimatedPrice'] ?? 499;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text('Collect Payment'),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.green.withValues(alpha: 0.15),
                          AppColors.green.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Amount to Collect',
                          style: TextStyle(color: AppColors.grey, fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₹$price',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Service completed • Collect now',
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  const SectionLabel('Payment Method'),
                  _paymentOption(
                    'upi',
                    Icons.qr_code_rounded,
                    'UPI / QR Code',
                    'Google Pay, PhonePe, Paytm',
                    AppColors.orange,
                  ),
                  SizedBox(height: 10),
                  _paymentOption(
                    'cash',
                    Icons.payments_rounded,
                    'Cash',
                    'Collect cash directly',
                    AppColors.green,
                  ),
                  SizedBox(height: 28),
                  if (_selectedMethod == 'upi') ...[
                    GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'Show this QR to customer',
                            style: TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                          SizedBox(height: 16),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.black),
                                  SizedBox(height: 4),
                                  Text(
                                    'fixer@upi',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'UPI ID: fixer@ybl',
                            style: TextStyle(color: AppColors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28),
                  ],
                  if (_selectedMethod == 'cash') ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.yellow, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Cash Collection Tips',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _tip('Collect exact amount ₹$price'),
                          _tip('Provide receipt to customer'),
                          _tip('Deposit to wallet within 24 hours'),
                        ],
                      ),
                    ),
                    SizedBox(height: 28),
                  ],
                  PrimaryButton(
                    label: 'Confirm Payment Received',
                    onTap: _confirmPayment,
                    isLoading: _loading,
                    color: AppColors.green,
                    icon: Icons.check_circle_rounded,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_success)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                child: Center(
                  child: ScaleTransition(
                    scale: _successScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.green,
                          ),
                          child: Icon(Icons.check_rounded, color: Colors.white, size: 56),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Payment Collected!',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Job completed successfully',
                          style: TextStyle(color: AppColors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, IconData icon, String title, String subtitle, Color color) {
    final selected = _selectedMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Theme.of(context).colorScheme.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color: selected ? color : AppColors.grey,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.arrow_right_rounded, color: AppColors.yellow, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.greyLight, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}