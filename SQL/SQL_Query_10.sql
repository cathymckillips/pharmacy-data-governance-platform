--compare--
SELECT
    'Medication' AS Domain,
    (SELECT COUNT(*) FROM raw.drug_reference) AS Raw_Rows,
    (SELECT COUNT(*) FROM staging.medication) AS Staging_Rows,
    (SELECT COUNT(*) FROM governed.dim_medication) AS Governed_Rows

UNION ALL

SELECT
    'Pharmacy',
    (SELECT COUNT(*) FROM raw.pharmacy_master),
    (SELECT COUNT(*) FROM staging.pharmacy),
    (SELECT COUNT(*) FROM governed.dim_pharmacy)

UNION ALL

SELECT
    'Formulary',
    (SELECT COUNT(*) FROM raw.formulary),
    (SELECT COUNT(*) FROM staging.formulary),
    (SELECT COUNT(*) FROM governed.dim_formulary)

UNION ALL

SELECT
    'Pricing',
    (SELECT COUNT(*) FROM raw.drug_pricing),
    (SELECT COUNT(*) FROM staging.drug_pricing),
    (SELECT COUNT(*) FROM governed.fact_drug_pricing)

UNION ALL

SELECT
    'Claims',
    (SELECT COUNT(*) FROM raw.pharmacy_claim),
    (SELECT COUNT(*) FROM staging.pharmacy_claim),
    (SELECT COUNT(*) FROM governed.fact_pharmacy_claim);
GO