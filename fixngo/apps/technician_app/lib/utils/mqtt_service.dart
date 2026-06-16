import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_client_stub.dart'
    if (dart.library.html) 'mqtt_client_web.dart'
    if (dart.library.io) 'mqtt_client_io.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  late MqttClient client;

  final Map<String, List<Function(dynamic)>> _callbacks = {
    'order-updated': [],
    'notification': [],
    'chat-message': [],
  };

  bool get isConnected => 
      client.connectionStatus?.state == MqttConnectionState.connected;

  factory MqttService() {
    return _instance;
  }

  MqttService._internal() {
    final host = const String.fromEnvironment('MQTT_HOST', defaultValue: '10.0.2.2');
    client = setupMqttClient(host, 'tech_client_${DateTime.now().millisecondsSinceEpoch}', 9001);
  }

  Future<void> connect() async {
    try {
      client.logging(on: false);
      client.keepAlivePeriod = 20;

      final connMess = MqttConnectMessage()
          .withClientIdentifier('tech_${DateTime.now().millisecondsSinceEpoch}')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce)
          .authenticateAs(
            const String.fromEnvironment('MQTT_USER', defaultValue: 'fixngo_app'),
            const String.fromEnvironment('MQTT_PASS', defaultValue: 'fixngo_secure_2026'),
          );
      client.connectionMessage = connMess;

      await client.connect();

      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('Tech MQTT connected');
        
        client.subscribe('server/order/#', MqttQos.atLeastOnce);
        client.subscribe('server/chat/#', MqttQos.atLeastOnce);
        if (_pendingUserId != null) {
          client.subscribe('server/user/$_pendingUserId/notification', MqttQos.atLeastOnce);
        }

        client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
          final recMess = c![0].payload as MqttPublishMessage;
          final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          final topic = c[0].topic;
          
          try {
            final data = jsonDecode(pt);
            if (topic.contains('/updated')) {
              _triggerCallbacks('order-updated', data);
            } else if (topic.contains('/notification')) {
              _triggerCallbacks('notification', data);
            } else if (topic.startsWith('server/chat/')) {
              _triggerCallbacks('chat-message', data);
            }
          } catch (e) {
            debugPrint('Error parsing mqtt message: $e');
          }
        });

      } else {
        debugPrint('Tech MQTT connection failed');
        client.disconnect();
      }
    } catch (e) {
      debugPrint('Error connecting to Tech MQTT: $e');
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

  void onOrderUpdated(Function(dynamic) callback) {
    _callbacks['order-updated']!.add(callback);
  }

  void onNotification(Function(dynamic) callback) {
    _callbacks['notification']!.add(callback);
  }

  String? _pendingUserId;

  void subscribeToUserNotifications(String userId) {
    _pendingUserId = userId;
    if (isConnected) {
      client.subscribe('server/user/$userId/notification', MqttQos.atLeastOnce);
    }
  }

  void emitLocationUpdate(String orderId, double latitude, double longitude) {
    publish('client/user/tech_id/location', {
      'orderId': orderId,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void updateOrderStatus(String orderId, String status, String? note) {
    publish('client/order/$orderId/status', {
      'orderId': orderId,
      'status': status,
      'note': note,
    });
  }

  void off(String event) {
    _callbacks[event]?.clear();
  }
}
