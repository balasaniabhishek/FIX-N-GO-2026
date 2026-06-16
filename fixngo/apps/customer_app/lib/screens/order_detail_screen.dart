import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'payment_sheet.dart';
import 'track_technician_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _errorMsg;
  bool _payLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        setState(() { _loading = false; _errorMsg = 'Not logged in. Please log in again.'; });
        return;
      }
      _api.setToken(token);
      final res = await _api.get('/api/orders/${widget.orderId}');
      final data = res['data'];
      setState(() {
        _order = data is Map<String, dynamic> ? data : null;
        _loading = false;
      });
    } catch (e) {
      print('ORDER DETAIL LOAD ERROR: $e');
      setState(() { _loading = false; _errorMsg = 'Failed to load order. Please try again.'; });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.brandGreen;
      case 'cancelled':
        return AppColors.statusRed;
      case 'in_progress':
      case 'started':
        return AppColors.accentOrange;
      default:
        return AppColors.brandBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        title: Text('Order Details',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : (_order == null || _errorMsg != null)
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.statusRed, size: 48),
          SizedBox(height: 12),
          Text(
            _errorMsg ?? 'Failed to load order details',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final o = _order!;
    final status = (o['status'] as String?) ?? 'pending';
    final brand = (o['brand'] as String?) ?? '';
    final model = (o['model'] as String?) ?? '';
    final issues = (o['issues'] as List<dynamic>?) ?? [];
    final total = o['total'] ?? 0;
    final techName = (o['technicianName'] as String?) ?? '';
    final rawTechUser = o['technicianUser'];
    final techUser = rawTechUser is Map ? (rawTechUser['_id']?.toString() ?? '') : (rawTechUser?.toString() ?? '');
    final createdAt = (o['createdAt'] as String?) ?? '';
    final isActive = ['pending', 'assigned', 'on_the_way', 'in_progress', 'started']
        .contains(status.toLowerCase());

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(status),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Device info card
            _card(
              icon: Icons.smartphone_rounded,
              title: '$brand $model',
              children: [
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: issues
                      .map((issue) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(issue.toString(),
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppColors.brandBlue)),
                          ))
                      .toList(),
                ),
              ],
            ),
            SizedBox(height: 14),

            // Price card
            _card(
              icon: Icons.receipt_rounded,
              title: 'Payment',
              children: [
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: AppColors.textSecondary)),
                    Text('₹$total',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 14),

            // Technician card
            if (techName.isNotEmpty)
              _card(
                icon: Icons.engineering_rounded,
                title: 'Technician',
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.brandBlue.withValues(alpha: 0.2),
                        child: Text(
                          techName.isNotEmpty ? techName[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(techName,
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface)),
                      ),
                      if (isActive && techUser.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                orderId: widget.orderId,
                                recipientId: techUser,
                                recipientName: techName,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.chat_bubble_rounded, color: AppColors.brandBlue, size: 18),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            if (techName.isNotEmpty) SizedBox(height: 14),

            // Date card
            if (createdAt.isNotEmpty)
              _card(
                icon: Icons.calendar_today_rounded,
                title: 'Order Date',
                children: [
                  SizedBox(height: 4),
                  Text(_formatDate(createdAt),
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            SizedBox(height: 24),

            // Payment section
            _buildPaymentSection(o, status, total),
            SizedBox(height: 24),

            // Action buttons
            if (isActive) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrackTechnicianScreen(orderId: widget.orderId),
                    ),
                  ),
                  icon: Icon(Icons.location_on_rounded),
                  label: Text('Track Technician',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelOrder(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusRed,
                    side: BorderSide(color: AppColors.statusRed),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel Order',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(Map<String, dynamic> o, String status, dynamic total) {
    final paymentStatus = (o['paymentStatus'] as String?) ?? 'pending';
    final isPaid = paymentStatus == 'collected';
    final isCompleted = status.toLowerCase() == 'completed';
    final isActive = ['pending', 'assigned', 'on_the_way', 'in_progress', 'started']
        .contains(status.toLowerCase());

    if (isPaid) {
      // Already paid — show a green badge
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.brandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.brandGreen, size: 22),
            SizedBox(width: 12),
            Text(
              'Payment Collected',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brandGreen,
              ),
            ),
            const Spacer(),
            Text(
              '₹$total',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.brandGreen,
              ),
            ),
          ],
        ),
      );
    }

    if (isCompleted || isActive) {
      // Show Pay Now button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _payLoading ? null : () => _handlePayNow(o, total),
          icon: _payLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Icon(Icons.payment_rounded),
          label: Text(
            _payLoading ? 'Processing...' : 'Pay ₹$total Now',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }

  Future<void> _handlePayNow(Map<String, dynamic> o, dynamic total) async {
    setState(() => _payLoading = true);
    try {
      final payService = PaymentService();
      final intentData = await payService.createPaymentIntent(
        widget.orderId,
        (total is num) ? total : num.parse(total.toString()),
      );
      final paymentId = intentData['paymentId']?.toString() ?? '';
      final clientSecret = intentData['clientSecret']?.toString() ?? '';
      final paymentIntentId = clientSecret.contains('_secret')
          ? clientSecret.split('_secret')[0]
          : clientSecret;

      if (!mounted) return;
      final success = await showPaymentSheet(
        context,
        orderId: widget.orderId,
        paymentId: paymentId,
        paymentIntentId: paymentIntentId,
        amount: (total is num) ? total : num.parse(total.toString()),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Payment successful!'),
            backgroundColor: AppColors.brandGreen,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _payLoading = false);
    }
  }


  Widget _card({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandBlue, size: 18),
              SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      var months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Cancel Order?',
            style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this order?',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            child: Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.patch('/api/orders/${widget.orderId}', {'status': 'cancelled'});
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }
}
