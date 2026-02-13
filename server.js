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
    const cargoData = JSON.stringify(result.rows);

    res.send(`
      <!DOCTYPE html>
      <html lang="sw">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>PANDAS GLOBAL | Logistics App</title>
          <style>
              body { font-family: 'Segoe UI', sans-serif; background-color: #f0f2f5; margin: 0; padding: 15px; }
              .container { max-width: 1000px; margin: auto; background: white; padding: 25px; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
              h1 { color: #1a73e8; text-align: center; margin-bottom: 20px; }
              .form-section { background: #f8f9fa; padding: 20px; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e1e4e8; }
              input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 8px; box-sizing: border-box; margin-bottom: 10px; }
              button { width: 100%; padding: 15px; background-color: #1a73e8; color: white; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; }
              .search-box { background: #fffde7; border: 2px solid #fbc02d; padding: 15px; border-radius: 10px; margin-bottom: 20px; }
              table { width: 100%; border-collapse: collapse; margin-top: 10px; }
              th, td { padding: 12px; border-bottom: 1px solid #eee; text-align: left; }
              th { background-color: #1a73e8; color: white; }
              .whatsapp-btn { background-color: #25d366; color: white; padding: 8px 12px; border-radius: 5px; text-decoration: none; font-size: 12px; font-weight: bold; display: inline-block; }
              .whatsapp-btn:hover { background-color: #128c7e; }
              @media (max-width: 600px) { th, td { padding: 8px; font-size: 11px; } .whatsapp-btn { padding: 5px 8px; } }
          </style>
      </head>
      <body>
          <div class="container">
              <h1>🐼 PANDAS GLOBAL LOGISTICS</h1>
              
              <div class="form-section">
                  <h3>Sajili Mzigo Mpya</h3>
                  <form action="/add-cargo-web" method="POST">
                      <input type="text" name="sender_name" placeholder="Jina la Mtumaji" required>
                      <input type="text" name="cargo_details" placeholder="Maelezo ya Mzigo" required>
                      <input type="text" name="destination" placeholder="Unakokwenda" required>
                      <button type="submit">Hifadhi Taarifa ✅</button>
                  </form>
              </div>

              <div class="search-box">
                  <input type="text" id="searchInput" onkeyup="filterTable()" placeholder="🔍 Tafuta kwa jina au unakokwenda...">
              </div>

              <h3>Orodha ya Mizigo</h3>
              <table id="cargoTable">
                  <thead>
                      <tr><th>Mtumaji</th><th>Mzigo</th><th>Destination</th><th>Msaada</th></tr>
                  </thead>
                  <tbody id="tableBody"></tbody>
              </table>
          </div>

          <script>
              const data = ${cargoData};
              const tableBody = document.getElementById('tableBody');

              function displayData(items) {
                  tableBody.innerHTML = items.map(item => {
                      const msg = encodeURIComponent("Habari PANDAS GLOBAL, naulizia mzigo wangu wa " + item.cargo_details + " (ID: " + item.id + ")");
                      const waLink = "https://wa.me/255717872888?text=" + msg;
                      return `
                        <tr>
                            <td><strong>${item.sender_name}</strong></td>
                            <td>${item.cargo_details}</td>
                            <td>${item.destination}</td>
                            <td><a href="${waLink}" class="whatsapp-btn" target="_blank">WhatsApp 💬</a></td>
                        </tr>
                      `;
                  }).join('');
              }

              function filterTable() {
                  const query = document.getElementById('searchInput').value.toLowerCase();
                  const filtered = data.filter(item => 
                      item.sender_name.toLowerCase().includes(query) || 
                      item.destination.toLowerCase().includes(query)
                  );
                  displayData(filtered);
              }
              displayData(data);
          </script>
      </body>
      </html>
    `);
  } catch (err) {
    res.status(500).send("Hitilafu ya mfumo.");
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
    res.status(500).send(err.message);
  }
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log('PANDAS App is Live!'));
