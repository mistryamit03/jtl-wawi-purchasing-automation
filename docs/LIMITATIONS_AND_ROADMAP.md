# Limitations and improvement backlog

**MVP v1.0 is complete as a manually tested simulation.** The entries below are explicitly not claimed as implemented.

## P1: Reliability before any unattended use

| Improvement | Why it matters | Evidence / acceptance criteria |
|---|---|---|
| Error handler / failure notifications | Main workflow error handler appeared disabled and was not tested | Investigate n8n version and workflow eligibility; attach handler; trigger and confirm a controlled failure alert |
| Independent notification channel | Gmail-based error handler would also fail if Gmail credentials fail | Confirm fallback via another channel |
| Order/request lifecycle | An identical proposal after rejection can be suppressed; a tiny stock change can create a new approval for an already-issued supplier request | Persist `pending`, `approved`, `rejected`, `sent`, `failed` and retry states with auditable IDs |
| Full post-deduplication regression | The two Remove Duplicates tests succeeded in isolation | Run full happy/reject/duplicate/changed-stock scenarios with the final graph |
| Negative-path coverage | Real ERP data is inconsistent | Test missing supplier, NULL stock, empty result, timeout, Gmail auth failure and multiple supplier rows |

## P2: Business realism

| Improvement | Why it matters |
|---|---|
| Dynamic Gmail subject and totals | Fixed 3-item / €810 text becomes misleading after inventory changes |
| Dynamic supplier addresses and grouping | Current one-inbox supplier simulation cannot scale to multiple suppliers |
| Better purchasing rules | Add forecast demand, lead times, open purchase orders, pack sizes, MOQ and buyer override |
| Approval timeout/escalation | Waiting indefinitely is not an operational strategy |
| Recurring trigger and status dashboard | Enable only after idempotency and failure recovery are tested |

## P3: Integration / security / portfolio

| Improvement | Why it matters |
|---|---|
| Native JTL purchase order integration | An email is not an ERP purchase order; use supported integration only, no direct unsupported SQL writes |
| Database security hardening | Restrict read access, validate TLS certificates, audit firewall exposure |
| Sanitized n8n workflow JSON export | Allow actual reproducible import into n8n; do not fabricate JSON from screenshots |
| Supplier acknowledgement and audit trail | Gmail send success does not mean a supplier accepted the request |

## Root limitation of the duplicate fingerprint

The observed identifier is `POOL-001:5:10:15|POOL-003:25:25:25|POOL-004:8:10:12`.

If available stock of POOL-001 changes from 5 to 4, the identifier becomes new even if a previously approved order has already been sent. Conversely, if a request is rejected and stock does not change, the key remains the same and may be silently suppressed. This is why a future release needs business-state tracking, not just alert deduplication.

## Error handler status

A separate `JTL Purchasing - Error Handler` workflow was attempted. In the main workflow settings it appeared disabled with a warning symbol; the Publish control was also disabled in the user's local interface. Root cause was not established. Error-trigger notification was not configured or tested in the main workflow. Do not claim it is unavailable on every self-hosted version of n8n.
