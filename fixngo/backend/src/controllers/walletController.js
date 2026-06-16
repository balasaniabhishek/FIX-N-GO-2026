const User = require('../models/userModel');
const Withdrawal = require('../models/withdrawalModel');
const WalletTransaction = require('../models/walletTransactionModel');
const mongoose = require('mongoose');

const requestWithdrawal = async (req, res, next) => {
  try {
    const { amount } = req.body;
    
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can withdraw funds' });
    }
    
    const user = await User.findById(req.user._id);
    const techMeta = user.technicianMeta;
    
    // Check KYC & Bank
    if (techMeta.verification.status !== 'verified') {
      return res.status(400).json({ success: false, message: 'KYC not verified. Cannot withdraw.' });
    }
    if (!techMeta.bankDetails || !techMeta.bankDetails.accountNumber) {
      return res.status(400).json({ success: false, message: 'No bank details linked.' });
    }
    
    // Check balance
    if (amount < 500) {
      return res.status(400).json({ success: false, message: 'Minimum withdrawal amount is ₹500' });
    }
    if (techMeta.walletBalance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient wallet balance' });
    }
    
    // Optimistic Debit Transaction
    const session = await mongoose.startSession();
    session.startTransaction();
    let withdrawal;
    
    try {
      withdrawal = await Withdrawal.create([{
        technician: user._id,
        amount: amount,
        bankAccount: techMeta.bankDetails.accountNumber,
        status: 'pending' // will change to processing once submitted to Razorpay
      }], { session });

      await WalletTransaction.create([{
        technicianId: user._id,
        type: 'debit',
        amount: amount,
        description: `Withdrawal request`,
        referenceId: withdrawal[0]._id.toString()
      }], { session });

      await User.findByIdAndUpdate(
        user._id,
        { $inc: { 'technicianMeta.walletBalance': -amount } },
        { session }
      );

      await session.commitTransaction();
      session.endSession();
    } catch (err) {
      await session.abortTransaction();
      session.endSession();
      throw err;
    }

    // TODO: In a real app, you would now trigger the Razorpay Payouts API 
    // using `withdrawal[0]._id` and update status to 'processing'.
    // If it fails immediately, you reverse the transaction.
    
    res.json({
      success: true,
      message: 'Withdrawal requested successfully',
      data: withdrawal[0]
    });

  } catch (error) {
    next(error);
  }
};

module.exports = { requestWithdrawal };
