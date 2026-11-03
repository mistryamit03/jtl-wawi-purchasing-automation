# JTL-Wawi Purchasing Automation Demo
## MVP v1.0 | Master Project Context and Closeout | Claude / LLM Handover

> **Purpose of this file:** A self-contained, evidence-aware explanation of the project's business objective, environment, data, architecture, SQL, actual n8n configurations, test outcomes, unresolved issues, and future improvements. It is **not** a click-by-click installation or implementation tutorial. Another assistant should be able to understand the system and continue work without fabricating missing details.

| Document field | Value |
|---|---|
| Project name in n8n | `JTL Purchasing Automation Demo` |
| Version and status | **MVP v1.0, CLOSED** as a functional *local, manually triggered simulation* |
| Closeout date | 2 November 2026 |
| Purpose | Portfolio / practical business-process automation demonstration informed by the POOL Total process-automation role |
| Business ownership | Independently built practice project. **Not** deployed at, authorized by, or connected to POOL Total GmbH's real systems |
| Main stack | JTL-Wawi 2.2.2; SQL Server 2022; local Docker-hosted n8n; Gmail |
| Canonical boundary | All SKUs, supplier and orders are fictional; **no native purchase order was created in JTL** and **no real supplier was contacted** |
| Source of truth | Project conversation, screenshots showing actual node outputs, and successfully executed SQL. Unverified assumptions are labeled as such. |

---

## 1. Business context, objective, and process being simulated

**Scenario:** A multichannel pool-products retailer (modeled after the operational context of POOL Total) holds stock of pool accessories and consumables. Manual inventory monitoring, reordering and supplier communication may cost time and create avoidable stockout risks, especially in seasonal peak periods.

**Objective:** Read current product stock and supplier data from an ERP database; detect SKUs at or below minimum stock; generate a defensible *sample* replenishment proposal with supplier SKUs, quantities and net prices; require human Purchasing approval; and send a **simulated** supplier order email only if approved.

**Actors and systems:**

- **JTL-Wawi** is the fictional company's ERP and the source of product, inventory, minimum-stock and supplier records.
- **SQL Server** stores the local JTL database. n8n reads data through a dedicated read-only SQL login.
- **n8n** evaluates stock, assembles a single proposal, prevents exact repeated proposals in a basic way, waits for a human approval decision and routes the outcome.
- **Purchasing** is the human decision maker who can approve or reject the whole three-product proposal.
- **Supplier** receives the simulated purchase request **only on approval**.
- **One Gmail account controlled by the builder** represents both Purchasing and Supplier for testing. These are logically separate roles but not separate real accounts.

**Successful MVP business outcome:** Demonstrate an actual email approval and supplier-notification flow generated from records in a working local ERP database, not from hardcoded mock arrays inside n8n.

**Out of scope:** Actual JTL purchase-order creation or writes, sending to real suppliers, real sales-driven replenishment, inventory forecasting, automatic scheduling, production error recovery, and operational deployment.

---

## 2. Current closure decision and verified feature status

| Capability | Closeout status | Evidence / qualification |
|---|---|---|
| Local ERP with fictional sample inventory | **Implemented** | JTL-Wawi 2.2.2 with five test SKUs, minimum-stock thresholds and supplier records |
| Docker n8n ↔ SQL Server connectivity | **Tested** | Container TCP connection succeeded and Microsoft SQL credential test succeeded |
| Dedicated read-only database access | **Implemented and tested** | `n8n_jtl_ro` can execute SQL SELECTs against `eazybusiness` |
| Enriched product/supplier inventory query | **Tested** | Exactly five rows with all required fields, including supplier SKU, price, reorder status and quantity |
| Low-stock detection | **Tested** | Three REORDER, two OK; equality at the threshold is REORDER |
| Aggregate and formatted purchasing proposal | **Tested** | Three products consolidated into one request totaling **EUR 810.00 net** |
| Gmail human approval / rejection | **Tested** | Approval email delivered, buttons available, approved response `true`; separate rejection test routed to False |
| Simulated supplier-email send | **Tested** | Supplier email received with correct items and net amount after an approved run |
| Rejection prevents supplier email | **Tested** | False branch received one item; supplier Gmail node not executed in rejected run |
| Remove Duplicates | **Tested in isolation** | First node execution kept one item; second discarded the identical proposal |
| Full regression after adding Remove Duplicates | **Not established** | Earlier end-to-end success was before insertion; duplicate node was tested separately afterward |
| Error-handler workflow | **Deferred** | Created/appeared in selector but selection was disabled; publishing was also unavailable in the UI; **no alert was confirmed working** |
| Scheduled / unattended execution | **Not implemented** | Workflow uses Manual Trigger; left in manual/test state |
| Native JTL purchase order | **Not implemented** | Supplier email explicitly says simulation and no JTL PO was created |

**Interpretation:** MVP v1.0 is a *working proof of concept*, not production-ready procurement automation. “MVP closed” means the agreed demonstration scope and tests were completed, with limitations documented; it does **not** mean every possible failure condition is handled.

---

## 3. Local environment, components and connections

### ERP and SQL environment

- **JTL application:** JTL-Wawi **2.2.2**.
- **JTL tenant:** `eB-Standard` under the `Standard` profile in this local practice environment.
- **Fictional business label used during setup:** `Pool Automation Demo`.
- **Product category:** `Pool Products`.
- **Warehouse:** `Default warehouse`; inventory management active for the five items.
- **Fictional supplier:** `Pool Supply Demo GmbH`; the same supplier is assigned to all five products in the demonstration.
- **Database engine:** Microsoft SQL Server **2022**, running as the named SQL instance `JTLWAWI` (service `MSSQL$JTLWAWI`).
- **Database:** `eazybusiness`.
- **Network protocol:** TCP/IP enabled, `Listen All = Yes`, static TCP port **14333** (after correcting an earlier mismatch with port 1433); server service restarted following configuration.
- **Windows localhost connectivity check:** `Test-NetConnection 127.0.0.1 -Port 14333` returned `TcpTestSucceeded : True`.
- **Authentication:** SQL `sa` was used *temporarily* for the initial administrative login/setup, not stored in n8n; the dedicated `n8n_jtl_ro` SQL login/user was subsequently created with membership in `db_datareader` on `eazybusiness`.
- **Database collation configured during setup:** `Latin1_General_CI_AS` (case-insensitive, accent-sensitive). Not relied upon for the workflow's business logic.

### Docker and n8n

- n8n runs in a local Docker Desktop container named **`n8n`**, based on `n8nio/n8n:latest` at the time of the screenshot. **Specific n8n application version/build not recorded**; do not infer it from the image tag.
- Local n8n interface at `http://localhost:5678`.
- SQL is installed on Windows, outside the container. The container accesses the Windows host using **`host.docker.internal`**, **not** `localhost`.
- An actual TCP socket test from the running n8n container to `host.docker.internal:14333` returned `CONNECTED`.
- n8n Microsoft SQL credential values:

  | Setting | Actual MVP configuration |
  |---|---|
  | Server | `host.docker.internal` |
  | Database | `eazybusiness` |
  | User | `n8n_jtl_ro` |
  | Password | Strong secret entered in n8n; **never store password in this document** |
  | Port | `14333` |
  | Domain | Empty |
  | TLS | Enabled |
  | Ignore SSL Issues (Insecure) | Enabled **for this local test only** (certificate validation bypass) |
  | Connect timeout / Request timeout | `15000` ms / `15000` ms |
  | TDS version | `7.4` (n8n UI default used during test) |

- The n8n credential test displayed **“Connection tested successfully.”** A subsequent `SELECT 1 AS connection_test` query returned the value **1**.
- The SQL user is **read-only under ordinary database role permissions**. For a production setup, limit permissions to approved views/tables, secure network access, enforce certificate validation and use an appropriate secret-management strategy.
- Actual Windows Firewall policy and external network exposure were **not comprehensively audited**. Working local connectivity is not proof of safe network isolation.

### Gmail setup

- Gmail was connected as an n8n credential named **`Gmail account`**.
- Both purchasing approval and supplier-test emails were sent via this same Gmail credential.
- The *same email inbox* also played the Purchasing and Supplier recipient roles. The exact personal email address is deliberately omitted from this reusable project handover.
- An alternate second Gmail sign-in caused difficulties, so it was deliberately abandoned; no second credential is required for this simulation.
- The supplier email address previously saved in ERP setup was **not dynamically read or used** by the n8n supplier-email node. The Gmail recipient is currently hardcoded.

---

## 4. Fictional sample data and business assumptions

### Product master, inventory and purchasing data (actual observed query results)

| SKU | Product | Warehouse stock | Available stock | Minimum stock | Reorder status | Supplier SKU | Supplier unit price, net (EUR) | Proposed qty | Proposed subtotal, net (EUR) |
|---|---|---:|---:|---:|---|---|---:|---:|---:|
| `POOL-001` | Chlorine Tablets 1 kg | 5 | 5 | 10 | REORDER | `SUP-POOL-001` | 10.00 | 15 | 150.00 |
| `POOL-002` | pH Minus 5 kg | 12 | 12 | 10 | OK | `SUP-POOL-002` | 8.00 | 0 | 0.00 |
| `POOL-003` | Filter Cartridge | 25 | 25 | 25 | REORDER | `SUP-POOL-003` | 12.00 | 25 | 300.00 |
| `POOL-004` | Pool Cover | 8 | 8 | 10 | REORDER | `SUP-POOL-004` | 30.00 | 12 | 360.00 |
| `POOL-005` | Pool Ladder | 3 | 3 | 2 | OK | `SUP-POOL-005` | 65.00 | 0 | 0.00 |

All five products are associated with the fictional supplier **Pool Supply Demo GmbH**. Net amounts are in EUR. In the captured run, total proposed purchase quantity was **52 units across 3 SKUs**, with an **EUR 810.00** net total.

**Important data semantics:** The 5/12/25/8/3 quantities were established as *fictional initial stock balances*, using JTL goods receipt / inventory setup in the demo. There is **no evidence of actual customer orders consuming that stock**. `Goods receipt` represents putting supplier-delivered units into stock, not issuing a reorder request. This distinction was explicitly clarified during development.

**SKU distinction:** `POOL-001` is the retailer's internal product SKU (`a.cArtNr`); `SUP-POOL-001` is the supplier-specific article number (`la.cLiefArtNr`). Different internal and supplier SKUs are intentional, not a mismatch.

### Decision policy

- A product **needs attention** if `available_stock <= minimum_stock`; equality counts as REORDER.
- A product **does not need attention** if `available_stock > minimum_stock`.
- **Demo-only replenishment rule:** if REORDER, target available stock = **2 × minimum stock**; proposed quantity = `2 × minimum_stock − available_stock`. Otherwise quantity = zero.
- Example: `POOL-001` has 5 available, minimum 10, target 20, proposed purchase **15**.
- Example: `POOL-003` has 25 available and minimum 25, so equality triggers **25** proposed units (target 50).
- This policy is an **explicit simulation assumption**, not a verified POOL Total purchasing policy. It ignores forecast demand, supplier lead time, open purchase orders, minimum order quantities, pack sizes, reserved stock semantics and commercial approval thresholds.
- No automatic order execution occurs after the SQL `CASE` calculation; the output is a *proposal requiring human approval*.

---

## 5. Workflow architecture and data flow

### Exact current main-workflow topology

```text
[Manual Trigger: When clicking 'Execute workflow']
    |
    v
[Microsoft SQL: Execute Query]
    | 5 enriched rows, one per sample SKU
    v
[IF: reorder_status is equal to 'REORDER']
    | True: 3 items                        | False: 2 items
    v                                      +--> End (no action)
[Aggregate: All Item Data (Into a Single List)]
    | 1 n8n item with reorder_items[] (3 objects)
    v
[Edit Fields: Manual Mapping]
    | 1 item: reorder_items[], purchasing_message, alert_key (present in later screenshot)
    v
[Remove Duplicates: previously processed items]
    | identical fingerprint discarded; new fingerprint kept
    v
[Gmail: Send message and wait for response]
    | response object: { "data": { "approved": true/false } }
    v
[IF: Check Purchasing Approval]
    | True: 1 item                         | False: 1 item on rejection
    v                                      +--> End (supplier not contacted)
[Gmail: Send Supplier Test Order]
    | mock supplier request email
    v
[End]
```

- Main workflow has **no scheduled trigger**. Re-running it manually sends new approvals **only when the duplicate detector accepts the current proposal fingerprint**.
- Purchasing approval is **one decision for the consolidated three-product proposal**, not a separate decision for each line item.
- False branch of the first IF leaves healthy products without follow-up; False branch of the second IF stops a rejected supplier request.
- The Gmail approval node emits the **approval result**, not all the original product fields. The supplier Gmail node therefore retrieves the proposal array by referencing the earlier `Edit Fields` node.
- No native JTL purchase-order entity, goods-receipt transaction or supplier acknowledgment is generated by n8n.

### n8n data contracts (representative of confirmed output)

**Microsoft SQL → first IF**, **5 items**, one per product:

```json
{
  "sku": "POOL-001",
  "product_name": "Chlorine Tablets 1 kg",
  "current_stock": 5,
  "available_stock": 5,
  "minimum_stock": 10,
  "supplier_name": "Pool Supply Demo GmbH",
  "supplier_sku": "SUP-POOL-001",
  "purchase_price": 10,
  "reorder_status": "REORDER",
  "proposed_order_qty": 15
}
```

**Aggregate → Edit Fields**, **1 item**, containing an array named `reorder_items` with **three** similar product objects. `Edit Fields` adds a `purchasing_message` string while retaining `reorder_items` through **Include Other Input Fields = ON**.

**Gmail approval → second IF**, **1 item** on successful approval:

```json
{
  "data": {
    "approved": true
  }
}
```

The Boolean and its exact JSON path were confirmed from a user screenshot. On a rejected test, the second IF's False branch received one item and the supplier Gmail node did not execute; the rejection JSON itself was not separately captured in the closeout evidence.

---

## 6. SQL implementation (actual working queries)

### 6.1 Initial connectivity smoke test (executed successfully)

```sql
SELECT 1 AS connection_test;
```

Returned one row: `connection_test = 1`.

### 6.2 Initial product/stock query (executed successfully before supplier enrichment)

> **Schema spelling warning:** The actual JTL-Wawi column is `a.nMidestbestand` in this installed database, **not** `a.nMindestbestand`. The latter returned `Invalid column name 'nMindestbestand'`. Do not silently 'correct' the unusual spelling.

```sql
SELECT
    a.cArtNr AS sku,
    CAST(lb.fLagerbestand AS INT) AS current_stock,
    CAST(lb.fVerfuegbar AS INT) AS available_stock,
    CAST(a.nMidestbestand AS INT) AS minimum_stock,
    CASE
        WHEN lb.fVerfuegbar <= a.nMidestbestand THEN 'REORDER'
        ELSE 'OK'
    END AS reorder_status
FROM dbo.tArtikel AS a
LEFT JOIN dbo.tLagerbestand AS lb
    ON a.kArtikel = lb.kArtikel
WHERE a.cArtNr LIKE 'POOL-%'
ORDER BY a.cArtNr;
```

Returned five products, three with `REORDER` and two with `OK`.

### 6.3 **Final enriched SQL query, successfully executed**

This is the **working query to preserve when resuming the project**. It joins supplier-specific article data and supplier master data. Actual results showed five enriched rows matching the fictional dataset above.

```sql
SELECT
    a.cArtNr AS sku,

    COALESCE(NULLIF(la.cName, ''), a.cArtNr) AS product_name,

    CAST(lb.fLagerbestand AS INT) AS current_stock,
    CAST(lb.fVerfuegbar AS INT) AS available_stock,
    CAST(a.nMidestbestand AS INT) AS minimum_stock,

    s.cFirma AS supplier_name,
    la.cLiefArtNr AS supplier_sku,
    CAST(la.fEKNetto AS DECIMAL(10,2)) AS purchase_price,

    CASE
        WHEN lb.fVerfuegbar <= a.nMidestbestand
        THEN 'REORDER'
        ELSE 'OK'
    END AS reorder_status,

    CASE
        WHEN lb.fVerfuegbar <= a.nMidestbestand
        THEN (a.nMidestbestand * 2) - lb.fVerfuegbar
        ELSE 0
    END AS proposed_order_qty

FROM dbo.tArtikel AS a

LEFT JOIN dbo.tLagerbestand AS lb
    ON a.kArtikel = lb.kArtikel

LEFT JOIN dbo.tLiefArtikel AS la
    ON a.kArtikel = la.tArtikel_kArtikel
    AND la.nStandard = 1

LEFT JOIN dbo.tLieferant AS s
    ON la.tLieferant_kLieferant = s.kLieferant

WHERE a.cArtNr LIKE 'POOL-%'

ORDER BY a.cArtNr;
```

**Table meanings and verified links:**

| Table/alias | Role | Join or selected fields |
|---|---|---|
| `dbo.tArtikel a` | Master product identifiers and minimum stock | `a.cArtNr` internal SKU, `a.kArtikel` key, `a.nMidestbestand` threshold |
| `dbo.tLagerbestand lb` | Available and current warehouse stock | Joined via `a.kArtikel = lb.kArtikel`; `lb.fLagerbestand`, `lb.fVerfuegbar` |
| `dbo.tLiefArtikel la` | Supplier-specific article information | Joined via `a.kArtikel = la.tArtikel_kArtikel`, filtered on `la.nStandard = 1`; name, supplier SKU, net purchase price |
| `dbo.tLieferant s` | Supplier name | Joined via `la.tLieferant_kLieferant = s.kLieferant`; `s.cFirma` |

**Interpretation and caveats:**

- `LEFT JOIN` preserves the master product row when a related record is missing, but does not by itself prevent duplicate rows if a related table has multiple matching records. **Five rows happened to be returned in this dataset; uniqueness is not proven for a larger ERP installation.**
- `la.nStandard = 1` chooses a standard supplier article record in this query, not a validated multi-supplier purchasing strategy.
- `COALESCE(NULLIF(la.cName, ''), a.cArtNr)` displays the supplier-article name when present, otherwise falls back to internal SKU. It is not an independent product-master name lookup.
- `CAST(... AS INT)` assumes whole-item quantities for this demo; fractional stock units would need a deliberate policy.
- If `lb.fVerfuegbar` or `a.nMidestbestand` is `NULL`, the `CASE` comparison will not be true, potentially misclassifying an unknown stock situation as `OK`. Missing stock must be handled explicitly in production.
- The query excludes open purchase orders and reservation/lead-time adjustments. These values are not production purchase recommendations.
- It is a **SELECT-only** query using `WHERE a.cArtNr LIKE 'POOL-%'` to isolate demo SKUs; it does not write to JTL tables.

### 6.4 Schema-exploration queries discussed (not confirmed executed)

These were proposed to help learn the database, but no evidence in the final screenshots establishes that the user ran them. They are included as *reference SQL*, not as completed tests.

```sql
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME IN ('tArtikel','tLagerbestand','tLiefArtikel','tLieferant')
ORDER BY TABLE_NAME;
```

```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('tArtikel','tLagerbestand','tLiefArtikel','tLieferant')
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

---

## 7. Exact n8n node settings and business logic

This section describes the **implemented configuration and executable expressions**, not a setup walkthrough.

### Node A. Manual Trigger

- Node shown as **`When clicking 'Execute workflow'`**.
- Starts the entire flow on demand; no timer/schedule/webhook trigger exists in v1.0.

### Node B. Microsoft SQL (`Execute Query`)

- Credential: dedicated `n8n_jtl_ro` Microsoft SQL credential described in Section 3.
- Operation: `Execute Query`.
- Query: **Section 6.3** enriched SELECT.
- Observed output: **5 n8n items** (one per POOL SKU), with all ten columns.

### Node C. First IF (`If`)

- Value 1, Expression: `{{ $json.reorder_status }}`.
- Data type: `String`.
- Operation: `is equal to`.
- Comparison value: `REORDER`.
- Observed result: **True = 3 items** (`POOL-001`, `POOL-003`, `POOL-004`); **False = 2 items** (`POOL-002`, `POOL-005`).

### Node D. Aggregate (`Aggregate`)

- Connected to the **True output** of the first IF (an initial wiring error sent all five records before being corrected).
- Aggregate mode: **`All Item Data (Into a Single List)`**.
- `Put Output in Field`: **`reorder_items`**.
- `Include`: **`All Fields`**.
- Observed result: **one n8n item**, with `reorder_items` array of exactly three product objects.

### Node E. Edit Fields (`Edit Fields`)

- Mode: **`Manual Mapping`**.
- **`Include Other Input Fields` = ON**, `Input Fields to Include = All`.
- Main field: `purchasing_message` (type String, in Expression mode).
- A subsequent screenshot also showed an `alert_key` field. The Remove Duplicates node ultimately computed its dedupe key **directly from `reorder_items`**, so maintaining `alert_key` as a separate output is redundant. See Node F and the technical-debt notes.
- An earlier accidental blank field created an `empty` output column; a later screenshot no longer showed that column, though an explicit final field-list audit is not recorded.

**Purchasing-message expression used for the working demo:**

```javascript
{{ [
  'PURCHASING ALERT - JTL DEMO',
  '',
  ...$json.reorder_items.flatMap(item => [
    'Product: ' + item.product_name,
    'SKU: ' + item.sku,
    'Available: ' + item.available_stock +
      ' | Minimum: ' + item.minimum_stock,
    'Supplier: ' + item.supplier_name,
    'Supplier SKU: ' + item.supplier_sku,
    'Proposed quantity: ' + item.proposed_order_qty,
    'Unit price (net): EUR ' +
      Number(item.purchase_price).toFixed(2),
    'Subtotal (net): EUR ' +
      (Number(item.proposed_order_qty) *
       Number(item.purchase_price)).toFixed(2),
    ''
  ]),
  'Total estimated cost (net): EUR ' +
    $json.reorder_items.reduce(
      (sum, item) =>
        sum + Number(item.proposed_order_qty) *
        Number(item.purchase_price),
      0
    ).toFixed(2),
  '',
  'STATUS: Awaiting purchasing approval',
  'TEST DATA - No order has been placed.'
].join(String.fromCharCode(10)) }}
```

- **Observed Gmail output** rendered human-readable newlines. n8n's Table/JSON views displayed escaped `\n` characters; this was a display/serialization difference, not evidence that Gmail received a single unbroken line.
- Net total is calculated dynamically here from proposed quantity × unit net purchase price, rather than hardcoded.

### Node F. Remove Duplicates (`Remove Duplicates`)

- Location: **after `Edit Fields`, before the Gmail approval request**.
- `Operation`: **`Remove Items Processed in Previous Executions`**.
- `Keep Items Where`: **`Value Is New`**.
- `Value to Dedupe On`: expression below; sorted deterministic composite fingerprint.
- Node's comparison state is part of the n8n duplicate-removal mechanism, not an ERP order ledger.

```javascript
{{ $json.reorder_items
  .map(i => [
    i.sku,
    i.available_stock,
    i.minimum_stock,
    i.proposed_order_qty
  ].join(':'))
  .sort()
  .join('|') }}
```

**Observed fingerprint:**

```text
POOL-001:5:10:15|POOL-003:25:25:25|POOL-004:8:10:12
```

An earlier attempt referenced `{{ $json.alert_key }}` and displayed `undefined` because that field was not present at the time; using the direct expression above fixed the problem. In a later screenshot the separate `alert_key` output appeared with visible escaped whitespace around its text; **the working deduplication used the direct expression**, not that field.

**Behavior confirmed with two isolated executions of Node F:**

1. First test: **Kept (1 item)**, because fingerprint was new.
2. Second test with identical data: **Discarded (1 item)**, because fingerprint had been previously seen.

As of closeout, the fingerprint above had already been stored by this node. A subsequent unchanged manual run would likely be suppressed until the deduplication state is reset or the incoming fingerprint changes. **Do not change stock or clear history casually on a live system; this is a simulation.**

### Node G. Gmail Purchasing Approval (`Send message and wait for response`)

- Node name shown: `Send message and wait for response`.
- Credential: existing `Gmail account`.
- `Resource`: `Message`.
- `Operation`: `Send and Wait for Response`.
- `To`: the controlled Purchasing test Gmail inbox (same inbox as the supplier role in v1.0).
- `Subject`: **`TEST | Einkaufsfreigabe | 3 Artikel | 810 EUR`** (static demo subject).
- `Message`: Expression **`{{ $json.purchasing_message }}`**.
- `Response Type`: **`Approval`**.
- `Type of Approval`: **`Approve and Disapprove`**.
- `Approve Button Label`: **`Bestellung freigeben`**.
- `Disapprove Button Label`: **`Bestellung ablehnen`**.
- Approval is for the **entire proposal**. The node pauses awaiting a user response and returns a response object, rather than forwarding the original array as output.
- Confirmed approved output:

```json
{
  "data": {
    "approved": true
  }
}
```

### Node H. Second IF (`Check Purchasing Approval`)

- This is a **new IF node after the Gmail approval**, separate from the low-stock IF.
- Value 1, Expression: **`{{ $json.data.approved }}`**.
- Data type: **Boolean**.
- Operation: **`is true`** (not the text string `"true"`).
- **True:** Continue to Gmail supplier email.
- **False:** End; supplier email is not sent.
- Verified separate runs: approval sent **1 item via True**; rejection sent **1 item via False**.

### Node I. Gmail Supplier Test Order (`Send Supplier Test Order`)

- Connected **only to the True branch** of `Check Purchasing Approval`.
- Credential: same existing `Gmail account`.
- `Resource`: `Message`.
- `Operation`: **`Send`** (NOT Send and Wait).
- `To`: same controlled Gmail account, playing the fictional supplier.
- `Subject`: **`TEST | SUPPLIER ORDER | 3 Articles | 810 EUR`** (static demo subject).
- `Email Type`: **`Text`**.
- Supplier email references earlier node data because the approval response contains just `data.approved`.

**Supplier-message expression used in the tested flow:**

```javascript
{{ [
  'TEST ONLY - SUPPLIER PURCHASE REQUEST',
  'Purchasing approval received.',
  '',
  ...$('Edit Fields').first().json.reorder_items.flatMap(item => [
    'Product: ' + item.product_name,
    'Supplier SKU: ' + item.supplier_sku,
    'Order quantity: ' + item.proposed_order_qty,
    'Unit price (net): EUR ' +
      Number(item.purchase_price).toFixed(2),
    ''
  ]),
  'Total estimated cost (net): EUR 810.00',
  '',
  'SIMULATION ONLY - DO NOT PROCESS.',
  'No purchase order has been created in JTL.'
].join(String.fromCharCode(10)) }}
```

**Known implementation limitation:** The supplier email's **EUR 810.00** total and the subject's three-item / 810-EUR count are **hardcoded for the current test dataset**. They can become incorrect if prices, stock or quantities change. A future version must compute totals and item counts dynamically and ensure that each approval refers to an immutable proposal snapshot.

---

## 8. Evidence-backed functional tests and actual results

| ID | Scenario | Observed result | Outcome |
|---|---|---|---|
| T01 | SQL Server service and local TCP connection | Windows SQL service running; localhost port `14333` reachable | **PASS** |
| T02 | Docker-to-Windows TCP socket test | Node TCP client inside n8n container printed `CONNECTED` | **PASS** |
| T03 | SQL authentication | Initial Windows Integrated Auth rejected as untrusted domain; SQL `sa` login worked; separate read-only account created | **PASS after correction** |
| T04 | n8n Microsoft SQL credential | UI showed `Connection tested successfully` | **PASS** |
| T05 | SQL query execution | `SELECT 1 AS connection_test` returned 1 | **PASS** |
| T06 | Inventory retrieval | Five demo SKUs, quantities 5/12/25/8/3 and configured thresholds returned | **PASS** |
| T07 | Supplier enrichment / quantity calculation | Five enriched rows returned with supplier, supplier SKU, net price, status and proposed quantity | **PASS** |
| T08 | Low-stock branching | Three True / REORDER, two False / OK | **PASS** |
| T09 | Equality boundary | `POOL-003` available 25 = minimum 25, classified REORDER | **PASS** |
| T10 | Aggregation | One n8n item, `reorder_items` has three entries | **PASS** |
| T11 | Purchasing proposal message | Gmail delivered correctly formatted three-product email, EUR 810 net, with Approve/Reject controls | **PASS** |
| T12 | Approval | User clicked `Bestellung freigeben`; n8n approval JSON was `{ "data": { "approved": true } }` | **PASS** |
| T13 | Approved supplier notification | Received test supplier email with three SKUs, quantities 15/25/12 and EUR 810 net | **PASS** |
| T14 | Rejection | User clicked `Bestellung ablehnen` in a new run; False received one item; supplier node remained unexecuted | **PASS** |
| T15 | Duplicate detection, first run | Kept one item | **PASS** |
| T16 | Duplicate detection, second identical run | Discarded one item | **PASS** |
| T17 | Complete flow after inserting duplicate node | Not evidenced in shared screenshots; earlier happy path preceded duplicate node | **NOT RETESTED** |
| T18 | Workflow-level error notification | Error handler unavailable for selection; no triggered failure alert demonstrated | **DEFERRED** |
| T19 | No-reorder-items case; missing supplier; email failure; timeouts; changed stock; scheduled trigger | Not tested in v1.0 | **NOT TESTED** |

**Performance:** A few local n8n executions appeared to complete rapidly in the UI, but there is no structured performance benchmark, throughput test, uptime claim or statistically valid time-savings measurement. **Do not invent ROI or labor-hour savings.**

---

## 9. Troubleshooting history and resolved issues

These are relevant if another LLM encounters an apparently familiar error:

| Problem during development | Explanation and resolution |
|---|---|
| Windows `Test-NetConnection` to port 14333 initially failed | SQL TCP/IP was enabled but IPAll static port had been 1433 rather than 14333; corrected and restarted `SQL Server (JTLWAWI)` |
| Docker ↔ SQL uncertainty | TCP test from `n8n` to `host.docker.internal:14333` returned `CONNECTED`; do not use `localhost` as the SQL host **inside** the container |
| PowerShell `SqlCredential` constructor complained `password must be marked as read only` | Corrected by calling `$pw.MakeReadOnly()` before creating `SqlCredential` |
| PowerShell `finally` parse error during earlier multiline paste | Multiline pasting was split into separate statements; subsequent single-line try/catch/finally test succeeded |
| Windows integrated SQL login rejected (`untrusted domain`) | Switched to SQL authentication for the test, then created dedicated read-only login |
| SQL error `Invalid column name 'nMindestbestand'` | Actual schema column in installed version was **`nMidestbestand`**, used successfully thereafter |
| Aggregate initially contained five products instead of three | It was connected to SQL output instead of **True** branch of first IF; corrected connections |
| `purchasing_message` showed `\n` in n8n Table view | Actual Gmail message rendered line breaks; it was a display/JSON escape distinction |
| `Remove Duplicates` showed `undefined` for `$json.alert_key` | Field was absent at that point; direct expression from `reorder_items` resolved the issue |
| Second Gmail account sign-in failed | Used same existing Gmail credential and recipient inbox for both simulated roles |
| Error-handler workflow greyed out in main workflow settings | `JTL Purchasing - Error Handler` visible but disabled in selector; Publish also disabled from user's view. Root cause **not established**, step deferred; do not claim universally cloud-only |

---

## 10. Operational limitations and risk analysis

### 10.1 Basic fingerprint is not full idempotency

The current duplicate key is a stable sorted concatenation of `SKU:available:minimum:proposedQuantity` for every product needing a reorder. It detects **exact repeated stock proposals**, which was verified with separate executions.

Example known fingerprint:

```text
POOL-001:5:10:15|POOL-003:25:25:25|POOL-004:8:10:12
```

If one more Chlorine Tablets unit is sold and stock moves from 5 to 4, the new key would start `POOL-001:4:10:16`. Remove Duplicates would treat it as **new**, even if the previous proposal had already been approved and its supplier email sent. Conversely, after a rejection or a Gmail delivery failure, the same unchanged stock fingerprint may be suppressed before a human can retry it. This is a meaningful failure of order-lifecycle management, not just a cosmetic issue.

**Production remedy:** Persistence keyed to a procurement request/order ID and business state, such as `pending → approved → supplier_sent → acknowledged/closed`, with explicit `rejected/failed/retry_pending` paths. Duplicate-send prevention and safe re-entry after a failure must be designed separately.

### 10.2 Other important boundaries

- **No ERP write-back:** SQL connection is read-only and supplier-order emails do not create a `Bestellung` / purchase order within JTL-Wawi.
- **Single fictional supplier:** Query and email design do not validate multi-supplier grouping and selection.
- **No confirmed supplier delivery/acceptance:** n8n/Gmail success indicates send operation succeeded and a message arrived in controlled test inbox, not that a real supplier accepted or fulfilled an order.
- **Email subject and supplier total are static:** If data changes, the email may misrepresent the underlying purchasing proposal.
- **No approval snapshot integrity control:** Approval is connected to a run's prior node data; no immutable proposal ID or dedicated persisted approval record exists.
- **No failure-alert channel:** Failures may only appear in n8n executions; error-handler workflow was not attached or tested.
- **No automatic scheduled execution:** Demonstrated using manual run, not a live daily production schedule.
- **Potential missing-data and join issues:** No explicit handling of NULL stock, no supplier, unexpected duplicate rows or fractional units. The final SQL was correct for five fictional rows only.
- **Local-dev security tradeoffs:** TLS certificate verification bypass was used; SQL account has broad read permissions; external host/firewall exposure was not formally audited; secrets remain outside the document.
- **Test scope:** Approval, rejection, happy path and isolated deduplication passed; full regression with all safeguards and abnormal scenarios remains untested.

---

## 11. Separate improvement backlog for MVP v2.0+

> **Everything in this table is proposed / deferred, not implemented in v1.0.** Priorities are recommended engineering priorities, not agreed business commitments.

| Priority | Enhancement | Business reason | Suggested validation / done condition |
|---|---|---|---|
| **P1** | Resolve error-handler workflow eligibility | Failed SQL/Gmail executions must be visible promptly | Identify actual reason `JTL Purchasing - Error Handler` was disabled; attach correct workflow; force a *non-manual* failure and receive an actionable alert |
| **P1** | Independent failure notification channel | Gmail-based error alerts can fail if Gmail itself is broken | Use a separate alerting route, e.g. Teams/Slack or a distinct SMTP provider, with verified delivery |
| **P1** | Persisted purchasing-request lifecycle and safe retries | Fingerprint-only suppression can drop rejected/failed requests or allow duplicate sends after small stock changes | Explicit `pending`, `approved`, `rejected`, `sent`, `failed`, retry states; idempotent supplier communication; auditable statuses |
| **P1** | End-to-end regression after deduplication | No verified final all-nodes pass after insertion | Test full approved path, full rejected path, repeated identical run, controlled reset, changed-stock run |
| **P1** | Negative-path and edge-case testing | Reliable automations need coverage beyond the happy path | Test zero flagged products, missing supplier, multiple supplier records, NULL quantities, email auth failure, timeout, restart while waiting for approval |
| **P2** | Dynamic supplier recipient and per-supplier grouping | Hardcoded one-inbox routing does not generalize | Resolve verified supplier email from approved source, send one scoped request per actual supplier, avoid leaks across suppliers |
| **P2** | Dynamic subject, totals and immutable proposal snapshot | Current static EUR 810 and 3-item values become stale | Calculate item count / total from approved snapshot, include unique request ID, ensure approval maps to exact submitted lines |
| **P2** | Realistic replenishment strategy | `2 × min stock` is only a toy rule | Add demand rate, lead time, inbound orders, reserve/safety stock, pack size, MOQ, commercial thresholds and buyer override |
| **P2** | Approved response timeouts and escalation | Requests may remain waiting indefinitely | Define deadline, reminder, escalation owner and expiry path |
| **P2** | Scheduled operations / monitoring | A real process requires repeatable unattended checking | Enable schedule only after controls and observability pass, set timezone, operational dashboard and runbook |
| **P3** | JTL purchase-order integration through supported interface | Email alone is not an ERP purchase order | Research supported JTL APIs/workflows and test creating or recording a PO **without unsupported direct SQL writes** |
| **P3** | Security hardening | Prototype has dev-only relaxed TLS and broad DB read rights | Trusted server cert, reduced SQL privileges, local network/firewall validation, credential rotation, environment separation |
| **P3** | Archival/export, operational documentation and recovery | Preserve portfolio/demo and enable safe changes | Export versioned n8n JSON (without secrets), store SQL, screenshots, decision log, and restore/test instructions |

**Explicitly deferred at closeout:** The Error Trigger/Gmail handler may exist as a separate draft, but it was **not selectable** in the main workflow's `Error Workflow` setting. Publishing was shown as disabled. The root cause was *not proven* to be the self-hosted edition, a license restriction or any other specific condition. Do not assert a diagnosis without inspecting the exact n8n version, validation warnings and execution mode.

---

## 12. Claude handover: truth boundaries, context to preserve, and potential continuation

### What another assistant can state as verified

- The project is an **independently created local demo** modeled on pool-products purchasing operations, not a POOL Total production project.
- It reads real rows from a locally installed JTL-Wawi `eazybusiness` database through n8n using a **read-only SQL credential**.
- Five demo products exist; three trigger low stock; proposal has **52 units, EUR 810.00 net**.
- The **exact final enriched SQL** in Section 6.3 executed successfully and returned all five enriched rows.
- Human approval and rejection were exercised in Gmail; supplier test email was received on an approved run and not executed on the rejected run.
- Duplicate removal kept a new proposal and discarded a repeat in isolated tests.
- **Error notifications were deferred; no native ERP purchase orders were created; no production schedule was enabled.**

### What another assistant must NOT silently claim

- No production deployment, POOL Total access, business ROI, measurable time savings, real supplier integration, real replenishment sales data, native JTL purchase-order creation, dynamic supplier addressing, live error alerts or fully tested unattended reliability.
- No proof that the final end-to-end chain *including Remove Duplicates* was retested after insertion.
- No proof that error-workflow selection is impossible on self-hosted n8n; it is an unresolved UI eligibility/configuration problem.
- No certainty that SQL join cardinalities and NULL handling are safe for a real large-scale JTL database.
- Do not invent Gmail addresses, stored passwords, n8n instance version or JTL schema fields not documented here.

### When resuming v2

- **Start from the main workflow and working SQL in this file.** Do not rebuild existing completed nodes without a reason.
- Check whether the duplicate fingerprint is already in the node's state before expecting a new purchasing email.
- Verify the current n8n build, export a clean workflow JSON without secrets, and confirm error-workflow activation requirements before changing production behavior.
- Prioritize stateful order lifecycle and reliable failure/approval handling before scheduling or issuing any real supplier request.

### Concise interview-safe explanation

> “I built a local ERP-to-n8n purchasing automation prototype with JTL-Wawi and SQL Server. It reads inventory and supplier records, flags items at or below minimum stock, calculates sample replenishment quantities and costs, groups them into a purchasing proposal, and requests human approval through Gmail. After approval it sends a simulated supplier request; rejection prevents the supplier message. I tested both decisions and repeated-proposal detection. The prototype is manual and read-only toward JTL. Production error handling, order lifecycle and native ERP write-back remain documented improvements.”

---

## 13. Change record

- **v1.0 initial closeout (2 Nov 2026):** Summarized MVP scope, tests, limitations and improvement list.
- **v1.0 expanded master-context revision (2 Nov 2026):** Added confirmed local architecture, environment and auth context, all five example SKU records, initial and final working SQL, exact node settings, full purchasing/supplier expressions, approval JSON, testing chronology, resolved issues, technical caveats, and a separate prioritized improvement backlog. **No claim of additional implementation or new tests.**

**End of canonical MVP v1.0 context.**
