-- 003_seed_data.sql
-- 1,000 bookings, 5 orgs, 6 cities, 5 statuses, spread over the last 90 days
-- so the "last 30 days" filter in the target query actually filters something.

SELECT setseed(0.42);  -- repeatable random values

WITH orgs AS (
    SELECT ARRAY[
        'a1b2c3d4-0000-4000-8000-000000000001',
        'a1b2c3d4-0000-4000-8000-000000000002',
        'a1b2c3d4-0000-4000-8000-000000000003',
        'a1b2c3d4-0000-4000-8000-000000000004',
        'a1b2c3d4-0000-4000-8000-000000000005'
    ]::uuid[] AS ids
),
src AS (
    SELECT g,
           (now() - random() * INTERVAL '90 days')::timestamp AS created_at,
           (random() * 20)::int                               AS lead_days,
           1 + (random() * 5)::int                            AS nights
    FROM generate_series(1, 1000) AS g
)
INSERT INTO hotel_bookings
    (org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    orgs.ids[1 + (g % 5)],
    'HTL-' || lpad((1 + (g % 40))::text, 4, '0'),
    (ARRAY['delhi','mumbai','bengaluru','goa','jaipur','chennai'])[1 + (g % 6)],
    created_at::date + lead_days,
    created_at::date + lead_days + nights,
    round((1500 + random() * 18500)::numeric, 2),
    (ARRAY['PENDING','CONFIRMED','CONFIRMED','COMPLETED','CANCELLED','REFUNDED'])
        [1 + floor(random() * 6)::int],
    created_at
FROM src, orgs;

-- Every booking gets a BOOKING_CREATED event
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'BOOKING_CREATED',
       jsonb_build_object('amount', amount, 'city', city, 'hotel_id', hotel_id),
       created_at
FROM hotel_bookings;

-- Bookings that moved past PENDING get a status-change event
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'STATUS_CHANGED',
       jsonb_build_object('from', 'PENDING', 'to', status),
       created_at + INTERVAL '2 hours'
FROM hotel_bookings
WHERE status <> 'PENDING';

-- Refunds get one more event with a reason
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'REFUND_ISSUED',
       jsonb_build_object('refund_amount', amount, 'reason', 'customer_request'),
       created_at + INTERVAL '1 day'
FROM hotel_bookings
WHERE status = 'REFUNDED';

ANALYZE hotel_bookings;
ANALYZE booking_events;
