# PANDAS GLOBAL LOGISTICS - DATABASE DOCUMENTATION

## 📋 Overview

This directory contains the complete database schema for the PANDAS Global Logistics MVP platform. The database is designed for **PostgreSQL 14+** and includes:

- Core user management (importers, agents, suppliers, admins)
- RFQ (Request for Quote) system
- Live Verification Call (LVC) management
- Order tracking and fulfillment
- Payment processing and agent commissions
- Messaging and notifications
- Reviews and ratings
- Analytics and reporting

---

## 🗂️ Files in This Directory

### 1. `01_create_schema.sql`
**Purpose**: Creates the complete database structure  
**What it does**:
- Creates all tables with proper relationships
- Defines custom ENUM types
- Sets up indexes for performance
- Creates triggers for automation (auto-generate IDs, update timestamps)
- Creates views for common data access patterns
- Adds database-level constraints and validations

**Run this file**: FIRST (on a fresh database)

### 2. `02_seed_data.sql`
**Purpose**: Populates the database with test data  
**What it does**:
- Creates 10 test users (3 importers, 3 agents, 3 suppliers, 1 admin)
- Adds sample RFQs, quotes, verifications, orders
- Creates test messages, reviews, notifications
- Generates analytics events

**Run this file**: SECOND (after schema creation)  
**Use case**: Development, staging, testing environments  
**Do NOT run in production!**

### 3. `03_common_queries.sql`
**Purpose**: Reference queries for API development  
**What it does**:
- Provides ready-to-use SQL queries for common operations
- Includes queries for all major features (RFQs, verifications, orders, etc)
- Shows examples of complex joins and aggregations
- Useful for building your REST API endpoints

**This is NOT meant to be executed** - it's a reference/documentation file.

---

## 🚀 Setup Instructions

### Prerequisites
- PostgreSQL 14 or higher installed
- `psql` command-line tool available
- Database admin credentials

### Step 1: Create Database

```bash
# Create the database
createdb pandas_db

# Or using psql
psql -U postgres -c "CREATE DATABASE pandas_db;"
```

### Step 2: Run Schema Creation

```bash
# Option A: Using psql command line
psql -U postgres -d pandas_db -f 01_create_schema.sql

# Option B: Using psql interactive
psql -U postgres pandas_db
\i 01_create_schema.sql
```

**Expected output**: Should see "Database schema created successfully!" at the end.

### Step 3: Run Seed Data (Development/Testing Only)

```bash
psql -U postgres -d pandas_db -f 02_seed_data.sql
```

**Expected output**: Should see "Seed data inserted successfully!" with counts.

### Step 4: Verify Installation

```bash
psql -U postgres -d pandas_db

# Check tables
\dt

# Check some data
SELECT * FROM users;
SELECT * FROM rfqs;
SELECT * FROM verifications;
```

---

## 🗄️ Database Schema Overview

### Core Tables

#### **users**
- **Purpose**: All platform users (importers, agents, suppliers, admins)
- **Key fields**: `id`, `role`, `full_name`, `phone`, `email`, `password_hash`
- **Relationships**: Central table - referenced by almost everything

#### **rfqs** (Request for Quotes)
- **Purpose**: Buyer requests for products
- **Key fields**: `rfq_number`, `importer_id`, `product_name`, `quantity`, `budget_min/max`
- **Relationships**: 
  - One RFQ → Many Quotes
  - One RFQ → One Verification (optional)
  - One RFQ → One Order (if successful)

#### **quotes**
- **Purpose**: Supplier responses to RFQs
- **Key fields**: `rfq_id`, `supplier_id`, `unit_price`, `total_price`, `delivery_days`
- **Relationships**: Many Quotes → One RFQ

#### **verifications**
- **Purpose**: Live Verification Calls (LVC) - core PANDAS feature
- **Key fields**: `type`, `scheduled_time`, `agent_id`, `room_link`, `recording_url`
- **Relationships**: 
  - Links Importer + Agent + Supplier
  - Has one Verification Report
  - Has one Call Session
  - Has many Call Media (photos/videos)

#### **verification_reports**
- **Purpose**: Agent's findings after verification
- **Key fields**: `overall_score`, `quality_scores`, `risk_flags`, `recommendations`, `pdf_url`
- **Relationships**: One Report → One Verification

#### **orders**
- **Purpose**: Confirmed orders between importers and suppliers
- **Key fields**: `order_number`, `total_amount`, `status`, `tracking_number`
- **Relationships**: 
  - One Order → Many Order Events (timeline)
  - One Order → Many Reviews

#### **agent_wallet**
- **Purpose**: Agent commission balances
- **Key fields**: `agent_id`, `balance`
- **Relationships**: 
  - One Wallet → Many Transactions
  - One Wallet → Many Withdrawals

### Supporting Tables

- **messages**: In-app chat between users
- **reviews**: Ratings and feedback for suppliers/agents
- **notifications**: System notifications (email, SMS, WhatsApp, push)
- **platform_events**: Analytics tracking
- **document_access_logs**: Security audit trail

---

## 🔐 Security Features

### 1. **Row-Level Security** (Not yet implemented - add in production)
```sql
-- Example for RFQs (only importer can see their own)
ALTER TABLE rfqs ENABLE ROW LEVEL SECURITY;

CREATE POLICY rfq_importer_policy ON rfqs
FOR ALL
USING (importer_id = current_setting('app.current_user_id')::UUID);
```

### 2. **Password Hashing**
- Passwords are stored as bcrypt hashes
- **Never store plain text passwords!**
- Use a library like `bcrypt` (Node.js) or `bcrypt` (Python) to hash/verify

### 3. **Encrypted Fields**
- Sensitive data (e.g., `withdrawal.account_details`) should be encrypted at application level
- Use `pgcrypto` extension for database-level encryption if needed

### 4. **Access Logs**
- All document access is logged in `document_access_logs`
- Useful for compliance and dispute resolution

---

## 📊 Indexes and Performance

### Pre-created Indexes

We've created indexes on:
- Foreign keys (all `_id` columns)
- Frequently searched fields (`status`, `role`, `created_at`)
- User lookup fields (`phone`, `email`)

### Query Performance Tips

1. **Always use indexes for WHERE clauses**
   ```sql
   -- Good (uses index)
   SELECT * FROM rfqs WHERE status = 'open';
   
   -- Bad (full table scan)
   SELECT * FROM rfqs WHERE UPPER(status) = 'OPEN';
   ```

2. **Use LIMIT for pagination**
   ```sql
   SELECT * FROM orders 
   ORDER BY created_at DESC 
   LIMIT 20 OFFSET 0;
   ```

3. **Use prepared statements to prevent SQL injection**
   ```javascript
   // Node.js example with pg library
   const result = await pool.query(
     'SELECT * FROM users WHERE id = $1',
     [userId]
   );
   ```

---

## 🔄 Automated Features (Triggers)

### 1. Auto-update `updated_at`
Whenever you UPDATE a row in these tables, `updated_at` is automatically set to NOW():
- `users`
- `rfqs`
- `orders`
- `agents`
- `suppliers`

### 2. Auto-generate Unique Numbers
- **RFQ Number**: `RFQ-2025-000001` (incremental)
- **Order Number**: `ORD-2025-000001` (incremental)

### 3. Auto-update Wallet Balance
When a transaction is inserted into `wallet_transactions`, the `agent_wallet.balance` is automatically updated.

### 4. Auto-update Review Averages
When a review is published, the `rating_average` for the agent/supplier is recalculated.

---

## 🔍 Common Query Patterns

### Get RFQ with Quotes
```sql
SELECT 
    r.*,
    jsonb_agg(q.*) AS quotes
FROM rfqs r
LEFT JOIN quotes q ON r.id = q.rfq_id
WHERE r.id = 'YOUR_RFQ_ID'
GROUP BY r.id;
```

### Get User Dashboard Data
```sql
-- For Importer
SELECT 
    (SELECT COUNT(*) FROM rfqs WHERE importer_id = $1) AS total_rfqs,
    (SELECT COUNT(*) FROM orders WHERE importer_id = $1) AS total_orders,
    (SELECT COUNT(*) FROM verifications WHERE importer_id = $1) AS total_verifications
FROM users WHERE id = $1;

-- For Agent
SELECT 
    balance,
    total_verifications,
    rating_average
FROM agent_wallet w
JOIN agents a ON w.agent_id = a.user_id
WHERE w.agent_id = $1;

-- For Supplier
SELECT 
    total_orders,
    total_revenue,
    rating_average
FROM suppliers
WHERE user_id = $1;
```

### Search with Filters
```sql
SELECT *
FROM rfqs
WHERE status = 'open'
AND category = ANY($1::TEXT[]) -- Array of categories
AND budget_max >= $2
AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;
```

---

## 🛠️ Maintenance Tasks

### 1. Backup Database
```bash
# Full backup
pg_dump -U postgres pandas_db > backup_$(date +%Y%m%d).sql

# Compressed backup
pg_dump -U postgres pandas_db | gzip > backup_$(date +%Y%m%d).sql.gz
```

### 2. Restore Database
```bash
# From plain SQL
psql -U postgres pandas_db < backup_20250210.sql

# From compressed
gunzip < backup_20250210.sql.gz | psql -U postgres pandas_db
```

### 3. Vacuum and Analyze (Performance Maintenance)
```sql
-- Run weekly
VACUUM ANALYZE;

-- Or for specific tables
VACUUM ANALYZE users;
VACUUM ANALYZE rfqs;
VACUUM ANALYZE verifications;
```

### 4. Monitor Database Size
```sql
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
WHERE datname = 'pandas_db';
```

---

## 📈 Scaling Considerations

### When to Scale

Monitor these metrics:
- **Database size** > 100GB → Consider partitioning
- **Query time** > 1 second → Add indexes, optimize queries
- **Concurrent connections** > 100 → Use connection pooling

### Scaling Strategies

1. **Vertical Scaling**: Increase server resources (RAM, CPU)
2. **Connection Pooling**: Use PgBouncer or built-in pooling
3. **Read Replicas**: Create read-only copies for analytics
4. **Partitioning**: Split large tables (e.g., `platform_events` by month)

---

## 🐛 Troubleshooting

### Problem: "relation does not exist"
**Cause**: Table not created yet  
**Solution**: Run `01_create_schema.sql` first

### Problem: "duplicate key value violates unique constraint"
**Cause**: Trying to insert duplicate phone/email/etc  
**Solution**: Check data before insert, or use `ON CONFLICT` clause

```sql
INSERT INTO users (phone, email, ...)
VALUES (...)
ON CONFLICT (phone) DO UPDATE SET email = EXCLUDED.email;
```

### Problem: Slow queries
**Solution**: 
1. Check if indexes exist: `\d+ table_name`
2. Explain query: `EXPLAIN ANALYZE SELECT ...`
3. Add missing indexes

### Problem: Permission denied
**Solution**: Grant privileges
```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO your_user;
```

---

## 🔗 Integration with Backend

### Node.js Example (using `pg`)

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  database: 'pandas_db',
  user: 'your_user',
  password: 'your_password',
  port: 5432,
});

// Get user by ID
async function getUserById(userId) {
  const result = await pool.query(
    'SELECT * FROM users WHERE id = $1',
    [userId]
  );
  return result.rows[0];
}

// Create RFQ
async function createRFQ(data) {
  const result = await pool.query(
    `INSERT INTO rfqs (
      importer_id, category, product_name, 
      quantity, budget_min, budget_max
    ) VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *`,
    [
      data.importer_id,
      data.category,
      data.product_name,
      data.quantity,
      data.budget_min,
      data.budget_max
    ]
  );
  return result.rows[0];
}
```

### Python Example (using `psycopg2`)

```python
import psycopg2
from psycopg2.extras import RealDictCursor

conn = psycopg2.connect(
    host="localhost",
    database="pandas_db",
    user="your_user",
    password="your_password"
)

# Get user by ID
def get_user_by_id(user_id):
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        return cur.fetchone()

# Create RFQ
def create_rfq(data):
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("""
            INSERT INTO rfqs (
                importer_id, category, product_name,
                quantity, budget_min, budget_max
            ) VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING *
        """, (
            data['importer_id'],
            data['category'],
            data['product_name'],
            data['quantity'],
            data['budget_min'],
            data['budget_max']
        ))
        conn.commit()
        return cur.fetchone()
```

---

## 📝 Migration Strategy (Future Updates)

When you need to update the schema in production:

1. **Never drop tables in production!**
2. Use migration tools:
   - **Node.js**: `knex.js` or `sequelize`
   - **Python**: `alembic` or `django migrations`
   - **Raw SQL**: Create versioned migration files

Example migration file structure:
```
migrations/
  001_initial_schema.sql
  002_add_verification_types.sql
  003_add_supplier_badges.sql
```

---

## 📞 Support

For database-related questions:
- **Technical Lead**: Yasir Feisal
- **CEO**: Sadick Faraji Said
- **Email**: dev@pandaslogistics.com

---

## ✅ Checklist for Deployment

Before deploying to production:

- [ ] Change admin password in seed data
- [ ] Remove seed data (02_seed_data.sql)
- [ ] Set up database backups (daily)
- [ ] Enable SSL/TLS connections
- [ ] Configure firewall rules (only allow backend server)
- [ ] Set up monitoring (query performance, errors)
- [ ] Create read-only user for analytics
- [ ] Document recovery procedures
- [ ] Test restore from backup
- [ ] Set up connection pooling

---

**Last Updated**: February 2025  
**Database Version**: 1.0 (MVP)  
**PostgreSQL Version**: 14+
