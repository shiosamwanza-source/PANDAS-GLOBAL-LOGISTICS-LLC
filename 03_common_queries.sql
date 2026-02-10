-- ========================================
-- PANDAS GLOBAL LOGISTICS - COMMON QUERIES
-- Useful SQL queries for API development
-- ========================================

-- ========================================
-- USER QUERIES
-- ========================================

-- Get user profile (any role)
SELECT 
    u.*,
    CASE 
        WHEN u.role = 'agent' THEN jsonb_build_object(
            'rating', a.rating_average,
            'total_verifications', a.total_verifications,
            'languages', a.languages,
            'expertise', a.expertise,
            'status', a.status
        )
        WHEN u.role = 'supplier' THEN jsonb_build_object(
            'company', s.company_name,
            'rating', s.rating_average,
            'total_orders', s.total_orders,
            'categories', s.product_categories,
            'status', s.status
        )
        ELSE NULL
    END AS profile_data
FROM users u
LEFT JOIN agents a ON u.id = a.user_id
LEFT JOIN suppliers s ON u.id = s.user_id
WHERE u.id = $1; -- Replace $1 with user ID

-- Authenticate user (for login)
SELECT id, role, full_name, email, phone, password_hash
FROM users
WHERE (email = $1 OR phone = $1)
AND is_active = TRUE;

-- Check if phone/email exists (for registration)
SELECT EXISTS(
    SELECT 1 FROM users 
    WHERE phone = $1 OR email = $2
) AS exists;

-- ========================================
-- RFQ QUERIES
-- ========================================

-- Get all RFQs for an importer
SELECT 
    r.*,
    (SELECT COUNT(*) FROM quotes q WHERE q.rfq_id = r.id) AS quote_count,
    (SELECT COUNT(*) FROM verifications v WHERE v.rfq_id = r.id) AS verification_count
FROM rfqs r
WHERE r.importer_id = $1
ORDER BY r.created_at DESC;

-- Get open RFQs for suppliers (matching)
SELECT 
    r.*,
    u.full_name AS importer_name,
    u.location_city AS importer_city
FROM rfqs r
JOIN users u ON r.importer_id = u.id
WHERE r.status = 'open'
AND r.category = ANY($1) -- Array of supplier's categories
AND r.budget_max >= $2 -- Supplier's minimum acceptable price
ORDER BY r.created_at DESC
LIMIT 20;

-- Get RFQ details with quotes
SELECT 
    r.*,
    u.full_name AS importer_name,
    jsonb_agg(
        jsonb_build_object(
            'quote_id', q.id,
            'supplier_id', q.supplier_id,
            'supplier_name', su.business_name,
            'supplier_rating', s.rating_average,
            'unit_price', q.unit_price,
            'total_price', q.total_price,
            'delivery_days', q.delivery_days,
            'status', q.status
        ) ORDER BY q.total_price ASC
    ) FILTER (WHERE q.id IS NOT NULL) AS quotes
FROM rfqs r
JOIN users u ON r.importer_id = u.id
LEFT JOIN quotes q ON r.id = q.rfq_id
LEFT JOIN users su ON q.supplier_id = su.id
LEFT JOIN suppliers s ON su.id = s.user_id
WHERE r.id = $1
GROUP BY r.id, u.full_name;

-- ========================================
-- QUOTE QUERIES
-- ========================================

-- Get quotes for a supplier
SELECT 
    q.*,
    r.product_name,
    r.category,
    r.quantity,
    u.full_name AS importer_name
FROM quotes q
JOIN rfqs r ON q.rfq_id = r.id
JOIN users u ON r.importer_id = u.id
WHERE q.supplier_id = $1
ORDER BY q.created_at DESC;

-- Compare quotes for an RFQ
SELECT 
    q.id,
    q.unit_price,
    q.total_price,
    q.delivery_days,
    q.minimum_order_quantity,
    q.payment_terms,
    q.status,
    su.business_name AS supplier_name,
    s.rating_average AS supplier_rating,
    s.total_orders AS supplier_orders,
    s.location_city AS supplier_location
FROM quotes q
JOIN users su ON q.supplier_id = su.id
JOIN suppliers s ON su.id = s.user_id
WHERE q.rfq_id = $1
ORDER BY 
    CASE WHEN q.status = 'selected' THEN 0 ELSE 1 END,
    q.total_price ASC;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Get upcoming verifications for an agent
SELECT 
    v.*,
    r.product_name,
    r.category,
    u_importer.full_name AS importer_name,
    u_importer.phone AS importer_phone,
    u_supplier.business_name AS supplier_name,
    u_supplier.location_city AS supplier_city
FROM verifications v
JOIN rfqs r ON v.rfq_id = r.id
JOIN users u_importer ON v.importer_id = u_importer.id
JOIN users u_supplier ON v.supplier_id = u_supplier.id
WHERE v.agent_id = $1
AND v.status IN ('scheduled', 'in_progress')
AND v.scheduled_time >= NOW()
ORDER BY v.scheduled_time ASC;

-- Get verification details (for all parties)
SELECT 
    v.*,
    r.product_name,
    r.category,
    r.description,
    q.total_price AS order_value,
    u_importer.full_name AS importer_name,
    u_importer.phone AS importer_phone,
    u_importer.email AS importer_email,
    u_agent.full_name AS agent_name,
    u_agent.phone AS agent_phone,
    a.rating_average AS agent_rating,
    u_supplier.business_name AS supplier_name,
    u_supplier.phone AS supplier_phone,
    s.factory_address AS supplier_address,
    vr.overall_score AS report_score,
    vr.recommendations AS report_recommendation,
    vr.pdf_url AS report_url
FROM verifications v
JOIN rfqs r ON v.rfq_id = r.id
LEFT JOIN quotes q ON v.quote_id = q.id
JOIN users u_importer ON v.importer_id = u_importer.id
LEFT JOIN users u_agent ON v.agent_id = u_agent.id
LEFT JOIN agents a ON u_agent.id = a.user_id
JOIN users u_supplier ON v.supplier_id = u_supplier.id
LEFT JOIN suppliers s ON u_supplier.id = s.user_id
LEFT JOIN verification_reports vr ON v.id = vr.verification_id
WHERE v.id = $1;

-- Find available agents for a verification
SELECT 
    u.id,
    u.full_name,
    u.phone,
    a.rating_average,
    a.total_verifications,
    a.languages,
    a.expertise,
    -- Calculate distance (simplified - use PostGIS for real distance)
    'Nearby' AS distance_status
FROM users u
JOIN agents a ON u.id = a.user_id
WHERE a.status = 'active'
AND a.is_available = TRUE
AND a.location_city = $1 -- Supplier's city
AND $2 = ANY(a.expertise) -- RFQ category
-- Check for conflicts in schedule
AND NOT EXISTS (
    SELECT 1 FROM verifications v
    WHERE v.agent_id = u.id
    AND v.status IN ('scheduled', 'in_progress')
    AND v.scheduled_time BETWEEN $3 - INTERVAL '2 hours' 
                              AND $3 + INTERVAL '2 hours'
)
ORDER BY a.rating_average DESC, a.total_verifications DESC
LIMIT 10;

-- ========================================
-- ORDER QUERIES
-- ========================================

-- Get orders for an importer
SELECT 
    o.*,
    r.product_name,
    r.category,
    su.business_name AS supplier_name,
    s.rating_average AS supplier_rating,
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'event_type', oe.event_type,
                'title', oe.title,
                'description', oe.description,
                'progress', oe.progress_percentage,
                'created_at', oe.created_at
            ) ORDER BY oe.created_at DESC
        )
        FROM order_events oe
        WHERE oe.order_id = o.id
    ) AS timeline
FROM orders o
JOIN rfqs r ON o.rfq_id = r.id
JOIN users su ON o.supplier_id = su.id
JOIN suppliers s ON su.id = s.user_id
WHERE o.importer_id = $1
ORDER BY o.created_at DESC;

-- Get orders for a supplier
SELECT 
    o.*,
    r.product_name,
    r.category,
    r.quantity,
    u.full_name AS importer_name,
    u.phone AS importer_phone
FROM orders o
JOIN rfqs r ON o.rfq_id = r.id
JOIN users u ON o.importer_id = u.id
WHERE o.supplier_id = $1
ORDER BY 
    CASE o.status
        WHEN 'awaiting_payment' THEN 1
        WHEN 'payment_confirmed' THEN 2
        WHEN 'in_production' THEN 3
        WHEN 'shipped' THEN 4
        ELSE 5
    END,
    o.created_at DESC;

-- Get order timeline events
SELECT 
    oe.*
FROM order_events oe
WHERE oe.order_id = $1
ORDER BY oe.created_at ASC;

-- ========================================
-- PAYMENT QUERIES
-- ========================================

-- Get agent wallet balance
SELECT 
    w.balance,
    w.currency,
    (
        SELECT SUM(wt.amount)
        FROM wallet_transactions wt
        WHERE wt.wallet_id = w.id
        AND wt.type = 'credit'
        AND wt.created_at >= DATE_TRUNC('month', NOW())
    ) AS earnings_this_month,
    (
        SELECT COUNT(*)
        FROM verifications v
        WHERE v.agent_id = w.agent_id
        AND v.status = 'completed'
        AND v.completed_at >= DATE_TRUNC('month', NOW())
    ) AS verifications_this_month
FROM agent_wallet w
WHERE w.agent_id = $1;

-- Get agent transaction history
SELECT 
    wt.*,
    v.scheduled_time AS verification_date,
    r.product_name,
    u.business_name AS supplier_name
FROM wallet_transactions wt
LEFT JOIN verifications v ON wt.verification_id = v.id
LEFT JOIN rfqs r ON v.rfq_id = r.id
LEFT JOIN users u ON v.supplier_id = u.id
WHERE wt.wallet_id = (
    SELECT id FROM agent_wallet WHERE agent_id = $1
)
ORDER BY wt.created_at DESC
LIMIT 50;

-- Get pending withdrawals (for admin)
SELECT 
    wd.*,
    u.full_name AS agent_name,
    u.phone AS agent_phone,
    u.email AS agent_email,
    a.rating_average AS agent_rating
FROM withdrawals wd
JOIN users u ON wd.agent_id = u.id
JOIN agents a ON u.id = a.user_id
WHERE wd.status = 'requested'
ORDER BY wd.created_at ASC;

-- ========================================
-- MESSAGING QUERIES
-- ========================================

-- Get conversation between two users
SELECT 
    m.*,
    u_sender.full_name AS sender_name,
    u_receiver.full_name AS receiver_name
FROM messages m
JOIN users u_sender ON m.sender_id = u_sender.id
JOIN users u_receiver ON m.receiver_id = u_receiver.id
WHERE (
    (m.sender_id = $1 AND m.receiver_id = $2)
    OR (m.sender_id = $2 AND m.receiver_id = $1)
)
AND ($3::UUID IS NULL OR m.rfq_id = $3) -- Optional RFQ filter
ORDER BY m.created_at ASC;

-- Get user's conversations (inbox)
SELECT DISTINCT ON (thread_id)
    CASE 
        WHEN m.sender_id = $1 THEN m.receiver_id
        ELSE m.sender_id
    END AS other_user_id,
    CASE 
        WHEN m.sender_id = $1 THEN u_receiver.full_name
        ELSE u_sender.full_name
    END AS other_user_name,
    CASE 
        WHEN m.sender_id = $1 THEN u_receiver.role
        ELSE u_sender.role
    END AS other_user_role,
    m.message AS last_message,
    m.created_at AS last_message_time,
    m.status AS last_message_status,
    COUNT(*) FILTER (WHERE m.receiver_id = $1 AND m.status != 'read') AS unread_count,
    CONCAT(
        LEAST(m.sender_id, m.receiver_id),
        '-',
        GREATEST(m.sender_id, m.receiver_id)
    ) AS thread_id
FROM messages m
JOIN users u_sender ON m.sender_id = u_sender.id
JOIN users u_receiver ON m.receiver_id = u_receiver.id
WHERE m.sender_id = $1 OR m.receiver_id = $1
GROUP BY thread_id, other_user_id, other_user_name, other_user_role, 
         m.message, last_message_time, last_message_status
ORDER BY thread_id, last_message_time DESC;

-- ========================================
-- REVIEW QUERIES
-- ========================================

-- Get reviews for a supplier/agent
SELECT 
    r.*,
    u_reviewer.full_name AS reviewer_name,
    o.order_number,
    rfq.product_name
FROM reviews r
JOIN users u_reviewer ON r.reviewer_id = u_reviewer.id
LEFT JOIN orders o ON r.order_id = o.id
LEFT JOIN rfqs rfq ON o.rfq_id = rfq.id
WHERE r.reviewee_id = $1
AND r.status = 'published'
ORDER BY r.created_at DESC
LIMIT 20;

-- Get average ratings breakdown
SELECT 
    reviewee_id,
    COUNT(*) AS total_reviews,
    AVG(rating)::DECIMAL(3,2) AS avg_rating,
    AVG(quality_rating)::DECIMAL(3,2) AS avg_quality,
    AVG(communication_rating)::DECIMAL(3,2) AS avg_communication,
    AVG(delivery_rating)::DECIMAL(3,2) AS avg_delivery,
    COUNT(*) FILTER (WHERE rating = 5) AS five_star_count,
    COUNT(*) FILTER (WHERE rating = 4) AS four_star_count,
    COUNT(*) FILTER (WHERE rating = 3) AS three_star_count,
    COUNT(*) FILTER (WHERE rating = 2) AS two_star_count,
    COUNT(*) FILTER (WHERE rating = 1) AS one_star_count
FROM reviews
WHERE reviewee_id = $1
AND status = 'published'
GROUP BY reviewee_id;

-- ========================================
-- NOTIFICATION QUERIES
-- ========================================

-- Get unread notifications for a user
SELECT *
FROM notifications
WHERE user_id = $1
AND read = FALSE
ORDER BY created_at DESC
LIMIT 50;

-- Mark notifications as read
UPDATE notifications
SET read = TRUE, read_at = NOW()
WHERE id = ANY($1) -- Array of notification IDs
AND user_id = $2
RETURNING *;

-- ========================================
-- ANALYTICS QUERIES
-- ========================================

-- Platform stats (admin dashboard)
SELECT 
    (SELECT COUNT(*) FROM users WHERE role = 'importer') AS total_importers,
    (SELECT COUNT(*) FROM users WHERE role = 'agent') AS total_agents,
    (SELECT COUNT(*) FROM users WHERE role = 'supplier') AS total_suppliers,
    (SELECT COUNT(*) FROM rfqs WHERE created_at >= NOW() - INTERVAL '30 days') AS rfqs_this_month,
    (SELECT COUNT(*) FROM verifications WHERE created_at >= NOW() - INTERVAL '30 days') AS verifications_this_month,
    (SELECT COUNT(*) FROM orders WHERE created_at >= NOW() - INTERVAL '30 days') AS orders_this_month,
    (SELECT SUM(verification_fee) FROM verifications WHERE payment_status = 'paid') AS total_revenue,
    (SELECT AVG(rating) FROM reviews WHERE status = 'published') AS avg_platform_rating;

-- Agent performance stats
SELECT 
    a.user_id,
    u.full_name,
    a.location_city,
    a.rating_average,
    a.total_verifications,
    a.total_earnings,
    (
        SELECT COUNT(*) 
        FROM verifications v 
        WHERE v.agent_id = a.user_id 
        AND v.created_at >= NOW() - INTERVAL '30 days'
    ) AS verifications_this_month,
    (
        SELECT AVG(vr.overall_score)
        FROM verification_reports vr
        WHERE vr.agent_id = a.user_id
    ) AS avg_report_score
FROM agents a
JOIN users u ON a.user_id = u.id
WHERE a.status = 'active'
ORDER BY a.rating_average DESC, a.total_verifications DESC
LIMIT 20;

-- Supplier performance stats
SELECT 
    s.user_id,
    u.business_name,
    s.location_city,
    s.rating_average,
    s.total_orders,
    s.total_revenue,
    (
        SELECT COUNT(*) 
        FROM orders o 
        WHERE o.supplier_id = s.user_id 
        AND o.status = 'completed'
    ) AS completed_orders,
    (
        SELECT AVG(delivery_days)
        FROM quotes q
        JOIN orders o ON q.id = o.quote_id
        WHERE q.supplier_id = s.user_id
    ) AS avg_delivery_days
FROM suppliers s
JOIN users u ON s.user_id = u.id
WHERE s.status = 'active'
ORDER BY s.rating_average DESC, s.total_orders DESC
LIMIT 20;

-- Revenue by month (for charts)
SELECT 
    DATE_TRUNC('month', created_at) AS month,
    COUNT(*) AS verification_count,
    SUM(verification_fee) AS total_revenue,
    AVG(verification_fee) AS avg_fee
FROM verifications
WHERE payment_status = 'paid'
AND created_at >= NOW() - INTERVAL '12 months'
GROUP BY month
ORDER BY month DESC;

-- ========================================
-- SEARCH QUERIES
-- ========================================

-- Search suppliers
SELECT 
    u.id,
    u.business_name,
    s.company_name,
    s.location_city,
    s.location_country,
    s.product_categories,
    s.rating_average,
    s.total_orders,
    s.minimum_order_quantity
FROM users u
JOIN suppliers s ON u.id = s.user_id
WHERE s.status = 'active'
AND (
    u.business_name ILIKE '%' || $1 || '%'
    OR s.company_name ILIKE '%' || $1 || '%'
    OR $2 = ANY(s.product_categories)
)
ORDER BY s.rating_average DESC, s.total_orders DESC
LIMIT 20;

-- Search RFQs
SELECT 
    r.*,
    u.full_name AS importer_name,
    u.location_city AS importer_city
FROM rfqs r
JOIN users u ON r.importer_id = u.id
WHERE r.status = 'open'
AND (
    r.product_name ILIKE '%' || $1 || '%'
    OR r.description ILIKE '%' || $1 || '%'
    OR r.category = $1
)
ORDER BY r.created_at DESC
LIMIT 20;

-- ========================================
-- VERIFICATION COMPLETE
-- ========================================

SELECT 'Common queries loaded successfully!' AS status;