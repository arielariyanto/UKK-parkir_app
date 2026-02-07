const express = require('express');
const router = express.Router();
const { publicRegister } = require('../controller/registerController');

// Public registration endpoint
router.post('/', publicRegister);

module.exports = router;
