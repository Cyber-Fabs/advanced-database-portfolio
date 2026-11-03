# Portfolio 4: NoSQL and Advanced Data Models

## Overview
The CareBridge clinic data was modelled as a **document database** in MongoDB Atlas (free M0 cluster). The same case study as Portfolios 1 to 3 is used.

## Files
| File | Purpose |
|---|---|
| `carebridge-mongo-setup.js` | Creates collections, schema validation and sample data (2,000 patients, 5 doctors, 3,000 invoices) |
| `setup-output.txt` | Output of the setup, including a full example patient document |
| `carebridge-mongo-queries.js` | Queries, aggregation, indexing, atomic update and validation tests |
| `queries-output.txt` | Output of the queries |

## Document model
| Collection | Design | Reason |
|---|---|---|
| `patients` | One document per patient, with `visits` **embedded**. Each visit holds its diagnosis, prescriptions and lab results | A patient's history is almost always read together, so one read returns everything |
| `doctors` | Separate collection, **referenced** from visits by `doctor_id` | Doctor details change independently of patient records |
| `invoices` | Separate collection, **referencing** the patient by `patient_id` | Billing grows continuously and is queried on its own (e.g. all unpaid invoices) |

Each visit also stores a copy of the doctor's name. This deliberate **denormalisation** avoids a lookup when showing a patient's history.

## Relational vs document model
| Task | PostgreSQL (Portfolio 1) | MongoDB (this portfolio) |
|---|---|---|
| Show a patient's full history | Join 6 tables: appointments, doctors, consultations, prescriptions, prescription_items, lab_requests | Read one document (Q1) |
| Record a visit with prescriptions | Multi-table transaction | One atomic `$push` update (Q6) |
| Enforce data rules | Constraints (`CHECK`, foreign keys) | `$jsonSchema` validation (Q7); no foreign keys |
| Reports across all patients | Simple `GROUP BY` | Aggregation pipeline with `$unwind` (Q3, Q4) |

## Results
| Query | What it shows | Result |
|---|---|---|
| Q1 | Full patient history | Returned in a single document read, with no joins |
| Q2 | Patients ever diagnosed with malaria | Before indexing: 2,000 documents examined. After a multikey index on `visits.diagnosis`: 377 examined for 377 results (81% less work) |
| Q3 | Most common diagnoses | Upper respiratory infection (436), gastroenteritis (420) |
| Q4 | Visits per doctor | Aggregated across embedded visits |
| Q5 | Largest unpaid invoices with phone numbers | `$lookup` joins invoices to patients |
| Q6 | Record a new visit | One atomic update; P0001 went from 2 to 3 visits |
| Q7 | Invalid blood group `Z+` | Rejected: "Document failed validation" |

A **multikey index** indexes every value inside an array, so one patient document appears in the index once for each diagnosis they have had. Execution times (2 ms to 1 ms) are small on this dataset; documents examined is the clearer measure of improvement.

Note: rerunning `carebridge-mongo-queries.js` adds another visit to P0001 each time (Q6). Rerunning the setup script resets the data.

## Why a document model suits CareBridge
- Patient records are naturally hierarchical (patient, visits, prescriptions, results), like a paper patient folder.
- Different visit types can hold different fields (e.g. lab results only when tests are ordered) without changing a fixed schema.
- Reading or updating one patient is a single-document operation, and single-document updates are atomic.

## Limitations and recommendation
- **Growing documents:** a patient with many years of visits produces a large document (MongoDB's limit is 16 MB). Older visits could be moved to an archive collection.
- **Duplicated data:** if a doctor's name changes, the copies inside past visits stay as they were. This is acceptable as a historical record but must be a conscious choice.
- **Weaker integrity:** there are no foreign keys, so an invoice could reference a patient that does not exist unless the application checks it.
- **Recommendation:** use **polyglot persistence**. Keep billing and payments in PostgreSQL, where strict constraints and multi-table transactions matter most, and use MongoDB for flexible patient records.

## How to run
The password is entered at runtime and never stored in the repository:

    read -s "MONGO_PW?Atlas password: "
    MONGO_URI="mongodb+srv://carebridge-cluster.alfjtbi.mongodb.net/"
    mongosh "$MONGO_URI" --apiVersion 1 --username favourfabuyi_db_user --password "$MONGO_PW" --quiet --file carebridge-mongo-setup.js
    mongosh "$MONGO_URI" --apiVersion 1 --username favourfabuyi_db_user --password "$MONGO_PW" --quiet --file carebridge-mongo-queries.js
