# Portfolio 2: Query Processing and Optimisation

## Files
| File | Purpose |
|---|---|
| `carebridge-queries.sql` | Six business queries for the CareBridge clinic |
| `query-results.txt` | Output of those queries |
| `explain-plans.sql` | `EXPLAIN (ANALYZE, BUFFERS)` for four key queries |
| `plans-before-indexing.txt` | Execution plans before adding indexes |
| `carebridge-indexes.sql` | Three indexes added to improve performance |
| `plans-after-indexing.txt` | Execution plans after adding indexes |
| `index-sizes.txt` | Storage used by each new index |

## Queries
| Query | Business question |
|---|---|
| Q1 | Full visit history for one patient |
| Q2 | One doctor's schedule for a given day |
| Q3 | Find a patient by name at the front desk |
| Q4 | Top five diagnoses |
| Q5 | Monthly revenue by payment method |
| Q6 | Unpaid invoices with patient phone numbers for follow-up |

Dataset: 5,000 patients and 20,000 appointments (January to early May 2025), generated synthetically. May revenue in Q5 is lower because only the first days of May are covered.

## Indexes added
| Index | Columns | Reason |
|---|---|---|
| `idx_appointments_patient_id` | `appointments(patient_id)` | PostgreSQL does not index foreign keys automatically |
| `idx_patients_last_first_name` | `patients(last_name, first_name)` | Supports name searches at the front desk |
| `idx_invoices_unpaid_amount` | `invoices(total_amount DESC) WHERE status = 'Unpaid'` | Partial index: stores only unpaid invoices, pre-sorted by amount |

## Results
| Query | Before | After | Plan change |
|---|---|---|---|
| Q1 Patient history | 1.463 ms | 0.144 ms | Seq Scan on 20,000 appointments → index lookup (about 10× faster) |
| Q2 Doctor schedule | 0.046 ms | 0.041 ms | No change: already uses the index created by the `UNIQUE` constraint |
| Q3 Patient by name | 0.085 ms | 0.061 ms | Small gain: `LIMIT 10` let the Seq Scan stop after about 775 rows |
| Q6 Unpaid invoices | 3.240 ms | 0.114 ms | Seq Scan, filter and sort of 13,469 invoices → reads top 10 from the partial index (about 28× faster) |

## Performance analysis
The largest gains came where a query filtered a large table on a column with no index. Before indexing, Q1 read all 20,000 appointments to find one patient's visits. After indexing, PostgreSQL went straight to the matching rows.

Q6 improved most because the partial index already holds only unpaid invoices in descending amount order. PostgreSQL reads the first ten entries instead of filtering 10,793 rows and sorting the remaining 2,676.

Q2 shows that constraints also create indexes. The `UNIQUE (doctor_id, appointment_date, appointment_time)` rule that prevents double-booking also makes schedule lookups fast.

Q3 shows that an index does not always produce a large gain. Because the query stops after ten matches, the sequential scan finished early. The index matters more for rare surnames, where a full scan of all patients would otherwise be needed.

## Trade-offs and limitations
- Every index uses extra storage (see `index-sizes.txt`) and slows down inserts and updates, because the index must be updated too. Indexes should only be added for frequent queries.
- Timings are from single runs on a small dataset held in memory, so they vary slightly between runs. The plan changes (Seq Scan to index scan) are more reliable evidence than the exact milliseconds.
- Q1 still uses a `Seq Scan on doctors` after indexing. This is expected: with only 10 doctors, reading the whole table is cheaper than an index lookup. The PostgreSQL planner chooses plans by estimated cost, not simply because an index exists.
