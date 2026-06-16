import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service_new.dart';
import 'utils/mqtt_service.dart';
import 'widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _api = ApiService();
  List<dynamic> _jobs = [];
  bool _loading = true;
  bool _isOnline = false;
  int _currentTab = 0;
  Map<String, dynamic>? _dashboard;

  Timer? _countdownTimer;
  int _countdown = 20;
  dynamic _incomingJob;
  late AnimationController _popupCtrl;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    MqttService().connect();
    
    MqttService().onNotification((data) {
      if (data['type'] == 'kyc_approved') {
        _fetchAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['title'] ?? 'KYC Approved'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      } else if (data['type'] == 'new_order_offer' || data['type'] == 'order_assigned' || data['type'] == 'new_order_broadcast') {
        _fetchAll();
      }
    });

    _popupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetchAll();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _popupCtrl.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    final jobs = await _api.getAvailableJobs();
    final dash = await _api.getDashboard();
    if (!mounted) return;
    
    if (dash != null && dash['_id'] != null) {
      MqttService().subscribeToUserNotifications(dash['_id']);
    }

    setState(() {
      _jobs = jobs;
      _dashboard = dash;
      _loading = false;
    });
    if (_jobs.isNotEmpty && _isOnline) {
      _showIncomingJob(_jobs[0]);
    }
  }

  void _showIncomingJob(dynamic job) {
    setState(() {
      _incomingJob = job;
      _countdown = 20;
    });
    _popupCtrl.forward(from: 0);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
        _dismissJobRequest();
      } else if (mounted) {
        setState(() => _countdown--);
      }
    });
  }

  void _dismissJobRequest() {
    _countdownTimer?.cancel();
    _popupCtrl.reverse().then((_) {
      if (mounted) setState(() => _incomingJob = null);
    });
  }

  void _acceptJob(String id) async {
    _dismissJobRequest();
    final success = await _api.acceptJob(id);
    if (!mounted) return;
    if (success) {
      final job = _jobs.firstWhere(
        (item) => item['_id'] == id,
        orElse: () => {'_id': id},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job accepted!'), backgroundColor: AppColors.green),
      );
      Navigator.pushNamed(context, '/job_detail', arguments: job);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept job'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _toggleOnline(bool val) async {
    if (val) {
      final verificationStatus = _dashboard?['verification']?['status'] ?? 'unverified';
      if (verificationStatus != 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete KYC process to earn'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isOnline = val);
    if (!val) {
      _positionStream?.cancel();
      _positionStream = null;
      await _api.updateLocation(0, 0, false);
      return;
    }
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isOnline = false);
        return;
      }

      // First time immediate location fetch
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _api.updateLocation(pos.latitude, pos.longitude, true);
      
      // Setup stream to broadcast continuously
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update when moved 5 meters
      );
      
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
        if (position != null && _isOnline) {
          _api.updateLocation(position.latitude, position.longitude, true);
        }
      });

      if (mounted) {
        await _fetchAll();
      }
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStats(),
                SizedBox(height: 8),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          if (_incomingJob != null) _buildJobRequestOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isOnline ? AppColors.green : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Icon(Icons.person_rounded, color: AppColors.grey, size: 24),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dashboard?['name'] ?? 'Technician',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOnline ? AppColors.green : AppColors.grey,
                      ),
                    ),
                    Text(
                      _isOnline ? 'Online • Accepting jobs' : 'Offline',
                      style: TextStyle(
                        color: _isOnline ? AppColors.green : AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 20),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/my_jobs'),
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Icon(Icons.assignment_outlined, color: AppColors.textPrimary, size: 20),
            ),
          ),
          GestureDetector(
            onTap: () => _toggleOnline(!_isOnline),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 30,
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _isOnline ? AppColors.green : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isOnline ? AppColors.green : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: _isOnline ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final today = _dashboard?['todayEarnings'] ?? 0;
    final jobs = _dashboard?['jobsDone'] ?? 0;
    final rating = _dashboard?['rating'] ?? '4.8';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statCard('₹$today', "Today's Earn", Icons.currency_rupee_rounded, AppColors.green),
          SizedBox(width: 10),
          _statCard('$jobs', 'Jobs Done', Icons.check_circle_rounded, AppColors.orange),
          SizedBox(width: 10),
          _statCard('$rating ★', 'Rating', Icons.star_rounded, AppColors.yellow),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: AppColors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentTab == 0) return _buildJobsTab();
    if (_currentTab == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/my_jobs');
      });
      setState(() => _currentTab = 0);
    }
    if (_currentTab == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/earnings');
      });
      setState(() => _currentTab = 0);
    }
    if (_currentTab == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/profile');
      });
      setState(() => _currentTab = 0);
    }
    return _buildJobsTab();
  }

  Widget _buildJobsTab() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 2));
    }

    // Check KYC status from dashboard
    final verificationStatus = _dashboard?['verification']?['status'] ?? 'unverified';
    final isKycVerified = verificationStatus == 'verified';

    return RefreshIndicator(
      color: AppColors.electricBlue,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onRefresh: _fetchAll,
      child: CustomScrollView(
        slivers: [
          // KYC Pending Banner
          if (!isKycVerified)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/kyc').then((_) => _fetchAll()),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: verificationStatus == 'pending'
                          ? AppColors.orange.withValues(alpha: 0.08)
                          : AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: verificationStatus == 'pending'
                            ? AppColors.orange.withValues(alpha: 0.4)
                            : AppColors.red.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          verificationStatus == 'pending'
                              ? Icons.hourglass_top_rounded
                              : Icons.warning_amber_rounded,
                          color: verificationStatus == 'pending' ? AppColors.orange : AppColors.red,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                verificationStatus == 'pending'
                                    ? 'KYC Under Review'
                                    : 'Complete KYC to Receive Orders',
                                style: TextStyle(
                                  color: verificationStatus == 'pending' ? AppColors.orange : AppColors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                verificationStatus == 'pending'
                                    ? 'Your documents are being verified. You\'ll be notified soon.'
                                    : 'Tap here to upload your Aadhaar and get verified.',
                                style: TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (verificationStatus != 'pending')
                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.grey, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Available Jobs',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_jobs.length}',
                      style: TextStyle(color: AppColors.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_isOnline)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
                    ),
                  child: Row(
                    children: [
                      Icon(Icons.power_off_rounded, color: AppColors.yellow, size: 20),
                      SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Go Online to receive job requests',
                          style: TextStyle(color: AppColors.yellow, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_jobs.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, color: AppColors.grey, size: 80),
                  SizedBox(height: 16),
                  Text(
                    'No jobs nearby',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pull to refresh or wait for new requests',
                    style: TextStyle(color: AppColors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildJobCard(_jobs[i]),
                  childCount: _jobs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(dynamic job) {
    final serviceType = job['serviceType'] ?? 'General Repair';
    final dist = job['distance'] != null ? '${(job['distance'] as num).toStringAsFixed(1)} km' : 'Nearby';
    final price = job['estimatedPrice'] ?? 0;
    final address = job['location']?['address'] ?? 'Customer Location';

    return GestureDetector(
      onTap: () => _showIncomingJob(job),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build_rounded, color: AppColors.electricBlue, size: 22),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        address,
                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹$price',
                      style: TextStyle(color: AppColors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(dist, style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outline, height: 1),
            SizedBox(height: 12),
            Row(
              children: [
                _jobMeta(Icons.smartphone_rounded, job['deviceModel'] ?? 'Device'),
                SizedBox(width: 16),
                _jobMeta(Icons.schedule_rounded, job['estimatedTime'] ?? '45 min'),
                const Spacer(),
                GestureDetector(
                  onTap: () => _acceptJob(job['_id']),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: AppShadows.glow,
                    ),
                    child: Text(
                      'Accept',
                      style: TextStyle(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.grey, size: 14),
        SizedBox(width: 4),
        Text(text, style: TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildJobRequestOverlay() {
    return AnimatedBuilder(
      animation: _popupCtrl,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Opacity(
            opacity: _popupCtrl.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.85 + (0.15 * _popupCtrl.value),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: _buildJobRequestCard(),
    );
  }

  Widget _buildJobRequestCard() {
    if (_incomingJob == null) return SizedBox();
    final job = _incomingJob!;
    final serviceType = job['serviceType'] ?? 'Screen Replacement';
    final price = job['estimatedPrice'] ?? 499;
    final dist = job['distance'] != null ? '${(job['distance'] as num).toStringAsFixed(1)} km' : '1.2 km';
    final address = job['location']?['address'] ?? '12, MG Road, Hyderabad';

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.5), width: 1.5),
        boxShadow: AppShadows.glow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            child: LinearProgressIndicator(
              value: _countdown / 20,
              backgroundColor: Theme.of(context).colorScheme.outline,
              color: _countdown > 8 ? AppColors.electricBlue : AppColors.red,
              minHeight: 4,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_rounded, color: AppColors.electricBlue, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'NEW JOB REQUEST',
                            style: TextStyle(
                              color: AppColors.electricBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _countdown > 8 ? AppColors.green : AppColors.red,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_countdown',
                          style: TextStyle(
                            color: _countdown > 8 ? AppColors.green : AppColors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  serviceType,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.grey, size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(color: AppColors.grey, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _infoChip(Icons.route_rounded, dist),
                    SizedBox(width: 10),
                    _infoChip(Icons.schedule_rounded, '~45 min'),
                    const Spacer(),
                    Text(
                      '₹$price',
                      style: TextStyle(color: AppColors.green,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _dismissJobRequest,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Center(
                            child: Text(
                              'Decline',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _acceptJob(job['_id']),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppShadows.green,
                          ),
                          child: Center(
                            child: Text(
                              'Accept Job',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.grey, size: 13),
          SizedBox(width: 4),
          Text(text, style: TextStyle(color: AppColors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
      _NavItem(Icons.assignment_rounded, Icons.assignment_outlined, 'My Jobs'),
      _NavItem(Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Earnings'),
      _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = _currentTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (i == 1) {
                      Navigator.pushNamed(context, '/my_jobs');
                    } else if (i == 2) {
                      Navigator.pushNamed(context, '/earnings');
                    } else if (i == 3) {
                      Navigator.pushNamed(context, '/profile');
                    } else {
                      setState(() => _currentTab = i);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        color: active ? AppColors.amber : AppColors.grey,
                        size: 24,
                      ),
                      SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: active ? AppColors.amber : AppColors.grey,
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;

  _NavItem(this.activeIcon, this.icon, this.label);
}
