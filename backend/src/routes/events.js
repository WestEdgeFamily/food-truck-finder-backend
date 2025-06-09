const express = require('express');
const Event = require('../models/Event');
const FoodTruck = require('../models/FoodTruck');
const { protect, authorize } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/events
// @desc    Get all public events
// @access  Public
router.get('/', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      eventType,
      city,
      state,
      status,
      startDate,
      endDate,
      lat,
      lng,
      radius = 50
    } = req.query;

    let query = { isActive: true, isPublic: true };

    // Filter by event type
    if (eventType) {
      query.eventType = eventType;
    }

    // Filter by location
    if (city) {
      query['location.city'] = new RegExp(city, 'i');
    }
    if (state) {
      query['location.state'] = new RegExp(state, 'i');
    }

    // Filter by date range
    if (startDate || endDate) {
      query.startDate = {};
      if (startDate) query.startDate.$gte = new Date(startDate);
      if (endDate) query.startDate.$lte = new Date(endDate);
    }

    // Filter by status
    const now = new Date();
    if (status === 'upcoming') {
      query.startDate = { $gt: now };
    } else if (status === 'active') {
      query.startDate = { $lte: now };
      query.endDate = { $gte: now };
    } else if (status === 'completed') {
      query.endDate = { $lt: now };
    }

    // Geographic search
    if (lat && lng) {
      query['location.coordinates'] = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: radius * 1609.34 // Convert miles to meters
        }
      };
    }

    const events = await Event.find(query)
      .populate('participatingTrucks.truck', 'name cuisineType location isActive')
      .sort({ startDate: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Event.countDocuments(query);

    res.json({
      events,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/events/:id
// @desc    Get single event
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('participatingTrucks.truck', 'name description cuisineType location businessHours isActive')
      .populate('createdBy', 'name email');

    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    res.json(event);
  } catch (error) {
    console.error('Error fetching event:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/events
// @desc    Create new event
// @access  Private (Admin)
router.post('/', protect, authorize('admin'), async (req, res) => {
  try {
    const eventData = {
      ...req.body,
      createdBy: req.user.userId,
      updatedBy: req.user.userId
    };

    const event = new Event(eventData);
    await event.save();

    res.status(201).json(event);
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/events/:id
// @desc    Update event
// @access  Private (Admin/Creator)
router.put('/:id', protect, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    // Check permissions
    if (req.user.role !== 'admin' && event.createdBy.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized to update this event' });
    }

    const updatedEvent = await Event.findByIdAndUpdate(
      req.params.id,
      { ...req.body, updatedBy: req.user.userId },
      { new: true, runValidators: true }
    ).populate('participatingTrucks.truck', 'name cuisineType');

    res.json(updatedEvent);
  } catch (error) {
    console.error('Error updating event:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/events/:id
// @desc    Delete event
// @access  Private (Admin/Creator)
router.delete('/:id', protect, async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);

    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    // Check permissions
    if (req.user.role !== 'admin' && event.createdBy.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized to delete this event' });
    }

    await Event.findByIdAndDelete(req.params.id);
    res.json({ message: 'Event deleted successfully' });
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/events/:id/join
// @desc    Join event as food truck
// @access  Private (Food Truck Owner)
router.post('/:id/join', protect, authorize('owner'), async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    // Find user's food truck
    const truck = await FoodTruck.findOne({ owner: req.user.userId });
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Check if truck can join
    if (!event.canTruckJoin()) {
      return res.status(400).json({ 
        message: 'Cannot join event: either full or registration deadline passed' 
      });
    }

    // Check if already participating
    const existingParticipation = event.participatingTrucks.find(
      pt => pt.truck.toString() === truck._id.toString()
    );

    if (existingParticipation) {
      return res.status(400).json({ message: 'Already participating in this event' });
    }

    await event.addTruck(truck._id, 'confirmed');
    
    const updatedEvent = await Event.findById(req.params.id)
      .populate('participatingTrucks.truck', 'name cuisineType');

    res.json({ message: 'Successfully joined event', event: updatedEvent });
  } catch (error) {
    console.error('Error joining event:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/events/:id/leave
// @desc    Leave event as food truck
// @access  Private (Food Truck Owner)
router.delete('/:id/leave', protect, authorize('owner'), async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    // Find user's food truck
    const truck = await FoodTruck.findOne({ owner: req.user.userId });
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    // Check if participating
    const isParticipating = event.participatingTrucks.some(
      pt => pt.truck.toString() === truck._id.toString()
    );

    if (!isParticipating) {
      return res.status(400).json({ message: 'Not participating in this event' });
    }

    await event.removeTruck(truck._id);
    
    const updatedEvent = await Event.findById(req.params.id)
      .populate('participatingTrucks.truck', 'name cuisineType');

    res.json({ message: 'Successfully left event', event: updatedEvent });
  } catch (error) {
    console.error('Error leaving event:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/events/my/participating
// @desc    Get events the user's truck is participating in
// @access  Private (Food Truck Owner)
router.get('/my/participating', protect, authorize('owner'), async (req, res) => {
  try {
    // Find user's food truck
    const truck = await FoodTruck.findOne({ owner: req.user.userId });
    if (!truck) {
      return res.status(404).json({ message: 'Food truck not found' });
    }

    const events = await Event.find({
      'participatingTrucks.truck': truck._id,
      isActive: true
    })
    .populate('participatingTrucks.truck', 'name cuisineType')
    .sort({ startDate: 1 });

    res.json(events);
  } catch (error) {
    console.error('Error fetching participating events:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/events/my/created
// @desc    Get events created by the user
// @access  Private (Admin)
router.get('/my/created', protect, authorize('admin'), async (req, res) => {
  try {
    const events = await Event.find({ createdBy: req.user.userId })
      .populate('participatingTrucks.truck', 'name cuisineType')
      .sort({ startDate: 1 });

    res.json(events);
  } catch (error) {
    console.error('Error fetching created events:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router; 