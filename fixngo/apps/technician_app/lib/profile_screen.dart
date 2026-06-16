
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';

import 'api_service_new.dart';
import 'widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  Uint8List? _photoBytes;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final dash = await _api.getDashboard();
    if (!mounted) return;
    setState(() {
      _profile = dash;
      _photoBytes = null;
      _photoUrl = dash?['profilePhoto'] as String?;
      _loading = false;
    });
  }

  Future<void> _updatePhoto() async {
    final source = (kIsWeb || 
                    defaultTargetPlatform == TargetPlatform.windows || 
                    defaultTargetPlatform == TargetPlatform.macOS || 
                    defaultTargetPlatform == TargetPlatform.linux)
        ? ImageSource.gallery
        : ImageSource.camera;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);

    if (kIsWeb) {
      return;
    }

    final uploaded = await _api.uploadProfilePhoto(image.path);
    if (!mounted) return;

    if (uploaded) {
      final refreshed = await _api.getDashboard();
      final photoUrl = refreshed?['profilePhoto'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        setState(() {
          _profile = refreshed;
          _photoUrl = photoUrl;
          _photoBytes = null;
        });
      }
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _miniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? 'Technician';
    final rating = _profile?['rating'] ?? '4.8';
    final jobs = _profile?['jobsDone'] ?? 0;

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
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          ),
        ),
        title: Text('Profile'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _updatePhoto,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.amber, width: 2.5),
                                ),
                                child: ClipOval(
                                  child: _photoBytes != null
                                      ? Image.memory(
                                          _photoBytes!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Theme.of(context).colorScheme.surface,
                                              child: Icon(Icons.person_rounded, color: AppColors.grey, size: 46),
                                            );
                                          },
                                        )
                                      : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                          ? Image.network(
                                              ApiService.imageUrl(_photoUrl!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Theme.of(context).colorScheme.surface,
                                                  child: Icon(Icons.person_rounded, color: AppColors.grey, size: 46),
                                                );
                                              },
                                            )
                                      : Container(
                                          color: Theme.of(context).colorScheme.surface,
                                          child: Icon(Icons.person_rounded, color: AppColors.grey, size: 46),
                                        ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _updatePhoto,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                  ),
                                  child: Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.navyDeep),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(name, style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Verified Technician', style: TextStyle(color: AppColors.green, fontSize: 13)),
                        SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _miniStat('$rating ★', 'Rating'),
                              Container(width: 1, height: 32, color: Theme.of(context).colorScheme.outline, margin: EdgeInsets.symmetric(horizontal: 20)),
                              _miniStat('$jobs', 'Jobs Done'),
                              Container(width: 1, height: 32, color: Theme.of(context).colorScheme.outline, margin: EdgeInsets.symmetric(horizontal: 20)),
                              _miniStat('4 yrs', 'Experience'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  const SectionLabel('Verification'),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.verified_rounded, color: AppColors.green),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aadhaar KYC', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text('Upload docs and keep your profile verified.', style: TextStyle(color: AppColors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('Manage'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  const SectionLabel('Specializations'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                        'Screen Replacement',
                      'Battery Fix',
                      'Water Damage',
                      'Charging Port',
                      'Software Issues',
                    ].map((s) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(s, style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                  SizedBox(height: 24),
                  const SectionLabel('Account'),
                  Consumer<ThemeProvider>(
                    builder: (context, theme, _) => Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode_outlined, color: AppColors.textPrimary, size: 20),
                          SizedBox(width: 14),
                          Expanded(child: Text('Dark Mode', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                          Switch(
                            value: theme.isDark,
                            onChanged: (_) => theme.toggle(),
                            activeColor: AppColors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _menuItem(Icons.edit, 'Edit Profile', () => Navigator.pushNamed(context, '/edit_profile')),
                  _menuItem(Icons.document_scanner_rounded, 'Documents & KYC', () => Navigator.pushNamed(context, '/kyc')),
                  _menuItem(Icons.account_balance_rounded, 'Bank Details', () => Navigator.pushNamed(context, '/bank_details')),
                  _menuItem(Icons.notifications_rounded, 'Notification Settings', () => Navigator.pushNamed(context, '/notification_settings')),
                  SizedBox(height: 16),
                  const SectionLabel('Support'),
                  _menuItem(Icons.help_rounded, 'Help & Support', () => Navigator.pushNamed(context, '/support')),
                  _menuItem(Icons.policy_rounded, 'Privacy Policy', () => Navigator.pushNamed(context, '/privacy')),
                  _menuItem(Icons.gavel_rounded, 'Terms of Service', () => Navigator.pushNamed(context, '/terms')),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(color: AppColors.red, fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
