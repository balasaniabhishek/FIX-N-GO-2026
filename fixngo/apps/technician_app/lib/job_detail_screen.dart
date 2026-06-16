import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service_new.dart';
import 'utils/mqtt_service.dart';
import 'widgets/common_widgets.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _job;
  bool _loading = false;
  int _currentStep = 0;
  final TextEditingController _otpController = TextEditingController();

  final List<String> _steps = [
    'Navigate to Customer',
    'Start Repair',
    'Complete Checklist',
    'Collect Payment',
  ];

  final List<bool> _checklist = [false, false, false, false, false];
  final List<String> _checklistItems = [
    'Inspect device condition',
    'Diagnose issue',
    'Replace/repair component',
    'Test device functionality',
    'Apply screen guard (if applicable)',
  ];

  StreamSubscription<Position>? _jobLocationStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && _job == null) {
      _job = args;
      _initNavigationStream();
    }
  }

  void _initNavigationStream() {
    if (_currentStep == 0 && _job?['_id'] != null) {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, 
      );
      _jobLocationStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        if (!mounted) return;
        MqttService().emitLocationUpdate(_job!['_id'], position.latitude, position.longitude);
      });
    }
  }

  @override
  void dispose() {
    _jobLocationStream?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _advanceStep() async {
    if (_currentStep == 0) {
      // Arrived at destination
      _jobLocationStream?.cancel();
    }

    if (_currentStep == 1) {
      setState(() => _loading = true);
      if (_job?['_id'] != null) {
        await _api.startJob(_job!['_id']);
      }
      if (!mounted) return;
      setState(() => _loading = false);
    }

    if (_currentStep == 2) {
      if (_checklist.contains(false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all checklist items first')),
        );
        return;
      }
      
      setState(() => _loading = true);
      if (_job?['_id'] != null) {
        final checklistData = _checklistItems.asMap().entries.map((e) => {
          'key': 'item_${e.key}',
          'label': e.value,
          'done': _checklist[e.key],
        }).toList();
        await _api.updateChecklist(_job!['_id'], checklistData);
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _currentStep++;
      });
      return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      return;
    }

    if (_currentStep == 3) {
      if (_otpController.text.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter the 4-digit PIN from the customer')));
        return;
      }
      setState(() => _loading = true);
      if (_job?['_id'] != null) {
        final success = await _api.completeJob(_job!['_id'], _otpController.text);
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job Completed Successfully!')));
          Navigator.pop(context);
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete job. Invalid PIN?')));
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceType = _job?['serviceType'] ?? 'Screen Replacement';
    final customerName = _job?['customerName'] ?? 'Customer';
    final phone = _job?['customerPhone'] ?? 'Unknown';
    final address = _job?['location']?['address'] ?? '12 MG Road, Hyderabad';
    final price = _job?['estimatedPrice'] ?? 499;
    final device = _job?['deviceModel'] ?? 'Samsung Galaxy S21';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceType,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        StatusBadge(status: _job?['status'] ?? 'accepted'),
                      ],
                    ),
                  ),
                  Text(
                    '₹$price',
                    style: TextStyle(color: AppColors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: _steps.asMap().entries.map((e) {
                  final i = e.key;
                  final done = i < _currentStep;
                  final active = i == _currentStep;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: done
                                      ? AppColors.green
                                      : active
                                          ? AppColors.amber
                                          : AppColors.card,
                                  border: Border.all(
                                    color: done
                                        ? AppColors.green
                                        : active
                                            ? AppColors.amber
                                            : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  done ? Icons.check_rounded : Icons.circle,
                                  size: done ? 16 : 8,
                                  color: done || active ? Colors.white : AppColors.border,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                e.value,
                                style: TextStyle(
                                  color: active ? AppColors.textPrimary : AppColors.grey,
                                  fontSize: 8,
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        if (i < _steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              margin: EdgeInsets.only(bottom: 24),
                              color: i < _currentStep ? AppColors.green : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded, color: AppColors.amber, size: 26),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  device,
                                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, color: AppColors.grey, size: 13),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _actionBtn(Icons.call_rounded, AppColors.green, () {}),
                              SizedBox(width: 8),
                              _actionBtn(Icons.navigation_rounded, AppColors.orange, () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_currentStep == 0) _buildNavigateContent(address),
                    if (_currentStep == 1) _buildStartContent(serviceType, device, phone),
                    if (_currentStep == 2) _buildChecklist(),
                    if (_currentStep == 3) _buildPaymentPreview(price),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: PrimaryButton(
                label: _currentStep == 0
                    ? 'I\'ve Arrived'
                    : _currentStep == 1
                        ? 'Start Repair'
                        : _currentStep == 2
                            ? 'Repair Complete'
                            : 'Collect Payment',
                isLoading: _loading,
                onTap: _advanceStep,
                color: _currentStep >= 3 ? AppColors.green : null,
                icon: _currentStep == 0
                    ? Icons.check_rounded
                    : _currentStep == 1
                        ? Icons.build_rounded
                        : _currentStep == 2
                            ? Icons.done_all_rounded
                            : Icons.payments_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildNavigateContent(String address) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map_rounded, color: AppColors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Navigation',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    CustomPaint(painter: _MapGridPainter(), size: Size.infinite),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.amber,
                            ),
                            child: Icon(Icons.my_location_rounded, color: Colors.white, size: 24),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'Tap to open Maps',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.amber, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartContent(String service, String device, String phone) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Job Details'),
          _detailRow('Service', service),
          _detailRow('Device', device),
          _detailRow('Phone', phone),
          _detailRow('Issues', _job?['issueDescription'] ?? 'Cracked screen'),
          _detailRow('Time Slot', _job?['timeSlot'] ?? 'ASAP'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: AppColors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: AppColors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Service Checklist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Complete all steps before proceeding',
            style: TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          SizedBox(height: 16),
          ...List.generate(_checklistItems.length, (i) {
            return GestureDetector(
              onTap: () => setState(() => _checklist[i] = !_checklist[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _checklist[i] ? AppColors.green.withValues(alpha: 0.08) : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _checklist[i] ? AppColors.green.withValues(alpha: 0.4) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _checklist[i] ? AppColors.green : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _checklist[i] ? AppColors.green : AppColors.grey,
                          width: 1.5,
                        ),
                      ),
                      child: _checklist[i]
                          ? Icon(Icons.check_rounded, color: Colors.white, size: 14)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Text(
                      _checklistItems[i],
                      style: TextStyle(
                        color: _checklist[i] ? AppColors.green : Colors.white,
                        fontSize: 14,
                        decoration: _checklist[i] ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentPreview(dynamic price) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppColors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _billRow('Service Charge', '₹${(price * 0.8).toInt()}'),
          _billRow('Parts & Material', '₹${(price * 0.2).toInt()}'),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹$price',
                style: TextStyle(color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Ask the customer for the 4-digit Completion PIN displayed on their screen to mark this job as complete and request payment.',
            style: TextStyle(color: AppColors.amber, fontSize: 13, height: 1.4),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '----',
              hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.5), letterSpacing: 8),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}