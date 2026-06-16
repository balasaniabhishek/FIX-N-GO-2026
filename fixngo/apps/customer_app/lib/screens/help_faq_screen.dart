import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I book a repair?',
      'a': 'From the home screen, tap "Mobile Repair" or "Screen Guard", '
          'select your device, choose the issue, and confirm your booking. '
          'A technician will be assigned automatically.',
    },
    {
      'q': 'How long does a typical repair take?',
      'a': 'Most repairs are completed within 30–60 minutes at your doorstep. '
          'Complex repairs like motherboard issues may take longer.',
    },
    {
      'q': 'What payment methods are accepted?',
      'a': 'We currently accept Cash on Delivery and UPI. '
          'Online payment via Stripe is coming soon.',
    },
    {
      'q': 'Can I cancel my order?',
      'a': 'Yes, you can cancel an active order from the Order Details screen. '
          'If a technician has already started work, cancellation may not be available.',
    },
    {
      'q': 'How do I track my technician?',
      'a': 'Once a technician is assigned, tap "Track Technician" on your '
          'active order to see their live location on the map.',
    },
    {
      'q': 'What if I\'m not satisfied with the repair?',
      'a': 'Contact our support team via "Chat with Support" in your profile. '
          'We offer a service guarantee and will resolve any issues promptly.',
    },
    {
      'q': 'How are technicians verified?',
      'a': 'All technicians undergo KYC verification including Aadhaar '
          'verification, background checks, and skill assessments before '
          'they can accept jobs on the platform.',
    },
    {
      'q': 'Do you provide a warranty on repairs?',
      'a': 'Yes, all repairs come with a 30-day warranty covering the same '
          'issue. If the problem recurs, we\'ll fix it free of charge.',
    },
  ];

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
        title: Text('Help & FAQ',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => SizedBox(height: 10),
        itemBuilder: (_, i) => _FaqTile(
          question: _faqs[i]['q']!,
          answer: _faqs[i]['a']!,
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded
                ? AppColors.brandBlue.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.question,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            if (_expanded) ...[
              SizedBox(height: 10),
              Container(height: 1, color: Theme.of(context).colorScheme.outline),
              SizedBox(height: 10),
              Text(widget.answer,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
