import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, String>> _addresses = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final profile = auth.userProfile ?? {};
    final addr = profile['address'] as String? ?? '';
    final city = profile['city'] as String? ?? '';
    final pin = profile['pincode'] as String? ?? '';
    if (addr.isNotEmpty || city.isNotEmpty) {
      _addresses = [
        {'label': 'Home', 'address': addr, 'city': city, 'pincode': pin}
      ];
    }
  }

  void _showAddDialog() {
    final labelCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Add Address',
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(labelCtrl, 'Label (e.g. Home, Office)'),
              SizedBox(height: 8),
              _field(addrCtrl, 'Address'),
              SizedBox(height: 8),
              _field(cityCtrl, 'City'),
              SizedBox(height: 8),
              _field(pinCtrl, 'Pincode'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (addrCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _addresses.add({
                    'label': labelCtrl.text.trim().isEmpty
                        ? 'Address'
                        : labelCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'pincode': pinCtrl.text.trim(),
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  TextField _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
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
        title: Text('Saved Addresses',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.brandBlue,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _addresses.isEmpty
          ? Center(
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
                    child: Icon(Icons.location_off_rounded,
                        size: 36, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 16),
                  Text('No saved addresses',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Text('Tap + to add one',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textMuted)),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(20),
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (_, i) {
                final a = _addresses[i];
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          a['label'] == 'Home'
                              ? Icons.home_rounded
                              : a['label'] == 'Office'
                                  ? Icons.work_rounded
                                  : Icons.location_on_rounded,
                          color: AppColors.brandBlue,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['label'] ?? 'Address',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text(
                              [a['address'], a['city'], a['pincode']]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(', '),
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _addresses.removeAt(i)),
                        child: Icon(Icons.delete_outline_rounded, color: AppColors.statusRed, size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
