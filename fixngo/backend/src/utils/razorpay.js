const Razorpay = require('razorpay');
require('dotenv').config();

// We default to dummy keys if not in env for testing
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_dummy_key_id',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'rzp_test_dummy_secret'
});

module.exports = razorpay;
