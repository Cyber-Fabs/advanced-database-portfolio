-- Execution plans for the key CareBridge queries

\echo '=== Existing indexes ==='
\di

\echo '=== Q1: Patient visit history ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.appointment_date, d.first_name || ' ' || d.last_name AS doctor, c.diagnosis
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
LEFT JOIN consultations c ON c.appointment_id = a.appointment_id
WHERE a.patient_id = 1234
ORDER BY a.appointment_date;

\echo '=== Q2: Doctor schedule for one day ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT appointment_time, patient_id, status
FROM appointments
WHERE doctor_id = 3 AND appointment_date = DATE '2025-03-10'
ORDER BY appointment_time;

\echo '=== Q3: Find patient by name ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT patient_id, first_name, last_name, phone
FROM patients
WHERE last_name = 'Okafor' AND first_name = 'Chioma'
LIMIT 10;

\echo '=== Q6: Unpaid invoices with patient phone numbers ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT i.invoice_id, p.first_name, p.last_name, p.phone, i.total_amount
FROM invoices i
JOIN patients p ON p.patient_id = i.patient_id
WHERE i.status = 'Unpaid'
ORDER BY i.total_amount DESC
LIMIT 10;
