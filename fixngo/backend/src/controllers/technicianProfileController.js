const User = require('../models/userModel');
const Order = require('../models/orderModel');
const Rating = require('../models/ratingModel');
const fs = require('fs');
const path = require('path');

const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Get technician public profile
const getTechnicianProfile = async (req, res, next) => {
  try {
    const { technicianId } = req.params;

    const technician = await User.findById(technicianId);

    if (!technician || technician.role !== 'technician') {
      return res.status(404).json({
        success: false,
        message: 'Technician not found',
      });
    }

    // Get ratings
    const ratings = await Rating.find({ technicianId });
    const averageRating =
      ratings.length > 0
        ? (ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length).toFixed(1)
        : 0;

    // Get completed jobs count
    const completedJobs = await Order.countDocuments({
      technicianUser: technicianId,
      status: 'completed',
    });

    res.json({
      success: true,
      data: {
        _id: technician._id,
        name: technician.name,
        phone: technician.phone,
        city: technician.city,
        address: technician.address,
        isOnline: technician.isOnline,
        profilePhoto: technician.profilePhoto || '',
        technicianMeta: {
          emoji: technician.technicianMeta?.emoji || '🛠️',
          rating: averageRating,
          experience: technician.technicianMeta?.experience || '',
          jobsDone: completedJobs,
          specialization: technician.technicianMeta?.specialization || [],
          verification: technician.technicianMeta?.verification || { status: 'unverified', aadhaarVerified: false },
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

// Update technician profile
const updateTechnicianProfile = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({
        success: false,
        message: 'Only technicians can update their profile',
      });
    }

    const { experience, specialization, emoji, documents, profilePhoto, bankDetails } = req.body;

    const technician = await User.findById(req.user._id);
    if (!technician) {
      return res.status(404).json({
        success: false,
        message: 'Technician not found',
      });
    }

    // Update fields
    if (experience) technician.technicianMeta.experience = experience;
    if (emoji) technician.technicianMeta.emoji = emoji;
    if (profilePhoto) technician.profilePhoto = profilePhoto;

    if (specialization && Array.isArray(specialization)) {
      technician.technicianMeta.specialization = specialization;
    }

    if (documents) {
      technician.technicianMeta.documents = {
        ...technician.technicianMeta.documents,
        ...documents,
      };

      const { aadharNumber, aadharFront, aadharBack } = documents;
      if (aadharNumber !== undefined) technician.technicianMeta.documents.aadharNumber = aadharNumber;
      if (aadharFront !== undefined) technician.technicianMeta.documents.aadharFront = aadharFront;
      if (aadharBack !== undefined) technician.technicianMeta.documents.aadharBack = aadharBack;

      if (aadharNumber || aadharFront || aadharBack) {
        technician.technicianMeta.verification = {
          ...(technician.technicianMeta.verification || {}),
          status: 'pending',
          aadhaarVerified: false,
        };
      }
    }

    if (bankDetails) {
      technician.technicianMeta.bankDetails = {
        ...technician.technicianMeta.bankDetails,
        ...bankDetails,
      };
    }

    await technician.save();

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        _id: technician._id,
        name: technician.name,
        email: technician.email,
        phone: technician.phone,
        city: technician.city,
        address: technician.address,
        profilePhoto: technician.profilePhoto || '',
        technicianMeta: technician.technicianMeta,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Upload technician profile photo
const updateTechnicianPhoto = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can update profile photo' });
    }

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Photo file is required' });
    }

    const technician = await User.findById(req.user._id);
    if (!technician) {
      return res.status(404).json({ success: false, message: 'Technician not found' });
    }

    const fileName = `profile_${req.user._id}_${Date.now()}_${req.file.originalname}`;
    const filePath = path.join(uploadDir, fileName);
    fs.renameSync(req.file.path, filePath);

    technician.profilePhoto = `/uploads/${fileName}`;
    await technician.save();

    res.json({
      success: true,
      message: 'Profile photo updated successfully',
      data: { profilePhoto: technician.profilePhoto },
    });
  } catch (error) {
    if (req.file) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (unlinkError) {
        console.error('Error deleting temp photo:', unlinkError);
      }
    }
    next(error);
  }
};

// Upload technician Aadhaar KYC details
const updateTechnicianKyc = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({ success: false, message: 'Only technicians can update KYC' });
    }

    const technician = await User.findById(req.user._id);
    if (!technician) {
      return res.status(404).json({ success: false, message: 'Technician not found' });
    }

    const { aadharNumber } = req.body;
    const frontFile = req.files?.aadharFront?.[0];
    const backFile = req.files?.aadharBack?.[0];

    if (!aadharNumber || !frontFile || !backFile) {
      return res.status(400).json({ success: false, message: 'Aadhaar number, front image, and back image are required' });
    }

    const frontName = `aadhaar_front_${req.user._id}_${Date.now()}_${frontFile.originalname}`;
    const backName = `aadhaar_back_${req.user._id}_${Date.now()}_${backFile.originalname}`;
    const frontPath = path.join(uploadDir, frontName);
    const backPath = path.join(uploadDir, backName);

    fs.renameSync(frontFile.path, frontPath);
    fs.renameSync(backFile.path, backPath);

    technician.technicianMeta.documents = {
      ...(technician.technicianMeta.documents || {}),
      aadharNumber,
      aadharFront: `/uploads/${frontName}`,
      aadharBack: `/uploads/${backName}`,
      aadhar: aadharNumber,
    };
    technician.technicianMeta.verification = {
      ...(technician.technicianMeta.verification || {}),
      status: 'pending',
      aadhaarVerified: false,
    };

    await technician.save();

    res.json({
      success: true,
      message: 'Aadhaar KYC updated successfully',
      data: {
        documents: technician.technicianMeta.documents,
        verification: technician.technicianMeta.verification,
      },
    });
  } catch (error) {
    if (req.files) {
      for (const key of ['aadharFront', 'aadharBack']) {
        const file = req.files?.[key]?.[0];
        if (file) {
          try {
            fs.unlinkSync(file.path);
          } catch (unlinkError) {
            console.error('Error deleting temp KYC file:', unlinkError);
          }
        }
      }
    }
    next(error);
  }
};

// Update technician location
const updateTechnicianLocation = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({
        success: false,
        message: 'Only technicians can update location',
      });
    }

    const { lat, lng, isOnline } = req.body;

    if (lat === undefined || lng === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required',
      });
    }

    const technician = await User.findByIdAndUpdate(
      req.user._id,
      {
        lastLat: parseFloat(lat),
        lastLng: parseFloat(lng),
        ...(isOnline !== undefined && { isOnline }),
      },
      { new: true }
    );

    res.json({
      success: true,
      message: 'Location updated',
      data: {
        lastLat: technician.lastLat,
        lastLng: technician.lastLng,
        isOnline: technician.isOnline,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get technician availability status
const getTechnicianStatus = async (req, res, next) => {
  try {
    const technician = await User.findById(req.params.technicianId);

    if (!technician || technician.role !== 'technician') {
      return res.status(404).json({
        success: false,
        message: 'Technician not found',
      });
    }

    res.json({
      success: true,
      data: {
        _id: technician._id,
        name: technician.name,
        isOnline: technician.isOnline,
        lastLat: technician.lastLat,
        lastLng: technician.lastLng,
        lastUpdated: technician.updatedAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get technician stats
const getTechnicianStats = async (req, res, next) => {
  try {
    if (req.user.role !== 'technician') {
      return res.status(403).json({
        success: false,
        message: 'Only technicians can access their stats',
      });
    }

    const technician = await User.findById(req.user._id);

    // Get various stats
    const completedOrders = await Order.countDocuments({
      technicianUser: req.user._id,
      status: 'completed',
    });

    const pendingOrders = await Order.countDocuments({
      technicianUser: req.user._id,
      status: { $in: ['pending', 'assigned', 'in_progress'] },
    });

    const ratings = await Rating.find({ technicianId: req.user._id });

    const averageRating =
      ratings.length > 0
        ? (ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length).toFixed(1)
        : 0;

    const totalEarnings = await Order.aggregate([
      {
        $match: {
          technicianUser: req.user._id,
          status: 'completed',
        },
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$technicianEarning' },
        },
      },
    ]);

    res.json({
      success: true,
      data: {
        completedOrders,
        pendingOrders,
        averageRating: parseFloat(averageRating),
        totalRatings: ratings.length,
        totalEarnings: totalEarnings[0]?.total || 0,
        pendingEarnings: technician.technicianMeta?.pendingEarnings || 0,
        walletBalance: technician.technicianMeta?.walletBalance || 0,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getTechnicianProfile,
  updateTechnicianProfile,
  updateTechnicianPhoto,
  updateTechnicianKyc,
  updateTechnicianLocation,
  getTechnicianStatus,
  getTechnicianStats,
};
