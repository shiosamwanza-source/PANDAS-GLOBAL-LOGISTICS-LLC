const express = require("express");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 5000;

// Static files
app.use(express.static(__dirname));

// Routes
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

app.get("/track.html", (req, res) => {
  res.sendFile(path.join(__dirname, "track.html"));
});

// API (tracking data)
app.get("/track/:id", (req, res) => {

  const data = {
    "PANDA123": {
      status: "In Transit 🚢",
      location: "Dubai Port",
      eta: "5 Days"
    },
    "PANDA456": {
      status: "Arrived ✅",
      location: "Dar es Salaam",
      eta: "Delivered"
    }
  };

  const result = data[req.params.id];

  if (!result) {
    return res.json({ error: "Not found" });
  }

  res.json(result);
});

// Start server
app.listen(PORT, () => {
  console.log("Server running on port " + PORT);
});
