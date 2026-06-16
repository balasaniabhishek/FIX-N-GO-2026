import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/mqtt_service.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'track_technician_screen.dart';

class FindingTechScreen extends StatefulWidget {
  final String orderId;
  const FindingTechScreen({super.key, required this.orderId});

  @override
  State<FindingTechScreen> createState() => _FindingTechScreenState();
}

class _FindingTechScreenState extends State<FindingTechScreen>
    with TickerProviderStateMixin {
  final MqttService _socketService = MqttService();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _dotController;
  late Animation<double> _pulseAnim;
  late Animation<double> _rippleAnim;

  bool _techFound = false;
  int _dotCount = 0;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _setupSocket();
    _fetchOrder();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _dotCount = (_dotCount + 1) % 4);
          _dotController.reset();
          _dotController.forward();
        }
      });
    _dotController.forward();

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _setupSocket() {
    _socketService.connect().then((_) {
      _socketService.onOrderUpdated((data) {
        if (data['orderId'] == widget.orderId) {
          final status = data['status'];
          if (status == 'assigned') {
            _fetchOrder();
          }
        }
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
          if (order.status == 'assigned') {
            _techFound = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching order: $e');
    }
  }

  @override
  void dispose() {
    _socketService.off('order-updated');
    _pulseController.dispose();
    _rippleController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 10),
              // Header
              Row(
                children: [
                  Text(
                    'Finding technician',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _dotController,
                builder: (_, __) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _techFound
                        ? 'Technician found! 🎉'
                        : 'Broadcasting to nearby fixers$dots',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _techFound
                          ? AppColors.brandGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Map area
              Expanded(
                child: Container(
                  width: double.infinity,
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
                        // Location label
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: AppColors.brandBlue, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  _order?.serviceAddress ?? 'Locating...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
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
              // Tech card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _techFound && _order != null
                    ? _TechFoundCard(
                        name: _order!.technicianName ?? 'Technician',
                        rating: _order!.technicianRating ?? 4.8,
                        onTrack: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TrackTechnicianScreen(orderId: widget.orderId)),
                          );
                        },
                      )
                    : _SearchingCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlutterMap() {
    final customerLat = _order?.serviceLat ?? 17.4065;
    final customerLng = _order?.serviceLng ?? 78.4772;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(customerLat, customerLng),
        initialZoom: 14.5,
      ),
      children: [
        TileLayer(
          urlTemplate: const String.fromEnvironment('TILESERVER_URL', defaultValue: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
          userAgentPackageName: 'com.fixngo.customerapp',
        ),
        MarkerLayer(
          markers: [
            // Center user marker with ripple
            Marker(
              point: LatLng(customerLat, customerLng),
              width: 150,
              height: 150,
              child: AnimatedBuilder(
                animation: _rippleAnim,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ripple
                      Opacity(
                        opacity: (1 - _rippleAnim.value) * 0.4,
                        child: Container(
                          width: 120 * _rippleAnim.value,
                          height: 120 * _rippleAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.brandBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Inner ripple
                      Opacity(
                        opacity: (1 - _rippleAnim.value).clamp(0.0, 1.0) * 0.6,
                        child: Container(
                          width: 70 * _rippleAnim.value,
                          height: 70 * _rippleAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandBlue.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      // User dot
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan.withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Mock nearby technicians
            if (!_techFound) ...[
              Marker(
                point: LatLng(customerLat + 0.005, customerLng + 0.005),
                width: 44,
                height: 44,
                child: const _TechMarker(name: 'R', isActive: false, delay: 0),
              ),
              Marker(
                point: LatLng(customerLat - 0.003, customerLng + 0.008),
                width: 44,
                height: 44,
                child: const _TechMarker(name: 'A', isActive: false, delay: 500),
              ),
              Marker(
                point: LatLng(customerLat - 0.006, customerLng - 0.004),
                width: 44,
                height: 44,
                child: const _TechMarker(name: 'K', isActive: false, delay: 1000),
              ),
            ],
            if (_techFound && _order?.technicianLat != null && _order?.technicianLng != null)
              Marker(
                point: LatLng(_order!.technicianLat!, _order!.technicianLng!),
                width: 44,
                height: 44,
                child: const _TechMarker(name: 'T', isActive: true, delay: 0),
              ),
          ],
        ),
      ],
    );
  }
}

class _TechMarker extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final String name;
  final bool isActive;
  final int delay;

  const _TechMarker({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.name,
    required this.isActive,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.brandBlue.withValues(alpha: 0.9)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppColors.brandBlue : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.brandBlue.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Center(
          child: Icon(Icons.person_rounded,
              color: isActive ? Colors.white : AppColors.textMuted, size: 22),
        ),
      ),
    );
  }
}

class _SearchingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.brandBlue.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Looking for technicians',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text('Searching in your area...',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechFoundCard extends StatelessWidget {
  final String name;
  final double rating;
  final VoidCallback onTrack;

  const _TechFoundCard({
    required this.name,
    required this.rating,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandBlue, AppColors.accentCyan],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded,
                    color: Colors.white, size: 26),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.starYellow, size: 14),
                        SizedBox(width: 4),
                        Text(rating.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            )),
                        SizedBox(width: 8),
                        Icon(Icons.directions_walk_rounded, color: AppColors.textMuted, size: 14),
                        SizedBox(width: 2),
                        Text('Nearby',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('Accepted',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandGreen,
                        )),
                    Text('~12 min',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTrack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Track Technician',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

