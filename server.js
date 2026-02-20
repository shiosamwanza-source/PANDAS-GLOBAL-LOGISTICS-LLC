const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(cors());
app.use(express.json());

// Serve frontend (landing page)
app.use(express.static(__dirname));

// Landing page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Tracking API
app.get('/track/:id', (req, res) => {
  const id = req.params.id;

  if (id === "101") {
    res.json({ status: "Mzigo uko Dar es Salaam 🚚" });
  } else {
    res.json({ status: null });
  }
});

// PORT (important for Render)
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log("Server running on port " + PORT);
});
cat << 'EOF' > server.js
(PASTE CODE HAPA)
EOF
