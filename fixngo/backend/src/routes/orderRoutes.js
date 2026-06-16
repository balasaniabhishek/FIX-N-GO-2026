const express = require('express');
const {
  getOrders,
  createOrder,
  getOrderById,
  updateOrderStatus,
  acceptOrder,
  rejectOrder,
  startEnRoute,
  startService,
  completeOrder,
  getAvailableOrders,
  getTechnicianOrders,
  getTrackingInfo,
} = require('../controllers/orderController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Technician Routes
router.get('/available', protect, getAvailableOrders);
router.get('/technician', protect, getTechnicianOrders);
router.patch('/:id/accept', protect, acceptOrder);
router.patch('/:id/reject', protect, rejectOrder);
router.patch('/:id/en-route', protect, startEnRoute);
router.patch('/:id/start-service', protect, startService);
router.post('/:id/complete', protect, completeOrder);

// Customer Routes
router.get('/:id/tracking', protect, getTrackingInfo);
router.route('/').get(protect, getOrders).post(protect, createOrder);
router.route('/:id').get(protect, getOrderById);
router.put('/:id/status', protect, updateOrderStatus);

module.exports = router;
