const express = require('express');
const { Pool } = require('pg');
const app = express();
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

// 1. Ukurasa wa mbele (Dashboard)
app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM cargo ORDER BY created_at DESC');
    let rows = '';
    result.rows.forEach(cargo => {
      rows += `<tr>
        <td>${cargo.id}</td>
        <td>${cargo.sender_name}</td>
        <td>${cargo.cargo_details}</td>
        <td>${cargo.destination}</td>
        <td>${new Date(cargo.created_at).toLocaleString()}</td>
      </tr>`;
    });

    res.send(`
      <html>
        <head>
          <title>PANDAS GLOBAL - Logistics</title>
          <style>
            body { font-family: Arial; margin: 40px; background: #f4f4f4; }
            table { width: 100%; border-collapse: collapse; background: white; }
            th, td { padding: 12px; border: 1px solid #ddd; text-align: left; }
            th { background: #333; color: white; }
            h1 { color: #2c3e50; }
          </style>
        </head>
        <body>
          <h1>PANDAS GLOBAL LOGISTICS - Cargo Dashboard</h1>
          <table>
            <tr>
              <th>ID</th><th>Sender</th><th>Details</th><th>Destination</th><th>Date</th>
            </tr>
            ${rows}
          </table>
        </body>
      </html>
    `);
  } catch (err) {
    res.status(500).send("Hitilafu ya Database.");
  }
});

// 2. Njia ya kuingiza mzigo (API)
app.post('/add-cargo', async (req, res) => {
  const { sender_name, cargo_details, destination } = req.body;
  try {
    await pool.query(
      'INSERT INTO cargo (sender_name, cargo_details, destination) VALUES (, , )',
      [sender_name, cargo_details, destination]
    );
    res.json({ message: "Mzigo umerekodiwa kikamilifu! ✅" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log('Server is Live on port ' + PORT));
