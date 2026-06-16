---
name: testing-fix-n-go
description: Test the Fix-N-Go admin panel and backend locally. Use when verifying admin panel UI, KYC flows, order lifecycle, or monitoring features.
---

# Testing Fix-N-Go Admin Panel & Backend

## Prerequisites

- MongoDB must be running locally (port 27017)
- Node.js available

## Setup Steps

### 1. Start MongoDB
```bash
mkdir -p /tmp/mongodb && mongod --dbpath /tmp/mongodb --fork --logpath /tmp/mongodb/mongod.log
```

### 2. Create Backend .env
```bash
cat > fixngo/backend/.env << 'EOF'
MONGO_URI=mongodb://localhost:27017/fixngo_test
JWT_SECRET=test_jwt_secret_key_2026
PORT=5000
NODE_ENV=development
CORS_ORIGINS=http://localhost:5173,http://localhost:3000
EOF
```

### 3. Start Backend
```bash
cd fixngo/backend && node src/server.js &
```
Expect warnings about email/Twilio credentials (mock mode) - this is fine for testing.

### 4. Start Admin Panel
```bash
cd fixngo/apps/admin_panel && npm run dev &
```
Runs on http://localhost:5173

### 5. Create Test Users
Admin role cannot be created via `/api/auth/register` (only customer/technician allowed). Create via script:
```bash
cd fixngo/backend && node -e "
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
require('dotenv').config();
async function main() {
  await mongoose.connect(process.env.MONGO_URI);
  const User = require('./src/models/userModel');
  const hash = await bcrypt.hash('Admin123!', await bcrypt.genSalt(10));
  await User.findOneAndUpdate({email:'admin@fixngo.com'}, {name:'Admin',email:'admin@fixngo.com',password:hash,role:'admin',accountStatus:'active',isApproved:true}, {upsert:true});
  await User.findOneAndUpdate({email:'tech@fixngo.com'}, {name:'Test Technician',email:'tech@fixngo.com',password:hash,role:'technician',accountStatus:'pending',isApproved:false,phone:'9876543210',lastLat:17.4648,lastLng:78.3678,isOnline:true,technicianMeta:{rating:4.5,jobsDone:10,specialization:['screen','battery'],documents:{aadharNumber:'1234-5678-9012'},verification:{status:'pending',aadhaarVerified:false},walletBalance:500}}, {upsert:true});
  await User.findOneAndUpdate({email:'customer@fixngo.com'}, {name:'Test Customer',email:'customer@fixngo.com',password:hash,role:'customer',accountStatus:'active',isApproved:true,phone:'9123456789',city:'Hyderabad'}, {upsert:true});
  console.log('Users created'); await mongoose.disconnect();
}
main();
"
```

## Test Credentials
- Admin: admin@fixngo.com / Admin123!
- Technician: tech@fixngo.com / Admin123!
- Customer: customer@fixngo.com / Admin123!

## Key API Endpoints to Test

### Auth
- `POST /api/auth/login` - body: `{email, password, role}`

### Orders (Customer token)
- `POST /api/orders` - Create order (requires brand, model, issues, total, serviceLat, serviceLng, searchRadius)
- `GET /api/orders/:id/tracking` - Live tracking info

### Orders (Technician token)
- `GET /api/orders/available?radius=15` - Nearby pending orders
- `PATCH /api/orders/:id/accept` - Accept order (atomic)
- `PATCH /api/orders/:id/en-route` - Mark en route
- `PATCH /api/orders/:id/start-service` - Start service (generates OTP)
- `POST /api/orders/:id/complete` - Complete with OTP validation: `{otp}`

### Admin (Admin token)
- `GET /api/admin/technicians` - List technicians
- `PATCH /api/admin/technicians/:id/approve` - Approve KYC
- `PATCH /api/admin/technicians/:id/reject` - Reject with `{reason}`
- `GET /api/admin/monitoring/active-requests` - Live active orders
- `GET /api/admin/monitoring/technician-locations` - Online tech positions
- `GET /api/admin/monitoring/payments` - Revenue/commission breakdown
- `GET /api/admin/stats` - Dashboard stats

## Admin Panel UI Test Flow
1. Login at http://localhost:5173 with admin credentials
2. Dashboard: Verify stat cards (Total Orders, Pending, Assigned, En Route, In Progress, Completed) and revenue/commission cards
3. Technicians: Click "View KYC" → see documents, reject with reason, approve
4. Live Monitoring: 3 tabs - Active Requests, Technician Locations, Payments & Commissions

## Notes
- The vite.config.js uses function-style `manualChunks` for Vite 8 compatibility
- Commission split is 70% technician / 30% platform
- Order lifecycle: pending → assigned → en_route → in_progress → completed
- Technician must be approved AND online to appear in location monitoring
- `searchRadius` accepts 5, 10, or 15 (km) for geospatial matching
