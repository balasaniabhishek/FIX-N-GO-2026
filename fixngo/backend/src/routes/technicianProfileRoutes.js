const express = require('express');
const multer = require('multer');
const path = require('path');
const {
  getTechnicianProfile,
  updateTechnicianProfile,
  updateTechnicianPhoto,
  updateTechnicianKyc,
  updateTechnicianLocation,
  getTechnicianStatus,
  getTechnicianStats,
} = require('../controllers/technicianProfileController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');

const router = express.Router();
const tempDir = path.join(__dirname, '../../temp');
if (!require('fs').existsSync(tempDir)) {
  require('fs').mkdirSync(tempDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, tempDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}_${file.originalname}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'application/octet-stream'];
    const ext = path.extname(file.originalname).toLowerCase();
    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp'];
    
    if (allowedMimes.includes(file.mimetype) || allowedExts.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, and WebP images are allowed'));
    }
  },
});

// Get technician public profile
router.get('/:technicianId', getTechnicianProfile);

// Get technician status
router.get('/:technicianId/status', getTechnicianStatus);

// Update technician profile (technician only)
router.put('/profile/update', protect, authorize('technician'), updateTechnicianProfile);
router.put('/profile/photo', protect, authorize('technician'), upload.single('photo'), updateTechnicianPhoto);
router.put(
  '/profile/kyc',
  protect,
  authorize('technician'),
  upload.fields([
    { name: 'aadharFront', maxCount: 1 },
    { name: 'aadharBack', maxCount: 1 },
  ]),
  updateTechnicianKyc
);

// Update technician location (technician only)
router.put('/location/update', protect, authorize('technician'), updateTechnicianLocation);

// Get technician stats (technician only)
router.get('/stats/my', protect, authorize('technician'), getTechnicianStats);

module.exports = router;
