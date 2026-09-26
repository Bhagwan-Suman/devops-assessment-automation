-- 002_create_indexes.sql

-- Target query:
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
-- city is an equality filter -> first column
-- created_at is a range filter -> second column
-- org_id, status, amount are only read -> INCLUDE, enables index-only scan
CREATE INDEX IF NOT EXISTS idx_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

-- Postgres does NOT index foreign keys automatically. Without this,
-- "show all events for a booking" and ON DELETE CASCADE do full scans.
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id
    ON booking_events (booking_id, created_at);
