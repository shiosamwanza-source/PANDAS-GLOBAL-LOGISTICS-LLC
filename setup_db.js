const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function createTable() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS cargo (
        id SERIAL PRIMARY KEY,
        sender_name TEXT NOT NULL,
        cargo_details TEXT NOT NULL,
        destination TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("Jedwali la mizigo limetengenezwa! ✅");
    process.exit();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}
createTable();
