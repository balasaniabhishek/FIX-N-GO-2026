const express = require('express');
const path = require('path');
const authRoutes = require('./authRoutes');
const orderRoutes = require('./orderRoutes');
const paymentRoutes = require('./paymentRoutes');
const ratingRoutes = require('./ratingRoutes');
const technicianProfileRoutes = require('./technicianProfileRoutes');
const technicianRoutes = require('./technicianRoutes');
const serviceRoutes = require('./serviceRoutes');
const catalogRoutes = require('./catalogRoutes');
const adminRoutes = require('./adminRoutes');
const technicianAppRoutes = require('./technicianAppRoutes');
const locationRoutes = require('./locationRoutes');
const photoRoutes = require('./photoRoutes');
const notificationRoutes = require('./notificationRoutes');
const supportRoutes = require('./supportRoutes');
const webhookRoutes = require('./webhookRoutes');
const walletRoutes = require('./walletRoutes');

const router = express.Router();

router.use('/api/auth', authRoutes);
router.use('/api/orders', orderRoutes);
router.use('/api/payments', paymentRoutes);
router.use('/api/ratings', ratingRoutes);
router.use('/api/technician-profile', technicianProfileRoutes);
router.use('/api/technician', technicianRoutes);
router.use('/api/tech', technicianAppRoutes);
router.use('/api/services', serviceRoutes);
router.use('/api/catalog', catalogRoutes);
router.use('/api/admin', adminRoutes);
router.use('/api/location', locationRoutes);
router.use('/api/photos', photoRoutes);
router.use('/api/notifications', notificationRoutes);
router.use('/api/support', supportRoutes);
router.use('/api/webhooks', webhookRoutes);
router.use('/api/wallet', walletRoutes);

router.use('/admin', express.static(path.join(__dirname, '../../../apps/admin_panel/public')));

router.get('/api/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Fix-N-Go backend is running' });
});

module.exports = router;

