import 'package:flutter/material.dart';
import 'widgets/common_widgets.dart';

class TermsOfServiceScreen extends StatelessWidget {
  TermsOfServiceScreen({super.key});

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
        title: Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: October 2023',
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            SizedBox(height: 24),
            _buildSection('1. Acceptance of Terms', 'By accessing and using our application, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using these particular services, you shall be subject to any posted guidelines or rules applicable to such services.'),
            _buildSection('2. Description of Service', 'Fix-N-Go provides an online platform that connects independent service professionals with individuals seeking repair services. Fix-N-Go does not directly provide repair services and is not an employer of any service professional.'),
            _buildSection('3. User Conduct', 'You agree to use the service only for lawful purposes. You agree not to take any action that might compromise the security of the service, render the service inaccessible to others or otherwise cause damage to the service or the Content.'),
            _buildSection('4. Payment Terms', 'Technicians are paid for completed jobs according to the rates agreed upon at the time of acceptance. Payments are processed on a weekly basis. Fix-N-Go reserves the right to withhold payment if fraud or breach of terms is suspected.'),
            _buildSection('5. Termination', 'We may terminate or suspend access to our Service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(color: AppColors.grey, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
