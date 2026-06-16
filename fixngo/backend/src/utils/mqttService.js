const mqtt = require('mqtt');
const Order = require('../models/orderModel');
const User = require('../models/userModel');
const Message = require('../models/messageModel');

let client;
const onlineUsers = new Set(); // To track online users (simple memory tracking)
const lastDbWriteTime = new Map(); // To throttle location DB writes

const initializeMqtt = () => {
  // Connect to Mosquitto broker
  client = mqtt.connect(process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883', {
    username: process.env.MQTT_USER || 'fixngo_app',
    password: process.env.MQTT_PASSWORD || 'fixngo_secure_2026'
  });

  client.on('connect', () => {
    console.log('Connected to MQTT broker');
    
    // Subscribe to topics where clients will publish their events
    client.subscribe('client/user/+/online');
    client.subscribe('client/user/+/offline');
    client.subscribe('client/order/+/status');
    client.subscribe('client/user/+/location');
    client.subscribe('client/chat/message');
  });

  client.on('message', async (topic, message) => {
    try {
      const data = JSON.parse(message.toString());
      const topicParts = topic.split('/');

      // client/user/:userId/online
      if (topic.startsWith('client/user/') && topic.endsWith('/online')) {
        const userId = topicParts[2];
        onlineUsers.add(userId);
        console.log(`User ${userId} is online`);
        client.publish(`server/user/${userId}/status`, JSON.stringify({ status: 'online', timestamp: new Date() }));
      }
      
      // client/user/:userId/offline
      else if (topic.startsWith('client/user/') && topic.endsWith('/offline')) {
        const userId = topicParts[2];
        onlineUsers.delete(userId);
        console.log(`User ${userId} is offline`);
        client.publish(`server/user/${userId}/status`, JSON.stringify({ status: 'offline', timestamp: new Date() }));
      }
      
      // client/order/:orderId/status
      else if (topic.startsWith('client/order/') && topic.endsWith('/status')) {
        const { orderId, status, note, userId } = data;
        const order = await Order.findById(orderId);
        if (order && (order.user?.toString() === userId || order.technicianUser?.toString() === userId)) {
          order.status = status;
          if (note) {
            order.statusHistory?.push({ status, timestamp: new Date(), note });
          }
          await order.save();
          // Broadcast order update
          client.publish(`server/order/${orderId}/updated`, JSON.stringify({ orderId, status, note, timestamp: new Date() }));
          console.log(`Order ${orderId} updated to ${status}`);
        }
      }
      
      // client/user/:userId/location
      else if (topic.startsWith('client/user/') && topic.endsWith('/location')) {
        const { latitude, longitude, orderId, userId } = data;
        
        const now = Date.now();
        const lastWrite = lastDbWriteTime.get(userId) || 0;
        
        // Write to DB at most once every 5 seconds per user
        if (now - lastWrite > 5000) {
          await User.findByIdAndUpdate(userId, { lastLat: latitude, lastLng: longitude, lastLocationUpdate: new Date() });
          lastDbWriteTime.set(userId, now);
        }
        
        // Forward location to specific order topic
        if (orderId) {
          client.publish(`server/order/${orderId}/location`, JSON.stringify({
            technicianId: userId,
            orderId,
            latitude,
            longitude,
            timestamp: new Date()
          }));
        }
      }
      
      // client/chat/message
      else if (topic === 'client/chat/message') {
        const { senderId, recipientId, message: chatMsg, orderId } = data;
        await Message.create({ orderId, senderId, receiverId: recipientId, message: chatMsg });
        // Send to recipient
        client.publish(`server/chat/${recipientId}`, JSON.stringify({
          senderId,
          message: chatMsg,
          orderId,
          timestamp: new Date()
        }));
      }
    } catch (error) {
      console.error('MQTT message processing error:', error);
    }
  });

  client.on('error', (err) => {
    console.error('MQTT Client Error:', err);
  });
};

// Expose equivalent methods from old socketService
const emitOrderUpdate = (orderId, data) => {
  if (client) {
    client.publish(`server/order/${orderId}/updated`, JSON.stringify({
      orderId,
      ...data,
      timestamp: new Date()
    }));
  }
};

const emitNotification = (userId, data) => {
  if (client) {
    client.publish(`server/user/${userId}/notification`, JSON.stringify({
      ...data,
      timestamp: new Date()
    }));
  }
};

const getConnectedUsers = () => {
  return Array.from(onlineUsers);
};

const isUserOnline = (userId) => {
  return onlineUsers.has(userId.toString());
};

// Aliased exports for drop-in replacement
module.exports = {
  initializeMqtt,
  initializeSocket: initializeMqtt, // Alias to avoid breaking other imports immediately
  emitOrderUpdate,
  emitNotification,
  getConnectedUsers,
  isUserOnline,
};
