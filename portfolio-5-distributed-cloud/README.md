# Portfolio 5: Distributed and Cloud Database Exercise

## Deployment
The CareBridge document database (Portfolio 4) runs on **MongoDB Atlas**, a managed cloud database service, using the free M0 tier on AWS in the **Paris (eu-west-3)** region. Atlas deploys it as a **three-node replica set**: one primary node that accepts writes and two secondary nodes that keep full copies of the data.

## Files
| File | Purpose |
|---|---|
| `carebridge-replication-demo.js` | Script that inspects the replica set and tests read preference, write concern and read concern |
| `replication-output.txt` | Output of the script |

## Evidence from the cluster
| Item | Result |
|---|---|
| MongoDB version | 8.0.36 |
| Replica set name | `atlas-tyo2lx-shard-0` |
| Nodes | `ac-frvytpn-shard-00-00`, `-01` and `-02` (`.alfjtbi.mongodb.net`) |
| Primary at test time | `ac-frvytpn-shard-00-01` |
| Read with `readPreference: primary` | Served by `shard-00-01` (the primary) |
| Read with `readPreference: secondary` | Served by `shard-00-00` (a secondary) |
| Average write time, `w: 1` | 156.1 ms (20 writes) |
| Average write time, `w: majority` | 170.9 ms (20 writes) |

## Replication and availability
Every write goes to the primary and is then copied to the secondaries. If the primary fails, the remaining nodes hold an **election** and promote a secondary to primary, usually within seconds, so the clinic system keeps working. The free tier does not allow a live failover test, so failover is explained here rather than demonstrated.

## Consistency: write and read concern
- `w: 1` confirms a write once the primary has it. If the primary failed before copying it, the write could be lost.
- `w: majority` confirms only once at least two of the three nodes have it, so it survives the loss of the primary. It cost about **15 ms (9%) more** per write in this test.
- Most of the 156 ms is network distance between Abuja and Paris; the extra cost of majority confirmation is small because the nodes are close to each other.
- `readConcern: majority` returns only data confirmed by most nodes, so a reader never sees a change that is later rolled back.

**Reads from a secondary can be slightly out of date** (eventual consistency), because secondaries copy changes after the primary. For CareBridge:
- **Bookings, payments and prescriptions:** write with `w: majority` and read from the primary, because stale or lost data could cause double-booking or wrong treatment.
- **Reports and dashboards** (e.g. monthly diagnosis counts): can read from secondaries, which spreads the load and is acceptable if a few seconds out of date.

## CAP theorem
The CAP theorem states that during a network **partition**, a distributed database must choose between **consistency** and **availability**. A MongoDB replica set chooses consistency: a primary that cannot reach a majority of nodes steps down and stops accepting writes, rather than risk two primaries accepting conflicting data. For CareBridge this is the right choice, since briefly refusing a booking is safer than double-booking a doctor or losing a prescription. The write concern test also illustrates the related trade-off between **latency and consistency** when there is no failure: stronger guarantees take longer.

## Sharding design (proposed)
Replication copies all data to every node; **sharding** splits data across groups of nodes so the database can grow beyond one server. The free tier cannot be sharded, so this is a design proposal for when CareBridge expands to many branches.

| Shard key option | Advantages | Disadvantages |
|---|---|---|
| Hashed `_id` (patient ID) | Spreads patients evenly; a lookup by patient goes to one shard | Reports by branch must query every shard |
| `branch_id` | Each branch's data is stored together, and zone sharding could keep data in a chosen country | Large branches create uneven "hot" shards |
| `visit_date` | Easy range queries by date | All new writes hit the newest shard, creating a bottleneck |

**Recommendation:** a compound key of `{ branch_id, _id }`. Queries for one patient stay on one shard, data is grouped by branch, and the patient ID keeps large branches from overloading a single shard.

## Cloud deployment considerations
- **Data protection and residency:** patient health data is sensitive personal data under Nigeria's Data Protection Act (NDPA) 2023. The Paris region was used only for coursework with synthetic data. A real deployment would host the data in Nigeria or a nearby region, or meet the NDPA's conditions for cross-border transfer, similar to the hybrid approach in the MTN case study.
- **Latency:** writes took about 156 ms mainly because of the distance to Paris. A closer region would make the system more responsive.
- **Backups:** backups are off on the free tier. Production would need scheduled backups with point-in-time recovery.
- **Security:** access is limited by an IP access list, a database user and encrypted (TLS) connections. The password is entered at runtime and never stored in the repository.
- **Free-tier limits:** shared resources, 512 MB storage, and no sharding or failover testing. A paid dedicated tier would be needed for production.

## Relational equivalent
PostgreSQL (Portfolios 1 to 3) offers similar replication through **streaming replication**: a primary sends its change log to standby servers that can take over or serve read-only queries. Billing data kept in PostgreSQL would use this for availability.
