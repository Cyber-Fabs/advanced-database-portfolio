-- Indexes to speed up the CareBridge queries

-- Q1: foreign keys are not indexed automatically in PostgreSQL
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id
  ON appointments (patient_id);

-- Q3: front-desk search by surname, then first name
CREATE INDEX IF NOT EXISTS idx_patients_last_first_name
  ON patients (last_name, first_name);

-- Q6: partial index holding only unpaid invoices, already sorted by amount
CREATE INDEX IF NOT EXISTS idx_invoices_unpaid_amount
  ON invoices (total_amount DESC)
  WHERE status = 'Unpaid';

ANALYZE;
