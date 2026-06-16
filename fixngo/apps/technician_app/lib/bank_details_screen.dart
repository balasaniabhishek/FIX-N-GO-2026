import 'package:flutter/material.dart';
import 'api_service_new.dart';
import 'widgets/common_widgets.dart';

class BankDetailsScreen extends StatefulWidget {
  BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _api = ApiService();
  final _accNameCtrl = TextEditingController();
  final _accNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _api.getProfile();
    if (!mounted) return;
    if (profile != null) {
      final bankDetails = profile['bankDetails'] as Map<String, dynamic>?;
      if (bankDetails != null) {
        setState(() {
          _accNameCtrl.text = bankDetails['accountName'] ?? '';
          _accNumberCtrl.text = bankDetails['accountNumber'] ?? '';
          _ifscCtrl.text = bankDetails['ifscCode'] ?? '';
        });
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _accNameCtrl.dispose();
    _accNumberCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBankDetails() async {
    setState(() => _saving = true);
    final success = await _api.updateBankDetails(
      accountName: _accNameCtrl.text.trim(),
      accountNumber: _accNumberCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bank details updated successfully!'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update bank details'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Bank Details'),
      ),
      body: _loading
        ? Center(child: CircularProgressIndicator(color: AppColors.amber))
        : SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: AppColors.amber, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Provide your bank details to receive your earnings payouts.',
                      style: TextStyle(color: AppColors.amber, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            SectionLabel('Account Holder Name'),
            TextField(
              controller: _accNameCtrl,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter account holder name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            SizedBox(height: 20),
            SectionLabel('Account Number'),
            TextField(
              controller: _accNumberCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter your bank account number',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            SizedBox(height: 20),
            SectionLabel('IFSC Code'),
            TextField(
              controller: _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter IFSC code',
                prefixIcon: Icon(Icons.domain_rounded),
              ),
            ),
            SizedBox(height: 40),
            PrimaryButton(
              label: 'Save Bank Details',
              isLoading: _saving,
              onTap: _saveBankDetails,
            ),
          ],
        ),
      ),
    );
  }
}
