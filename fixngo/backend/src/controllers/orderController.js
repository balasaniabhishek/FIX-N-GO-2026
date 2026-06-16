const Order = require('../models/orderModel');
const User = require('../models/userModel');
const { defaultChecklist, technicianCut, pushStatusHistory, assignServiceCoords, formatOrderForTech, haversineKm } = require('../utils/orderHelpers');
const { emitNotification, emitOrderUpdate } = require('../utils/socketService');

// Broadcast order to nearby technicians within configurable radius
const broadcastToTechnicians = async (order, radius = 5) => {
  try {
    const nearbyTechs = await User.find({
      role: 'technician',
      isApproved: true,
      isOnline: true,
      location: {
        $nearSphere: {
          $geometry: {
            type: 'Point',
            coordinates: [order.serviceLng, order.serviceLat],
          },
          $maxDistance: radius * 1000,
        },
      },
    });

    if (nearbyTechs.length === 0) return null;

    order.dispatchStatus = 'broadcasting';
    order.searchRadius = radius;
    order.broadcastedTo = nearbyTechs.map(t => t._id);
    await order.save();

    nearbyTechs.forEach(tech => {
      const distance = haversineKm(tech.lastLat, tech.lastLng, order.serviceLat, order.serviceLng);
      emitNotification(tech._id.toString(), {
        type: 'new_order_broadcast',
        title: 'New Job Available!',
        message: `${order.brand} ${order.model} - ${order.issues[0] || 'Repair'} (${distance.toFixed(1)} km away)`,
        orderId: order._id,
        distance: distance.toFixed(1),
        serviceAddress: order.serviceAddress,
        estimatedEarning: technicianCut(order.total),
      });
    });

    return nearbyTechs;
  } catch (error) {
    console.error('Broadcast error:', error);
    return null;
  }
};

const formatOrderForCustomer = (order) => {
  const tech = order.technicianUser;
  return {
    ...order.toObject(),
    technicianName: order.technician || tech?.name || '',
    technicianRating: tech?.technicianMeta?.rating,
    technicianPhone: tech?.phone || '',
    technicianLat: tech?.lastLat || null,
    technicianLng: tech?.lastLng || null,
    technicianSpecialization: tech?.technicianMeta?.specialization || [],
    technicianJobsDone: tech?.technicianMeta?.jobsDone || 0,
    statusHistory: order.statusHistory || [],
  };
};

// Get all orders for a customer
const getOrders = async (req, res, next) => {
  try {
    const { status, sortBy = 'createdAt' } = req.query;
    let query = { user: req.user._id };

    if (status) {
      query.status = status;
    }

    const orders = await Order.find(query)
      .populate('technicianUser', 'name phone technicianMeta lastLat lastLng')
      .sort({ [sortBy]: -1 });

    res.json({
      success: true,
      count: orders.length,
      data: orders.map(formatOrderForCustomer),
    });
  } catch (error) {
    next(error);
  }
};

// Create a new order
const createOrder = async (req, res, next) => {
  try {
    const {
      brand,
      model,
      issues,
      total,
      technician,
      customerPhone,
      serviceAddress,
      city,
      pincode,
      serviceLat,
      serviceLng,
      description,
      estimatedDateTime,
      searchRadius,
    } = req.body;

    if (!brand || !model || !issues || issues.length === 0 || !total) {
      return res.status(400).json({ success: false, message: 'Order data is incomplete' });
    }

    // Check for conflicting orders
    const conflictingOrder = await Order.findOne({
      user: req.user._id,
      status: { $in: ['pending', 'assigned', 'en_route', 'in_progress'] },
    });

    if (conflictingOrder) {
      return res.status(400).json({
        success: false,
        message: 'You have an active order. Please complete or cancel it before creating a new one.',
      });
    }

    const order = await Order.create({
      user: req.user._id,
      brand,
      model,
      issues,
      total,
      description: description || '',
      estimatedDateTime: estimatedDateTime || null,
      status: 'pending',
      technician: technician || '',
      customerPhone: customerPhone || req.user.phone || '',
      serviceAddress: serviceAddress || req.user.address || '',
      city: city || req.user.city || '',
      pincode: pincode || req.user.pincode || '',
      searchRadius: searchRadius || 5,
      statusHistory: [{ status: 'pending', note: 'Order placed', at: new Date() }],
    });

    // Set service coordinates
    if (serviceLat != null && serviceLng != null) {
      order.serviceLat = Number(serviceLat);
      order.serviceLng = Number(serviceLng);
    } else {
      assignServiceCoords(order, `${req.user._id}-${Date.now()}`);
    }

    order.location = {
      type: 'Point',
      coordinates: [order.serviceLng, order.serviceLat],
    };

    await order.save();

    // Broadcast to nearby technicians with configurable radius (5, 10, or 15 km)
    const radius = searchRadius || 5;
    const techs = await broadcastToTechnicians(order, radius);

    // Notify customer about search status
    emitNotification(req.user._id.toString(), {
      type: 'order_created',
      title: 'Request Sent!',
      message: techs
        ? `Searching for technicians within ${radius} km. ${techs.length} technician(s) notified.`
        : 'Order placed. Searching for available technicians...',
      orderId: order._id,
      status: 'pending',
    });

    const populated = await Order.findById(order._id).populate(
      'technicianUser',
      'name phone technicianMeta lastLat lastLng'
    );

    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: formatOrderForCustomer(populated),
    });
  } catch (error) {
    next(error);
  }
};

// Get order by ID
const getOrderById = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id).populate(
      'technicianUser',
      'name phone technicianMeta lastLat lastLng'
    );

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      if (order.technicianUser?._id?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ success: false, message: 'Not authorized' });
      }
    }

    res.json({
      success: true,
      data: formatOrderForCustomer(order),
    });
  } catch (error) {
    next(error);
  }
};

// Technician accepts order (Atomic First-Accept-Wins like Rapido)
const acceptOrder = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can accept orders' });
    }

    if (!req.user.isApproved) {
      return res.status(403).json({ success: false, message: 'Your KYC is not approved yet' });
    }

    // Atomic update: only succeed if status is still 'pending'
    const order = await Order.findOneAndUpdate(
      { _id: req.params.id, status: 'pending' },
      {
        $set: {
          status: 'assigned',
          dispatchStatus: 'accepted',
          technicianUser: req.user._id,
          technician: req.user.name,
          technicianEarning: 0,
        },
      },
      { new: true }
    );

    if (!order) {
      return res.status(400).json({ success: false, message: 'Job is no longer available or already accepted.' });
    }

    // Generate checklist and calculate earnings
    order.checklist = defaultChecklist(order.issues);
    order.technicianEarning = technicianCut(order.total);
    pushStatusHistory(order, 'assigned', `Accepted by ${req.user.name}`);
    await order.save();

    // Update technician's job count
    await User.findByIdAndUpdate(req.user._id, { $inc: { 'technicianMeta.jobsDone': 1 } });

    // Calculate ETA based on distance
    let eta = null;
    if (req.user.lastLat && req.user.lastLng && order.serviceLat && order.serviceLng) {
      const distance = haversineKm(req.user.lastLat, req.user.lastLng, order.serviceLat, order.serviceLng);
      eta = Math.ceil(distance * 3); // ~3 min per km estimate
    }

    // Notify customer: technician accepted with details
    emitNotification(order.user.toString(), {
      type: 'technician_accepted',
      title: 'Technician Assigned!',
      message: `${req.user.name} has accepted your request and is on the way.`,
      orderId: order._id,
      status: 'assigned',
      technician: {
        name: req.user.name,
        phone: req.user.phone,
        rating: req.user.technicianMeta?.rating || 4.8,
        jobsDone: req.user.technicianMeta?.jobsDone || 0,
        specialization: req.user.technicianMeta?.specialization || [],
        lat: req.user.lastLat,
        lng: req.user.lastLng,
      },
      eta: eta ? `${eta} mins` : 'Calculating...',
    });

    // Broadcast order update to admin
    emitOrderUpdate(order._id.toString(), {
      status: 'assigned',
      technicianName: req.user.name,
    });

    const populated = await Order.findById(order._id).populate('technicianUser', 'name phone technicianMeta lastLat lastLng');

    res.json({
      success: true,
      message: 'Order accepted successfully',
      data: formatOrderForTech(populated, req.user),
    });
  } catch (error) {
    next(error);
  }
};

// Technician rejects/declines order
const rejectOrder = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can reject orders' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.status !== 'pending' && order.status !== 'assigned') {
      return res.status(400).json({ success: false, message: 'Order is not available for rejection' });
    }

    // If this technician was assigned, reset
    if (order.technicianUser?.toString() === req.user._id.toString()) {
      order.status = 'pending';
      order.dispatchStatus = 'declined';
      order.technicianUser = null;
      order.technician = '';
      order.checklist = [];
      pushStatusHistory(order, 'pending', `Declined by ${req.user.name}`);
      await order.save();

      // Re-broadcast to other nearby technicians
      await broadcastToTechnicians(order, order.searchRadius || 5);
    }

    res.json({
      success: true,
      message: 'Order rejected successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Technician marks en_route (on the way)
const startEnRoute = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can update this status' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.technicianUser?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (order.status !== 'assigned') {
      return res.status(400).json({ success: false, message: 'Order must be in assigned status' });
    }

    order.status = 'en_route';
    pushStatusHistory(order, 'en_route', 'Technician on the way');
    await order.save();

    // Calculate ETA
    let eta = null;
    if (req.user.lastLat && req.user.lastLng && order.serviceLat && order.serviceLng) {
      const distance = haversineKm(req.user.lastLat, req.user.lastLng, order.serviceLat, order.serviceLng);
      eta = Math.ceil(distance * 3);
    }

    // Notify customer
    emitNotification(order.user.toString(), {
      type: 'technician_en_route',
      title: 'Technician On The Way!',
      message: `${req.user.name} is heading to your location.${eta ? ` ETA: ~${eta} mins` : ''}`,
      orderId: order._id,
      status: 'en_route',
      technicianLat: req.user.lastLat,
      technicianLng: req.user.lastLng,
      eta: eta ? `${eta} mins` : null,
    });

    emitOrderUpdate(order._id.toString(), { status: 'en_route' });

    res.json({
      success: true,
      message: 'Status updated to en_route',
      data: formatOrderForTech(order, req.user),
    });
  } catch (error) {
    next(error);
  }
};

// Technician starts service
const startService = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can start service' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.technicianUser?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (order.status !== 'assigned' && order.status !== 'en_route') {
      return res.status(400).json({ success: false, message: 'Order must be assigned or en_route to start service' });
    }

    order.status = 'in_progress';
    // Generate 4-digit OTP for service completion
    order.completionOtp = Math.floor(1000 + Math.random() * 9000).toString();
    pushStatusHistory(order, 'in_progress', 'Service started');
    await order.save();

    // Notify customer
    emitNotification(order.user.toString(), {
      type: 'service_started',
      title: 'Service Started!',
      message: `${req.user.name} has begun the repair. You'll receive a completion OTP when done.`,
      orderId: order._id,
      status: 'in_progress',
    });

    emitOrderUpdate(order._id.toString(), { status: 'in_progress' });

    res.json({
      success: true,
      message: 'Service started',
      data: {
        ...formatOrderForTech(order, req.user),
        completionOtp: order.completionOtp,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Technician completes order (requires OTP from customer)
const completeOrder = async (req, res, next) => {
  try {
    const { otp } = req.body;

    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    if (req.user.role !== 'technician' || order.technicianUser?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized to complete this order' });
    }

    if (order.status !== 'in_progress') {
      return res.status(400).json({ success: false, message: 'Order is not in progress' });
    }

    if (!otp || order.completionOtp !== otp) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    order.status = 'completed';
    order.completedAt = new Date();
    order.paymentStatus = 'pending';
    pushStatusHistory(order, 'completed', 'Service completed - awaiting payment');
    await order.save();

    // Update technician earnings
    await User.findByIdAndUpdate(req.user._id, {
      $inc: {
        'technicianMeta.totalEarnings': order.technicianEarning,
        'technicianMeta.pendingEarnings': order.technicianEarning,
      },
    });

    // Notify customer to make payment
    emitNotification(order.user.toString(), {
      type: 'service_completed',
      title: 'Service Completed!',
      message: 'Your repair is complete. Please make the payment.',
      orderId: order._id,
      status: 'completed',
      amount: order.total,
    });

    emitOrderUpdate(order._id.toString(), { status: 'completed' });

    res.json({
      success: true,
      message: 'Order completed successfully',
      data: formatOrderForTech(order, req.user),
    });
  } catch (error) {
    next(error);
  }
};

// Update order status (generic)
const updateOrderStatus = async (req, res, next) => {
  try {
    const { status, note } = req.body;
    const validStatuses = ['pending', 'assigned', 'en_route', 'in_progress', 'completed', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: `Invalid status: ${status}` });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (req.user.role === 'customer' && order.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    if (req.user.role === 'technician' && order.technicianUser?.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    // Validate status transition
    const statusFlow = {
      pending: ['assigned', 'cancelled'],
      assigned: ['en_route', 'in_progress', 'pending', 'cancelled'],
      en_route: ['in_progress', 'cancelled'],
      in_progress: ['completed', 'cancelled'],
      completed: [],
      cancelled: [],
    };

    if (!statusFlow[order.status]?.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot transition from ${order.status} to ${status}`,
      });
    }

    order.status = status;
    if (status === 'completed') {
      order.completedAt = new Date();
    }

    pushStatusHistory(order, status, note || '');
    await order.save();

    // Broadcast status update to all parties
    emitOrderUpdate(order._id.toString(), { status, note });

    // Notify relevant parties
    if (order.technicianUser) {
      emitNotification(order.technicianUser.toString(), {
        type: 'order_status_update',
        title: 'Order Updated',
        message: `Order status: ${status}`,
        orderId: order._id,
        status,
      });
    }
    emitNotification(order.user.toString(), {
      type: 'order_status_update',
      title: 'Order Updated',
      message: `Your order status: ${status}`,
      orderId: order._id,
      status,
    });

    res.json({
      success: true,
      message: 'Order status updated',
      data: formatOrderForCustomer(order),
    });
  } catch (error) {
    next(error);
  }
};

// Get available orders for technician (nearby, configurable radius)
const getAvailableOrders = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can access this endpoint' });
    }

    if (!req.user.isApproved) {
      return res.status(403).json({ success: false, message: 'Your KYC is not approved yet' });
    }

    const { radius = 15 } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = 10;
    const skip = (page - 1) * limit;

    const techLat = req.user.lastLat;
    const techLng = req.user.lastLng;

    let orders;
    if (techLat != null && techLng != null) {
      orders = await Order.find({ status: 'pending' })
        .populate('user', 'name phone')
        .sort({ createdAt: -1 });

      orders = orders
        .map((order) => {
          const distance = haversineKm(techLat, techLng, order.serviceLat, order.serviceLng);
          return { order, distance };
        })
        .filter(({ distance }) => distance <= Number(radius))
        .sort((a, b) => a.distance - b.distance)
        .slice(skip, skip + limit)
        .map(({ order, distance }) => ({
          ...formatOrderForTech(order, req.user),
          distanceKm: distance.toFixed(1),
          estimatedEta: `${Math.ceil(distance * 3)} mins`,
        }));
    } else {
      orders = await Order.find({ status: 'pending' })
        .populate('user', 'name phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

      orders = orders.map((order) => formatOrderForTech(order, req.user));
    }

    res.json({
      success: true,
      count: orders.length,
      page,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
};

// Get technician's active orders
const getTechnicianOrders = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can access this endpoint' });
    }

    const { status } = req.query;
    let query = { technicianUser: req.user._id };
    if (status) query.status = status;

    const orders = await Order.find(query)
      .populate('user', 'name phone address')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: orders.length,
      data: orders.map((order) => formatOrderForTech(order, req.user)),
    });
  } catch (error) {
    next(error);
  }
};

// Get live tracking info for a customer
const getTrackingInfo = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('technicianUser', 'name phone technicianMeta lastLat lastLng lastLocationUpdate');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    if (order.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const tech = order.technicianUser;
    let eta = null;
    let distance = null;

    if (tech?.lastLat && tech?.lastLng && order.serviceLat && order.serviceLng) {
      distance = haversineKm(tech.lastLat, tech.lastLng, order.serviceLat, order.serviceLng);
      eta = Math.ceil(distance * 3);
    }

    res.json({
      success: true,
      data: {
        orderId: order._id,
        status: order.status,
        technician: tech ? {
          name: tech.name,
          phone: tech.phone,
          rating: tech.technicianMeta?.rating,
          lat: tech.lastLat,
          lng: tech.lastLng,
          lastUpdate: tech.lastLocationUpdate,
        } : null,
        serviceLocation: {
          lat: order.serviceLat,
          lng: order.serviceLng,
          address: order.serviceAddress,
        },
        distance: distance ? `${distance.toFixed(1)} km` : null,
        eta: eta ? `${eta} mins` : null,
        statusHistory: order.statusHistory,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getOrders,
  createOrder,
  getOrderById,
  acceptOrder,
  rejectOrder,
  startEnRoute,
  startService,
  completeOrder,
  updateOrderStatus,
  getAvailableOrders,
  getTechnicianOrders,
  getTrackingInfo,
};
