import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get serverOrigin {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:5000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  static String get baseUrl {
    return serverOrigin;
  }

  static String get apiBaseUrl {
    return '$serverOrigin/api';
  }

  static String imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$serverOrigin$path';
  }
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': 'technician'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Use the new standardized /api/tech endpoints
  Future<List<dynamic>> getIncomingOffers() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/tech/jobs/offers'), headers: await _getHeaders());
      return jsonDecode(res.body);
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAvailableJobs() async {
    return getIncomingOffers();
  }

  Future<bool> acceptJob(String orderId) async {
    try {
      final res = await http.post(Uri.parse('$apiBaseUrl/tech/jobs/$orderId/accept'), headers: await _getHeaders());
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/tech/dashboard'), headers: await _getHeaders());
      return jsonDecode(res.body);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStats() async {
    final dashboard = await getDashboard();
    if (dashboard == null) return null;
    return {
      'walletBalance': dashboard['walletBalance'],
      'totalEarnings': (dashboard['walletBalance'] ?? 0) + (dashboard['pendingEarnings'] ?? 0),
      'completedOrdersCount': dashboard['jobsDone'],
    };
  }

  Future<bool> updateLocation(double lat, double lng, [bool? isOnline]) async {
    try {
      if (isOnline != null) {
        await setOnline(isOnline);
      }
      final res = await http.patch(
        Uri.parse('$apiBaseUrl/tech/location'), 
        headers: await _getHeaders(),
        body: jsonEncode({'lat': lat, 'lng': lng})
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setOnline(bool isOnline) async {
    try {
      final res = await http.patch(
        Uri.parse('$apiBaseUrl/tech/availability'), 
        headers: await _getHeaders(),
        body: jsonEncode({'isOnline': isOnline})
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getWallet() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/tech/wallet'), headers: await _getHeaders());
      return jsonDecode(res.body);
    } catch (e) {
      return null;
    }
  }

  Future<bool> requestWithdrawal(int amount, String bankAccount) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/payments/withdraw'), 
        headers: await _getHeaders(),
        body: jsonEncode({'amount': amount, 'bankAccount': bankAccount})
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getMyJobs() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/tech/jobs?status=active'), headers: await _getHeaders());
      return jsonDecode(res.body);
    } catch (e) {
      return [];
    }
  }

  Future<bool> startJob(String orderId) async {
    try {
      final res = await http.post(Uri.parse('$apiBaseUrl/tech/jobs/$orderId/start'), headers: await _getHeaders());
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeJob(String orderId) async {
    try {
      final res = await http.post(Uri.parse('$apiBaseUrl/tech/jobs/$orderId/complete'), headers: await _getHeaders());
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getMyNotifications() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/notifications/mine'), headers: await _getHeaders());
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data'] as List<dynamic>?) ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      final res = await http.patch(Uri.parse('$apiBaseUrl/notifications/mine/$id/read'), headers: await _getHeaders());
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      final res = await http.patch(Uri.parse('$apiBaseUrl/notifications/mine/read-all'), headers: await _getHeaders());
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getMySupportTickets() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/support/mine'), headers: await _getHeaders());
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data'] as List<dynamic>?) ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createSupportTicket({
    required String subject,
    required String message,
    String category = 'general',
    String priority = 'medium',
    String? orderId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/support'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'subject': subject,
          'message': message,
          'category': category,
          'priority': priority,
          'orderId': orderId,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> registerTechnician({
    required String name,
    required String email,
    required String password,
    required String phone,
    required List<String> skills,
    required String aadhaarNumber,
    required String aadhaarFrontPath,
    required String aadhaarBackPath,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'technician',
          'specialization': skills,
          'aadhaarNumber': aadhaarNumber,
          'aadhaarFront': aadhaarFrontPath,
          'aadhaarBack': aadhaarBackPath,
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await saveToken(data['token'] as String);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadProfilePhoto(String filePath) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final request = http.MultipartRequest('PUT', Uri.parse('$apiBaseUrl/technician-profile/profile/photo'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      final streamed = await request.send();
      return streamed.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadTechnicianKyc({
    required String aadhaarNumber,
    required String frontPath,
    required String backPath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final request = http.MultipartRequest('PUT', Uri.parse('$apiBaseUrl/technician-profile/profile/kyc'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['aadharNumber'] = aadhaarNumber;
      request.files.add(await http.MultipartFile.fromPath('aadharFront', frontPath));
      request.files.add(await http.MultipartFile.fromPath('aadharBack', backPath));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateTechnicianProfile({
    List<String>? specialization,
    String? experience,
    String? emoji,
    String? profilePhoto,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (specialization != null) body['specialization'] = specialization;
      if (experience != null) body['experience'] = experience;
      if (emoji != null) body['emoji'] = emoji;
      if (profilePhoto != null) body['profilePhoto'] = profilePhoto;

      final res = await http.put(
        Uri.parse('$apiBaseUrl/technician-profile/profile/update'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    if (status == 'completed') {
      return completeJob(orderId);
    } else if (status == 'in_progress' || status == 'started') {
      return startJob(orderId);
    }
    return false;
  }
}
