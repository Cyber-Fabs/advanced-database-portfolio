-- CareBridge Specialist Clinic: relational schema (PostgreSQL)

DROP TABLE IF EXISTS payments, invoices, lab_requests, lab_tests, prescription_items,
  prescriptions, medications, consultations, appointments, patients, doctors, departments CASCADE;

CREATE TABLE departments (
  department_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name          VARCHAR(100) NOT NULL UNIQUE,
  location      VARCHAR(100)
);

CREATE TABLE doctors (
  doctor_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name    VARCHAR(50) NOT NULL,
  last_name     VARCHAR(50) NOT NULL,
  specialty     VARCHAR(100),
  phone         VARCHAR(20) UNIQUE,
  department_id INT NOT NULL REFERENCES departments(department_id) ON DELETE RESTRICT
);

CREATE TABLE patients (
  patient_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name    VARCHAR(50) NOT NULL,
  last_name     VARCHAR(50) NOT NULL,
  date_of_birth DATE NOT NULL CHECK (date_of_birth > DATE '1900-01-01'),
  gender        VARCHAR(10) CHECK (gender IN ('Male', 'Female')),
  phone         VARCHAR(20) UNIQUE,
  blood_group   VARCHAR(3) CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
);

CREATE TABLE appointments (
  appointment_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id       INT NOT NULL REFERENCES patients(patient_id) ON DELETE RESTRICT,
  doctor_id        INT NOT NULL REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  status           VARCHAR(20) NOT NULL DEFAULT 'Scheduled'
                   CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'No-show')),
  UNIQUE (doctor_id, appointment_date, appointment_time)
);

CREATE TABLE consultations (
  consultation_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  appointment_id  INT NOT NULL UNIQUE REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  symptoms        TEXT,
  diagnosis       TEXT
);

CREATE TABLE medications (
  medication_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name          VARCHAR(100) NOT NULL UNIQUE,
  unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE prescriptions (
  prescription_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id INT NOT NULL REFERENCES consultations(consultation_id) ON DELETE CASCADE,
  date_issued     DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE prescription_items (
  prescription_id INT NOT NULL REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
  medication_id   INT NOT NULL REFERENCES medications(medication_id) ON DELETE RESTRICT,
  dosage          VARCHAR(100) NOT NULL,
  quantity        INT NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (prescription_id, medication_id)
);

CREATE TABLE lab_tests (
  test_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  test_name VARCHAR(100) NOT NULL UNIQUE,
  price     NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE lab_requests (
  request_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consultation_id INT NOT NULL REFERENCES consultations(consultation_id) ON DELETE CASCADE,
  test_id         INT NOT NULL REFERENCES lab_tests(test_id) ON DELETE RESTRICT,
  result          TEXT,
  result_date     DATE
);

CREATE TABLE invoices (
  invoice_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id   INT NOT NULL REFERENCES patients(patient_id) ON DELETE RESTRICT,
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
  status       VARCHAR(20) NOT NULL DEFAULT 'Unpaid'
               CHECK (status IN ('Unpaid', 'Part-paid', 'Paid'))
);

CREATE TABLE payments (
  payment_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  invoice_id     INT NOT NULL REFERENCES invoices(invoice_id) ON DELETE RESTRICT,
  amount         NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('Cash', 'Card', 'Transfer', 'HMO')),
  payment_date   DATE NOT NULL DEFAULT CURRENT_DATE
);
