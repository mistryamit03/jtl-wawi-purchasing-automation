# Screenshot selection and disclosure checklist

Seven evidence screenshots are included in `screenshots/`. These are derived from the actual recorded test run, not illustrative replacements. Gmail screenshots were cropped to exclude the personal account header and address.

| Image | What it shows | Why it matters |
|---|---|---|
| `01-workflow-overview.png` | Entire main n8n graph | Architecture; proves connected nodes |
| `02-sql-inventory-output.png` | Enriched SQL query returning five rows | Real JTL SQL integration and supplier + reorder calculations |
| `03-purchasing-approval.png` | Approval email body and buttons | Human-in-the-loop action and readable proposal |
| `04-supplier-email.png` | Received supplier test message body | Approved branch produces supplier communication |
| `05-duplicate-first-kept.png` | First Remove Duplicates test | Unseen key accepted |
| `06-duplicate-repeat-discarded.png` | Second Remove Duplicates test | Identical key suppressed |
| `07-rejection-branch.png` | False path after rejection, supplier node inactive | Negative-path test |

## If you retake screenshots in n8n

1. Use canvas **fit-to-screen** so names and true/false connections are visible.
2. Keep node names aligned with the public README, or explicitly document original names.
3. On the SQL node, select results showing SKU, available/minimum, supplier, price and proposed quantity.
4. For the approval email, capture the proposal and **both decision buttons**.
5. For rejection, show `False: 1 item` and the supplier node **not executed** in that same run.
6. For duplicates, capture **both** `Kept (1 item)` and `Discarded (1 item)`; these should be from distinct tests, not fabricated outputs.

## Before public publication

- [ ] No personal Gmail address, sender header, avatar or recipient list.
- [ ] No passwords, OAuth codes, access tokens, cookies or connection-string secrets.
- [ ] No private Google account settings or sensitive Gmail URLs.
- [ ] No real customer, supplier, order or payment data.
- [ ] No unredacted system-configuration screenshots showing personal Windows paths if not needed.
- [ ] Verify cropped screenshots still clearly represent actual output and are labeled as cropped.
