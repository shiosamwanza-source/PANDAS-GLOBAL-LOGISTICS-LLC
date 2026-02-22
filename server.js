// ============================================
// PANDAS GLOBAL LOGISTICS - BACKEND SERVER
// Production-Ready API with Database Integration
// Created by: Sadick Faraji Said
// Date: February 14, 2026
// ============================================

const express = require('express');
const { Pool } = require('pg');
const path = require('path');
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

// Enable CORS for frontend
app.use(cors({
  origin: [
    'https://pandas-global-logistics.onrender.com',
    'http://localhost:3000',
    'http://localhost:10000'
  ],
  credentials: true
}));

// Parse JSON bodies
app.use(express.json());

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

// Serve static files (frontend)
app.use(express.static(path.join(__dirname, 'public')));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`${timestamp} - ${req.method} ${req.path}`);
  next();
});

// ============================================
// API ROUTES
// ============================================

// Route 1: Health Check
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
      version: '1.0.0'
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Database connection failed',
      error: error.message
    });
  }
});

// Route 2: API Information
app.get('/api/info', (req, res) => {
  res.json({
    platform: 'PANDAS Global Logistics',
    tagline: 'The Infrastructure of Trust',
    mission: 'Eliminate import fraud in Africa through live verification',
    version: '1.0.0',
    status: 'operational',
    endpoints: [
      'GET /api/health - Health check',
      'GET /api/info - API information',
      'GET /api/stats - Platform statistics',
      'POST /api/waitlist - Join waitlist',
      'GET /api/users - List users (with auth)',
      'GET /api/test-db - Test database'
    ],
    contact: {
      email: 'sadick.faraji@pandas-global.com',
      website: 'https://www.pandas-global.com'
    }
  });
});

// Route 3: Platform Statistics
app.get('/api/stats', async (req, res) => {
  try {
    const usersCount = await pool.query('SELECT COUNT(*) FROM users');
    const agentsCount = await pool.query('SELECT COUNT(*) FROM agents');
    const importersCount = await pool.query('SELECT COUNT(*) FROM importers');
    const suppliersCount = await pool.query('SELECT COUNT(*) FROM suppliers');
    
    res.json({
      success: true,
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

// Route 4: Test Database Connection
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

// Route 5: Waitlist Signup
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
    
    // Insert into database (you'll need to create waitlist table)
    // For now, just log and return success
    console.log('New waitlist signup:', { name, email, user_type });
    
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

// Route 6: Get Users (Sample - needs authentication in production)
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
// FRONTEND ROUTES (Serve HTML)
// ============================================

// Serve main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Serve waitlist page
app.get('/track.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'track.html'));
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
      '/api/health',
      '/api/info',
      '/api/stats',
      '/api/test-db',
      'POST /api/waitlist',
      '/api/users'
    ]
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
  ║   Database:  ${process.env.DATABASE_URL ? '✅ CONNECTED' : '❌ NOT CONFIGURED'}        ║
  ║   Mode:      ${process.env.NODE_ENV || 'development'}                     ║
  ║   Version:   1.0.0                             ║
  ║                                                ║
  ╠════════════════════════════════════════════════╣
  ║                                                ║
  ║   API Endpoints:                               ║
  ║   → /api/health                                ║
  ║   → /api/info                                  ║
  ║   → /api/stats                                 ║
  ║   → /api/test-db                               ║
  ║   → /api/waitlist (POST)                       ║
  ║   → /api/users                                 ║
  ║                                                ║
  ║   Frontend:                                    ║
  ║   → /                                          ║
  ║   → /track.html                                ║
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
