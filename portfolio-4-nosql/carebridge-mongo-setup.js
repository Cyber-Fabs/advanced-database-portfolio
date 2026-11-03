// CareBridge clinic: MongoDB document model (Portfolio 4)
db = db.getSiblingDB('carebridge');
db.patients.drop(); db.doctors.drop(); db.invoices.drop();

// Schema validation: MongoDB is flexible, but key fields are still enforced
db.createCollection('patients', { validator: { $jsonSchema: {
  bsonType: 'object',
  required: ['name', 'date_of_birth', 'phone'],
  properties: {
    name: { bsonType: 'object', required: ['first', 'last'] },
    date_of_birth: { bsonType: 'date' },
    phone: { bsonType: 'string' },
    blood_group: { enum: ['A+','A-','B+','B-','AB+','AB-','O+','O-'] },
    visits: { bsonType: 'array' }
  }
}}});

db.doctors.insertMany([
  { _id: 'D001', name: 'Dr Ngozi Okafor', specialty: 'General Practitioner', department: { name: 'General Medicine', location: 'Block A' } },
  { _id: 'D002', name: 'Dr Ibrahim Musa', specialty: 'General Practitioner', department: { name: 'General Medicine', location: 'Block A' } },
  { _id: 'D003', name: 'Dr Tunde Adeyemi', specialty: 'Cardiologist', department: { name: 'Cardiology', location: 'Block B' } },
  { _id: 'D004', name: 'Dr Fatima Bello', specialty: 'Paediatrician', department: { name: 'Paediatrics', location: 'Block C' } },
  { _id: 'D005', name: 'Dr Funmilayo Ojo', specialty: 'Obstetrician', department: { name: 'Obstetrics and Gynaecology', location: 'Block D' } }
]);

// One fully detailed patient record: the whole medical history in a single document
db.patients.insertOne({
  _id: 'P0001', name: { first: 'Chioma', last: 'Okafor' }, date_of_birth: new Date('1988-04-12'),
  gender: 'Female', phone: '09050000001', blood_group: 'O+', allergies: ['Penicillin'],
  visits: [
    { visit_date: new Date('2025-03-10'), doctor: { doctor_id: 'D001', name: 'Dr Ngozi Okafor' },
      symptoms: 'Fever and headache', diagnosis: 'Malaria',
      prescriptions: [ { medication: 'Artemether-Lumefantrine', dosage: 'Twice daily', quantity: 6 },
                       { medication: 'Paracetamol 500mg', dosage: 'Three times daily', quantity: 9 } ],
      lab_results: [ { test: 'Malaria Parasite Test', result: 'Positive', result_date: new Date('2025-03-10') } ] },
    { visit_date: new Date('2025-04-22'), doctor: { doctor_id: 'D003', name: 'Dr Tunde Adeyemi' },
      symptoms: 'Chest pain', diagnosis: 'Hypertension',
      prescriptions: [ { medication: 'Amlodipine 5mg', dosage: 'Once daily', quantity: 30 } ],
      lab_results: [ { test: 'Lipid Profile', result: 'Abnormal', result_date: new Date('2025-04-23') } ] }
  ]
});

// Generate more patients with random visits, and invoices that reference patients
const firsts = ['Emeka','Aisha','Tunde','Ngozi','Ibrahim','Funke','Musa','Blessing','David','Chioma'];
const lasts = ['Okafor','Adeyemi','Bello','Eze','Ojo','Musa','Obi','Garba','Balogun','Nwosu'];
const diagnoses = ['Malaria','Hypertension','Upper respiratory infection','Gastroenteritis','Anaemia','Type 2 diabetes'];
const meds = ['Paracetamol 500mg','Amoxicillin 500mg','Artemether-Lumefantrine','Amlodipine 5mg','Metformin 500mg'];
const bloods = ['A+','A-','B+','B-','AB+','AB-','O+','O-'];
const doctors = db.doctors.find().toArray();
const pick = a => a[Math.floor(Math.random() * a.length)];
const pid = n => 'P' + String(n).padStart(4, '0');

const patients = [];
for (let i = 2; i <= 2000; i++) {
  const visits = [];
  for (let v = 0; v < Math.floor(Math.random() * 4); v++) {
    const d = pick(doctors);
    visits.push({ visit_date: new Date(2025, 0, 1 + Math.floor(Math.random() * 150)),
      doctor: { doctor_id: d._id, name: d.name }, diagnosis: pick(diagnoses),
      prescriptions: [ { medication: pick(meds), dosage: 'Twice daily', quantity: 1 + Math.floor(Math.random() * 20) } ] });
  }
  patients.push({ _id: pid(i), name: { first: pick(firsts), last: pick(lasts) },
    date_of_birth: new Date(1950 + Math.floor(Math.random() * 70), 0, 1 + Math.floor(Math.random() * 365)),
    phone: '0905' + String(i).padStart(7, '0'), blood_group: pick(bloods), visits });
}
db.patients.insertMany(patients);

const invoices = [];
for (let i = 1; i <= 3000; i++) {
  invoices.push({ patient_id: pid(1 + Math.floor(Math.random() * 2000)),
    amount: Math.round(5000 + Math.random() * 45000),
    status: pick(['Paid','Paid','Part-paid','Unpaid']),
    issued: new Date(2025, 0, 1 + Math.floor(Math.random() * 150)) });
}
db.invoices.insertMany(invoices);

print('patients: ' + db.patients.countDocuments());
print('doctors:  ' + db.doctors.countDocuments());
print('invoices: ' + db.invoices.countDocuments());
print('--- Example patient document ---');
printjson(db.patients.findOne({ _id: 'P0001' }));
