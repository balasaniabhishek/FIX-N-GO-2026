import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class EarningsScreen extends StatefulWidget {
  EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  

  Map<String, dynamic> _earnings = {};
  List<dynamic> _monthly = [];
  bool _loading = true;
  String? _error;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _paymentService.getTechnicianEarnings(),
        _paymentService.getMonthlyEarnings(),
      ]);
      setState(() {
        _earnings = results[0] as Map<String, dynamic>;
        _monthly = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          ),
        ),
        title: Text(
          'My Earnings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.greyLight),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.green,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.grey,
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Withdraw'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.green))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverview(),
                    _buildWithdraw(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
          SizedBox(height: 12),
          Text('Failed to load earnings',
              style: GoogleFonts.poppins(
                  color: AppColors.grey, fontSize: 14)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final wallet = (_earnings['walletBalance'] ?? 0).toDouble();
    final total = (_earnings['totalEarned'] ?? 0).toDouble();
    final completed = _earnings['completedOrders'] ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.green,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), AppColors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Wallet Balance',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '₹${wallet.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStat('Total Earned', '₹${total.toStringAsFixed(0)}'),
                      SizedBox(width: 24),
                      _miniStat('Jobs Done', '$completed'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Monthly breakdown
            Text(
              'Monthly Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 14),

            if (_monthly.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Center(
                  child: Text(
                    'No earnings yet. Complete jobs to see your breakdown.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: AppColors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...(_monthly.map((m) => _monthCard(m)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white60, fontSize: 11)),
        Text(value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }

  Widget _monthCard(dynamic m) {
    final month = m['month']?.toString() ?? '';
    final earning = (m['earning'] ?? 0).toDouble();
    final orders = m['orders'] ?? 0;

    String label = month;
    try {
      final parts = month.split('-');
      var months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      final idx = int.parse(parts[1]) - 1;
      label = '${months[idx]} ${parts[0]}';
    } catch (_) {}

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded, color: AppColors.green, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                Text('$orders job${orders != 1 ? 's' : ''} completed',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.greyLight)),
              ],
            ),
          ),
          Text(
            '₹${earning.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdraw() {
    return _WithdrawTab(
      walletBalance: (_earnings['walletBalance'] ?? 0).toDouble(),
      paymentService: _paymentService,
      onWithdrawn: _load,
    );
  }
}

// ─── Withdraw Tab ─────────────────────────────────────────────────────────────

class _WithdrawTab extends StatefulWidget {
  final double walletBalance;
  
  final VoidCallback onWithdrawn;

  _WithdrawTab({
    required this.walletBalance,
    required this.paymentService,
    required this.onWithdrawn,
  });

  @override
  State<_WithdrawTab> createState() => _WithdrawTabState();
}

class _WithdrawTabState extends State<_WithdrawTab> {
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _snack('Enter a valid amount');
      return;
    }
    if (amount > widget.walletBalance) {
      _snack('Amount exceeds wallet balance');
      return;
    }
    if (_accountCtrl.text.isEmpty || _ifscCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
      _snack('Fill in all bank details');
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.paymentService.requestWithdrawal(
        amount: amount,
        bankAccount: {
          'accountNumber': _accountCtrl.text.trim(),
          'ifsc': _ifscCtrl.text.trim().toUpperCase(),
          'accountHolder': _nameCtrl.text.trim(),
        },
      );
      widget.onWithdrawn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Withdrawal request submitted!'),
            backgroundColor: AppColors.green,
          ),
        );
        _amountCtrl.clear();
      }
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.green, size: 22),
                SizedBox(width: 12),
                Text('Available Balance',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.greyLight)),
                Spacer(),
                Text(
                  '₹${widget.walletBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          Text('Withdrawal Amount',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          SizedBox(height: 10),
          _field(_amountCtrl, 'e.g. 500',
              keyboardType: TextInputType.number,
              prefix: '₹ '),
          SizedBox(height: 20),

          Text('Bank Details',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          SizedBox(height: 10),
          _field(_nameCtrl, 'Account Holder Name'),
          SizedBox(height: 10),
          _field(_accountCtrl, 'Account Number',
              keyboardType: TextInputType.number),
          SizedBox(height: 10),
          _field(_ifscCtrl, 'IFSC Code',
              textCapitalization: TextCapitalization.characters),
          SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _submitting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text('Request Withdrawal',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Withdrawals are processed within 1-2 business days',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixStyle: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14),
        hintStyle:
            GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}
