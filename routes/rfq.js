const express = require('express');
const router = express.Router();

// TEST ROUTE
router.get('/test-rfq', (req, res) => {
  res.send('RFQ route working ✅');
});

module.exports = router;
