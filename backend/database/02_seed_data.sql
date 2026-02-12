-- ========================================
-- PANDAS GLOBAL LOGISTICS - SEED DATA
-- Test Data for Development/Staging
-- ========================================
-- Run this AFTER 01_create_schema.sql
-- ========================================

-- ========================================
-- TEST USERS
-- ========================================

-- Password for all test users: 'Test123!'
-- Hash generated with bcrypt (adjust based on your auth library)

-- Test Importers (3 users)
INSERT INTO users (role, full_name, phone, email, password_hash, business_name, location_city, location_country, phone_verified, email_verified, timezone)
VALUES 
    ('importer', 'Fatma Hassan', '+255712345678', 'fatma@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Fatma Textiles', 'Dar es Salaam', 'Tanzania', TRUE, TRUE, 'Africa/Dar_es_Salaam'),
    ('importer', 'John Mwamba', '+254722345678', 'john@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Mwamba Trading', 'Nairobi', 'Kenya', TRUE, TRUE, 'Africa/Nairobi'),
    ('importer', 'Sarah Nakato', '+256712345678', 'sarah@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Nakato Imports', 'Kampala', 'Uganda', TRUE, TRUE, 'Africa/Kampala');

-- Test Agents (3 users)
INSERT INTO users (role, full_name, phone, email, password_hash, location_city, location_country, phone_verified, email_verified, timezone)
VALUES 
    ('agent', 'Chen Wei', '+8613812345678', 'chen@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Guangzhou', 'China', TRUE, TRUE, 'Asia/Shanghai'),
    ('agent', 'Li Ming', '+8613887654321', 'li@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Shenzhen', 'China', TRUE, TRUE, 'Asia/Shanghai'),
    ('agent', 'Ahmed Al-Rashid', '+971501234567', 'ahmed@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Dubai', 'UAE', TRUE, TRUE, 'Asia/Dubai');

-- Test Suppliers (3 users)
INSERT INTO users (role, full_name, phone, email, password_hash, business_name, location_city, location_country, phone_verified, email_verified, timezone)
VALUES 
    ('supplier', 'Wang Manufacturing', '+8620123456789', 'wang@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Wang Textiles Ltd', 'Guangzhou', 'China', TRUE, TRUE, 'Asia/Shanghai'),
    ('supplier', 'Zhang Electronics', '+8675512345678', 'zhang@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Zhang Electronics Co', 'Shenzhen', 'China', TRUE, TRUE, 'Asia/Shanghai'),
    ('supplier', 'Emirates Trading', '+971501987654', 'emirates@example.com', '$2b$10$rZ8qRhQUBqFqE4GKLlYNQ.QVZCXwV3XxqKdYRJKL3YCpQQ0wXqJ3m', 'Emirates Trading LLC', 'Dubai', 'UAE', TRUE, TRUE, 'Asia/Dubai');

-- ========================================
-- AGENT PROFILES
-- ========================================

INSERT INTO agents (user_id, location_city, location_country, service_radius_km, languages, expertise, years_experience, background_check_status, training_completed, rating_average, total_verifications, status, approved_at)
SELECT 
    id,
    location_city,
    location_country,
    50,
    CASE 
        WHEN full_name = 'Chen Wei' THEN ARRAY['Mandarin', 'English', 'Cantonese']
        WHEN full_name = 'Li Ming' THEN ARRAY['Mandarin', 'English']
        WHEN full_name = 'Ahmed Al-Rashid' THEN ARRAY['Arabic', 'English', 'Hindi']
    END,
    CASE 
        WHEN full_name = 'Chen Wei' THEN ARRAY['textiles', 'garments', 'fabrics']
        WHEN full_name = 'Li Ming' THEN ARRAY['electronics', 'machinery', 'hardware']
        WHEN full_name = 'Ahmed Al-Rashid' THEN ARRAY['textiles', 'jewelry', 'luxury_goods']
    END,
    CASE 
        WHEN full_name = 'Chen Wei' THEN 8
        WHEN full_name = 'Li Ming' THEN 5
        WHEN full_name = 'Ahmed Al-Rashid' THEN 12
    END,
    'passed',
    TRUE,
    4.8,
    25,
    'active',
    NOW() - INTERVAL '30 days'
FROM users WHERE role = 'agent';

-- Create wallets for agents
INSERT INTO agent_wallet (agent_id, balance)
SELECT id, 0.00
FROM users WHERE role = 'agent';

-- ========================================
-- SUPPLIER PROFILES
-- ========================================

INSERT INTO suppliers (user_id, company_name, location_city, location_country, product_categories, minimum_order_quantity, production_capacity_monthly, rating_average, total_orders, status, approved_at)
SELECT 
    id,
    business_name,
    location_city,
    location_country,
    CASE 
        WHEN business_name = 'Wang Textiles Ltd' THEN ARRAY['textiles', 'fabrics', 'garments']
        WHEN business_name = 'Zhang Electronics Co' THEN ARRAY['electronics', 'consumer_electronics', 'components']
        WHEN business_name = 'Emirates Trading LLC' THEN ARRAY['textiles', 'fashion', 'accessories']
    END,
    CASE 
        WHEN business_name = 'Wang Textiles Ltd' THEN 1000
        WHEN business_name = 'Zhang Electronics Co' THEN 500
        WHEN business_name = 'Emirates Trading LLC' THEN 2000
    END,
    CASE 
        WHEN business_name = 'Wang Textiles Ltd' THEN 50000
        WHEN business_name = 'Zhang Electronics Co' THEN 10000
        WHEN business_name = 'Emirates Trading LLC' THEN 30000
    END,
    4.7,
    15,
    'active',
    NOW() - INTERVAL '60 days'
FROM users WHERE role = 'supplier';

-- ========================================
-- SAMPLE RFQs
-- ========================================

INSERT INTO rfqs (importer_id, category, product_name, description, quantity, unit, budget_min, budget_max, quality_level, deadline, status)
SELECT 
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    'textiles',
    'Cotton Fabric for Dresses',
    'High-quality cotton fabric, 100% cotton, medium weight, suitable for dress making. Need solid colors: navy, black, burgundy.',
    5000,
    'meters',
    3.50,
    5.00,
    'Premium',
    NOW() + INTERVAL '45 days',
    'open'
UNION ALL
SELECT 
    (SELECT id FROM users WHERE full_name = 'John Mwamba'),
    'electronics',
    'LED Bulbs - E27 Base',
    'Energy-efficient LED bulbs, 9W, warm white (3000K), E27 screw base. CE certified.',
    10000,
    'pieces',
    0.80,
    1.50,
    'Standard',
    NOW() + INTERVAL '30 days',
    'quoted'
UNION ALL
SELECT 
    (SELECT id FROM users WHERE full_name = 'Sarah Nakato'),
    'fashion',
    'Women''s Leather Handbags',
    'PU leather handbags, medium size, assorted colors. Good quality hardware and zippers.',
    500,
    'pieces',
    8.00,
    15.00,
    'Premium',
    NOW() + INTERVAL '60 days',
    'open';

-- ========================================
-- SAMPLE QUOTES
-- ========================================

INSERT INTO quotes (rfq_id, supplier_id, unit_price, total_price, minimum_order_quantity, delivery_days, payment_terms, shipping_method, status)
SELECT 
    (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
    (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd'),
    4.20,
    21000.00,
    3000,
    25,
    '30% deposit, 70% before shipment',
    'Sea freight to Dar es Salaam',
    'selected'
UNION ALL
SELECT 
    (SELECT id FROM rfqs WHERE product_name = 'LED Bulbs - E27 Base'),
    (SELECT id FROM users WHERE business_name = 'Zhang Electronics Co'),
    1.05,
    10500.00,
    5000,
    20,
    '50% deposit, 50% before shipment',
    'Air freight to Nairobi',
    'pending'
UNION ALL
SELECT 
    (SELECT id FROM rfqs WHERE product_name = 'LED Bulbs - E27 Base'),
    (SELECT id FROM users WHERE business_name = 'Emirates Trading LLC'),
    1.25,
    12500.00,
    5000,
    15,
    '40% deposit, 60% before shipment',
    'Air freight to Nairobi',
    'pending';

-- ========================================
-- SAMPLE VERIFICATION (Scheduled)
-- ========================================

INSERT INTO verifications (
    rfq_id, 
    quote_id,
    importer_id, 
    agent_id, 
    supplier_id,
    type,
    scheduled_time,
    timezone,
    verification_fee,
    agent_commission,
    payment_status,
    payment_method,
    video_platform,
    room_link,
    status
)
SELECT 
    (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
    (SELECT id FROM quotes WHERE supplier_id = (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd')),
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    (SELECT id FROM users WHERE full_name = 'Chen Wei'),
    (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd'),
    'factory_visit',
    NOW() + INTERVAL '2 days' + INTERVAL '6 hours', -- 2 days from now, 6am
    'Africa/Dar_es_Salaam',
    50.00,
    35.00,
    'paid',
    'stripe',
    'twilio',
    'https://video.twilio.com/v1/Rooms/RMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    'scheduled';

-- ========================================
-- SAMPLE ORDER
-- ========================================

INSERT INTO orders (
    rfq_id,
    quote_id,
    importer_id,
    supplier_id,
    verification_id,
    total_amount,
    payment_method,
    shipping_method,
    tracking_number,
    status
)
SELECT 
    (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
    (SELECT id FROM quotes WHERE supplier_id = (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd')),
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd'),
    (SELECT id FROM verifications LIMIT 1),
    21000.00,
    'Bank wire transfer',
    'Sea freight',
    'MAEU123456789',
    'in_production';

-- Add order events
INSERT INTO order_events (order_id, event_type, title, description, progress_percentage)
SELECT 
    id,
    'payment_confirmed',
    'Payment Received',
    'Supplier confirmed receipt of 30% deposit ($6,300)',
    10
FROM orders WHERE status = 'in_production'
UNION ALL
SELECT 
    id,
    'production_started',
    'Production Started',
    'Fabric cutting and dyeing in progress',
    25
FROM orders WHERE status = 'in_production';

-- ========================================
-- SAMPLE MESSAGES
-- ========================================

INSERT INTO messages (sender_id, receiver_id, rfq_id, message, status, read_at)
SELECT 
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd'),
    (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
    'Hi, can you provide fabric samples before I place the order?',
    'read',
    NOW() - INTERVAL '1 hour'
UNION ALL
SELECT 
    (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd'),
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
    'Yes, we can send samples. Please provide your shipping address.',
    'read',
    NOW() - INTERVAL '30 minutes';

-- ========================================
-- SAMPLE REVIEWS
-- ========================================

INSERT INTO reviews (
    order_id,
    verification_id,
    reviewer_id,
    reviewee_id,
    reviewee_type,
    rating,
    comment,
    quality_rating,
    communication_rating,
    delivery_rating,
    status,
    published_at
)
SELECT 
    (SELECT id FROM orders LIMIT 1),
    (SELECT id FROM verifications LIMIT 1),
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    (SELECT id FROM users WHERE full_name = 'Chen Wei'),
    'agent',
    5,
    'Excellent verification! Mr. Chen was very thorough and professional. He showed me everything I needed to see.',
    5,
    5,
    NULL, -- Not applicable for agent review
    'published',
    NOW() - INTERVAL '1 day';

-- ========================================
-- SAMPLE NOTIFICATIONS
-- ========================================

INSERT INTO notifications (user_id, type, title, message, action_url, rfq_id, read, sent_email, sent_push)
SELECT 
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    'verification_scheduled',
    'Verification Scheduled',
    'Your verification with Wang Textiles is scheduled for ' || TO_CHAR(NOW() + INTERVAL '2 days', 'Mon DD at HH:MI AM'),
    '/verifications/' || (SELECT id FROM verifications LIMIT 1),
    (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
    FALSE,
    TRUE,
    TRUE
UNION ALL
SELECT 
    (SELECT id FROM users WHERE full_name = 'Chen Wei'),
    'verification_assignment',
    'New Verification Job',
    'You have been assigned a factory visit in Guangzhou. Fee: $35',
    '/agent/verifications/' || (SELECT id FROM verifications LIMIT 1),
    NULL,
    FALSE,
    TRUE,
    TRUE;

-- ========================================
-- SAMPLE ANALYTICS
-- ========================================

INSERT INTO platform_events (user_id, event_type, event_category, properties)
SELECT 
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    'rfq_created',
    'rfq',
    jsonb_build_object(
        'category', 'textiles',
        'budget', 21000,
        'quantity', 5000
    )
UNION ALL
SELECT 
    (SELECT id FROM users WHERE business_name = 'Wang Textiles Ltd'),
    'quote_submitted',
    'quote',
    jsonb_build_object(
        'rfq_id', (SELECT id FROM rfqs WHERE product_name = 'Cotton Fabric for Dresses'),
        'amount', 21000,
        'delivery_days', 25
    )
UNION ALL
SELECT 
    (SELECT id FROM users WHERE full_name = 'Fatma Hassan'),
    'verification_booked',
    'verification',
    jsonb_build_object(
        'type', 'factory_visit',
        'fee', 50,
        'agent_id', (SELECT id FROM users WHERE full_name = 'Chen Wei')
    );

-- ========================================
-- VERIFICATION COMPLETE
-- ========================================

SELECT 'Seed data inserted successfully!' AS status,
       (SELECT COUNT(*) FROM users) AS total_users,
       (SELECT COUNT(*) FROM rfqs) AS total_rfqs,
       (SELECT COUNT(*) FROM quotes) AS total_quotes,
       (SELECT COUNT(*) FROM verifications) AS total_verifications,
       (SELECT COUNT(*) FROM orders) AS total_orders;