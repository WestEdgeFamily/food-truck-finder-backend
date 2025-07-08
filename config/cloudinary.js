const cloudinary = require('cloudinary').v2;
  const { CloudinaryStorage } = require('multer-storage-cloudinary');
  const multer = require('multer');

  cloudinary.config({
    cloud_name: process.CLOUDINARY_API_KEY,
    api_key: process.CLOUDINARY_API_SECRET,
    api_secret: process.CLOUDINARY_CLOUD_NAME
  });

  const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
      folder: 'food-trucks',
      allowed_formats: ['jpg', 'jpeg', 'png', 'webp']
    }
  });

  const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }
  });

  module.exports = { upload };
