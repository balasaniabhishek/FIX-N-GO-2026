import 'package:flutter/material.dart';
import 'widgets/common_widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _newJobs = true;
  bool _jobUpdates = true;
  bool _earnings = false;
  bool _promotions = false;

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
        title: Text('Notification Settings'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('Job Notifications'),
            _buildToggle(
              'New Job Requests',
              'Get notified when a new job matches your skills.',
              _newJobs,
              (v) => setState(() => _newJobs = v),
            ),
            SizedBox(height: 16),
            _buildToggle(
              'Job Updates',
              'Notifications about status changes or customer messages.',
              _jobUpdates,
              (v) => setState(() => _jobUpdates = v),
            ),
            SizedBox(height: 32),
            SectionLabel('Account & Earnings'),
            _buildToggle(
              'Earnings & Payouts',
              'Get notified when payments are processed or deposited.',
              _earnings,
              (v) => setState(() => _earnings = v),
            ),
            SizedBox(height: 16),
            _buildToggle(
              'Promotions & News',
              'Updates about Fix-N-Go features and special bonuses.',
              _promotions,
              (v) => setState(() => _promotions = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.grey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.green,
            activeTrackColor: AppColors.green.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.grey,
            inactiveTrackColor: Theme.of(context).colorScheme.surface,
          ),
        ],
      ),
    );
  }
}
