const express = require('express');
const router = express.Router();

// TEST ROUTE
router.get('/test-auth', (req, res) => {
  res.send('Auth route working ✅');
});

module.exports = router;
