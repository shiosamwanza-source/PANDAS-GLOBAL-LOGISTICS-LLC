const express = require('express');
const { Pool } = require('pg');
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

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
        <td>${new Date(cargo.created_at).toLocaleDateString()}</td>
      </tr>`;
    });

    res.send(`
      <!DOCTYPE html>
      <html lang="sw">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>PANDAS GLOBAL | Logistics App</title>
          <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5; margin: 0; padding: 20px; }
              .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
              h1 { color: #1a73e8; text-align: center; border-bottom: 2px solid #1a73e8; padding-bottom: 10px; }
              .form-group { margin-bottom: 15px; }
              input, select { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; }
              button { width: 100%; padding: 15px; background-color: #1a73e8; color: white; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 16px; }
              button:hover { background-color: #1557b0; }
              table { width: 100%; border-collapse: collapse; margin-top: 30px; }
              th, td { padding: 12px; border: 1px solid #eee; text-align: left; }
              th { background-color: #1a73e8; color: white; }
              tr:nth-child(even) { background-color: #f9f9f9; }
              .badge { background: #e8f0fe; color: #1a73e8; padding: 5px 10px; border-radius: 5px; font-size: 12px; font-weight: bold; }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>🐼 PANDAS GLOBAL LOGISTICS</h1>
              
              <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 30px;">
                  <h3>Sajili Mzigo Mpya</h3>
                  <form action="/add-cargo-web" method="POST">
                      <div class="form-group"><input type="text" name="sender_name" placeholder="Jina la Mtumaji" required></div>
                      <div class="form-group"><input type="text" name="cargo_details" placeholder="Maelezo ya Mzigo (Mfano: Box la Nguo)" required></div>
                      <div class="form-group"><input type="text" name="destination" placeholder="Unakokwenda (Mfano: London, UK)" required></div>
                      <button type="submit">Hifadhi Mzigo Sasa</button>
                  </form>
              </div>

              <h3>Orodha ya Mizigo Inayosafirishwa</h3>
              <table>
                  <tr><th>ID</th><th>Mtumaji</th><th>Mzigo</th><th>Gereji/Destination</th><th>Tarehe</th></tr>
                  ${rows}
              </table>
          </div>
      </body>
      </html>
    `);
  } catch (err) {
    res.status(500).send("Hitilafu imetokea kwenye mfumo.");
  }
});

app.post('/add-cargo-web', async (req, res) => {
  const { sender_name, cargo_details, destination } = req.body;
  try {
    await pool.query(
      'INSERT INTO cargo (sender_name, cargo_details, destination) VALUES (, , )',
      [sender_name, cargo_details, destination]
    );
    res.redirect('/');
  } catch (err) {
    res.status(500).send("Kosa la kiufundi: " + err.message);
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log('PANDAS App is Live!'));
