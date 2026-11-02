-- CareBridge clinic: transaction demonstrations (Portfolio 3, Part A)
-- Clean up previous demo runs so the script can be rerun
DELETE FROM appointments WHERE appointment_date >= DATE '2025-06-01';

-- DEMO 1: COMMIT - book an appointment and record its consultation as one unit
BEGIN;
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (1, 1, DATE '2025-06-02', TIME '09:00', 'Completed');
INSERT INTO consultations (appointment_id, symptoms, diagnosis)
SELECT appointment_id, 'Fever and headache', 'Malaria' FROM appointments
WHERE doctor_id = 1 AND appointment_date = DATE '2025-06-02' AND appointment_time = TIME '09:00';
COMMIT;
SELECT a.appointment_id, a.status, c.diagnosis
FROM appointments a JOIN consultations c USING (appointment_id)
WHERE a.appointment_date = DATE '2025-06-02';

-- DEMO 2: ROLLBACK - a card payment is declined, so all changes are undone
SELECT invoice_id, status, total_amount FROM invoices WHERE invoice_id = 8190;
BEGIN;
INSERT INTO payments (invoice_id, amount, payment_method) VALUES (8190, 49986.74, 'Card');
UPDATE invoices SET status = 'Paid' WHERE invoice_id = 8190;
SELECT invoice_id, status FROM invoices WHERE invoice_id = 8190;
ROLLBACK;
SELECT invoice_id, status FROM invoices WHERE invoice_id = 8190;
SELECT COUNT(*) AS payments_for_8190 FROM payments WHERE invoice_id = 8190;

-- DEMO 3: An error aborts the whole transaction (atomicity)
-- The second insert tries to double-book Dr 1 at 09:00, which breaks the UNIQUE rule
BEGIN;
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (2, 1, DATE '2025-06-02', TIME '10:00', 'Scheduled');
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (3, 1, DATE '2025-06-02', TIME '09:00', 'Scheduled');
SELECT 'this will not run' AS note;
ROLLBACK;
SELECT appointment_time, patient_id FROM appointments WHERE appointment_date = DATE '2025-06-02';

-- DEMO 4: SAVEPOINT - keep the valid lab request, undo only the faulty one
BEGIN;
INSERT INTO lab_requests (consultation_id, test_id)
SELECT c.consultation_id, 2 FROM consultations c JOIN appointments a USING (appointment_id)
WHERE a.appointment_date = DATE '2025-06-02';
SAVEPOINT before_second_test;
INSERT INTO lab_requests (consultation_id, test_id)
SELECT c.consultation_id, 99 FROM consultations c JOIN appointments a USING (appointment_id)
WHERE a.appointment_date = DATE '2025-06-02';
ROLLBACK TO SAVEPOINT before_second_test;
COMMIT;
SELECT lr.request_id, t.test_name FROM lab_requests lr JOIN lab_tests t USING (test_id)
JOIN consultations c USING (consultation_id) JOIN appointments a USING (appointment_id)
WHERE a.appointment_date = DATE '2025-06-02';
