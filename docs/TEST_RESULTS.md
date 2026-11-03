# Verified tests and evidence (MVP v1.0)

The statuses below reflect actual screenshots and execution outputs recorded during development. A green n8n node only establishes that the node executed in that run, not that the entire production system is resilient.

| ID | Scenario | Observed result | Status |
|---|---|---|---|
| T01 | SQL Server + port reachability | Service running, 127.0.0.1:14333 reachable | PASS |
| T02 | n8n Docker-to-Windows reachability | `CONNECTED` using host.docker.internal:14333 | PASS |
| T03 | Read-only SQL credential + query | Connection tested successfully; `SELECT 1` returned 1 | PASS |
| T04 | Enriched inventory query | 5 products + supplier details + quantities | PASS |
| T05 | Low-stock check | 3 REORDER, 2 OK | PASS |
| T06 | Equality edge | POOL-003 stock 25, min 25 → REORDER | PASS |
| T07 | Aggregate | 3 flagged products in one list | PASS |
| T08 | Purchasing email | Human-readable proposal received, €810 net | PASS |
| T09 | Purchasing approval | `data.approved = true`; supplier message received | PASS |
| T10 | Purchasing rejection | False route: 1 item; supplier node not executed | PASS |
| T11 | First duplicate test | Kept 1 item | PASS, standalone node test |
| T12 | Identical duplicate test | Discarded 1 item | PASS, standalone node test |
| T13 | Full end-to-end after adding duplicate step | No final all-node regression shown | NOT VERIFIED |
| T14 | Automatic error notification | Configuration attempt deferred | NOT IMPLEMENTED |
| T15 | Missing supplier / empty reorder set / failures / scheduling | Not tested | NOT VERIFIED |

## Evidence files

- [Complete n8n graph](../screenshots/01-workflow-overview.png)
- [SQL output with five rows](../screenshots/02-sql-inventory-output.png)
- [Approval request screenshot](../screenshots/03-purchasing-approval.png)
- [Supplier test email screenshot](../screenshots/04-supplier-email.png)
- [Duplicate first accepted](../screenshots/05-duplicate-first-kept.png)
- [Duplicate second discarded](../screenshots/06-duplicate-repeat-discarded.png)
- [Rejection path](../screenshots/07-rejection-branch.png)

## What these tests do not prove

No native JTL purchasing order, real supplier acceptance, runtime SLA, performance benchmark, production monitoring, business ROI, or verified full-chain behavior with final duplicate node was established. The project is a demonstrable local MVP, not a production system.
