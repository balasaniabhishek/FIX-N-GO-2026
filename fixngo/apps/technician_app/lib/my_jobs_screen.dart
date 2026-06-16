import 'package:flutter/material.dart';
import 'api_service_new.dart';
import 'theme/app_theme.dart';

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  final _apiService = ApiService();
  List<dynamic> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _loading = true);
    final jobs = await _apiService.getMyJobs();
    setState(() {
      _jobs = jobs;
      _loading = false;
    });
  }

  void _markCompleted(String id) async {
    bool success = await _apiService.updateOrderStatus(id, 'completed');
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job marked as completed!')));
      _fetchJobs();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete job.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Active Jobs'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _loading 
        ? Center(child: CircularProgressIndicator())
        : _jobs.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text('You have no active jobs.', style: TextStyle(color: AppColors.grey, fontSize: 16)),
                ],
              )
            )
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                final isCompleted = job['status'] == 'completed';
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/job_detail',
                      arguments: job,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    title: Text(job['serviceType'] ?? 'General Repair', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('Address: ${job['location']?['address'] ?? 'N/A'}'),
                        Text('Est. Price: \$${job['estimatedPrice'] ?? '?'}'),
                        Text('Status: ${job['status']}'),
                      ]
                    ),
                    trailing: isCompleted 
                        ? Icon(Icons.check, color: AppColors.green, size: 32)
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white),
                            onPressed: () => _markCompleted(job['_id']),
                            child: Text('COMPLETE'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
