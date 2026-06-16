const Order = require('../models/orderModel');
const User = require('../models/userModel');
const Withdrawal = require('../models/withdrawalModel');
const {
  defaultChecklist,
  technicianCut,
  pushStatusHistory,
  formatOrderForTech,
} = require('../utils/orderHelpers');

const getTechnicianProfile = async (req, res, next) => {
  try {
    const user = req.user;
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      address: user.address,
      city: user.city,
      pincode: user.pincode,
      isOnline: user.isOnline,
      ...user.technicianMeta?.toObject?.() ? user.technicianMeta.toObject() : user.technicianMeta,
      rating: user.technicianMeta?.rating ?? 4.8,
      jobsDone: user.technicianMeta?.jobsDone ?? 0,
      walletBalance: user.technicianMeta?.walletBalance ?? 0,
      pendingEarnings: user.technicianMeta?.pendingEarnings ?? 0,
      emoji: user.technicianMeta?.emoji ?? '🛠️',
    });
  } catch (error) {
    next(error);
  }
};

const updateTechnicianProfile = async (req, res, next) => {
  try {
    const { name, phone, address, city, pincode, emoji, experience, bankDetails } = req.body;
    const user = await User.findById(req.user._id);
    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    if (address !== undefined) user.address = address;
    if (city !== undefined) user.city = city;
    if (pincode !== undefined) user.pincode = pincode;
    if (emoji) user.technicianMeta.emoji = emoji;
    if (experience) user.technicianMeta.experience = experience;
    if (bankDetails) {
      user.technicianMeta.bankDetails = {
        ...user.technicianMeta.bankDetails,
        ...bankDetails,
      };
    }
    await user.save();
    req.user = user;
    return getTechnicianProfile(req, res, next);
  } catch (error) {
    next(error);
  }
};

const setOnlineStatus = async (req, res, next) => {
  try {
    const { isOnline } = req.body;
    if (typeof isOnline !== 'boolean') {
      return res.status(400).json({ message: 'isOnline must be a boolean' });
    }
    req.user.isOnline = isOnline;
    await req.user.save();
    res.json({ isOnline: req.user.isOnline });
  } catch (error) {
    next(error);
  }
};

const orderBelongsToTech = (order, techId) =>
  order.technicianUser && order.technicianUser.toString() === techId.toString();

const getJobs = async (req, res, next) => {
  try {
    const { status = 'active' } = req.query;
    let filter = { technicianUser: req.user._id };

    if (status === 'active') {
      filter.status = { $in: ['assigned', 'in_progress'] };
      filter.dispatchStatus = 'accepted';
    } else if (status === 'completed') {
      filter.status = 'completed';
    } else if (status === 'cancelled') {
      filter.status = 'cancelled';
    }

    const orders = await Order.find(filter)
      .populate('user', 'name phone')
      .sort({ updatedAt: -1 });

    res.json(orders.map((o) => formatOrderForTech(o, req.user)));
  } catch (error) {
    next(error);
  }
};

const getIncomingOffers = async (req, res, next) => {
  try {
    const orders = await Order.find({
      technicianUser: req.user._id,
      dispatchStatus: 'offered',
      status: { $in: ['pending', 'assigned'] },
    })
      .populate('user', 'name phone')
      .sort({ createdAt: -1 });

    res.json(orders.map((o) => formatOrderForTech(o, req.user)));
  } catch (error) {
    next(error);
  }
};

const getJobById = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id).populate('user', 'name phone');
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }
    res.json(formatOrderForTech(order, req.user));
  } catch (error) {
    next(error);
  }
};

const updateLocation = async (req, res, next) => {
  try {
    const { lat, lng } = req.body;
    if (lat == null || lng == null) {
      return res.status(400).json({ message: 'lat and lng are required' });
    }
    req.user.lastLat = Number(lat);
    req.user.lastLng = Number(lng);
    req.user.location = {
      type: 'Point',
      coordinates: [Number(lng), Number(lat)],
    };
    await req.user.save();
    res.json({
      lastLat: req.user.lastLat,
      lastLng: req.user.lastLng,
      location: req.user.location,
    });
  } catch (error) {
    next(error);
  }
};

const acceptJob = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }
    if (order.dispatchStatus !== 'offered') {
      return res.status(400).json({ message: 'Job is not available to accept' });
    }

    order.dispatchStatus = 'accepted';
    order.status = 'assigned';
    order.technicianEarning = technicianCut(order.total);
    order.checklist = defaultChecklist(order.issues);
    pushStatusHistory(order, 'assigned', 'Technician accepted job');
    await order.save();

    const user = await User.findById(req.user._id);
    user.technicianMeta.pendingEarnings =
      (user.technicianMeta.pendingEarnings || 0) + order.technicianEarning;
    await user.save();

    const populated = await Order.findById(order._id).populate('user', 'name phone');
    res.json(formatOrderForTech(populated, req.user));
  } catch (error) {
    next(error);
  }
};

const declineJob = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }

    order.dispatchStatus = 'declined';
    order.technicianUser = null;
    order.technician = '';
    order.status = 'pending';
    pushStatusHistory(order, 'pending', 'Technician declined job');
    await order.save();
    res.json({ message: 'Job declined' });
  } catch (error) {
    next(error);
  }
};

const startJob = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }

    order.status = 'in_progress';
    pushStatusHistory(order, 'in_progress', 'Technician started job');
    await order.save();

    const populated = await Order.findById(order._id).populate('user', 'name phone');
    res.json(formatOrderForTech(populated, req.user));
  } catch (error) {
    next(error);
  }
};

const updateChecklist = async (req, res, next) => {
  try {
    const { checklist } = req.body;
    if (!Array.isArray(checklist)) {
      return res.status(400).json({ message: 'checklist array required' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }

    order.checklist = checklist;
    await order.save();
    res.json({ checklist: order.checklist });
  } catch (error) {
    next(error);
  }
};

const completeJob = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }

    const allDone = (order.checklist || []).every((item) => item.done);
    if (!allDone && order.checklist?.length) {
      return res.status(400).json({ message: 'Complete all checklist items first' });
    }

    order.status = 'completed';
    pushStatusHistory(order, 'completed', 'Job completed');
    await order.save();

    const user = await User.findById(req.user._id);
    user.technicianMeta.jobsDone = (user.technicianMeta.jobsDone || 0) + 1;
    await user.save();

    const populated = await Order.findById(order._id).populate('user', 'name phone');
    res.json(formatOrderForTech(populated, req.user));
  } catch (error) {
    next(error);
  }
};

const collectPayment = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: 'Job not found' });
    if (!orderBelongsToTech(order, req.user._id)) {
      return res.status(403).json({ message: 'Not your job' });
    }

    order.paymentStatus = 'collected';
    if (order.status !== 'completed') {
      order.status = 'completed';
      pushStatusHistory(order, 'completed', 'Payment collected');
    }

    const earning = order.technicianEarning || technicianCut(order.total);
    order.technicianEarning = earning;
    await order.save();

    const user = await User.findById(req.user._id);
    user.technicianMeta.walletBalance = (user.technicianMeta.walletBalance || 0) + earning;
    user.technicianMeta.pendingEarnings = Math.max(
      0,
      (user.technicianMeta.pendingEarnings || 0) - earning
    );
    user.technicianMeta.jobsDone = (user.technicianMeta.jobsDone || 0) + 1;
    await user.save();

    res.json({
      paymentStatus: order.paymentStatus,
      walletBalance: user.technicianMeta.walletBalance,
      earning,
    });
  } catch (error) {
    next(error);
  }
};

const getWallet = async (req, res, next) => {
  try {
    const user = req.user;
    const completed = await Order.find({
      technicianUser: user._id,
      status: 'completed',
    }).sort({ updatedAt: -1 });

    const withdrawals = await Withdrawal.find({ technician: user._id }).sort({ createdAt: -1 });

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEarnings = completed
      .filter((o) => o.updatedAt >= today && o.paymentStatus === 'collected')
      .reduce((sum, o) => sum + (o.technicianEarning || technicianCut(o.total)), 0);

    const transactions = [
      ...completed.map((o) => ({
        type: 'earning',
        _id: o._id,
        jobId: `#${o._id.toString().slice(-4).toUpperCase()}`,
        title: o.issues[0] || 'Service',
        amount: o.technicianEarning || technicianCut(o.total),
        status: o.paymentStatus === 'collected' ? 'completed' : 'pending',
        date: o.updatedAt,
      })),
      ...withdrawals.map((w) => ({
        type: 'withdrawal',
        _id: w._id,
        jobId: 'Withdrawal',
        title: 'Bank Transfer',
        amount: -w.amount,
        status: w.status,
        date: w.createdAt,
      })),
    ].sort((a, b) => b.date - a.date);

    res.json({
      walletBalance: user.technicianMeta?.walletBalance ?? 0,
      pendingEarnings: user.technicianMeta?.pendingEarnings ?? 0,
      todayEarnings,
      jobsDone: user.technicianMeta?.jobsDone ?? 0,
      transactions: transactions.slice(0, 50),
    });
  } catch (error) {
    next(error);
  }
};

const getDashboard = async (req, res, next) => {
  try {
    const user = req.user;
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const activeCount = await Order.countDocuments({
      technicianUser: user._id,
      status: { $in: ['assigned', 'in_progress'] },
      dispatchStatus: 'accepted',
    });
    const completedToday = await Order.countDocuments({
      technicianUser: user._id,
      status: 'completed',
      updatedAt: { $gte: startOfDay },
    });
    const todayOrders = await Order.find({
      technicianUser: user._id,
      status: 'completed',
      paymentStatus: 'collected',
      updatedAt: { $gte: startOfDay },
    });
    const todayEarnings = todayOrders.reduce(
      (sum, o) => sum + (o.technicianEarning || technicianCut(o.total)),
      0
    );

    res.json({
      _id: user._id,
      name: user.name,
      isOnline: user.isOnline,
      rating: user.technicianMeta?.rating ?? 4.8,
      jobsDone: user.technicianMeta?.jobsDone ?? 0,
      activeJobs: activeCount,
      completedToday,
      todayEarnings,
      pendingEarnings: user.technicianMeta?.pendingEarnings ?? 0,
      walletBalance: user.technicianMeta?.walletBalance ?? 0,
      verification: user.technicianMeta?.verification ?? { status: 'unverified' }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getTechnicianProfile,
  updateTechnicianProfile,
  updateLocation,
  setOnlineStatus,
  getJobs,
  getIncomingOffers,
  getJobById,
  acceptJob,
  declineJob,
  startJob,
  updateChecklist,
  completeJob,
  collectPayment,
  getWallet,
  getDashboard,
};
