const mongoose = require('mongoose');

const withdrawalSchema = mongoose.Schema(
  {
    technician: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      ref: 'User',
    },
    amount: {
      type: Number,
      required: true,
    },
    bankAccount: {
      type: String,
      required: true,
    },
    payoutGatewayId: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed', 'reversed', 'approved', 'rejected'],
      default: 'pending',
    },
    processedAt: {
      type: Date,
    },
    notes: {
      type: String,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Withdrawal', withdrawalSchema);
