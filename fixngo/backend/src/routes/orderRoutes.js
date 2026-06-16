const express = require('express');
const {
  getOrders,
  createOrder,
  getOrderById,
  updateOrderStatus,
  acceptOrder,
  rejectOrder,
  completeOrder,
  getAvailableOrders,
  getTechnicianOrders,
} = require('../controllers/orderController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Technician Routes
router.get('/available', protect, getAvailableOrders);
router.get('/technician', protect, getTechnicianOrders);
router.patch('/:id/accept', protect, acceptOrder);
router.patch('/:id/reject', protect, rejectOrder);
router.post('/:id/complete', protect, completeOrder);

// Customer/General Routes
router.route('/').get(protect, getOrders).post(protect, createOrder);
router.route('/:id').get(protect, getOrderById);
router.put('/:id/status', protect, updateOrderStatus);

module.exports = router;

