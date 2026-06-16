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
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('Anand43211234@#', salt);
    
    // Create or update admin user
    const adminData = {
      name: 'Anand Admin',
      email: 'anandpalaparti19@gmail.com',
      password: hashedPassword,
      role: 'admin',
      phone: '0000000000'
    };

    const existingAdmin = await User.findOne({ email: 'anandpalaparti19@gmail.com' });
    if (existingAdmin) {
      await User.updateOne({ email: 'anandpalaparti19@gmail.com' }, { $set: adminData });
      console.log('✅ Admin account updated successfully!');
    } else {
      await User.create(adminData);
      console.log('✅ Admin account created successfully!');
    }

    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
};

connectDB().then(() => createAdmin());
