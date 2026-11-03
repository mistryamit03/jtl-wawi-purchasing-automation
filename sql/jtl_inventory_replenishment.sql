-- JTL-Wawi 2.2.2 local demo: successfully executed query
-- Source: local fictional 'Pool Products' SKU set in eazybusiness.
-- IMPORTANT: nMidestbestand is the verified column spelling in this installation.
-- Read-only SELECT. The suggested quantity rule (2 x minimum) is demo-only.

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
