const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Configure Cloudinary storage for multer
const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'food-truck-covers', // Folder in Cloudinary
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      {
        width: 1200,      // Reduced from 1200 for faster processing
        height: 600,      // Keep aspect ratio friendly
        crop: 'fill',
        quality: 'auto:low', // More aggressive compression
        fetch_format: 'auto', // Let Cloudinary choose best format
        dpr: 'auto'       // Optimize for device pixel ratio
      }
    ],
    public_id: (req, file) => {
      // Generate unique filename
      const truckId = req.params.id || 'unknown';
      const timestamp = Date.now();
      return `cover_${truckId}_${timestamp}`;
    },
  },
});

// File filter to validate image types
const fileFilter = (req, file, cb) => {
  // Check if file is an image
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

// Configure multer with Cloudinary storage
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit (reduced from 10MB for mobile)
  },
});

// Alternative local storage for development
const localStorage = multer({
  dest: 'uploads/covers/',
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
});

module.exports = {
  cloudinary,
  upload,
  localStorage
};
