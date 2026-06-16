import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service_new.dart';
import 'widgets/common_widgets.dart';

class KycScreen extends StatefulWidget {
  KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  final _aadhaarCtrl = TextEditingController();
  XFile? _aadhaarFront;
  XFile? _aadhaarBack;
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool front) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null || !mounted) return;
    setState(() {
      if (front) {
        _aadhaarFront = image;
      } else {
        _aadhaarBack = image;
      }
    });
  }

  Future<void> _submitKyc() async {
    if (_aadhaarCtrl.text.trim().length < 12) {
      _showSnack('Enter a valid 12-digit Aadhaar number', isError: true);
      return;
    }
    if (_aadhaarFront == null || _aadhaarBack == null) {
      _showSnack('Upload both front and back of your Aadhaar card', isError: true);
      return;
    }

    setState(() => _loading = true);

    final result = await _api.uploadTechnicianKyc(
      aadhaarNumber: _aadhaarCtrl.text.trim(),
      frontFile: _aadhaarFront!,
      backFile: _aadhaarBack!,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result != null) {
      setState(() => _submitted = true);
    } else {
      _showSnack('KYC upload failed. Please try again.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        title: Text('KYC Verification'),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: AppColors.green, size: 44),
            ),
            SizedBox(height: 24),
            Text(
              'KYC Submitted!',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 12),
            Text(
              'Your Aadhaar documents have been submitted for review. You\'ll be able to receive orders once our team verifies your KYC (usually within 24 hours).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 32),
            PrimaryButton(
              label: 'Go to Home',
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.yellow, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'KYC verification is required before you can start receiving repair orders.',
                    style: TextStyle(color: AppColors.yellow, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28),
          SectionLabel('Aadhaar Number'),
          TextField(
            controller: _aadhaarCtrl,
            keyboardType: TextInputType.number,
            maxLength: 12,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '12-digit Aadhaar number',
              prefixIcon: Icon(Icons.badge_outlined),
              counterText: '',
            ),
          ),
          SizedBox(height: 24),
          SectionLabel('Aadhaar Card Images'),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _uploadTile(
                  title: 'Front Side',
                  file: _aadhaarFront,
                  icon: Icons.image_outlined,
                  onTap: () => _pickImage(true),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _uploadTile(
                  title: 'Back Side',
                  file: _aadhaarBack,
                  icon: Icons.document_scanner_outlined,
                  onTap: () => _pickImage(false),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Aadhaar details are used only for identity verification and are kept secure.',
            style: TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          SizedBox(height: 36),
          PrimaryButton(
            label: 'Submit KYC',
            isLoading: _loading,
            onTap: _submitKyc,
          ),
        ],
      ),
    );
  }

  Widget _uploadTile({
    required String title,
    required XFile? file,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final uploaded = file != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded ? AppColors.green.withValues(alpha: 0.07) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? AppColors.green.withValues(alpha: 0.5) : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (uploaded ? AppColors.green : AppColors.amber).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    uploaded ? Icons.check_circle_rounded : icon,
                    color: uploaded ? AppColors.green : AppColors.amber,
                    size: 18,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              file?.name ?? 'Tap to upload',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: uploaded ? AppColors.green : AppColors.grey,
                fontSize: 12,
                fontWeight: uploaded ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
