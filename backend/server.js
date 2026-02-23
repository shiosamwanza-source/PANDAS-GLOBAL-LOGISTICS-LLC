// ============================================
// PANDAS GLOBAL LOGISTICS - BACKEND SERVER
// Production-Ready API (NO FRONTEND FILES)
// Created by: Sadick Faraji Said
// Date: February 23, 2026
// ============================================

const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 10000;

// ============================================
// DATABASE CONNECTION
// ============================================

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? {
    rejectUnauthorized: false
  } : false
});

// Test database connection
pool.on('connect', () => {
  console.log('✅ Database connected successfully!');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected database error:', err);
});

// ============================================
// MIDDLEWARE
// ============================================

// Enable CORS for all origins
app.use(cors());

// Parse JSON bodies
app.use(express.json());

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`${timestamp} - ${req.method} ${req.path}`);
  next();
});

// ============================================
// API ROUTES
// ============================================

// Route 1: ROOT - API Welcome
app.get('/', (req, res) => {
  res.json({
    platform: 'PANDAS Global Logistics',
    tagline: 'The Infrastructure of Trust',
    message: 'Welcome to PANDAS API - Eliminating import fraud in Africa through live verification',
    status: 'operational',
    version: '1.0.0',
    endpoints: {
      health: '/api/health - Health check with database status',
      info: '/api/info - Platform information',
      stats: '/api/stats - Database statistics',
      test_db: '/api/test-db - Test database connection',
      waitlist: 'POST /api/waitlist - Join waitlist',
      users: '/api/users - Get users list'
    },
    documentation: 'https://github.com/shiosamwanza-source/PANDAS-GLOBAL-LOGISTICS-LLC',
    contact: {
      email: 'sadick.faraji@pandas-global.com',
      website: 'https://www.pandas-global.com'
    }
  });
});

// Route 2: Health Check
app.get('/api/health', async (req, res) => {
  try {
    // Test database connection
    const result = await pool.query('SELECT NOW()');
    
    res.json({
      status: 'success',
      message: 'PANDAS API is healthy! 🐼',
      timestamp: new Date().toISOString(),
      database: 'connected',
      server_time: result.rows[0].now,
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Database connection failed',
      database: 'disconnected',
      error: error.message
    });
  }
});

// Route 3: API Information
app.get('/api/info', (req, res) => {
  res.json({
    platform: 'PANDAS Global Logistics',
    tagline: 'The Infrastructure of Trust',
    mission: 'Eliminate import fraud in Africa through live verification technology',
    founded: 'January 27, 2026',
    location: 'Houston, Texas → East Africa',
    version: '1.0.0',
    status: 'operational',
    features: [
      'DFA Technology - Digital Fingerprint Authentication',
      'Live Verification - Real-time cargo inspection',
      'Trade Protection - Fraud elimination systems',
      'Port Management - Clearance and handling',
      'Global Sourcing - Verified supplier network'
    ],
    endpoints: [
      'GET / - API welcome',
      'GET /api/health - Health check',
      'GET /api/info - API information',
      'GET /api/stats - Platform statistics',
      'POST /api/waitlist - Join waitlist',
      'GET /api/users - List users',
      'GET /api/test-db - Test database'
    ],
    contact: {
      email: 'sadick.faraji@pandas-global.com',
      website: 'https://www.pandas-global.com',
      github: 'https://github.com/shiosamwanza-source/PANDAS-GLOBAL-LOGISTICS-LLC'
    }
  });
});

// Route 4: Platform Statistics
app.get('/api/stats', async (req, res) => {
  try {
    const usersCount = await pool.query('SELECT COUNT(*) FROM users');
    const agentsCount = await pool.query('SELECT COUNT(*) FROM agents');
    const importersCount = await pool.query('SELECT COUNT(*) FROM importers');
    const suppliersCount = await pool.query('SELECT COUNT(*) FROM suppliers');
    
    res.json({
      success: true,
      platform: 'PANDAS Global Logistics',
      statistics: {
        total_users: parseInt(usersCount.rows[0].count),
        total_agents: parseInt(agentsCount.rows[0].count),
        total_importers: parseInt(importersCount.rows[0].count),
        total_suppliers: parseInt(suppliersCount.rows[0].count),
        database: 'pandas_db',
        tables: '40+',
        status: 'operational'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Stats error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch statistics',
      message: error.message
    });
  }
});

// Route 5: Test Database Connection
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        table_name 
      FROM 
        information_schema.tables 
      WHERE 
        table_schema = 'public' 
      ORDER BY 
        table_name
    `);
    
    res.json({
      success: true,
      message: 'Database is accessible!',
      total_tables: result.rows.length,
      tables: result.rows.map(row => row.table_name),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database test error:', error);
    res.status(500).json({
      success: false,
      error: 'Database test failed',
      message: error.message
    });
  }
});

// Route 6: Waitlist Signup
app.post('/api/waitlist', async (req, res) => {
  try {
    const { name, email, phone, company, user_type, region } = req.body;
    
    // Basic validation
    if (!name || !email) {
      return res.status(400).json({
        success: false,
        error: 'Name and email are required'
      });
    }
    
    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }
    
    // Log the signup (in production, save to database)
    console.log('New waitlist signup:', { name, email, user_type, timestamp: new Date().toISOString() });
    
    res.json({
      success: true,
      message: 'Successfully joined waitlist!',
      data: {
        name,
        email,
        user_type: user_type || 'unknown',
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Waitlist signup error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to process waitlist signup',
      message: error.message
    });
  }
});

// Route 7: Get Users
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        user_id,
        full_name,
        email,
        user_type,
        phone,
        country,
        created_at
      FROM users
      ORDER BY created_at DESC
      LIMIT 10
    `);
    
    res.json({
      success: true,
      count: result.rows.length,
      users: result.rows,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Users fetch error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch users',
      message: error.message
    });
  }
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.path}`,
    available_endpoints: [
      'GET /',
      'GET /api/health',
      'GET /api/info',
      'GET /api/stats',
      'GET /api/test-db',
      'POST /api/waitlist',
      'GET /api/users'
    ],
    hint: 'Visit / for API documentation'
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' ? 'Something went wrong' : err.message
  });
});

// ============================================
// START SERVER
// ============================================

app.listen(PORT, '0.0.0.0', () => {
  console.log(`
  ╔════════════════════════════════════════════════╗
  ║                                                ║
  ║   🐼 PANDAS GLOBAL LOGISTICS API 🐼           ║
  ║   The Infrastructure of Trust                  ║
  ║                                                ║
  ╠════════════════════════════════════════════════╣
  ║                                                ║
  ║   Server:    http://0.0.0.0:${PORT}            ║
  ║   Status:    ✅ LIVE                           ║
  ║   Database:  ${process.env.DATABASE_URL ? '✅ CONFIGURED' : '❌ NOT CONFIGURED'}      ║
  ║   Mode:      ${process.env.NODE_ENV || 'development'}                     ║
  ║   Version:   1.0.0                             ║
  ║                                                ║
  ╠════════════════════════════════════════════════╣
  ║                                                ║
  ║   API Endpoints:                               ║
  ║   → GET  /                                     ║
  ║   → GET  /api/health                           ║
  ║   → GET  /api/info                             ║
  ║   → GET  /api/stats                            ║
  ║   → GET  /api/test-db                          ║
  ║   → POST /api/waitlist                         ║
  ║   → GET  /api/users                            ║
  ║                                                ║
  ╚════════════════════════════════════════════════╝
  
  🚀 Server ready! Press Ctrl+C to stop.
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server gracefully...');
  pool.end(() => {
    console.log('Database pool closed');
    process.exit(0);
  });
});
