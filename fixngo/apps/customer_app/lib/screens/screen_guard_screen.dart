import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'finding_tech_screen.dart';

class ScreenGuardScreen extends StatefulWidget {
  final String device;
  final String orderId;
  const ScreenGuardScreen({super.key, required this.device, this.orderId = ''});

  @override
  State<ScreenGuardScreen> createState() => _ScreenGuardScreenState();
}

class _ScreenGuardScreenState extends State<ScreenGuardScreen> {
  String selectedGuard = 'Tempered Glass';
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  final List<Map<String, dynamic>> guardTypes = [
    {
      'name': 'Tempered Glass',
      'price': 199,
      'icon': Icons.shield_rounded,
      'color': AppColors.brandGreen,
      'popular': true,
      'desc': 'Maximum protection',
    },
    {
      'name': 'Anti-Spy',
      'price': 299,
      'icon': Icons.visibility_off_rounded,
      'color': AppColors.accentCyan,
      'popular': false,
      'desc': 'Privacy screen',
    },
    {
      'name': 'Matte Guard',
      'price': 249,
      'icon': Icons.texture_rounded,
      'color': AppColors.accentOrange,
      'popular': false,
      'desc': 'Anti-glare finish',
    },
    {
      'name': 'Premium UV',
      'price': 399,
      'icon': Icons.star_rounded,
      'color': const Color(0xFFD946EF),
      'popular': false,
      'desc': 'Best quality',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selected = guardTypes.firstWhere((g) => g['name'] == selectedGuard);

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
        title: Text(
          'Choose guard type',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Text(
                  widget.device,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: guardTypes.length,
                  itemBuilder: (context, i) {
                    final g = guardTypes[i];
                    final isSelected = selectedGuard == g['name'];
                    return GestureDetector(
                      onTap: () => setState(() => selectedGuard = g['name'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (g['color'] as Color).withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (g['color'] as Color)
                                : Theme.of(context).colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: (g['color'] as Color).withValues(alpha: 0.2),
                                      blurRadius: 12)
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (g['color'] as Color).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(g['icon'] as IconData,
                                      color: g['color'] as Color, size: 20),
                                ),
                                const Spacer(),
                                if (g['popular'] as bool)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandGreen.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Best',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: AppColors.brandGreen,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              g['name'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              g['desc'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₹${g['price']}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: g['color'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.brandGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✓ Includes professional fitting',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandGreen,
                            ),
                          ),
                          Text(
                            'Bubble-free installation at your door',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _createOrder(selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Book Installation — ₹${selected['price']}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createOrder(Map<String, dynamic> selected) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storageService.getToken();
      _apiService.setToken(token);

      final parts = widget.device.split(' ');
      final brand = parts.isNotEmpty ? parts[0] : 'Generic';
      final model = parts.length > 1 ? parts.sublist(1).join(' ') : 'Device';

      String address = 'Current Location';
      double? lat;
      double? lng;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          lat = position.latitude;
          lng = position.longitude;

          final placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            address = '${pm.street ?? ""}, ${pm.locality ?? pm.subAdministrativeArea ?? ""}, ${pm.postalCode ?? ""}';
          }
        }
      } catch (e) {
        debugPrint('Location fetch failed: $e');
      }

      final result = await _apiService.createOrder(
        brand: brand,
        model: model,
        issues: ['Screen Guard: ${selected['name']}'],
        total: selected['price'] as int,
        serviceAddress: address,
        city: 'Hyderabad',
        serviceLat: lat,
        serviceLng: lng,
      );

      if (mounted) {
        final orderId = result['data']['_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FindingTechScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
