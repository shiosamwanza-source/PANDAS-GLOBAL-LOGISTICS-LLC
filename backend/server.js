const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    message: 'PANDAS Global Logistics API',
    status: 'running',
    version: '1.0.0',
    founder: 'Sadick Faraji Said - Coding Founder! 💪'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'success',
    message: 'PANDAS API is alive! 🐼'
  });
});

app.listen(PORT, () => {
  console.log('\n✅ PANDAS API Server Running!');
  console.log('🌐 http://localhost:3000');
  console.log('Press Ctrl+C to stop\n');
});
