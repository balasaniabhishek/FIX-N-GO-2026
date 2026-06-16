const Order = require('../models/orderModel');
const User = require('../models/userModel');
const WalletTransaction = require('../models/walletTransactionModel');
const PlatformLedger = require('../models/platformLedgerModel');
const mongoose = require('mongoose');
const { emitNotification } = require('../utils/mqttService');

const razorpayWebhook = async (req, res) => {
  try {
    const crypto = require('crypto');
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET || 'rzp_test_webhook_secret';
    
    const signature = req.headers['x-razorpay-signature'];
    if (!signature) {
      return res.status(400).send('Missing signature');
    }
    
    const expectedSignature = crypto.createHmac('sha256', secret)
                                    .update(JSON.stringify(req.body))
                                    .digest('hex');
                                    
    if (signature !== expectedSignature) {
      return res.status(400).send('Invalid signature');
    }

    const event = req.body;
    
    if (event.event === 'payment.captured') {
      const payment = event.payload.payment.entity;
      const rpOrderId = payment.order_id;
      
      const order = await Order.findOne({ paymentGatewayOrderId: rpOrderId });
      if (!order) return res.status(200).send('Order not found, skipping');
      if (order.paymentStatus === 'captured') return res.status(200).send('Already captured');

      const session = await mongoose.startSession();
      session.startTransaction();
      try {
        order.paymentStatus = 'captured';
        await order.save({ session });

        // Credit Technician Wallet
        await WalletTransaction.create([{
          technicianId: order.technicianUser,
          bookingId: order._id,
          type: 'credit',
          amount: order.technicianEarning,
          description: `Earnings for order ${order._id}`
        }], { session });

        // Update User Balance
        await User.findByIdAndUpdate(
          order.technicianUser,
          { 
            $inc: { 
              'technicianMeta.walletBalance': order.technicianEarning, 
              'technicianMeta.totalEarnings': order.technicianEarning 
            } 
          },
          { session }
        );

        // Record Platform Cut
        await PlatformLedger.create([{
          bookingId: order._id,
          customerFee: order.customerFee,
          technicianCommission: order.technicianCommission,
          totalRevenue: order.customerFee + order.technicianCommission
        }], { session });

        await session.commitTransaction();
        session.endSession();

        // Notify Technician
        emitNotification(order.technicianUser.toString(), {
          type: 'wallet_credited',
          title: 'Payment Received!',
          message: `₹${order.technicianEarning} has been credited to your wallet for order ${order._id}.`,
          amount: order.technicianEarning
        });

      } catch (err) {
        await session.abortTransaction();
        session.endSession();
        console.error('Webhook transaction failed', err);
        return res.status(500).send('Webhook Processing Error');
      }
    }
    
    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Error handling webhook');
  }
};

module.exports = { razorpayWebhook };
