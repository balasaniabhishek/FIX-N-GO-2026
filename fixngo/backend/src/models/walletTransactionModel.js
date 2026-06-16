const mongoose = require('mongoose');

const walletTransactionSchema = mongoose.Schema(
  {
    technicianId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    bookingId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'Order' 
    },
    type: { 
      type: String, 
      enum: ['credit', 'debit'], 
      required: true 
    },
    amount: { 
      type: Number, 
      required: true 
    },
    status: { 
      type: String, 
      enum: ['success', 'pending', 'failed'], 
      default: 'success' 
    },
    description: { 
      type: String 
    },
    referenceId: { 
      type: String // For payout IDs or Razorpay order IDs
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('WalletTransaction', walletTransactionSchema);
