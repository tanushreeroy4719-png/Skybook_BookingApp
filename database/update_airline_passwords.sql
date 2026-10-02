-- Run this once on an EXISTING skybook database to set every airline
-- account's password to: airline@123
USE skybook;
UPDATE app_users
SET password_hash = '84fccc02d6ef896f0f447fb7d1978ba2ecdc6d90453e50a2509887603ce1244e'
WHERE role = 'AIRLINE';
