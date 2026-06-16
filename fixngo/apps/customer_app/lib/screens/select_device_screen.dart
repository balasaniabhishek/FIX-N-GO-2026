import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'screen_guard_screen.dart';
import 'repair_issue_screen.dart';

class SelectDeviceScreen extends StatefulWidget {
  final String serviceType;
  const SelectDeviceScreen({super.key, required this.serviceType});

  @override
  State<SelectDeviceScreen> createState() => _SelectDeviceScreenState();
}

class _SelectDeviceScreenState extends State<SelectDeviceScreen> {
  String? selectedBrand = 'Samsung';
  String selectedModel = 'Galaxy S25 Ultra';
  final TextEditingController _customModelCtrl = TextEditingController();

  @override
  void dispose() {
    _customModelCtrl.dispose();
    super.dispose();
  }

  final List<String> brands = [
    'Samsung',
    'iPhone',
    'Google Pixel',
    'OnePlus',
    'Xiaomi',
    'Redmi',
    'POCO',
    'Realme',
    'Vivo',
    'iQOO',
    'OPPO',
    'Motorola',
    'Nokia',
    'Sony Xperia',
    'Asus ROG',
    'Asus Zenfone',
    'Other',
  ];

  final Map<String, List<String>> models = {
    'Samsung': [
      'Galaxy S21', 'Galaxy S21+', 'Galaxy S21 Ultra',
      'Galaxy Z Fold 3', 'Galaxy Z Flip 3',
      'Galaxy A52', 'Galaxy A72',
      'Galaxy S22', 'Galaxy S22+', 'Galaxy S22 Ultra',
      'Galaxy Z Fold 4', 'Galaxy Z Flip 4', 'Galaxy A53 5G',
      'Galaxy S23', 'Galaxy S23+', 'Galaxy S23 Ultra',
      'Galaxy Z Fold 5', 'Galaxy Z Flip 5',
      'Galaxy S24', 'Galaxy S24+', 'Galaxy S24 Ultra',
      'Galaxy Z Fold 6', 'Galaxy Z Flip 6',
      'Galaxy S25', 'Galaxy S25+', 'Galaxy S25 Ultra',
    ],
    'iPhone': [
      'iPhone 12', 'iPhone 12 Mini', 'iPhone 12 Pro', 'iPhone 12 Pro Max',
      'iPhone SE 3',
      'iPhone 13', 'iPhone 13 Mini', 'iPhone 13 Pro', 'iPhone 13 Pro Max',
      'iPhone 14', 'iPhone 14 Plus', 'iPhone 14 Pro', 'iPhone 14 Pro Max',
      'iPhone 15', 'iPhone 15 Plus', 'iPhone 15 Pro', 'iPhone 15 Pro Max',
      'iPhone 16', 'iPhone 16 Plus', 'iPhone 16 Pro', 'iPhone 16 Pro Max', 'iPhone 16e',
    ],
    'Google Pixel': [
      'Pixel 5a',
      'Pixel 6', 'Pixel 6 Pro', 'Pixel 6a',
      'Pixel 7', 'Pixel 7 Pro', 'Pixel 7a', 'Pixel Fold',
      'Pixel 8', 'Pixel 8 Pro', 'Pixel 8a',
      'Pixel 9', 'Pixel 9 Pro', 'Pixel 9 Pro XL', 'Pixel 9 Pro Fold',
    ],
    'OnePlus': [
      'OnePlus 9', 'OnePlus 9 Pro', 'OnePlus Nord 2',
      'OnePlus 10 Pro', 'OnePlus Nord 2T', 'OnePlus 10T',
      'OnePlus 11', 'OnePlus Nord 3', 'OnePlus Open',
      'OnePlus 12', 'OnePlus Nord 4',
      'OnePlus 13', 'OnePlus 13R',
    ],
    'Xiaomi': [
      'Xiaomi 11T Pro',
      'Xiaomi 12', 'Xiaomi 12 Pro',
      'Xiaomi 13', 'Xiaomi 13 Pro',
      'Xiaomi 14', 'Xiaomi 14 Ultra',
      'Xiaomi 15', 'Xiaomi 15 Ultra',
    ],
    'Redmi': [
      'Redmi Note 10 Pro',
      'Redmi Note 11 Pro',
      'Redmi Note 12 Pro',
      'Redmi Note 13 Pro',
    ],
    'POCO': [
      'POCO F3',
      'POCO X4 Pro 5G',
      'POCO F5 Pro',
      'POCO X6 Pro',
    ],
    'Realme': [
      'Realme 8 Pro', 'Realme GT', 'Realme Narzo 30',
      'Realme GT 2 Pro', 'Realme 9 Pro+', 'Realme C35', 'Realme GT Neo 3',
      'Realme 11 Pro+',
      'Realme GT 5 Pro', 'Realme 13 Pro+',
      'Realme 14 Pro+',
    ],
    'Vivo': [
      'Vivo X60 Pro', 'Vivo V21 5G',
      'Vivo X80 Pro', 'Vivo V25 Pro',
      'Vivo X90 Pro+',
      'Vivo X100 Pro',
      'Vivo X200 Pro',
    ],
    'iQOO': [
      'iQOO 7',
      'iQOO 10 Pro',
      'iQOO 11',
      'iQOO 12',
      'iQOO 13',
    ],
    'OPPO': [
      'OPPO Find X3 Pro', 'OPPO Reno 6 Pro', 'OPPO A74',
      'OPPO Find X5 Pro', 'OPPO Reno 8 Pro',
      'OPPO Find X6 Pro', 'OPPO Reno 10 Pro+',
      'OPPO Find X7 Ultra', 'OPPO Reno 12 Pro',
      'OPPO Find X8 Pro',
    ],
    'Motorola': [
      'Moto G100', 'Motorola Edge 20', 'Moto G Stylus 5G',
      'Moto Edge 30 Pro', 'Moto G82 5G', 'Motorola Razr 5G',
      'Moto Edge 40 Pro', 'Motorola Razr 40',
      'Moto Edge 50 Pro', 'Motorola Razr 50',
      'Motorola Edge 60',
    ],
    'Nokia': [
      'Nokia XR20', 'Nokia G50', 'Nokia C30',
      'Nokia G60', 'Nokia X30 5G',
      'Nokia G42 5G', 'Nokia G310 5G',
      'Nokia C300', 'Nokia G400',
    ],
    'Sony Xperia': [
      'Xperia 1 III', 'Xperia 5 III', 'Xperia 10 III',
      'Xperia 1 IV', 'Xperia 5 IV',
      'Xperia 1 V', 'Xperia 5 V',
      'Xperia 1 VI', 'Xperia 5 VI',
      'Xperia 1 VII',
    ],
    'Asus ROG': [
      'ROG Phone 5',
      'ROG Phone 6',
      'ROG Phone 7',
      'ROG Phone 8 Pro',
      'ROG Phone 9',
    ],
    'Asus Zenfone': [
      'Zenfone 8',
      'Zenfone 9',
      'Zenfone 10',
      'Zenfone 11 Ultra',
    ],
  };

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
        title: Text(
          'Select your phone',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Brand',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          )),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: brands.map((brand) {
                          final isSelected = selectedBrand == brand;
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedBrand = brand;
                              if (brand == 'Other') {
                                selectedModel = '';
                                _customModelCtrl.clear();
                              } else {
                                selectedModel = models[brand]!.first;
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.brandBlue : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.brandBlue : Theme.of(context).colorScheme.outline,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(
                                        color: AppColors.brandBlue.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4))]
                                    : [],
                              ),
                              child: Text(
                                brand,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 28),
                      Text('Model',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          )),
                      SizedBox(height: 12),
                      if (selectedBrand == 'Other') ...[  
                        // Custom model text input
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _customModelCtrl.text.isEmpty
                                  ? Theme.of(context).colorScheme.outline
                                  : AppColors.brandBlue,
                            ),
                          ),
                          child: TextField(
                            controller: _customModelCtrl,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. Samsung Galaxy M15',
                              hintStyle: GoogleFonts.poppins(
                                  color: AppColors.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              suffixIcon: Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 18),
                            ),
                            onChanged: (val) => setState(() => selectedModel = val.trim()),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Type your exact phone model name above',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ] else ...[  
                        // Normal dropdown
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: DropdownButton<String>(
                            value: selectedModel,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            underline: SizedBox(),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            items: (models[selectedBrand] ?? []).map((model) {
                              return DropdownMenuItem(value: model, child: Text(model));
                            }).toList(),
                            onChanged: (val) => setState(() => selectedModel = val!),
                          ),
                        ),
                      ],
                      SizedBox(height: 24),
                      // Phone preview
                      Center(
                        child: Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selectedBrand == 'iPhone' || selectedBrand == 'Google Pixel'
                                    ? Icons.phone_iphone_rounded
                                    : selectedBrand == 'Asus ROG'
                                        ? Icons.sports_esports_rounded
                                        : Icons.smartphone_rounded,
                                size: 60,
                                color: AppColors.brandBlue.withValues(alpha: 0.6),
                              ),
                              SizedBox(height: 8),
                              Text(
                                selectedBrand ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedModel.trim().isEmpty ? null : () {
                    final device = selectedBrand == 'Other'
                        ? _customModelCtrl.text.trim()
                        : selectedModel;
                    if (widget.serviceType == 'guard') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScreenGuardScreen(device: device),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepairIssueScreen(device: device),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
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
}
