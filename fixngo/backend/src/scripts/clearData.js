require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/userModel');
const Order = require('../models/orderModel');
const Service = require('../models/serviceModel');
const Rating = require('../models/ratingModel');

const connectDB = async () => {
  const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/fixngo';
  try {
    await mongoose.connect(uri);
    console.log('MongoDB Connected');
  } catch (error) {
    console.error('DB Connection Error:', error.message);
    process.exit(1);
  }
};

const clearDatabase = async () => {
  try {
    console.log('Starting database clear...');
    
    // Clear all collections
    await User.deleteMany({});
    await Order.deleteMany({});
    await Service.deleteMany({});
    await Rating.deleteMany({});
    
    console.log('✅ Successfully removed all fake data from the database.');
    process.exit(0);
  } catch (error) {
    console.error('Clear error:', error);
    process.exit(1);
  }
};

connectDB().then(() => clearDatabase());
