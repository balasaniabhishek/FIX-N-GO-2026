import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PaymentService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<void> _ensureToken() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      _api.setToken(token);
    }
  }

  /// Create a payment intent for an order
  Future<Map<String, dynamic>> createPaymentIntent(String orderId, num amount) async {
    await _ensureToken();
    final res = await _api.post('/api/payments/create-intent', {
      'orderId': orderId,
      'amount': amount,
    });
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Confirm a card or UPI payment after user completes it
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String paymentId,
    required String orderId,
  }) async {
    await _ensureToken();
    final res = await _api.post('/api/payments/confirm', {
      'paymentIntentId': paymentIntentId,
      'paymentId': paymentId,
      'orderId': orderId,
    });
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Confirm cash-on-delivery payment (uses mock pi_test_ prefix)
  Future<Map<String, dynamic>> confirmCashPayment({
    required String paymentId,
    required String orderId,
  }) async {
    await _ensureToken();
    final mockId = 'pi_test_cash_${DateTime.now().millisecondsSinceEpoch}';
    final res = await _api.post('/api/payments/confirm', {
      'paymentIntentId': mockId,
      'paymentId': paymentId,
      'orderId': orderId,
    });
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Get payment history for the logged-in customer
  Future<List<dynamic>> getPaymentHistory() async {
    await _ensureToken();
    final res = await _api.get('/api/payments/history');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  /// Get earnings summary for technician
  Future<Map<String, dynamic>> getTechnicianEarnings() async {
    await _ensureToken();
    final res = await _api.get('/api/payments/earnings');
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Get monthly earnings breakdown for technician
  Future<List<dynamic>> getMonthlyEarnings() async {
    await _ensureToken();
    final res = await _api.get('/api/payments/earnings/monthly');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  /// Request a withdrawal (technician only)
  Future<Map<String, dynamic>> requestWithdrawal({
    required num amount,
    required Map<String, dynamic> bankAccount,
  }) async {
    await _ensureToken();
    final res = await _api.post('/api/payments/withdraw', {
      'amount': amount,
      'bankAccount': bankAccount,
    });
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  /// Get withdrawal history (technician only)
  Future<List<dynamic>> getWithdrawalHistory() async {
    await _ensureToken();
    final res = await _api.get('/api/payments/withdraw/history');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  Future<bool> processPayment(String orderId, int amount) async {
    debugPrint('processPayment called for order $orderId amount $amount');
    return false;
  }
}
