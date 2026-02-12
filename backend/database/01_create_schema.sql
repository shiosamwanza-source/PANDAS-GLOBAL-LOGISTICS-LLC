-- ========================================
-- PANDAS GLOBAL LOGISTICS - DATABASE SCHEMA
-- PostgreSQL 14+
-- ========================================
-- Version: 1.0 (MVP)
-- Created: February 2025
-- Author: PANDAS Development Team
-- ========================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- ENUMS (Custom Types)
-- ========================================

CREATE TYPE user_role AS ENUM ('importer', 'agent', 'supplier', 'admin');
CREATE TYPE rfq_status AS ENUM ('open', 'quoted', 'selected', 'completed', 'cancelled');
CREATE TYPE quote_status AS ENUM ('pending', 'selected', 'rejected');
CREATE TYPE verification_type AS ENUM ('factory_visit', 'warehouse_inspection', 'sample_testing');
CREATE TYPE verification_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'paid', 'refunded', 'failed');
CREATE TYPE payment_method AS ENUM ('mpesa', 'stripe', 'bank_transfer', 'paypal');
CREATE TYPE order_status AS ENUM (
    'awaiting_payment', 
    'payment_confirmed', 
    'in_production', 
    'quality_inspection',
    'shipped', 
    'in_transit',
    'customs_clearance',
    'delivered', 
    'disputed', 
    'completed',
    'cancelled'
);
CREATE TYPE assignment_status AS ENUM ('offered', 'accepted', 'declined', 'timeout');
CREATE TYPE report_status AS ENUM ('draft', 'submitted', 'approved', 'rejected');
CREATE TYPE agent_status AS ENUM ('pending', 'active', 'suspended', 'terminated');
CREATE TYPE supplier_status AS ENUM ('pending', 'active', 'suspended', 'terminated');
CREATE TYPE background_check_status AS ENUM ('pending', 'passed', 'failed');
CREATE TYPE call_recording_status AS ENUM ('processing', 'ready', 'failed');
CREATE TYPE wallet_transaction_type AS ENUM ('credit', 'debit');
CREATE TYPE withdrawal_status AS ENUM ('requested', 'approved', 'processing', 'completed', 'rejected');
CREATE TYPE document_access_action AS ENUM ('viewed', 'downloaded', 'shared');
CREATE TYPE badge_type AS ENUM ('verified', 'top_rated', 'fast_shipper', 'responsive', 'quality_guaranteed');
CREATE TYPE review_status AS ENUM ('pending', 'published', 'flagged', 'removed');
CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read');

-- ========================================
-- CORE TABLES
-- ========================================

-- Users Table (All user types: importers, agents, suppliers, admins)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role user_role NOT NULL,
    
    -- Basic Info
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Business Info
    business_name VARCHAR(255),
    location_city VARCHAR(100),
    location_country VARCHAR(50),
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Verification
    phone_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- OTP Codes for phone/email verification
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(6) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'phone' or 'email'
    expires_at TIMESTAMP NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- IMPORTER TABLES
-- ========================================

-- RFQs (Request for Quotes)
CREATE TABLE rfqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rfq_number VARCHAR(20) UNIQUE NOT NULL,
    importer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Product Details
    category VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL,
    unit VARCHAR(50) DEFAULT 'pieces',
    
    -- Budget
    budget_min DECIMAL(10,2),
    budget_max DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Requirements
    quality_level VARCHAR(20), -- 'Basic', 'Standard', 'Premium'
    deadline DATE,
    photos TEXT[], -- Array of S3 URLs
    requirements TEXT,
    
    -- Status
    status rfq_status DEFAULT 'open',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    closed_at TIMESTAMP
);

-- Quotes from Suppliers
CREATE TABLE quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rfq_id UUID REFERENCES rfqs(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Pricing
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Terms
    minimum_order_quantity INTEGER,
    delivery_days INTEGER NOT NULL,
    payment_terms TEXT,
    shipping_method VARCHAR(100),
    
    -- Supporting Materials
    product_photos TEXT[],
    specifications TEXT,
    certifications TEXT[], -- URLs to certification docs
    
    -- Status
    status quote_status DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    selected_at TIMESTAMP
);

-- ========================================
-- VERIFICATION TABLES
-- ========================================

-- Verifications (LVC - Live Verification Calls)
CREATE TABLE verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rfq_id UUID REFERENCES rfqs(id) ON DELETE CASCADE,
    quote_id UUID REFERENCES quotes(id) ON DELETE SET NULL,
    
    -- Participants
    importer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id) ON DELETE SET NULL,
    supplier_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Schedule
    type verification_type NOT NULL,
    scheduled_time TIMESTAMP NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    
    -- Payment
    verification_fee DECIMAL(10,2) NOT NULL,
    agent_commission DECIMAL(10,2), -- Agent gets 70%, PANDAS gets 30%
    payment_status payment_status DEFAULT 'pending',
    payment_method payment_method,
    
    -- Video Platform
    video_platform VARCHAR(20) DEFAULT 'twilio', -- 'twilio' or 'zoom'
    room_id VARCHAR(255),
    room_link TEXT,
    passcode VARCHAR(50),
    
    -- Recording
    recording_url TEXT,
    recording_status call_recording_status DEFAULT 'processing',
    recording_duration_minutes INTEGER,
    
    -- Location Verification (GPS)
    supplier_address TEXT,
    agent_checkin_coordinates VARCHAR(100), -- lat,lng
    agent_checkin_time TIMESTAMP,
    
    -- Status
    status verification_status DEFAULT 'scheduled',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Verification Assignments (Agent matching)
CREATE TABLE verification_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Assignment Details
    status assignment_status DEFAULT 'offered',
    offer_expires_at TIMESTAMP, -- 2 hours to respond
    
    -- Timestamps
    offered_at TIMESTAMP DEFAULT NOW(),
    responded_at TIMESTAMP
);

-- Call Sessions (Live call metadata)
CREATE TABLE call_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    
    -- Session Details
    session_id VARCHAR(255) UNIQUE, -- Twilio/Zoom session ID
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_minutes INTEGER,
    
    -- Participants (JSON with join/leave times)
    participants JSONB,
    
    -- Chat Messages
    chat_messages JSONB[], -- [{user_id, message, timestamp}]
    
    -- Quality Metrics
    network_quality VARCHAR(20), -- 'excellent', 'good', 'poor'
    video_quality VARCHAR(20),
    audio_quality VARCHAR(20),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- Call Media (Photos/videos captured during call)
CREATE TABLE call_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Media Details
    media_type VARCHAR(20), -- 'photo', 'voice_note', 'video_clip'
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_size_bytes INTEGER,
    
    -- Location
    gps_coordinates VARCHAR(100),
    caption TEXT,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- Verification Reports
CREATE TABLE verification_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Quality Scores (1-10)
    overall_score INTEGER CHECK (overall_score >= 1 AND overall_score <= 10),
    quality_scores JSONB, -- {materials: 8, workmanship: 7, facility: 9}
    
    -- Red Flags
    risk_flags TEXT[],
    has_red_flags BOOLEAN DEFAULT FALSE,
    
    -- Report Content
    summary TEXT NOT NULL,
    detailed_findings TEXT,
    recommendations VARCHAR(20), -- 'proceed', 'negotiate', 'reject'
    
    -- Media
    photos TEXT[], -- Additional photos beyond call media
    video_highlights TEXT[], -- Timestamped video clips
    pdf_url TEXT, -- Generated PDF report
    
    -- Status
    status report_status DEFAULT 'draft',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    submitted_at TIMESTAMP,
    approved_at TIMESTAMP
);

-- Agent Notes (During verification preparation)
CREATE TABLE agent_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    note TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE, -- If true, not shared with importer
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- ORDER TABLES
-- ========================================

-- Orders
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    
    -- References
    rfq_id UUID REFERENCES rfqs(id) ON DELETE SET NULL,
    quote_id UUID REFERENCES quotes(id) ON DELETE SET NULL,
    verification_id UUID REFERENCES verifications(id) ON DELETE SET NULL,
    
    -- Parties
    importer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    supplier_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Financial
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(50), -- Importer's payment method (not PANDAS)
    payment_receipt_url TEXT,
    
    -- Shipping
    shipping_method VARCHAR(100),
    tracking_number VARCHAR(255),
    estimated_delivery_date DATE,
    
    -- Status
    status order_status DEFAULT 'awaiting_payment',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    payment_confirmed_at TIMESTAMP,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP
);

-- Order Events (Timeline milestones)
CREATE TABLE order_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Event Details
    event_type VARCHAR(50) NOT NULL, -- 'production_started', 'shipped', etc
    title VARCHAR(255),
    description TEXT,
    
    -- Progress
    progress_percentage INTEGER CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    
    -- Media
    photos TEXT[],
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- PAYMENT TABLES
-- ========================================

-- Payments (Verification fee payments to PANDAS)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    verification_id UUID REFERENCES verifications(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Amount
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Payment Details
    method payment_method NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    external_reference VARCHAR(255), -- M-Pesa/Stripe reference
    
    -- Status
    status payment_status DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    failed_at TIMESTAMP,
    refunded_at TIMESTAMP
);

-- Agent Wallet
CREATE TABLE agent_wallet (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    
    -- Balance
    balance DECIMAL(10,2) DEFAULT 0 CHECK (balance >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Wallet Transactions
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES agent_wallet(id) ON DELETE CASCADE,
    verification_id UUID REFERENCES verifications(id) ON DELETE SET NULL,
    
    -- Transaction Details
    type wallet_transaction_type NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT,
    
    -- Balance Tracking
    balance_before DECIMAL(10,2),
    balance_after DECIMAL(10,2),
    
    -- Status
    status payment_status DEFAULT 'completed',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- Withdrawals (Agent cash-out requests)
CREATE TABLE withdrawals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES agent_wallet(id) ON DELETE CASCADE,
    
    -- Amount
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Withdrawal Details
    method VARCHAR(50) NOT NULL, -- 'bank_transfer', 'alipay', 'paypal', 'wise'
    account_details JSONB, -- Encrypted account info
    
    -- Processing
    status withdrawal_status DEFAULT 'requested',
    admin_notes TEXT,
    transaction_reference VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    processed_at TIMESTAMP,
    completed_at TIMESTAMP,
    rejected_at TIMESTAMP
);

-- ========================================
-- AGENT TABLES
-- ========================================

-- Agents (Extended profile for verification agents)
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    
    -- Location
    location_city VARCHAR(100) NOT NULL,
    location_country VARCHAR(50) NOT NULL,
    service_radius_km INTEGER DEFAULT 50,
    
    -- Skills
    languages TEXT[] NOT NULL, -- ['English', 'Mandarin', 'Swahili']
    expertise TEXT[] NOT NULL, -- ['textiles', 'electronics']
    years_experience INTEGER,
    
    -- Documents
    id_document_url TEXT,
    resume_url TEXT,
    certifications TEXT[], -- URLs to agent certifications
    
    -- Verification
    background_check_status background_check_status DEFAULT 'pending',
    background_check_date DATE,
    training_completed BOOLEAN DEFAULT FALSE,
    training_completed_date DATE,
    
    -- Performance
    rating_average DECIMAL(3,2) DEFAULT 0,
    total_verifications INTEGER DEFAULT 0,
    total_earnings DECIMAL(10,2) DEFAULT 0,
    
    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    calendar_url TEXT, -- Google Calendar sync
    
    -- Status
    status agent_status DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    suspended_at TIMESTAMP
);

-- Agent Availability Calendar
CREATE TABLE agent_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Time Slot
    day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Agent Blocked Dates (Vacations, etc)
CREATE TABLE agent_blocked_dates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- SUPPLIER TABLES
-- ========================================

-- Suppliers (Extended profile for suppliers)
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    
    -- Business Info
    company_name VARCHAR(255) NOT NULL,
    company_registration_number VARCHAR(100),
    location_city VARCHAR(100) NOT NULL,
    location_country VARCHAR(50) NOT NULL,
    factory_address TEXT,
    
    -- Products
    product_categories TEXT[] NOT NULL, -- ['textiles', 'electronics']
    minimum_order_quantity INTEGER,
    production_capacity_monthly INTEGER,
    
    -- Certifications
    certifications TEXT[], -- URLs to ISO, CE, etc
    
    -- Performance
    rating_average DECIMAL(3,2) DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0,
    
    -- Status
    status supplier_status DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    suspended_at TIMESTAMP
);

-- Supplier Badges
CREATE TABLE supplier_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supplier_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    badge_type badge_type NOT NULL,
    earned_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    
    UNIQUE(supplier_id, badge_type)
);

-- ========================================
-- MESSAGING TABLES
-- ========================================

-- Messages (In-app chat)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Participants
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Context
    rfq_id UUID REFERENCES rfqs(id) ON DELETE SET NULL,
    verification_id UUID REFERENCES verifications(id) ON DELETE SET NULL,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    
    -- Message Content
    message TEXT NOT NULL,
    attachments TEXT[], -- URLs to uploaded files
    
    -- Status
    status message_status DEFAULT 'sent',
    read_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- Message Threads (Conversation grouping)
CREATE TABLE message_threads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Participants
    participant_1_id UUID REFERENCES users(id) ON DELETE CASCADE,
    participant_2_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Context
    rfq_id UUID REFERENCES rfqs(id) ON DELETE SET NULL,
    
    -- Metadata
    last_message_at TIMESTAMP,
    unread_count_p1 INTEGER DEFAULT 0,
    unread_count_p2 INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(participant_1_id, participant_2_id, rfq_id)
);

-- ========================================
-- REVIEW TABLES
-- ========================================

-- Reviews (Importers review Suppliers & Agents)
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    verification_id UUID REFERENCES verifications(id) ON DELETE SET NULL,
    
    -- Participants
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reviewee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reviewee_type user_role NOT NULL, -- 'supplier' or 'agent'
    
    -- Rating
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    
    -- Review Content
    comment TEXT,
    photos TEXT[],
    
    -- Categories (specific ratings)
    quality_rating INTEGER CHECK (quality_rating >= 1 AND quality_rating <= 5),
    communication_rating INTEGER CHECK (communication_rating >= 1 AND communication_rating <= 5),
    delivery_rating INTEGER CHECK (delivery_rating >= 1 AND delivery_rating <= 5),
    
    -- Status
    status review_status DEFAULT 'pending',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    published_at TIMESTAMP,
    
    -- Prevent duplicate reviews
    UNIQUE(order_id, reviewer_id, reviewee_id)
);

-- ========================================
-- DOCUMENT ACCESS LOG
-- ========================================

-- Document Access Logs (Track who accessed reports)
CREATE TABLE document_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES verification_reports(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Access Details
    action document_access_action NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Share Links
    share_link_token VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- Share Links (Temporary links to share reports)
CREATE TABLE share_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_id UUID REFERENCES verification_reports(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Link Details
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    access_count INTEGER DEFAULT 0,
    max_access_count INTEGER, -- Optional limit
    
    -- Password Protection
    password_hash VARCHAR(255),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    last_accessed_at TIMESTAMP
);

-- ========================================
-- NOTIFICATION TABLES
-- ========================================

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Notification Details
    type VARCHAR(50) NOT NULL, -- 'rfq_quote', 'verification_scheduled', etc
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    
    -- Links
    action_url TEXT, -- Deep link to specific page
    
    -- Related Entities
    rfq_id UUID REFERENCES rfqs(id) ON DELETE SET NULL,
    verification_id UUID REFERENCES verifications(id) ON DELETE SET NULL,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    
    -- Status
    read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    
    -- Channels
    sent_email BOOLEAN DEFAULT FALSE,
    sent_sms BOOLEAN DEFAULT FALSE,
    sent_whatsapp BOOLEAN DEFAULT FALSE,
    sent_push BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- ANALYTICS TABLES
-- ========================================

-- User Sessions (Login tracking)
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Session Details
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type VARCHAR(50), -- 'mobile', 'desktop', 'tablet'
    
    -- Location
    country VARCHAR(50),
    city VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    last_activity_at TIMESTAMP
);

-- Platform Events (Analytics tracking)
CREATE TABLE platform_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Event Details
    event_type VARCHAR(100) NOT NULL, -- 'rfq_created', 'quote_submitted', etc
    event_category VARCHAR(50), -- 'rfq', 'verification', 'payment'
    
    -- Properties (flexible JSON)
    properties JSONB,
    
    -- Session
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- ADMIN TABLES
-- ========================================

-- Admin Actions Log
CREATE TABLE admin_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Action Details
    action_type VARCHAR(100) NOT NULL, -- 'approve_agent', 'suspend_supplier', etc
    target_type VARCHAR(50), -- 'user', 'verification', 'order'
    target_id UUID,
    
    -- Details
    description TEXT,
    metadata JSONB,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW()
);

-- ========================================
-- INDEXES (Performance Optimization)
-- ========================================

-- Users
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at);

-- RFQs
CREATE INDEX idx_rfqs_importer_id ON rfqs(importer_id);
CREATE INDEX idx_rfqs_status ON rfqs(status);
CREATE INDEX idx_rfqs_category ON rfqs(category);
CREATE INDEX idx_rfqs_created_at ON rfqs(created_at);

-- Quotes
CREATE INDEX idx_quotes_rfq_id ON quotes(rfq_id);
CREATE INDEX idx_quotes_supplier_id ON quotes(supplier_id);
CREATE INDEX idx_quotes_status ON quotes(status);

-- Verifications
CREATE INDEX idx_verifications_importer_id ON verifications(importer_id);
CREATE INDEX idx_verifications_agent_id ON verifications(agent_id);
CREATE INDEX idx_verifications_supplier_id ON verifications(supplier_id);
CREATE INDEX idx_verifications_status ON verifications(status);
CREATE INDEX idx_verifications_scheduled_time ON verifications(scheduled_time);

-- Orders
CREATE INDEX idx_orders_importer_id ON orders(importer_id);
CREATE INDEX idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Messages
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Reviews
CREATE INDEX idx_reviews_reviewee_id ON reviews(reviewee_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_status ON reviews(status);

-- Agents
CREATE INDEX idx_agents_status ON agents(status);
CREATE INDEX idx_agents_location_city ON agents(location_city);
CREATE INDEX idx_agents_rating_average ON agents(rating_average);

-- Suppliers
CREATE INDEX idx_suppliers_status ON suppliers(status);
CREATE INDEX idx_suppliers_location_city ON suppliers(location_city);
CREATE INDEX idx_suppliers_rating_average ON suppliers(rating_average);

-- Notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- ========================================
-- TRIGGERS (Automated Actions)
-- ========================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rfqs_updated_at BEFORE UPDATE ON rfqs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-generate RFQ number
CREATE OR REPLACE FUNCTION generate_rfq_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.rfq_number = 'RFQ-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('rfq_number_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE rfq_number_seq START 1;

CREATE TRIGGER generate_rfq_number_trigger BEFORE INSERT ON rfqs
    FOR EACH ROW EXECUTE FUNCTION generate_rfq_number();

-- Auto-generate Order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.order_number = 'ORD-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('order_number_seq')::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE order_number_seq START 1;

CREATE TRIGGER generate_order_number_trigger BEFORE INSERT ON orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- Update wallet balance on transaction
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type = 'credit' THEN
        UPDATE agent_wallet
        SET balance = balance + NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.wallet_id;
    ELSE
        UPDATE agent_wallet
        SET balance = balance - NEW.amount,
            updated_at = NOW()
        WHERE id = NEW.wallet_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_wallet_balance_trigger AFTER INSERT ON wallet_transactions
    FOR EACH ROW EXECUTE FUNCTION update_wallet_balance();

-- Update review counts and averages
CREATE OR REPLACE FUNCTION update_review_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reviewee_type = 'agent' THEN
        UPDATE agents
        SET rating_average = (
            SELECT AVG(rating)::DECIMAL(3,2)
            FROM reviews
            WHERE reviewee_id = NEW.reviewee_id AND status = 'published'
        )
        WHERE user_id = NEW.reviewee_id;
    ELSIF NEW.reviewee_type = 'supplier' THEN
        UPDATE suppliers
        SET rating_average = (
            SELECT AVG(rating)::DECIMAL(3,2)
            FROM reviews
            WHERE reviewee_id = NEW.reviewee_id AND status = 'published'
        )
        WHERE user_id = NEW.reviewee_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_review_stats_trigger AFTER INSERT OR UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_review_stats();

-- ========================================
-- VIEWS (Convenient Data Access)
-- ========================================

-- Active Verifications View
CREATE VIEW active_verifications AS
SELECT 
    v.*,
    u_importer.full_name AS importer_name,
    u_importer.phone AS importer_phone,
    u_agent.full_name AS agent_name,
    u_agent.phone AS agent_phone,
    u_supplier.business_name AS supplier_name,
    r.product_name,
    r.category
FROM verifications v
JOIN users u_importer ON v.importer_id = u_importer.id
LEFT JOIN users u_agent ON v.agent_id = u_agent.id
JOIN users u_supplier ON v.supplier_id = u_supplier.id
JOIN rfqs r ON v.rfq_id = r.id
WHERE v.status IN ('scheduled', 'in_progress');

-- Agent Performance Dashboard
CREATE VIEW agent_performance AS
SELECT 
    a.user_id,
    u.full_name,
    a.location_city,
    a.rating_average,
    a.total_verifications,
    a.total_earnings,
    w.balance AS current_balance,
    COUNT(DISTINCT v.id) AS verifications_this_month
FROM agents a
JOIN users u ON a.user_id = u.id
LEFT JOIN agent_wallet w ON a.user_id = w.agent_id
LEFT JOIN verifications v ON a.user_id = v.agent_id 
    AND v.created_at >= DATE_TRUNC('month', NOW())
GROUP BY a.user_id, u.full_name, a.location_city, a.rating_average, 
         a.total_verifications, a.total_earnings, w.balance;

-- Supplier Performance Dashboard
CREATE VIEW supplier_performance AS
SELECT 
    s.user_id,
    u.business_name,
    s.location_city,
    s.rating_average,
    s.total_orders,
    s.total_revenue,
    COUNT(DISTINCT q.id) AS quotes_submitted,
    COUNT(DISTINCT o.id) AS active_orders
FROM suppliers s
JOIN users u ON s.user_id = u.id
LEFT JOIN quotes q ON s.user_id = q.supplier_id
LEFT JOIN orders o ON s.user_id = o.supplier_id 
    AND o.status NOT IN ('completed', 'cancelled')
GROUP BY s.user_id, u.business_name, s.location_city, 
         s.rating_average, s.total_orders, s.total_revenue;

-- ========================================
-- INITIAL SEED DATA
-- ========================================

-- Create admin user (Change password in production!)
INSERT INTO users (role, full_name, phone, email, password_hash, phone_verified, email_verified, is_active)
VALUES (
    'admin',
    'PANDAS Admin',
    '+255000000000',
    'admin@pandaslogistics.com',
    -- Password: 'ChangeMe123!' (use bcrypt in production)
    '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m',
    TRUE,
    TRUE,
    TRUE
);

-- ========================================
-- GRANTS (Security - Adjust for your setup)
-- ========================================

-- Create application user (separate from superuser)
-- CREATE USER pandas_app WITH PASSWORD 'your_secure_password_here';
-- GRANT CONNECT ON DATABASE pandas_db TO pandas_app;
-- GRANT USAGE ON SCHEMA public TO pandas_app;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pandas_app;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pandas_app;

-- ========================================
-- COMMENTS (Documentation)
-- ========================================

COMMENT ON TABLE users IS 'All platform users: importers, agents, suppliers, admins';
COMMENT ON TABLE rfqs IS 'Request for Quotes from importers';
COMMENT ON TABLE verifications IS 'Live Verification Calls (LVC) - core PANDAS feature';
COMMENT ON TABLE agent_wallet IS 'Agent earnings wallet for commission payouts';
COMMENT ON TABLE reviews IS 'Reviews and ratings for suppliers and agents';

-- ========================================
-- END OF SCHEMA
-- ========================================

-- Verify setup
SELECT 'Database schema created successfully!' AS status;