import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_client_stub.dart'
    if (dart.library.html) 'mqtt_client_web.dart'
    if (dart.library.io) 'mqtt_client_io.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  late MqttClient client;
  final StorageService _storageService = StorageService();

  final Map<String, List<Function(dynamic)>> _callbacks = {
    'order-updated': [],
    'technician-location': [],
    'notification': [],
    'user-status': [],
    'chat-message': [],
  };

  bool get isConnected => 
      client.connectionStatus?.state == MqttConnectionState.connected;

  factory MqttService() {
    return _instance;
  }

  MqttService._internal() {
    final host = const String.fromEnvironment('MQTT_HOST', defaultValue: '10.0.2.2');
    client = setupMqttClient(host, 'customer_client_${DateTime.now().millisecondsSinceEpoch}', 9001);
  }

  Future<void> connect() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) return;
      
      client.logging(on: false);
      client.keepAlivePeriod = 20;

      final connMess = MqttConnectMessage()
          .withClientIdentifier('customer_${DateTime.now().millisecondsSinceEpoch}')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce)
          .authenticateAs(
            const String.fromEnvironment('MQTT_USER', defaultValue: 'fixngo_app'),
            const String.fromEnvironment('MQTT_PASS', defaultValue: 'fixngo_secure_2026'),
          );
      client.connectionMessage = connMess;

      await client.connect();

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('MQTT connected');
        
        // Since we don't know the exact user ID here trivially, 
        // we'll just subscribe to global chat/order wildcards for the customer scope 
        // (In a real secure app, ACLs would prevent wildcards)
        client.subscribe('server/order/#', MqttQos.atLeastOnce);
        client.subscribe('server/chat/#', MqttQos.atLeastOnce);
        client.subscribe('server/user/#', MqttQos.atLeastOnce);

        client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
          final recMess = c![0].payload as MqttPublishMessage;
          final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          final topic = c[0].topic;
          
          try {
            final data = jsonDecode(pt);
            if (topic.contains('/updated')) {
              _triggerCallbacks('order-updated', data);
            } else if (topic.contains('/location')) {
              _triggerCallbacks('technician-location', data);
            } else if (topic.contains('/notification')) {
              _triggerCallbacks('notification', data);
            } else if (topic.startsWith('server/chat/')) {
              _triggerCallbacks('chat-message', data);
            } else if (topic.endsWith('/status')) {
              _triggerCallbacks('user-status', data);
            }
          } catch (e) {
            debugPrint('Error parsing mqtt message: $e');
          }
        });

      } else {
        debugPrint('MQTT connection failed - state is ${client.connectionStatus!.state}');
        client.disconnect();
      }
    } catch (e) {
      debugPrint('Error connecting to MQTT: $e');
    }
  }

  void _triggerCallbacks(String event, dynamic data) {
    if (_callbacks.containsKey(event)) {
      for (var cb in _callbacks[event]!) {
        cb(data);
      }
    }
  }

  void disconnect() {
    client.disconnect();
  }

  void publish(String topic, Map<String, dynamic> data) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(data));
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  // Listen to order updates
  void onOrderUpdated(Function(dynamic) callback) {
    _callbacks['order-updated']!.add(callback);
  }

  // Listen to technician location
  void onTechnicianLocation(Function(dynamic) callback) {
    _callbacks['technician-location']!.add(callback);
  }

  // Listen to notifications
  void onNotification(Function(dynamic) callback) {
    _callbacks['notification']!.add(callback);
  }

  // Listen to user status
  void onUserStatus(Function(dynamic) callback) {
    _callbacks['user-status']!.add(callback);
  }

  // Listen to chat messages
  void onChatMessage(Function(dynamic) callback) {
    _callbacks['chat-message']!.add(callback);
  }

  // Emit order status update
  void updateOrderStatus(String orderId, String status, String? note) {
    publish('client/order/$orderId/status', {
      'orderId': orderId,
      'status': status,
      'note': note,
    });
  }

  // Emit notification
  void sendNotification(
    String recipientId,
    String type,
    String title,
    String message,
    String orderId,
  ) {
    publish('client/order/notification', {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      'orderId': orderId,
    });
  }

  // Emit chat message
  void sendChatMessage(String recipientId, String message, String orderId) {
    publish('client/chat/message', {
      'recipientId': recipientId,
      'message': message,
      'orderId': orderId,
    });
  }

  // Remove listener
  void off(String event) {
    _callbacks[event]?.clear();
  }
}
