-- CareBridge Specialist Clinic: sample data
SELECT setseed(0.42);
TRUNCATE departments, doctors, patients, appointments, consultations, medications, prescriptions,
  prescription_items, lab_tests, lab_requests, invoices, payments RESTART IDENTITY CASCADE;

INSERT INTO departments (name, location) VALUES
  ('General Medicine','Block A'), ('Cardiology','Block B'), ('Paediatrics','Block C'),
  ('Obstetrics and Gynaecology','Block D'), ('Laboratory Services','Block E');

INSERT INTO doctors (first_name, last_name, specialty, phone, department_id) VALUES
  ('Ngozi','Okafor','General Practitioner','08030000001',1),
  ('Ibrahim','Musa','General Practitioner','08030000002',1),
  ('Tunde','Adeyemi','Cardiologist','08030000003',2),
  ('Amaka','Eze','Cardiologist','08030000004',2),
  ('Fatima','Bello','Paediatrician','08030000005',3),
  ('Chukwuemeka','Obi','Paediatrician','08030000006',3),
  ('Funmilayo','Ojo','Obstetrician','08030000007',4),
  ('Aisha','Yusuf','Gynaecologist','08030000008',4),
  ('Segun','Balogun','Pathologist','08030000009',5),
  ('Halima','Garba','General Practitioner','08030000010',1);

INSERT INTO medications (name, unit_price) VALUES
  ('Paracetamol 500mg',50), ('Amoxicillin 500mg',150), ('Artemether-Lumefantrine',1200),
  ('Amlodipine 5mg',100), ('Metformin 500mg',80), ('Ibuprofen 400mg',70),
  ('Ferrous Sulphate',40), ('Ciprofloxacin 500mg',200);

INSERT INTO lab_tests (test_name, price) VALUES
  ('Full Blood Count',5000), ('Malaria Parasite Test',2500), ('Fasting Blood Sugar',3000),
  ('Lipid Profile',8000), ('Urinalysis',2000), ('Widal Test',3000);

INSERT INTO patients (first_name, last_name, date_of_birth, gender, phone, blood_group)
SELECT
  (ARRAY['Chioma','Emeka','Aisha','Tunde','Ngozi','Ibrahim','Funke','Musa','Blessing','David'])[1 + floor(random()*10)::int],
  (ARRAY['Okafor','Adeyemi','Bello','Eze','Ojo','Musa','Obi','Garba','Balogun','Nwosu'])[1 + floor(random()*10)::int],
  DATE '1950-01-01' + floor(random()*25000)::int,
  (ARRAY['Male','Female'])[1 + floor(random()*2)::int],
  '0905' || lpad(g::text, 7, '0'),
  (ARRAY['A+','A-','B+','B-','AB+','AB-','O+','O-'])[1 + floor(random()*8)::int]
FROM generate_series(1, 5000) AS g;

-- 20,000 appointments: each doctor gets 16 half-hour slots per day, so no double-booking
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
SELECT
  1 + floor(random()*5000)::int,
  (g % 10) + 1,
  DATE '2025-01-01' + (g / 10) / 16,
  TIME '08:00' + ((g / 10) % 16) * INTERVAL '30 minutes',
  (ARRAY['Completed','Completed','Completed','Completed','Cancelled','No-show'])[1 + floor(random()*6)::int]
FROM generate_series(0, 19999) AS g;

INSERT INTO consultations (appointment_id, symptoms, diagnosis)
SELECT appointment_id,
  (ARRAY['Fever and headache','Chest pain','Cough and catarrh','Abdominal pain','Fatigue','Routine check-up'])[1 + floor(random()*6)::int],
  (ARRAY['Malaria','Hypertension','Upper respiratory infection','Gastroenteritis','Anaemia','Type 2 diabetes','Healthy'])[1 + floor(random()*7)::int]
FROM appointments WHERE status = 'Completed';

INSERT INTO prescriptions (consultation_id, date_issued)
SELECT c.consultation_id, a.appointment_date
FROM consultations c JOIN appointments a ON a.appointment_id = c.appointment_id
WHERE random() < 0.7;

INSERT INTO prescription_items (prescription_id, medication_id, dosage, quantity)
SELECT prescription_id, 1 + (prescription_id % 8), 'Twice daily', 1 + floor(random()*20)::int
FROM prescriptions;

INSERT INTO prescription_items (prescription_id, medication_id, dosage, quantity)
SELECT prescription_id, 1 + ((prescription_id + 3) % 8), 'Once daily', 1 + floor(random()*20)::int
FROM prescriptions WHERE prescription_id % 2 = 0;

INSERT INTO lab_requests (consultation_id, test_id, result, result_date)
SELECT c.consultation_id, 1 + floor(random()*6)::int,
  (ARRAY['Normal','Abnormal','Normal','Pending review'])[1 + floor(random()*4)::int],
  a.appointment_date + 1
FROM consultations c JOIN appointments a ON a.appointment_id = c.appointment_id
WHERE random() < 0.4;

INSERT INTO invoices (patient_id, invoice_date, total_amount, status)
SELECT a.patient_id, a.appointment_date, round((5000 + random()*45000)::numeric, 2),
  (ARRAY['Paid','Paid','Paid','Part-paid','Unpaid'])[1 + floor(random()*5)::int]
FROM consultations c JOIN appointments a ON a.appointment_id = c.appointment_id;

INSERT INTO payments (invoice_id, amount, payment_method, payment_date)
SELECT invoice_id,
  CASE WHEN status = 'Paid' THEN total_amount ELSE round(total_amount / 2, 2) END,
  (ARRAY['Cash','Card','Transfer','HMO'])[1 + floor(random()*4)::int],
  invoice_date
FROM invoices WHERE status IN ('Paid', 'Part-paid');

ANALYZE;
