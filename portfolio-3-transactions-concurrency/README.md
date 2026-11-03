# Portfolio 3: Transactions and Concurrency

## Files
| File | Purpose |
|---|---|
| `transaction-demos.sql` | Scripted demos 1 to 4: commit, rollback, atomicity and savepoint |
| `transaction-demos-output.txt` | Full output of the scripted demos, including the intended errors |
| `session-a-booking-and-isolation.txt` | Transcript of Receptionist A (demos 5 and 6) |
| `session-b-concurrent-booking.txt` | Transcript of Receptionist B (demos 5 and 6) |

## Single-session transactions (demos 1 to 4)
| Demo | Clinic scenario | Result |
|---|---|---|
| 1. COMMIT | Book an appointment and record its consultation together | Both rows saved as one unit |
| 2. ROLLBACK | A card payment for invoice 8190 is declined | Invoice showed "Paid" inside the transaction, then "Unpaid" after rollback, with 0 payments stored |
| 3. Atomicity | A transaction books 10:00, then tries to double-book 09:00 | The duplicate-key error aborted the whole transaction, so the valid 10:00 booking was undone too |
| 4. SAVEPOINT | Two lab tests requested; the second uses a non-existent test ID | Rolled back to the savepoint; the valid Malaria Parasite Test request was kept |

These demos show **Atomicity** (all or nothing) and **Consistency** (constraints reject invalid data) from ACID. Committed data surviving later sessions demonstrates **Durability**.

## Concurrency control (demo 5)
Two psql sessions acted as two receptionists booking Dr 2 at 11:00 on 2 June 2025.

1. Receptionist A began a transaction and inserted the booking, without committing.
2. Receptionist B tried to insert the same slot. B's session **blocked** and waited.
3. When A committed, B was released and immediately failed with a duplicate-key error on the `UNIQUE (doctor_id, appointment_date, appointment_time)` constraint.

PostgreSQL could not yet know whether A would commit or roll back, so it made B wait on A's uncommitted entry in the unique index. This prevented a race condition in which both receptionists see the slot as free and both book it. A final query confirmed only one booking existed (patient 10).

## Isolation levels (demo 6)
| Isolation level | A's first read | B changes status to "Cancelled" | A's second read (same transaction) |
|---|---|---|---|
| READ COMMITTED (default) | Scheduled | committed | **Cancelled**: a non-repeatable read |
| REPEATABLE READ | Scheduled | committed | **Scheduled**: A keeps its snapshot until it commits |

PostgreSQL uses **MVCC (multi-version concurrency control)**: readers see a snapshot of committed data instead of waiting for writers. Under READ COMMITTED a new snapshot is taken for every statement; under REPEATABLE READ one snapshot is used for the whole transaction.

**Choice for CareBridge:** READ COMMITTED suits most short front-desk operations. REPEATABLE READ is better for reports such as end-of-day billing, where every query in the report should see the same data. Bookings rely on the unique constraint, so double-booking is prevented at any isolation level.

## Reflection
On the first attempt, both bookings were typed into the same session by mistake. PostgreSQL warned "there is already a transaction in progress" and the second insert failed inside the same transaction, which showed a constraint error but not concurrency. Labelling each session's prompt (`A>` and `B>`) fixed this, and the corrected run is shown later in each transcript.
