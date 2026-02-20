require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

const authRoutes = require('./routes/auth');
const rfqRoutes = require('./routes/rfq');

app.use('/api', authRoutes);
app.use('/api', rfqRoutes);

app.get('/', (req, res) => {
  res.send('PANDAS API RUNNING 🚀');
});

app.listen(5000, () => {
  console.log('Server running on http://localhost:5000');
});
