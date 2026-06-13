const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const User = require('../models/userModel');
const OTP = require('../models/otpModel');
const PasswordReset = require('../models/passwordResetModel');
const RefreshToken = require('../models/refreshTokenModel');
const generateToken = require('../utils/generateToken');
const { sendPasswordResetEmail, generateOTP, generateResetToken } = require('../utils/emailService');
const { sendOtpSms, generateOTP: generateOtpSms } = require('../utils/smsService');

const normalizeEmail = (value) => String(value || '').trim().toLowerCase();
const escapeRegex = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const emailSelector = (emailNorm) => ({ email: new RegExp(`^${escapeRegex(emailNorm)}$`, 'i') });

const userResponse = (user, token, refreshToken) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
  accountStatus: user.accountStatus || 'active',
  isApproved: user.isApproved || false,
  phone: user.phone || '',
  address: user.address || '',
  city: user.city || '',
  pincode: user.pincode || '',
  profilePhoto: user.profilePhoto || '',
  isOnline: user.isOnline || false,
  technicianMeta: user.role === 'technician' ? user.technicianMeta || {} : undefined,
  customerMeta: user.role === 'customer' ? user.customerMeta || {} : undefined,
  adminMeta: user.role === 'admin' ? user.adminMeta || {} : undefined,
  token: token || generateToken(user._id, user.role),
  refreshToken: refreshToken || '',
});

const registerUser = async (req, res, next) => {
  try {
    const {
      name,
      email,
      password,
      role,
      phone,
      address,
      city,
      pincode,
      profilePhoto,
      aadhaarNumber,
      aadhaarFront,
      aadhaarBack,
    } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    const emailNorm = normalizeEmail(email);
    const allowedRoles = ['customer', 'technician'];
    const userRole = allowedRoles.includes(role) ? role : 'customer';

    const existingUser = await User.findOne(emailSelector(emailNorm));
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const user = await User.create({
      name,
      email: emailNorm,
      password: hashedPassword,
      role: userRole,
      phone: phone || '',
      address: address || '',
      city: city || 'Hyderabad',
      pincode: pincode || '',
      profilePhoto: profilePhoto || '',
      accountStatus: userRole === 'technician' ? 'pending' : 'active',
      isApproved: userRole !== 'technician',
      isOnline: userRole === 'technician',
      customerMeta:
        userRole === 'customer'
          ? {
              savedAddresses: [],
              favoriteServices: [],
              serviceCount: 0,
              lastServiceAt: null,
              preferredContact: 'phone',
            }
          : undefined,
      technicianMeta:
        userRole === 'technician'
          ? {
              emoji: '🛠️',
              rating: 4.8,
              experience: '5+ years',
              jobsDone: 0,
              documents: {
                aadharNumber: aadhaarNumber || '',
                aadharFront: aadhaarFront || '',
                aadharBack: aadhaarBack || '',
              },
              verification: {
                status: aadhaarNumber || aadhaarFront || aadhaarBack ? 'pending' : 'unverified',
                aadhaarVerified: false,
              },
            }
          : undefined,
    });

    const accessToken = generateToken(user._id, user.role);
    const refreshToken = await issueRefreshToken(user._id);
    res.status(201).json(userResponse(user, accessToken, refreshToken));
  } catch (error) {
    // Handle MongoDB duplicate key error (race condition on unique email index)
    if (error.code === 11000) {
      return res.status(409).json({ message: 'User already exists' });
    }
    next(error);
  }
};

const loginUser = async (req, res, next) => {
  try {
    const { email, password, role } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const emailNorm = normalizeEmail(email);
    const user = await User.findOne(emailSelector(emailNorm));
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (role && user.role !== role) {
      return res.status(403).json({ message: `This account is not a ${role}` });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const accessToken = generateToken(user._id, user.role);
    const refreshToken = await issueRefreshToken(user._id);
    res.json(userResponse(user, accessToken, refreshToken));
  } catch (error) {
    next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: 'User not found' });
    }

    res.json({
      _id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      accountStatus: req.user.accountStatus || 'active',
      isApproved: req.user.isApproved || false,
      phone: req.user.phone || '',
      address: req.user.address || '',
      city: req.user.city || '',
      pincode: req.user.pincode || '',
      profilePhoto: req.user.profilePhoto || '',
      customerMeta: req.user.role === 'customer' ? req.user.customerMeta || {} : undefined,
      technicianMeta: req.user.role === 'technician' ? req.user.technicianMeta || {} : undefined,
      adminMeta: req.user.role === 'admin' ? req.user.adminMeta || {} : undefined,
    });
  } catch (error) {
    next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { name, phone, address, city, pincode, profilePhoto } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (name) user.name = name;
    if (phone !== undefined) user.phone = phone;
    if (address !== undefined) user.address = address;
    if (city !== undefined) user.city = city;
    if (pincode !== undefined) user.pincode = pincode;
    if (profilePhoto !== undefined) user.profilePhoto = profilePhoto;
    await user.save();

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      address: user.address,
      city: user.city,
      pincode: user.pincode,
      profilePhoto: user.profilePhoto || '',
      accountStatus: user.accountStatus || 'active',
      isApproved: user.isApproved || false,
    });
  } catch (error) {
    next(error);
  }
};

// PHASE 1: PASSWORD RESET ENDPOINTS
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    const emailNorm = normalizeEmail(email);
    const user = await User.findOne(emailSelector(emailNorm));
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Generate OTP and reset token
    const otp = generateOTP();
    const token = generateResetToken();

    // Store reset token in DB
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    await PasswordReset.create({
      userId: user._id,
      email: user.email,
      token,
      otp,
      expiresAt,
    });

    // Send reset email
    const emailResult = await sendPasswordResetEmail(user.email, otp, user.name);

    if (!emailResult.success) {
      return res.status(500).json({ success: false, message: 'Failed to send reset email' });
    }

    res.json({
      success: true,
      message: 'Reset OTP sent to your email',
      resetToken: token, // Client needs this to verify OTP
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const { resetToken, otp, newPassword } = req.body;

    if (!resetToken || !otp || !newPassword) {
      return res
        .status(400)
        .json({ success: false, message: 'Reset token, OTP, and new password are required' });
    }

    if (newPassword.length < 6) {
      return res
        .status(400)
        .json({ success: false, message: 'Password must be at least 6 characters' });
    }

    // Find the reset token
    const resetRecord = await PasswordReset.findOne({ token: resetToken, otp, isUsed: false });

    if (!resetRecord) {
      return res.status(400).json({ success: false, message: 'Invalid or expired reset token' });
    }

    if (new Date() > resetRecord.expiresAt) {
      return res.status(400).json({ success: false, message: 'Reset token has expired' });
    }

    // Update password
    const user = await User.findById(resetRecord.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    // Mark reset record as used
    resetRecord.isUsed = true;
    await resetRecord.save();

    res.json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    next(error);
  }
};

// PHASE 1: PHONE OTP ENDPOINTS
const sendPhoneOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required' });
    }

    // Generate OTP
    const otp = generateOtpSms();

    // Calculate expiry (5 minutes)
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    // Delete old OTP if exists
    await OTP.deleteMany({ phone });

    // Save new OTP
    const otpRecord = await OTP.create({
      phone,
      otp,
      expiresAt,
    });

    // Send OTP via SMS
    const smsResult = await sendOtpSms(phone, otp);

    if (!smsResult.success) {
      return res.status(500).json({ success: false, message: 'Failed to send OTP' });
    }

    console.log(`OTP sent to ${phone}: ${otp}`);

    res.json({
      success: true,
      message: 'OTP sent to your phone',
      otpId: otpRecord._id, // For tracking verification
    });
  } catch (error) {
    console.error('Send OTP error:', error);
    next(error);
  }
};

const verifyPhoneOtp = async (req, res, next) => {
  try {
    const { phone, otp, name, email, password, role } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ success: false, message: 'Phone and OTP are required' });
    }

    // Find OTP record
    const otpRecord = await OTP.findOne({ phone, otp, isVerified: false });

    if (!otpRecord) {
      return res.status(400).json({ success: false, message: 'Invalid OTP' });
    }

    if (new Date() > otpRecord.expiresAt) {
      return res.status(400).json({ success: false, message: 'OTP has expired' });
    }

    // Mark OTP as verified
    otpRecord.isVerified = true;
    await otpRecord.save();

    // If phone verification only (existing user), return success
    if (!name || !email || !password) {
      return res.json({
        success: true,
        message: 'Phone verified successfully',
        verified: true,
      });
    }

    // If signup via OTP
    const emailNorm = normalizeEmail(email);
    const existingUser = await User.findOne(emailSelector(emailNorm));
    if (existingUser) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const existingPhone = await User.findOne({ phone });
    if (existingPhone) {
      return res.status(409).json({ success: false, message: 'Phone already registered' });
    }

    // Create new user
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const allowedRoles = ['customer', 'technician'];
    const userRole = allowedRoles.includes(role) ? role : 'customer';

    const user = await User.create({
      name,
      email: emailNorm,
      password: hashedPassword,
      role: userRole,
      phone,
      isOnline: userRole === 'technician',
      technicianMeta:
        userRole === 'technician'
          ? { emoji: '🛠️', rating: 4.8, experience: '5+ years', jobsDone: 0 }
          : undefined,
    });

    const accessToken = generateToken(user._id, user.role);
    const refreshToken = await issueRefreshToken(user._id);
    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: userResponse(user, accessToken, refreshToken),
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    next(error);
  }
};

// REFRESH TOKEN ENDPOINT
const refreshAccessToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token is required' });
    }

    // Find the refresh token in DB
    const storedToken = await RefreshToken.findOne({ token: refreshToken, revoked: false });
    if (!storedToken) {
      return res.status(401).json({ success: false, message: 'Invalid or expired refresh token' });
    }

    if (new Date() > storedToken.expiresAt) {
      storedToken.revoked = true;
      await storedToken.save();
      return res.status(401).json({ success: false, message: 'Refresh token has expired' });
    }

    // Revoke the old token (rotation)
    storedToken.revoked = true;
    await storedToken.save();

    // Issue new access token
    const user = await User.findById(storedToken.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const newAccessToken = generateToken(user._id, user.role);

    // Issue new refresh token
    const newRefreshTokenStr = crypto.randomBytes(64).toString('hex');
    await RefreshToken.create({
      userId: user._id,
      token: newRefreshTokenStr,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
    });

    res.json({
      success: true,
      token: newAccessToken,
      refreshToken: newRefreshTokenStr,
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    next(error);
  }
};

// Issue a refresh token on login/register
const issueRefreshToken = async (userId) => {
  const token = crypto.randomBytes(64).toString('hex');
  await RefreshToken.create({
    userId,
    token,
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
  });
  return token;
};

module.exports = {
  registerUser,
  loginUser,
  getProfile,
  updateProfile,
  forgotPassword,
  resetPassword,
  sendPhoneOtp,
  verifyPhoneOtp,
  refreshAccessToken,
  issueRefreshToken,
};
