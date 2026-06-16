const mongoose = require('mongoose');

const platformLedgerSchema = mongoose.Schema(
  {
    bookingId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'Order', 
      required: true 
    },
    customerFee: { 
      type: Number, 
      required: true 
    },
    technicianCommission: { 
      type: Number, 
      required: true 
    },
    totalRevenue: { 
      type: Number, 
      required: true 
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('PlatformLedger', platformLedgerSchema);
