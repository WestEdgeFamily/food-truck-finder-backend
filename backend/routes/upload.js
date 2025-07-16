const express = require('express');
const router = express.Router();
const { upload } = require('../config/cloudinary');
const verifyToken = require('../middleware/auth');
const FoodTruck = require('../models/FoodTruck');

// POST /api/trucks/:truckId/upload
router.post('/:truckId/upload', verifyToken, upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No image file provided' });
        }

        const truckId = req.params.truckId;
        const imageUrl = req.file.path;
        const isCoverPhoto = req.body.isCoverPhoto === 'true';

        // Find the truck by id field (not _id)
        const truck = await FoodTruck.findOne({ id: truckId });
        if (!truck) {
            return res.status(404).json({ success: false, message: 'Truck not found' });
        }

        // Verify ownership
        if (truck.ownerId.toString() !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Not authorized to upload images for this truck' });
        }

        // Update the appropriate field
        if (isCoverPhoto) {
            truck.image = imageUrl;
        } else {
            if (!truck.images) truck.images = [];
            truck.images.push({
                url: imageUrl,
                type: 'gallery',
                uploadedAt: new Date()
            });
        }

        truck.lastUpdated = new Date();
        await truck.save();

        res.json({
            success: true,
            imageUrl,
            message: `${isCoverPhoto ? 'Cover photo' : 'Image'} uploaded successfully`
        });
    } catch (error) {
        console.error('Error uploading image:', error);
        res.status(500).json({ success: false, message: 'Error uploading image' });
    }
});

module.exports = router;
