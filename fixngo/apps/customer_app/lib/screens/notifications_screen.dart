import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final profile = auth.userProfile ?? {};
    _api.setToken(profile['token'] as String?);
    try {
      final res = await _api.get('/api/notifications/mine');
      setState(() {
        _notifications = (res['data'] as List<dynamic>?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id, int index) async {
    try {
      await _api.patch('/api/notifications/mine/$id/read', {});
      setState(() {
        final n = Map<String, dynamic>.from(_notifications[index] as Map);
        n['read'] = true;
        _notifications[index] = n;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.patch('/api/notifications/mine/read-all', {});
      setState(() {
        _notifications = _notifications.map((n) {
          final m = Map<String, dynamic>.from(n as Map);
          m['read'] = true;
          return m;
        }).toList();
      });
    } catch (_) {}
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'technician':
        return Icons.engineering_rounded;
      default:
        return Icons.notifications_rounded;
    }
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
        title: Text('Notifications',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        actions: [
          if (_notifications.any(
              (n) => (n as Map)['read'] != true))
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brandBlue,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n = _notifications[i] as Map<String, dynamic>;
                      final read = n['read'] == true;
                      final type = (n['type'] as String?) ?? '';
                      return GestureDetector(
                        onTap: () {
                          if (!read) _markRead(n['_id'] as String, i);
                        },
                        child: Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: read ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: read
                                  ? Theme.of(context).colorScheme.outline
                                  : AppColors.brandBlue.withValues(alpha: 0.3),
                            ),
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
                                child: Icon(_iconFor(type),
                                    color: AppColors.brandBlue, size: 20),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (n['title'] as String?) ?? 'Notification',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (n['message'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          n['message'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
            child: Icon(Icons.notifications_off_rounded,
                size: 36, color: AppColors.textMuted),
          ),
          SizedBox(height: 16),
          Text('No notifications yet',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
