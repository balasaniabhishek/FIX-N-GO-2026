require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/userModel');

const connectDB = async () => {
  const uri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/fixngo';
  try {
    await mongoose.connect(uri);
  } catch (error) {
    console.error('DB Connection Error:', error.message);
    process.exit(1);
  }
};

const createAdmin = async () => {
  try {
    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@fixngo.com' });
    if (existingAdmin) {
      console.log('Admin already exists.');
      process.exit(0);
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('admin123', salt);
    
    // Create admin user
    await User.create({
      name: 'Super Admin',
      email: 'admin@fixngo.com',
      password: hashedPassword,
      role: 'admin',
      phone: '0000000000'
    });
    
    console.log('✅ Admin account created successfully!');
    console.log('-----------------------------------');
    console.log('Email: admin@fixngo.com');
    console.log('Password: admin123');
    console.log('-----------------------------------');
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
};

connectDB().then(() => createAdmin());
