// CareBridge clinic: distributed database evidence (Portfolio 5)
db = db.getSiblingDB('carebridge');
const h = db.hello();

print('=== 1. Replica set membership ===');
print('MongoDB version: ' + db.version());
print('Replica set name: ' + h.setName);
print('Nodes in the replica set:');
h.hosts.forEach(x => print('  ' + x));
print('Current primary: ' + h.primary);

print('=== 2. Which node serves a read? ===');
const servedBy = () => db.patients.find({ _id: 'P0001' }).explain().serverInfo.host;
db.getMongo().setReadPref('primary');
print('readPreference primary   -> served by ' + servedBy());
db.getMongo().setReadPref('secondary');
print('readPreference secondary -> served by ' + servedBy());
db.getMongo().setReadPref('primary');

print('=== 3. Write concern: confirmed by 1 node vs a majority of nodes ===');
db.replication_test.drop();
const timeWrites = (wc, n) => {
  const start = Date.now();
  for (let i = 0; i < n; i++) {
    db.replication_test.insertOne({ write_concern: String(wc.w), n: i, at: new Date() }, { writeConcern: wc });
  }
  return ((Date.now() - start) / n).toFixed(1);
};
print('Average ms per write, w: 1        -> ' + timeWrites({ w: 1 }, 20));
print('Average ms per write, w: majority -> ' + timeWrites({ w: 'majority' }, 20));
print('Test documents written: ' + db.replication_test.countDocuments());

print('=== 4. Read concern majority: only data confirmed by most nodes ===');
printjson(db.patients.find({ _id: 'P0001' }, { name: 1, phone: 1 }).readConcern('majority').toArray());
