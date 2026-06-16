import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _loading = true;
  List<Map<String, dynamic>> _allOrders = [];
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        setState(() { _loading = false; _errorMsg = 'Not logged in.'; });
        return;
      }
      _api.setToken(token);
      final res = await _api.get('/api/orders');
      final data = res['data'];
      if (data is List) {
        setState(() {
          _allOrders = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _allOrders = []; });
      }
    } catch (e) {
      print('ORDERS LOAD ERROR: $e');
      setState(() { _loading = false; _errorMsg = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _activeOrders => _allOrders
      .where((o) => ['pending', 'assigned', 'in_progress', 'started', 'on_the_way']
          .contains((o['status'] as String? ?? '').toLowerCase()))
      .toList();

  List<Map<String, dynamic>> get _completedOrders => _allOrders
      .where((o) => (o['status'] as String? ?? '').toLowerCase() == 'completed')
      .toList();

  List<Map<String, dynamic>> get _cancelledOrders => _allOrders
      .where((o) => (o['status'] as String? ?? '').toLowerCase() == 'cancelled')
      .toList();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return AppColors.brandGreen;
      case 'cancelled': return AppColors.statusRed;
      case 'in_progress':
      case 'started': return AppColors.accentOrange;
      default: return AppColors.brandBlue;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'in_progress':
      case 'started': return Icons.build_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Orders',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadOrders,
                    icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorPadding: EdgeInsets.all(4),
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
                  : _errorMsg != null
                      ? _buildError()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersList(_activeOrders, isActive: true),
                            _buildOrdersList(_completedOrders),
                            _buildOrdersList(_cancelledOrders),
                          ],
                        ),
            ),
          ],
        ),
      ),
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
            _errorMsg ?? 'Failed to load orders',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 14),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadOrders,
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

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, {bool isActive = false}) {
    if (orders.isEmpty) {
      return _buildEmptyState(isActive ? 'No active orders' : 'No orders here');
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.brandBlue,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: orders.length,
        itemBuilder: (context, i) {
          final order = orders[i];
          final status = (order['status'] as String? ?? 'pending');
          final orderId = order['_id']?.toString() ?? '';
          final brand = order['brand'] as String? ?? '';
          final model = order['model'] as String? ?? '';
          final total = order['total'] ?? 0;
          final issues = order['issues'] as List<dynamic>? ?? [];
          final createdAt = order['createdAt'] as String? ?? '';
          final statusCol = _statusColor(status);

          return GestureDetector(
            onTap: () {
              if (orderId.isNotEmpty && orderId.length > 8) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
                );
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? AppColors.brandBlue.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline,
                ),
                boxShadow: isActive
                    ? [BoxShadow(color: AppColors.brandBlue.withValues(alpha: 0.08), blurRadius: 16)]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: statusCol.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_statusIcon(status), color: statusCol, size: 24),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$brand $model',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (issues.isNotEmpty)
                              Text(
                                issues.take(2).join(', '),
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$total',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusCol.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusCol,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(height: 1, color: Theme.of(context).colorScheme.outline),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.receipt_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        orderId.length > 8 ? '#${orderId.substring(orderId.length - 6).toUpperCase()}' : orderId,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Spacer(),
                      Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                      SizedBox(width: 3),
                      Text(
                        _formatDate(createdAt),
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (isActive && orderId.isNotEmpty && orderId.length > 8) ...[
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text('View Details →',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(Icons.receipt_long_rounded, size: 36, color: AppColors.textMuted),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
