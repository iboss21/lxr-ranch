-- Database Migration for Rex Ranch Production System
-- Run this if you want to add production time tracking in the future

-- Check if the last_product_time column exists, if not add it
-- This is optional - the current system works without it

-- For MySQL/MariaDB:
-- ALTER TABLE rex_ranch_animals ADD COLUMN IF NOT EXISTS last_product_time INT DEFAULT 0;

-- For other databases that don't support IF NOT EXISTS:
-- First check if column exists:
-- SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
-- WHERE TABLE_NAME = 'rex_ranch_animals' AND COLUMN_NAME = 'last_product_time';

-- If column doesn't exist, run:
-- ALTER TABLE rex_ranch_animals ADD COLUMN last_product_time INT DEFAULT 0;

-- Note: The current production system works without this column
-- This migration is only needed if you want to implement precise production timing