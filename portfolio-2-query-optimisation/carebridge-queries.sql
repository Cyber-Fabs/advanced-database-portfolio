-- CareBridge clinic: business queries for Portfolio 2

\echo '--- Q1: Full visit history for one patient (doctor seen and diagnosis) ---'
SELECT a.appointment_date, d.first_name || ' ' || d.last_name AS doctor, c.diagnosis
FROM appointments a
JOIN doctors d ON d.doctor_id = a.doctor_id
LEFT JOIN consultations c ON c.appointment_id = a.appointment_id
WHERE a.patient_id = 1234
ORDER BY a.appointment_date;

\echo '--- Q2: One doctor''s schedule for a given day ---'
SELECT appointment_time, patient_id, status
FROM appointments
WHERE doctor_id = 3 AND appointment_date = DATE '2025-03-10'
ORDER BY appointment_time;

\echo '--- Q3: Find a patient by name at the front desk ---'
SELECT patient_id, first_name, last_name, phone
FROM patients
WHERE last_name = 'Okafor' AND first_name = 'Chioma'
LIMIT 10;

\echo '--- Q4: Top 5 diagnoses ---'
SELECT diagnosis, COUNT(*) AS cases
FROM consultations
GROUP BY diagnosis
ORDER BY cases DESC
LIMIT 5;

\echo '--- Q5: Monthly revenue by payment method ---'
SELECT date_trunc('month', payment_date)::date AS month, payment_method, SUM(amount) AS revenue
FROM payments
GROUP BY month, payment_method
ORDER BY month, payment_method;

\echo '--- Q6: Unpaid invoices with patient phone numbers (for follow-up calls) ---'
SELECT i.invoice_id, p.first_name, p.last_name, p.phone, i.total_amount
FROM invoices i
JOIN patients p ON p.patient_id = i.patient_id
WHERE i.status = 'Unpaid'
ORDER BY i.total_amount DESC
LIMIT 10;
