const { Pool } = require('pg');

const pool = new Pool({
  connectionString: 'postgresql://localhost:5432/pandas'
});

module.exports = pool;
