// CareBridge clinic: MongoDB queries (Portfolio 4)
db = db.getSiblingDB('carebridge');
db.patients.dropIndexes();   // start without extra indexes so the "before" result is fair

const summary = (label, e) => {
  const s = e.executionStats;
  print(label + ' | used index: ' + JSON.stringify(e.queryPlanner.winningPlan).includes('IXSCAN') +
        ' | documents examined: ' + s.totalDocsExamined + ' | results: ' + s.nReturned +
        ' | time (ms): ' + s.executionTimeMillis);
};

print('=== Q1: Full history of one patient in a single read (no joins) ===');
printjson(db.patients.findOne({ _id: 'P0001' }, { name: 1, 'visits.visit_date': 1, 'visits.diagnosis': 1 }));

print('=== Q2: Patients ever diagnosed with malaria, BEFORE indexing ===');
summary('Before', db.patients.find({ 'visits.diagnosis': 'Malaria' }).explain('executionStats'));

db.patients.createIndex({ 'visits.diagnosis': 1 });
print('=== Q2: Same query AFTER a multikey index on visits.diagnosis ===');
summary('After ', db.patients.find({ 'visits.diagnosis': 'Malaria' }).explain('executionStats'));

print('=== Q3: Most common diagnoses (aggregation pipeline) ===');
db.patients.aggregate([
  { $unwind: '$visits' },
  { $group: { _id: '$visits.diagnosis', cases: { $sum: 1 } } },
  { $sort: { cases: -1 } }
]).forEach(printjson);

print('=== Q4: Number of visits handled by each doctor ===');
db.patients.aggregate([
  { $unwind: '$visits' },
  { $group: { _id: '$visits.doctor.name', visits: { $sum: 1 } } },
  { $sort: { visits: -1 } }
]).forEach(printjson);

print('=== Q5: Five largest unpaid invoices with patient phone ($lookup = join) ===');
db.invoices.aggregate([
  { $match: { status: 'Unpaid' } },
  { $sort: { amount: -1 } },
  { $limit: 5 },
  { $lookup: { from: 'patients', localField: 'patient_id', foreignField: '_id', as: 'patient' } },
  { $unwind: '$patient' },
  { $project: { _id: 0, patient_id: 1, amount: 1, name: '$patient.name', phone: '$patient.phone' } }
]).forEach(printjson);

print('=== Q6: Record a new visit with one atomic update ($push) ===');
printjson(db.patients.updateOne({ _id: 'P0001' }, { $push: { visits: {
  visit_date: new Date('2025-05-15'), doctor: { doctor_id: 'D001', name: 'Dr Ngozi Okafor' },
  symptoms: 'Follow-up', diagnosis: 'Healthy', prescriptions: [] } } }));
print('P0001 now has ' + db.patients.findOne({ _id: 'P0001' }).visits.length + ' visits');

print('=== Q7: Schema validation rejects an invalid patient ===');
try {
  db.patients.insertOne({ name: { first: 'Test', last: 'Patient' }, date_of_birth: new Date('1990-01-01'),
                          phone: '09000000000', blood_group: 'Z+' });
} catch (err) {
  print('Rejected as expected: ' + err.message);
}
