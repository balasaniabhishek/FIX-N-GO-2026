const Order = require('../models/orderModel');
const User = require('../models/userModel');
const Service = require('../models/serviceModel');
const Withdrawal = require('../models/withdrawalModel');
const { emitNotification } = require('../utils/socketService');

const getAllOrders = async (req, res, next) => {
  try {
    const orders = await Order.find()
      .populate('user', 'name email phone')
      .populate('technicianUser', 'name email phone lastLat lastLng technicianMeta')
      .sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {
    next(error);
  }
};

const updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const allowed = ['pending', 'assigned', 'en_route', 'in_progress', 'completed', 'cancelled'];
    if (!status || !allowed.includes(status)) {
      return res.status(400).json({ message: `Status must be one of: ${allowed.join(', ')}` });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    order.status = status;
    if (status === 'completed') order.completedAt = new Date();
    order.statusHistory.push({ status, note: 'Updated by admin', at: new Date() });
    await order.save();
    res.json(order);
  } catch (error) {
    next(error);
  }
};

const getStats = async (req, res, next) => {
  try {
    const [orders, users, services, technicians] = await Promise.all([
      Order.countDocuments(),
      User.countDocuments({ role: 'customer' }),
      Service.countDocuments(),
      User.countDocuments({ role: 'technician' }),
    ]);
    const admins = await User.countDocuments({ role: 'admin' });
    const pending = await Order.countDocuments({ status: 'pending' });
    const completed = await Order.countDocuments({ status: 'completed' });
    const inProgress = await Order.countDocuments({ status: 'in_progress' });
    const enRoute = await Order.countDocuments({ status: 'en_route' });
    const assigned = await Order.countDocuments({ status: 'assigned' });

    // Revenue stats
    const completedOrders = await Order.find({ status: 'completed' });
    const totalRevenue = completedOrders.reduce((sum, o) => sum + (o.total || 0), 0);
    const totalCommissions = completedOrders.reduce((sum, o) => sum + (o.total - (o.technicianEarning || 0)), 0);

    res.json({
      orders, users, services, technicians, admins,
      pending, completed, inProgress, enRoute, assigned,
      totalRevenue, totalCommissions,
    });
  } catch (error) {
    next(error);
  }
};

const assignTechnician = async (req, res, next) => {
  try {
    const { orderId, technicianId } = req.body;
    const order = await Order.findById(orderId);
    const tech = await User.findOne({ _id: technicianId, role: 'technician' });

    if (!order || !tech) {
      return res.status(404).json({ message: 'Order or Technician not found' });
    }

    const { technicianCut, defaultChecklist, pushStatusHistory } = require('../utils/orderHelpers');

    order.technicianUser = tech._id;
    order.technician = tech.name;
    order.status = 'assigned';
    order.dispatchStatus = 'offered';
    order.technicianEarning = technicianCut(order.total);
    order.checklist = defaultChecklist(order.issues);
    pushStatusHistory(order, 'assigned', `Admin assigned to ${tech.name}`);
    await order.save();

    emitNotification(tech._id.toString(), {
      type: 'order_assigned',
      title: 'New Job Assigned',
      message: `Admin has assigned you a new job: ${order.brand} ${order.model}`,
      orderId: order._id,
    });

    res.json({ success: true, order });
  } catch (error) {
    next(error);
  }
};

const getAllUsers = async (req, res, next) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    res.json(users);
  } catch (error) {
    next(error);
  }
};

// Get all technicians with full details
const getAllTechnicians = async (req, res, next) => {
  try {
    const technicians = await User.find({ role: 'technician' })
      .select('-password')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: technicians });
  } catch (error) {
    next(error);
  }
};

// Approve a technician's KYC
const approveTechnician = async (req, res, next) => {
  try {
    const tech = await User.findOne({ _id: req.params.id, role: 'technician' });
    if (!tech) {
      return res.status(404).json({ success: false, message: 'Technician not found' });
    }
    tech.isApproved = true;
    tech.accountStatus = 'active';
    if (tech.technicianMeta?.verification) {
      tech.technicianMeta.verification.status = 'verified';
      tech.technicianMeta.verification.aadhaarVerified = true;
      tech.technicianMeta.verification.verifiedAt = new Date();
      tech.technicianMeta.verification.rejectionReason = '';
    }
    tech.isOnline = true;
    await tech.save();

    emitNotification(tech._id.toString(), {
      type: 'kyc_approved',
      title: 'KYC Approved!',
      message: 'Your documents have been verified. You can now accept service requests.',
    });

    res.json({ success: true, message: 'Technician approved', data: tech });
  } catch (error) {
    next(error);
  }
};

// Reject a technician's KYC with reason
const rejectTechnician = async (req, res, next) => {
  try {
    const { reason } = req.body;
    if (!reason) {
      return res.status(400).json({ success: false, message: 'Rejection reason is required' });
    }

    const tech = await User.findOne({ _id: req.params.id, role: 'technician' });
    if (!tech) {
      return res.status(404).json({ success: false, message: 'Technician not found' });
    }

    tech.isApproved = false;
    tech.accountStatus = 'pending';
    if (tech.technicianMeta?.verification) {
      tech.technicianMeta.verification.status = 'rejected';
      tech.technicianMeta.verification.aadhaarVerified = false;
      tech.technicianMeta.verification.rejectionReason = reason;
      tech.technicianMeta.verification.rejectedAt = new Date();
    }
    tech.isOnline = false;
    await tech.save();

    emitNotification(tech._id.toString(), {
      type: 'kyc_rejected',
      title: 'KYC Rejected',
      message: `Your documents were rejected. Reason: ${reason}. Please resubmit.`,
      reason,
    });

    res.json({ success: true, message: 'Technician KYC rejected', data: tech });
  } catch (error) {
    next(error);
  }
};

// Suspend a technician
const suspendTechnician = async (req, res, next) => {
  try {
    const tech = await User.findOne({ _id: req.params.id, role: 'technician' });
    if (!tech) {
      return res.status(404).json({ success: false, message: 'Technician not found' });
    }
    tech.isApproved = false;
    tech.accountStatus = 'suspended';
    if (tech.technicianMeta?.verification) {
      tech.technicianMeta.verification.status = 'rejected';
    }
    tech.isOnline = false;
    await tech.save();

    emitNotification(tech._id.toString(), {
      type: 'account_suspended',
      title: 'Account Suspended',
      message: 'Your account has been suspended by admin.',
    });

    res.json({ success: true, message: 'Technician suspended', data: tech });
  } catch (error) {
    next(error);
  }
};

// ── Admin Monitoring Endpoints ──────────────────────────────────────

// Get active/live requests
const getActiveRequests = async (req, res, next) => {
  try {
    const activeOrders = await Order.find({
      status: { $in: ['pending', 'assigned', 'en_route', 'in_progress'] },
    })
      .populate('user', 'name email phone')
      .populate('technicianUser', 'name phone lastLat lastLng technicianMeta')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: activeOrders.length,
      data: activeOrders.map(order => ({
        _id: order._id,
        status: order.status,
        brand: order.brand,
        model: order.model,
        issues: order.issues,
        total: order.total,
        customerName: order.user?.name || 'N/A',
        customerPhone: order.user?.phone || order.customerPhone,
        technicianName: order.technicianUser?.name || 'Unassigned',
        technicianPhone: order.technicianUser?.phone || '',
        technicianLat: order.technicianUser?.lastLat,
        technicianLng: order.technicianUser?.lastLng,
        serviceAddress: order.serviceAddress,
        serviceLat: order.serviceLat,
        serviceLng: order.serviceLng,
        createdAt: order.createdAt,
        statusHistory: order.statusHistory,
      })),
    });
  } catch (error) {
    next(error);
  }
};

// Get all technician locations (live map data)
const getTechnicianLocations = async (req, res, next) => {
  try {
    const technicians = await User.find({
      role: 'technician',
      isApproved: true,
    }).select('name phone isOnline lastLat lastLng lastLocationUpdate technicianMeta');

    res.json({
      success: true,
      data: technicians.map(t => ({
        _id: t._id,
        name: t.name,
        phone: t.phone,
        isOnline: t.isOnline,
        lat: t.lastLat,
        lng: t.lastLng,
        lastUpdate: t.lastLocationUpdate,
        rating: t.technicianMeta?.rating,
        jobsDone: t.technicianMeta?.jobsDone,
        specialization: t.technicianMeta?.specialization,
      })),
    });
  } catch (error) {
    next(error);
  }
};

// Get customer bookings overview
const getCustomerBookings = async (req, res, next) => {
  try {
    const { customerId } = req.query;
    let query = {};
    if (customerId) query.user = customerId;

    const orders = await Order.find(query)
      .populate('user', 'name email phone')
      .populate('technicianUser', 'name phone')
      .sort({ createdAt: -1 })
      .limit(100);

    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

// Get payments and commissions overview
const getPaymentsOverview = async (req, res, next) => {
  try {
    const completedOrders = await Order.find({ status: 'completed' })
      .populate('user', 'name')
      .populate('technicianUser', 'name')
      .sort({ completedAt: -1 })
      .limit(100);

    const totalRevenue = completedOrders.reduce((sum, o) => sum + (o.total || 0), 0);
    const totalTechEarnings = completedOrders.reduce((sum, o) => sum + (o.technicianEarning || 0), 0);
    const platformCommission = totalRevenue - totalTechEarnings;

    res.json({
      success: true,
      summary: {
        totalRevenue,
        totalTechEarnings,
        platformCommission,
        completedCount: completedOrders.length,
      },
      data: completedOrders.map(o => ({
        _id: o._id,
        customerName: o.user?.name || 'N/A',
        technicianName: o.technicianUser?.name || 'N/A',
        total: o.total,
        technicianEarning: o.technicianEarning,
        platformFee: (o.total || 0) - (o.technicianEarning || 0),
        paymentStatus: o.paymentStatus,
        paymentMethod: o.paymentMethod,
        completedAt: o.completedAt,
      })),
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllOrders,
  updateOrderStatus,
  getStats,
  getAllUsers,
  assignTechnician,
  getAllTechnicians,
  approveTechnician,
  rejectTechnician,
  suspendTechnician,
  getActiveRequests,
  getTechnicianLocations,
  getCustomerBookings,
  getPaymentsOverview,
};
