import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class TrackTechnicianScreen extends StatefulWidget {
  final String orderId;
  const TrackTechnicianScreen({super.key, required this.orderId});

  @override
  State<TrackTechnicianScreen> createState() => _TrackTechnicianScreenState();
}

class _TrackTechnicianScreenState extends State<TrackTechnicianScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final MqttService _socketService = MqttService();
  final StorageService _storageService = StorageService();

  late AnimationController _moveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  
  OrderModel? _order;
  bool _isLoading = true;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    _setupSocket();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _setupSocket() {
    _socketService.connect().then((_) {
      _socketService.onOrderUpdated((data) {
        if (data['orderId'] == widget.orderId) {
          _fetchOrder();
        }
      });

      _socketService.onNotification((data) {
        if (data['type'] == 'order_completed' && data['orderId'] == widget.orderId) {
          _fetchOrder();
          _openRazorpayCheckout(data['checkoutSession']);
        }
      });

      _socketService.onTechnicianLocation((data) {
        // Location data received - used for real map integration
        // ignore: unused_local_variable
        if (data['orderId'] == widget.orderId) setState(() {});
      });
    });
  }

  Future<void> _fetchOrder() async {
    try {
      final token = await _storageService.getToken();
      _apiService.setToken(token);
      final result = await _apiService.getOrderById(widget.orderId);
      final order = OrderModel.fromJson(result['data']);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> session) {
    var options = {
      'key': 'rzp_test_replace_me', // Replace with your key
      'amount': session['amount'], // in paise
      'name': 'Fix-N-Go',
      'order_id': session['id'],
      'description': 'Repair Service Payment',
      'prefill': {
        'contact': _order?.customerPhone ?? '',
        'email': 'customer@example.com'
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Successful!')));
    _fetchOrder();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed. Please try again.')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet Selected: ${response.walletName}')));
  }

  @override
  void dispose() {
    _socketService.off('order-updated');
    _socketService.off('technician-location');
    _socketService.off('notification');
    _pulseController.dispose();
    _razorpay.clear();
    super.dispose();
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
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        title: Text('Track Technician',
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Icon(Icons.phone_rounded, color: AppColors.brandGreen, size: 22),
              onPressed: () {
                final phone = _order?.technicianPhone ?? '';
                if (phone.isNotEmpty) {
                  launchUrl(Uri.parse('tel:$phone'));
                }
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Live map
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1A2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            _buildFlutterMap(),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.brandGreen),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_rounded, color: AppColors.brandGreen, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      _order?.status == 'assigned' ? 'Coming soon' : 'On site',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Info cards
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Technician info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.brandBlue, AppColors.accentCyan],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person_rounded,
                                    color: Colors.white, size: 28),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_order?.technicianName ?? 'Technician',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        )),
                                    Row(
                                      children: [
                                        Icon(Icons.star_rounded, color: AppColors.starYellow, size: 14),
                                        SizedBox(width: 3),
                                        Text(_order?.technicianRating?.toString() ?? '4.8',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            )),
                                        Text(' · Top Fixer',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                    _ActionButton(
                                      icon: Icons.chat_bubble_rounded,
                                      color: AppColors.brandBlue,
                                      onTap: () {
                                        if (_order != null && _order!.technicianUser != null && _order!.technicianUser!.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatScreen(
                                                orderId: widget.orderId,
                                                recipientId: _order!.technicianUser!,
                                                recipientName: _order!.technicianName ?? 'Technician',
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Technician not assigned yet')),
                                          );
                                        }
                                      },
                                    ),
                                  SizedBox(width: 10),
                                  _ActionButton(
                                    icon: Icons.phone_rounded,
                                    color: AppColors.brandGreen,
                                    onTap: () {
                                      final phone = _order?.technicianPhone ?? '';
                                      if (phone.isNotEmpty) {
                                        launchUrl(Uri.parse('tel:$phone'));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // OTP Display if in progress
                        if (_order?.status == 'in_progress' && _order?.completionOtp != null)
                          Container(
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.brandGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.brandGreen),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Completion PIN:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                                Text(_order!.completionOtp!, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.brandGreen)),
                              ],
                            ),
                          ),
                        // Progress steps
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  )),
                              SizedBox(height: 12),
                              _StatusStep(
                                  label: 'Booking Confirmed',
                                  isDone: true,
                                  icon: Icons.check_circle_rounded),
                              _StatusStep(
                                  label: 'Technician On the Way',
                                  isDone: _order?.status != 'pending',
                                  isActive: _order?.status == 'assigned',
                                  icon: Icons.directions_bike_rounded),
                              _StatusStep(
                                  label: 'Repair In Progress',
                                  isDone: _order?.status == 'in_progress' || _order?.status == 'completed',
                                  isActive: _order?.status == 'in_progress',
                                  icon: Icons.build_rounded),
                              _StatusStep(
                                  label: 'Completed',
                                  isDone: _order?.status == 'completed',
                                  isLast: true,
                                  icon: Icons.verified_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildFlutterMap() {
    final customerLat = _order?.serviceLat ?? 17.4065;
    final customerLng = _order?.serviceLng ?? 78.4772;
    
    // Fallback to customer location if tech location is unknown
    final techLat = _order?.technicianLat ?? customerLat + 0.005;
    final techLng = _order?.technicianLng ?? customerLng + 0.005;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(customerLat, customerLng),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: const String.fromEnvironment('TILESERVER_URL', defaultValue: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
              userAgentPackageName: 'com.fixngo.customerapp',
            ),
            MarkerLayer(
              markers: [
                // Customer Marker
                Marker(
                  point: LatLng(customerLat, customerLng),
                  width: 60,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.statusRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.statusRed.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(Icons.home_rounded, color: Colors.white, size: 16),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.statusRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('You',
                            style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                // Technician Marker
                if (_order?.status != 'pending')
                  Marker(
                    point: LatLng(techLat, techLng),
                    width: 70,
                    height: 70,
                    child: Transform.scale(
                      scale: _pulseAnim.value,
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.brandBlue, AppColors.accentCyan],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandBlue.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 18),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(_order?.technicianName ?? 'Fixer',
                                style: GoogleFonts.poppins(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // We can draw a polyline between customer and tech using PolylineLayer if desired
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [
                    LatLng(techLat, techLng),
                    LatLng(customerLat, customerLng),
                  ],
                  color: AppColors.brandBlue.withValues(alpha: 0.5),
                  strokeWidth: 4.0,
                  pattern: StrokePattern.dashed(segments: [10.0, 10.0]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isLast;
  final IconData icon;

  const _StatusStep({
    required this.label,
    required this.isDone,
    this.isActive = false,
    this.isLast = false,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? (isActive ? AppColors.brandBlue : AppColors.brandGreen)
        : Theme.of(context).colorScheme.outline;

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone ? color.withValues(alpha: 0.2) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            if (!isLast)
              Container(width: 2, height: 20, color: color.withValues(alpha: 0.4)),
          ],
        ),
        SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isDone ? Theme.of(context).colorScheme.onSurface : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}


