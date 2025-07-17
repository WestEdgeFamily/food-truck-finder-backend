# Exact Changes to Add to server.js for Image Upload

## 1. Add Import at Top (around line 30, after other requires)

```javascript
// Add this after the line: const emailService = require('./services/emailService');
const { upload } = require('./config/cloudinary');
```

## 2. Add Image Upload Route (add after line 2520, after the review routes)

```javascript
// ===== IMAGE UPLOAD ROUTE =====
// Upload image for food truck
app.post('/api/trucks/:id/upload-image', verifyToken, upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if user owns this truck
    const truck = await FoodTruck.findById(id);
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }
    
    if (truck.ownerId.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    if (!req.file) {
      return res.status(400).json({ message: 'No image uploaded' });
    }
    
    // Update truck with new image
    truck.image = req.file.path;
    await truck.save();
    
    logger.info(`✅ Image uploaded for truck ${truck.name}`);
    
    res.json({
      success: true,
      imageUrl: req.file.path,
      message: 'Image uploaded successfully'
    });
  } catch (error) {
    logger.error('❌ Upload error:', error);
    res.status(500).json({ message: 'Upload failed' });
  }
});
```

## That's ALL! Just these 2 additions to server.js

1. One import line at the top
2. One route after the review routes

The rest of your server.js remains exactly the same.