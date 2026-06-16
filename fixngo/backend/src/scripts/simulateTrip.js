require('dotenv').config();
const mongoose = require('mongoose');
const mqtt = require('mqtt');
const Order = require('../models/orderModel');
const User = require('../models/userModel');

const connectDB = async () => {
  const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/fixngo';
  await mongoose.connect(uri);
  console.log('Connected to MongoDB');
};

const simulateTrip = async () => {
  try {
    await connectDB();

    // 1. Connect to MQTT
    const client = mqtt.connect(process.env.MQTT_BROKER_URL || 'mqtt://127.0.0.1:1883', {
      username: process.env.MQTT_USER || 'fixngo_app',
      password: process.env.MQTT_PASSWORD || 'fixngo_secure_2026',
      protocolVersion: 4,
      clean: true,
      reconnectPeriod: 1000
    });

    client.on('error', (err) => {
      console.error('\n❌ Failed to connect to MQTT Broker.');
      console.error('Error details:', err.message);
    });

    await new Promise((resolve) => {
      client.on('connect', resolve);
    });
    console.log('Connected to MQTT Broker');

    // 2. Find or Create a Test Technician
    let tech = await User.findOne({ email: 'sim_tech@fixngo.com' });
    if (!tech) {
      tech = await User.create({
        name: 'Simulated Tech',
        email: 'sim_tech@fixngo.com',
        password: 'password123',
        role: 'technician',
        phone: '9999999999'
      });
      console.log('Created Simulated Technician');
    }

    // 3. Find a pending order
    const orderIdArg = process.argv[2];
    let order;
    if (orderIdArg) {
      order = await Order.findById(orderIdArg);
    } else {
      order = await Order.findOne({ status: 'pending' }).sort({ createdAt: -1 });
    }

    if (!order) {
      console.log('No pending order found! Creating a dummy order for testing...');
      const customer = await User.findOne({ role: 'customer' });
      if (!customer) {
        console.error('No customer found in the database. Please register a customer in the app.');
        process.exit(1);
      }
      
      order = await Order.create({
        user: customer._id,
        brand: 'Apple',
        model: 'iPhone 13',
        issues: ['Screen Replacement'],
        total: 199,
        status: 'pending',
        serviceLat: 17.4065,
        serviceLng: 78.4772
      });
      console.log(`Created dummy order: ${order._id}`);
    }

    console.log(`Found Order: ${order._id}`);
    
    // 4. Accept the order
    order.status = 'assigned';
    order.technicianUser = tech._id;
    order.technicianName = tech.name;
    await order.save();
    console.log('Order accepted by Simulated Technician');

    client.publish(`client/order/${order._id}/status`, JSON.stringify({
      orderId: order._id,
      status: 'assigned',
      userId: tech._id.toString()
    }));

    // 5. Simulate Trip
    // Start roughly 2km away from the customer
    const targetLat = order.serviceLat || 17.4065;
    const targetLng = order.serviceLng || 78.4772;
    
    let currentLat = targetLat + 0.02; // Offset by ~2km
    let currentLng = targetLng + 0.02;

    const steps = 120; // 120 seconds trip (2 minutes)
    const latStep = (targetLat - currentLat) / steps;
    const lngStep = (targetLng - currentLng) / steps;

    let stepCount = 0;

    console.log(`Starting trip from [${currentLat.toFixed(4)}, ${currentLng.toFixed(4)}] to [${targetLat.toFixed(4)}, ${targetLng.toFixed(4)}]`);

    const interval = setInterval(() => {
      currentLat += latStep;
      currentLng += lngStep;
      stepCount++;

      // Publish location
      client.publish(`client/user/${tech._id}/location`, JSON.stringify({
        userId: tech._id.toString(),
        orderId: order._id.toString(),
        latitude: currentLat,
        longitude: currentLng
      }));

      console.log(`[Step ${stepCount}/${steps}] Location: ${currentLat.toFixed(5)}, ${currentLng.toFixed(5)}`);

      if (stepCount >= steps) {
        clearInterval(interval);
        console.log('Reached customer location!');
        
        // Mark as in_progress (arrived)
        client.publish(`client/order/${order._id}/status`, JSON.stringify({
          orderId: order._id,
          status: 'in_progress',
          userId: tech._id.toString()
        }));
        console.log('Order marked as in_progress. Simulation Complete.');
        
        setTimeout(() => process.exit(0), 1000);
      }
    }, 1000); // Update every 1 second

  } catch (err) {
    console.error('Simulation Error:', err);
    process.exit(1);
  }
};

simulateTrip();
