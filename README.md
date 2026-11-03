# Advanced Database Systems Portfolio: CareBridge Specialist Clinic

- **Course:** MIT 8103 Advanced Database Systems, MIVA Open University
- **Student:** Favour Segun Fabuyi (Student ID 301906467)
- **Session:** 2026/2027, First Semester

## Case study
**CareBridge Specialist Clinic, Abuja** is a simulated outpatient clinic with general and specialist consultations, an on-site laboratory and a pharmacy. The database supports patient registration, appointment booking, consultations and diagnoses, prescriptions, lab results, invoicing and payments. Full details: [case-study.md](case-study.md).

All data in this repository is synthetic. No real patient information is used.

## Portfolio contents
| Portfolio | Topic | Main evidence |
|---|---|---|
| [Portfolio 1](portfolio-1-database-design/) | Database Design and Modelling | ER diagram, PostgreSQL schema with 12 tables, keys and constraints, normalisation to 3NF |
| [Portfolio 2](portfolio-2-query-optimisation/) | Query Processing and Optimisation | Six business queries, execution plans before and after indexing (up to 28 times faster), partial index |
| [Portfolio 3](portfolio-3-transactions-concurrency/) | Transactions and Concurrency | COMMIT, ROLLBACK, atomicity, SAVEPOINT, two-session double-booking test, READ COMMITTED vs REPEATABLE READ |
| [Portfolio 4](portfolio-4-nosql/) | NoSQL and Advanced Data Models | MongoDB document model with embedded visits, schema validation, aggregation, multikey index |
| [Portfolio 5](portfolio-5-distributed-cloud/) | Distributed and Cloud Database | Three-node Atlas replica set, read preference, write concern timings, CAP and sharding design |

Each portfolio folder has its own README explaining what was done, how it was tested and what the results show.

## Tools used
| Tool | Purpose |
|---|---|
| PostgreSQL 18 (Postgres.app) | Relational database for Portfolios 1 to 3 |
| dbdiagram.io | ER diagram |
| MongoDB Atlas (free M0 cluster, AWS Paris) and mongosh 2.14 | Document database for Portfolios 4 and 5 |
| Git and GitHub | Version control and progressive submission |

## How to reproduce
PostgreSQL (from the repository folder):

    createdb carebridge_clinic
    psql -d carebridge_clinic -f portfolio-1-database-design/carebridge-schema.sql
    psql -d carebridge_clinic -f portfolio-1-database-design/carebridge-sample-data.sql
    psql -d carebridge_clinic -f portfolio-2-query-optimisation/carebridge-indexes.sql

MongoDB (the password is typed at runtime and never stored in this repository):

    read -s "MONGO_PW?Atlas password: "
    mongosh "mongodb+srv://carebridge-cluster.alfjtbi.mongodb.net/" --apiVersion 1 --username favourfabuyi_db_user --password "$MONGO_PW" --quiet --file portfolio-4-nosql/carebridge-mongo-setup.js

## AI use declaration
- **Tool used:** Claude (Anthropic), an AI assistant.
- **What it was used for:** step-by-step guidance on setting up the tools; explaining database concepts; drafting the SQL and MongoDB scripts and the first versions of the README files; and helping diagnose errors during setup.
- **How the output was reviewed and verified:** every script was run on my own machine and cloud cluster, and all results in this repository come from those runs. Errors were investigated and fixed (for example a truncated schema file, an empty DBML file and a concurrency test first run in a single session). README figures were checked against the saved output files, and the text was reviewed and edited so that I can explain every design decision.
