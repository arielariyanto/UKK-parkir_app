const express = require('express');
const router = express.Router();
const userController = require('../controller/userController');
const { authMiddleware, roleMiddleware } = require('../middleware/authMiddleware');

// Public
router.post('/login', userController.login);

// Protected
router.post('/logout', authMiddleware, userController.logout);
router.get('/profile', authMiddleware, userController.getProfile);

// Admin & Owner
router.get('/', authMiddleware, roleMiddleware('admin', 'owner'), userController.getAllUsers);
router.post('/register', authMiddleware, roleMiddleware('admin'), userController.register);
router.put('/:id', authMiddleware, roleMiddleware('admin'), userController.updateUser);
router.delete('/:id', authMiddleware, roleMiddleware('admin'), userController.deleteUser);

module.exports = router;
