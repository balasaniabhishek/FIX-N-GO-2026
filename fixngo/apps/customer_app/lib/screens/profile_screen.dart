import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'auth/login_screen.dart';
import 'help_faq_screen.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'payment_methods_screen.dart';
import 'rate_app_screen.dart';
import 'saved_addresses_screen.dart';
import 'support_chat_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final profile = auth.userProfile ?? {};
    final nameController = TextEditingController(text: profile['name'] ?? '');
    final phoneController = TextEditingController(text: profile['phone'] ?? '');
    final addressController = TextEditingController(text: profile['address'] ?? '');
    final cityController = TextEditingController(text: profile['city'] ?? '');
    final pincodeController = TextEditingController(text: profile['pincode'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 8),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 8),
              TextField(
                controller: pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await auth.updateProfile(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
                city: cityController.text.trim(),
                pincode: pincodeController.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile')),
                  );
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langCode = context.watch<LocaleProvider>().languageCode.toUpperCase();
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final profile = auth.userProfile ?? {};
        final name = profile['name'] as String? ?? 'Customer';
        final phone = profile['phone'] as String? ?? '';
        final email = profile['email'] as String? ?? '';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header gradient
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A2A4A), Theme.of(context).scaffoldBackgroundColor],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.profile,
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                )),
                            GestureDetector(
                              onTap: () => _showEditProfileDialog(context, auth),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                                ),
                                child: Icon(Icons.edit_rounded,
                                    size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.brandBlue, AppColors.accentCyan],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                              ),
                              child: Icon(Icons.person_rounded,
                                  color: Colors.white, size: 44),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.brandGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: Icon(Icons.verified,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            )),
                        if (email.isNotEmpty)
                          Text(email,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              )),
                        if (phone.isNotEmpty)
                          Text(phone,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              )),
                        SizedBox(height: 20),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatItem(value: '7', label: l10n.repairs),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu items
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MenuSection(
                          title: l10n.account,
                          items: [
                            _MenuItem(
                                icon: Icons.person_outline_rounded,
                                label: l10n.personalInfo,
                                onTap: () => _showEditProfileDialog(context, auth)),
                            _MenuItem(
                                icon: Icons.location_on_outlined,
                                label: l10n.savedAddresses,
                                badge: '2',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const SavedAddressesScreen()))),
                            _MenuItem(
                                icon: Icons.payment_rounded,
                                label: l10n.paymentMethods,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
                          ],
                        ),
                        SizedBox(height: 20),
                        _MenuSection(
                          title: l10n.support,
                          items: [
                            _MenuItem(
                                icon: Icons.help_outline_rounded,
                                label: l10n.helpFaq,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const HelpFaqScreen()))),
                            _MenuItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: l10n.chatSupport,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const SupportChatScreen()))),
                            _MenuItem(
                                icon: Icons.star_outline_rounded,
                                label: l10n.rateApp,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const RateAppScreen()))),
                          ],
                        ),
                        SizedBox(height: 20),
                        _MenuSection(
                          title: l10n.preferences,
                          items: [
                            _MenuItem(
                                icon: Icons.dark_mode_outlined,
                                label: 'Dark Mode',
                                trailing: Consumer<ThemeProvider>(
                                  builder: (ctx, theme, _) => Switch(
                                    value: theme.isDark,
                                    onChanged: (_) => theme.toggle(),
                                    activeThumbColor: AppColors.brandBlue,
                                    activeTrackColor: AppColors.brandBlue.withValues(alpha: 0.4),
                                  ),
                                ),
                                onTap: () => context.read<ThemeProvider>().toggle()),
                            _MenuItem(
                                icon: Icons.notifications_outlined,
                                label: l10n.notifications,
                                trailing: Switch(
                                  value: true,
                                  onChanged: (_) {},
                                  activeThumbColor: AppColors.brandBlue,
                                  activeTrackColor: AppColors.brandBlue.withValues(alpha: 0.4),
                                ),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                            _MenuItem(
                                icon: Icons.language_rounded,
                                label: l10n.language,
                                badge: langCode,
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const LanguageScreen()))),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Logout button
                        GestureDetector(
                          onTap: () async {
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.statusRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.statusRed.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, color: AppColors.statusRed, size: 20),
                                SizedBox(width: 10),
                                Text(l10n.logout,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusRed,
                                    )),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(l10n.version,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            )),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            )),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (i < items.length - 1)
                    Container(
                      margin: EdgeInsets.only(left: 56),
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.badge,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Icon(icon, size: 18, color: AppColors.brandBlue),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
            ),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandBlue,
                    )),
              ),
            if (trailing != null) trailing!,
            if (badge == null && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
