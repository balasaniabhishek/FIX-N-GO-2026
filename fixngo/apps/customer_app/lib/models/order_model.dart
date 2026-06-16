class OrderModel {
  final String id;
  final String brand;
  final String model;
  final List<String> issues;
  final int total;
  final String status;
  final String? technicianName;
  final String? technicianUser;
  final double? technicianRating;
  final String? technicianPhone;
  final double? technicianLat;
  final double? technicianLng;
  final String paymentStatus;
  final String serviceAddress;
  final double? serviceLat;
  final double? serviceLng;
  final List<StatusHistory>? statusHistory;
  final String? completionOtp;

  OrderModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.issues,
    required this.total,
    required this.status,
    this.technicianName,
    this.technicianUser,
    this.technicianRating,
    this.technicianPhone,
    this.technicianLat,
    this.technicianLng,
    required this.paymentStatus,
    required this.serviceAddress,
    this.serviceLat,
    this.serviceLng,
    this.statusHistory,
    this.completionOtp,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      issues: List<String>.from(json['issues'] ?? []),
      total: json['total'] ?? 0,
      status: json['status'] ?? 'pending',
      technicianName: json['technicianName'],
      technicianUser: json['technicianUser'] is String 
          ? json['technicianUser'] 
          : (json['technicianUser'] is Map ? json['technicianUser']['_id'] : null),
      technicianRating: (json['technicianRating'] as num?)?.toDouble(),
      technicianPhone: json['technicianPhone'],
      technicianLat: (json['technicianLat'] as num?)?.toDouble(),
      technicianLng: (json['technicianLng'] as num?)?.toDouble(),
      paymentStatus: json['paymentStatus'] ?? 'pending',
      serviceAddress: json['serviceAddress'] ?? '',
      serviceLat: (json['serviceLat'] as num?)?.toDouble(),
      serviceLng: (json['serviceLng'] as num?)?.toDouble(),
      statusHistory: (json['statusHistory'] as List?)
          ?.map((e) => StatusHistory.fromJson(e))
          .toList(),
      completionOtp: json['completionOtp'],
    );
  }
}

class StatusHistory {
  final String status;
  final String note;
  final DateTime at;

  StatusHistory({required this.status, required this.note, required this.at});

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] ?? '',
      note: json['note'] ?? '',
      at: DateTime.parse(json['at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
