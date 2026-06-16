const mongoose = require('mongoose');

const checklistItemSchema = mongoose.Schema(
  {
    key: { type: String, required: true },
    label: { type: String, required: true },
    done: { type: Boolean, default: false },
  },
  { _id: false }
);

const orderSchema = mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'User' },
    brand: { type: String, required: true },
    model: { type: String, required: true },
    issues: [{ type: String, required: true }],
    basePrice: { type: Number, required: true },
    customerFee: { type: Number, required: true },
    technicianCommission: { type: Number, required: true },
    customerTotal: { type: Number, required: true },
    total: { type: Number, required: true }, // Keeping for backwards compatibility
    status: {
      type: String,
      enum: ['pending', 'assigned', 'in_progress', 'completed', 'cancelled'],
      default: 'pending',
    },
    technician: { type: String, default: '' },
    technicianUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    dispatchStatus: {
      type: String,
      enum: ['none', 'offered', 'accepted', 'declined'],
      default: 'none',
    },
    customerPhone: { type: String, default: '' },
    serviceAddress: { type: String, default: '' },
    city: { type: String, default: '' },
    pincode: { type: String, default: '' },
    serviceLat: { type: Number, default: null },
    serviceLng: { type: Number, default: null },
    location: {
      type: { type: String, default: 'Point' },
      coordinates: { type: [Number], default: [0, 0] },
    },
    checklist: [checklistItemSchema],
    photos: {
      before: [{ type: String }],
      after: [{ type: String }],
    },
    notes: { type: String, default: '' },
    servicePhotos: [
      {
        url: { type: String, required: true },
        fileName: { type: String, required: true },
        uploadedAt: { type: Date, default: Date.now },
        uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      },
    ],
    serviceNotes: [
      {
        text: { type: String, required: true },
        addedAt: { type: Date, default: Date.now },
        addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      },
    ],
    completionOtp: { type: String, default: null },
    paymentStatus: { type: String, enum: ['pending', 'captured', 'failed', 'collected'], default: 'pending' },
    paymentMethod: { type: String, enum: ['cash', 'card', 'upi'], default: 'cash' },
    paymentGatewayOrderId: { type: String, default: '' },
    stripePaymentIntentId: { type: String, default: '' },
    technicianEarning: { type: Number, default: 0 },
    estimatedDateTime: { type: Date, default: null },
    completedAt: { type: Date, default: null },
    description: { type: String, default: '' },
    statusHistory: [
      {
        status: String,
        note: String,
        at: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

orderSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Order', orderSchema);

