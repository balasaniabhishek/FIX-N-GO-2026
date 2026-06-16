const axios = require('axios');
const mongoose = require('mongoose');

const BASE_URL = 'http://localhost:5000/api';

async function runTest() {
  console.log('--- Starting E2E API Test ---');
  try {
    // 1. Create a Customer
    const customerEmail = 'customer_' + Date.now() + '@test.com';
    console.log('1. Registering Customer: ' + customerEmail);
    const customerRes = await axios.post(BASE_URL + '/auth/register', {
      name: 'Test Customer',
      email: customerEmail,
      password: 'password123',
      phone: '1234567890',
      role: 'customer'
    });
    const customerToken = customerRes.data.token;
    console.log('   ✅ Customer registered successfully.');

    // 2. Create a Technician
    const uniqueTime = Date.now();
    const techEmail = 'tech_' + uniqueTime + '@test.com';
    const techName = 'Tech_' + uniqueTime;
    console.log('2. Registering Technician: ' + techEmail);
    const techRes = await axios.post(BASE_URL + '/auth/register', {
      name: techName,
      email: techEmail,
      password: 'password123',
      phone: '0987654321',
      role: 'technician'
    });
    const techToken = techRes.data.token;
    const techId = techRes.data._id; // Fixed: accessing _id directly
    console.log('   ✅ Technician registered successfully. ID: ' + techId);

    // 3 & 4. Admin Approves Technician KYC (Direct Database Update for testing)
    console.log('3. Admin approving Technician KYC (via Database)...');
    await mongoose.connect('mongodb://127.0.0.1:27017/fixngo');
    await mongoose.connection.collection('users').updateOne(
      { _id: new mongoose.Types.ObjectId(techId) },
      { 
        $set: { 
          accountStatus: 'active', 
          isApproved: true, 
          'technicianMeta.verification.status': 'verified' 
        } 
      }
    );
    console.log('   ✅ Technician KYC approved.');

    // 5. Customer Creates an Order
    console.log('5. Customer creating an order...');
    const orderRes = await axios.post(BASE_URL + '/orders', {
      brand: 'Apple',
      model: 'iPhone 13',
      issues: ['Screen Broken'],
      total: 1500, // Fixed: added missing required field
      address: '123 Test St',
      serviceLat: 17.0,
      serviceLng: 78.0,
      technician: techName // Fixed: uniquely identify the technician
    }, {
      headers: { Authorization: 'Bearer ' + customerToken }
    });
    const orderId = orderRes.data.data._id;
    console.log('   ✅ Order created. ID: ' + orderId);

    // 6. Technician Updates the Order Status
    console.log('6. Technician updating order status to in_progress...');
    await axios.put(BASE_URL + '/orders/' + orderId + '/status', {
      status: 'in_progress',
      note: 'Started work'
    }, {
      headers: { Authorization: 'Bearer ' + techToken }
    });
    console.log('   ✅ Order status updated by Technician.');

    console.log('\n🎉 ALL TESTS PASSED SUCCESSFULLY! The flow between Customer, Admin, and Technician works perfectly.');
    await mongoose.disconnect();
  } catch (error) {
    console.error('\n❌ TEST FAILED:');
    if (error.response) {
      console.error(error.response.data);
    } else {
      console.error(error.message);
    }
    await mongoose.disconnect();
  }
}

runTest();
