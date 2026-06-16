import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service_new.dart';
import 'widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  int _step = 0;
  XFile? _aadhaarFront;
  XFile? _aadhaarBack;

  final List<String> _allSkills = [
    'Screen Replacement',
    'Battery Replacement',
    'Charging Port Fix',
    'Water Damage Repair',
    'Speaker/Mic Fix',
    'Camera Repair',
    'Software Fix',
    'Screen Guard Installation',
    'Data Recovery',
    'Back Cover Fix',
  ];
  final Set<String> _selectedSkills = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAadhaarImage(bool front) async {
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

  void _register() async {
    if (_selectedSkills.isEmpty) {
      _showSnack('Select at least one skill', isError: true);
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack('Phone number is required', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await _api.registerTechnician(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        phone: _phoneCtrl.text.trim(),
        skills: _selectedSkills.toList(),
        aadhaarNumber: '',
        aadhaarFrontPath: '',
        aadhaarBackPath: '',
      );

      if (!mounted) return;
      setState(() => _loading = false);

      // TODO: Re-enable KYC upload after testing
      // KYC upload temporarily disabled

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);

      _showSnack('Registration submitted! Awaiting approval.');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack(e.toString(), isError: true);
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_step == 0) {
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        setState(() => _step = 0);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0 ? 'Personal Info' : 'Your Skills',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Step ${_step + 1} of 2',
                          style: TextStyle(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _step >= 1 ? AppColors.amber : Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _step == 0 ? _buildStep0() : _buildStep1(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: PrimaryButton(
                label: _step == 0 ? 'Continue' : 'Submit Registration',
                isLoading: _loading,
                onTap: () {
                  if (_step == 0) {
                    if (_nameCtrl.text.isEmpty ||
                        _emailCtrl.text.isEmpty ||
                        _passCtrl.text.isEmpty) {
                      _showSnack('Please fill all fields', isError: true);
                      return;
                    }
                    setState(() => _step = 1);
                  } else {
                    _register();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Full Name'),
        TextField(
          controller: _nameCtrl,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        SizedBox(height: 16),
        const SectionLabel('Phone Number'),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        SizedBox(height: 16),
        const SectionLabel('Email'),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'your@email.com',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        SizedBox(height: 16),
        const SectionLabel('Password'),
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.grey,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        // TODO: Re-enable Aadhaar verification section after testing
        // Aadhaar section temporarily hidden
        SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text.rich(
              TextSpan(
                text: 'Already registered? ',
                style: TextStyle(color: AppColors.grey, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your repair specializations',
          style: TextStyle(color: AppColors.grey, fontSize: 14),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allSkills.map((skill) {
            final selected = _selectedSkills.contains(skill);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedSkills.remove(skill);
                  } else {
                    _selectedSkills.add(skill);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.amber.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? AppColors.amber : Theme.of(context).colorScheme.outline,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected)
                      Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 16),
                      ),
                    Text(
                      skill,
                      style: TextStyle(
                        color: selected ? AppColors.amber : AppColors.greyLight,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _uploadTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? fileName,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                    color: AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.amber, size: 18),
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
              fileName ?? 'Tap to upload',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fileName == null ? AppColors.grey : AppColors.green,
                fontSize: 12,
                fontWeight: fileName == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}