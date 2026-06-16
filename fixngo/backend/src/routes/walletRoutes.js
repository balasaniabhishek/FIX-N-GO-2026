const express = require('express');
const { requestWithdrawal } = require('../controllers/walletController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/withdraw', protect, requestWithdrawal);

module.exports = router;
