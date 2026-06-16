import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';

class ApiService {
  static String get apiBaseUrl {
    return ApiConfig.apiBaseUrl;
  }

  static String imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ApiConfig.baseUrl}$path';
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
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': 'technician',
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveToken(data['token']);
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection failed');
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

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/tech/profile'), headers: await _getHeaders());
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

  Future<bool> updateProfile({String? name, String? phone, String? email}) async {
    try {
      final res = await http.patch(
        Uri.parse('$apiBaseUrl/auth/profile'),
        headers: await _getHeaders(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBankDetails({required String accountName, required String accountNumber, required String ifscCode}) async {
    try {
      final res = await http.patch(
        Uri.parse('$apiBaseUrl/tech/profile'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'bankDetails': {
            'accountName': accountName,
            'accountNumber': accountNumber,
            'ifscCode': ifscCode,
          }
        }),
      );
      return res.statusCode == 200;
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

  Future<bool> updateChecklist(String orderId, List<Map<String, dynamic>> checklist) async {
    try {
      final res = await http.patch(
        Uri.parse('$apiBaseUrl/tech/jobs/$orderId/checklist'),
        headers: await _getHeaders(),
        body: jsonEncode({'checklist': checklist}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeJob(String orderId, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBaseUrl/orders/$orderId/complete'),
        headers: await _getHeaders(),
        body: jsonEncode({'otp': otp}),
      );
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
          ...? (orderId == null ? null : {'orderId': orderId}),
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
          'email': email.trim().toLowerCase(),
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
      } else {
        try {
          final errorData = jsonDecode(res.body);
          throw Exception(errorData['message'] ?? 'Registration failed');
        } catch (e) {
          throw Exception('Registration failed (Code ${res.statusCode})');
        }
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
    required XFile frontFile,
    required XFile backFile,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final request = http.MultipartRequest('PUT', Uri.parse('$apiBaseUrl/technician-profile/profile/kyc'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['aadharNumber'] = aadhaarNumber;

      // Use fromBytes for cross-platform compatibility (works on Web + Mobile)
      final frontBytes = await frontFile.readAsBytes();
      final backBytes = await backFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('aadharFront', frontBytes, filename: frontFile.name));
      request.files.add(http.MultipartFile.fromBytes('aadharBack', backBytes, filename: backFile.name));

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

  Future<bool> updateOrderStatus(String orderId, String status, {String? otp}) async {
    if (status == 'completed' && otp != null) {
      return completeJob(orderId, otp);
    } else if (status == 'in_progress' || status == 'started') {
      return startJob(orderId);
    }
    return false;
  }
}
