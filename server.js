const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(cors());
app.use(express.json());

// Serve frontend
app.use(express.static(__dirname));

// Landing page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Tracking API
app.get('/track/:id', (req, res) => {
  const id = req.params.id;

  if (id === "101") {
    res.json({
      status: "📦 Delivered",
      location: "Dar es Salaam",
      eta: "Completed"
    });
  } else {
    res.json({
      status: null
    });
  }
});

// PORT (IMPORTANT)
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log("Server running on port " + PORT);
});
