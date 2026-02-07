const express = require('express');
const router = express.Router();
const userController = require('../controller/userController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// Public
router.post('/login', userController.login);

// Protected
router.get('/profile', authMiddleware, userController.getProfile);

// Admin only
router.post('/register', authMiddleware, roleMiddleware('admin'), userController.register);

module.exports = router;
