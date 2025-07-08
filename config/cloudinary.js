const cloudinary = require('cloudinary').v2;
  const { CloudinaryStorage } = require('multer-storage-cloudinary');
  const multer = require('multer');

  cloudinary.config({
    cloud_name: process.env.dq3guuc4j,
    api_key: process.env.856555319135848,
    api_secret: process.env.bcV4E-3z-Hf6KGoAMjUw_RZgt0c
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
