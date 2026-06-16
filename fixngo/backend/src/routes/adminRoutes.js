const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const { adminOnly } = require('../middleware/adminMiddleware');
const {
  getAllOrders,
  updateOrderStatus,
  getStats,
  getAllUsers,
  assignTechnician,
  getAllTechnicians,
  approveTechnician,
  rejectTechnician,
  suspendTechnician,
  getActiveRequests,
  getTechnicianLocations,
  getCustomerBookings,
  getPaymentsOverview,
} = require('../controllers/adminController');

const router = express.Router();

router.use(protect, adminOnly);

// Dashboard
router.get('/stats', getStats);

// Orders
router.get('/orders', getAllOrders);
router.patch('/orders/:id', updateOrderStatus);
router.post('/orders/assign', assignTechnician);

// Users
router.get('/users', getAllUsers);

// Technician management
router.get('/technicians', getAllTechnicians);
router.patch('/technicians/:id/approve', approveTechnician);
router.patch('/technicians/:id/reject', rejectTechnician);
router.patch('/technicians/:id/suspend', suspendTechnician);

// Monitoring
router.get('/monitoring/active-requests', getActiveRequests);
router.get('/monitoring/technician-locations', getTechnicianLocations);
router.get('/monitoring/customer-bookings', getCustomerBookings);
router.get('/monitoring/payments', getPaymentsOverview);

module.exports = router;
