require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// ✅ ROOT (test if server is alive)
app.get('/', (req, res) => {
  res.send('PANDAS BACKEND LIVE 🚀');
});

// ✅ TRACKING API (REAL ENDPOINT)
app.get('/track/:id', (req, res) => {
  const cargoId = req.params.id;

  // Simple demo database
  const cargos = {
    "101": { status: "Mzigo uko Dar es Salaam 🇹🇿" },
    "202": { status: "Mzigo uko Dubai 🇦🇪" },
    "303": { status: "Mzigo uko China 🇨🇳" }
  };

  if (cargos[cargoId]) {
    res.json(cargos[cargoId]);
  } else {
    res.json({ status: null });
  }
});

// ✅ IMPORTANT FOR RENDER (dynamic port)
const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
