# Architecture and n8n node reference

## System boundary

JTL-Wawi 2.2.2 stores fictional item and supplier data in SQL Server 2022 (`eazybusiness`). A dedicated database account with ordinary read-only database permissions supplies data to n8n's Microsoft SQL node. n8n runs locally in Docker and reaches the Windows host using `host.docker.internal:14333`. Gmail is used for the human approval request and for the **test-only** supplier email. Both messages go to an inbox controlled by the builder.

The workflow is manually triggered. It does not create a purchase order inside JTL or update stock.

## Flow / data contracts

| Order | Observed UI node name | Function | Data |
|---|---|---|---|
| 1 | When clicking 'Execute workflow' | Manual trigger | 1 input item |
| 2 | Microsoft SQL | Read enriched inventory using [`../sql/jtl_inventory_replenishment.sql`](../sql/jtl_inventory_replenishment.sql) | 5 rows |
| 3 | If | `{{$json.reorder_status}}` equals `REORDER` | 3 True / 2 False |
| 4 | Aggregate | All Item Data (Into a Single List), field `reorder_items`, Include All Fields; True branch only | 1 item / 3 products |
| 5 | Edit Fields | Build `purchasing_message` and preserve incoming data | 1 item |
| 6 | Remove Duplicates | Reject previously seen proposal fingerprint | 1 first, 0 identical repeat (isolated tests) |
| 7 | Send message and wait for response | Gmail Purchasing approval, Approve/Disapprove | `{ "data": { "approved": true } }` for approved test |
| 8 | Check Purchasing Approval | Boolean `{{$json.data.approved}} is true` | True → supplier; False → end |
| 9 | Send Supplier Test Order | Gmail plain-text demo supplier request | Test email delivered on approved run |

Renaming nodes is optional. If `Edit Fields` is renamed, update `$('Edit Fields')` in the supplier message expression (or confirm n8n updated it automatically).

## Node configuration details

### 1. Microsoft SQL

- Credential uses host `host.docker.internal`, SQL database `eazybusiness`, TCP port `14333` and a dedicated read-only login.
- Execute Query uses the final working SQL in [`sql/jtl_inventory_replenishment.sql`](../sql/jtl_inventory_replenishment.sql).
- The demo instance uses TLS with certificate verification bypass for local development; do not copy that security choice into production.

### 2. Low-stock IF

- Expression `{{ $json.reorder_status }}` (String)
- Condition `is equal to` `REORDER`
- True items: POOL-001, POOL-003, POOL-004
- False items: POOL-002, POOL-005

### 3. Aggregate

- Operation: `All Item Data (Into a Single List)`
- Output field: `reorder_items`
- Include: `All Fields`

### 4. Edit Fields

- Mode `Manual Mapping`
- Field `purchasing_message` of type String, in Expression mode
- `Include Other Input Fields` = ON, `Input Fields to Include` = All

The following was the implemented purchasing proposal expression:

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

### 5. Remove Duplicates

- Operation `Remove Items Processed in Previous Executions`
- Keep Items Where `Value Is New`
- Value to Dedupe On:

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

The observed identifier was:

```text
POOL-001:5:10:15|POOL-003:25:25:25|POOL-004:8:10:12
```

A separate `alert_key` field appeared in a later Edit Fields screenshot but is not needed for the working direct-expression dedupe configuration.

### 6. Gmail request for purchasing approval

- Resource `Message`; Operation `Send and Wait for Response`
- Subject used in tested demo: `TEST | Einkaufsfreigabe | 3 Artikel | 810 EUR`
- Message expression: `{{ $json.purchasing_message }}`
- Response Type `Approval`; Type `Approve and Disapprove`
- Buttons: `Bestellung freigeben` / `Bestellung ablehnen`
- Recipient: controlled simulation inbox, omitted from this repository

### 7. Purchasing approval IF

- Expression `{{ $json.data.approved }}`
- Data type Boolean, condition `is true`
- True → Gmail test supplier request; False → no supplier action

### 8. Gmail supplier test request

- Resource `Message`; Operation `Send`; Email Type `Text`
- Subject used in tested demo: `TEST | SUPPLIER ORDER | 3 Articles | 810 EUR`
- Recipient: the same controlled test inbox, omitted from repository

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

**Known issue:** The supplier message total and both Gmail subject strings are static demo values. They must be made dynamic before varying the dataset or scheduling the workflow.

## Security and correctness boundaries

- Read-only connection avoids unsupported writes to ERP business tables, but SQL `db_datareader` is broad and should be limited to validated views in a real deployment.
- SQL query relationships are validated only against this five-item fictional dataset. `LEFT JOIN` can return multiple rows for real-world suppliers; missing available stock can be misclassified as OK due to SQL NULL semantics.
- The proposed reorder rule is an illustrative 2×minimum target, not demand forecasting.
- No auditable purchase order lifecycle or true exactly-once order guarantee exists.
- Error workflow could not be attached; it is explicitly deferred, not implemented.
