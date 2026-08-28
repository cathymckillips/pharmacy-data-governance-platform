--load--
;WITH RankedPharmacy AS
(
    SELECT
        Pharmacy_Source_ID,
        NPI,
        NCPDP_ID,
        Pharmacy_Name,
        Pharmacy_Type,
        Address,
        City,
        State,
        ZIP,
        Network_Status,
        Effective_Date,
        End_Date,
        Source_System,

        ROW_NUMBER() OVER
        (
            PARTITION BY NPI
            ORDER BY
                CASE WHEN End_Date IS NULL THEN 0 ELSE 1 END,
                Effective_Date DESC,
                Pharmacy_Source_ID
        ) AS rn

    FROM staging.pharmacy

    WHERE
        NPI IS NOT NULL
        AND LEN(NPI) = 10
        AND LEN(State) = 2
        AND LEN(ZIP) = 5
        AND ZIP NOT LIKE '%[^0-9]%'
)
INSERT INTO governed.dim_pharmacy
(
    Governed_Pharmacy_ID,
    Pharmacy_Source_ID,
    NPI,
    NCPDP_ID,
    Pharmacy_Name,
    Pharmacy_Type,
    Address,
    City,
    State,
    ZIP,
    Network_Status,
    Effective_Date,
    End_Date,
    Source_System,
    Certification_Status
)
SELECT
    'PHARM-' + RIGHT('000000' + CAST(ROW_NUMBER() OVER (ORDER BY NPI) AS VARCHAR(6)), 6),
    Pharmacy_Source_ID,
    NPI,
    NCPDP_ID,
    Pharmacy_Name,
    Pharmacy_Type,
    Address,
    City,
    State,
    ZIP,
    Network_Status,
    Effective_Date,
    End_Date,
    Source_System,
    'Certified'
FROM RankedPharmacy
WHERE rn = 1;
GO

--validate--
SELECT COUNT(*) AS Governed_Pharmacies
FROM governed.dim_pharmacy;
GO

--count--
SELECT
    NPI,
    COUNT(*) AS Record_Count
FROM governed.dim_pharmacy
GROUP BY NPI
HAVING COUNT(*) > 1;
GO

--load--
INSERT INTO governed.dim_formulary
(
    Formulary_Record_ID,
    Plan_ID,
    Medication_Key,
    Formulary_Tier,
    Coverage_Status,
    Prior_Authorization_Flag,
    Step_Therapy_Flag,
    Quantity_Limit_Flag,
    Effective_Date,
    End_Date,
    Source_System
)
SELECT
    f.Formulary_Record_ID,
    f.Plan_ID,
    m.Medication_Key,
    f.Formulary_Tier,
    f.Coverage_Status,
    f.Prior_Authorization_Flag,
    f.Step_Therapy_Flag,
    f.Quantity_Limit_Flag,
    f.Effective_Date,
    f.End_Date,
    f.Source_System
FROM staging.formulary f
INNER JOIN governed.dim_medication m
    ON f.NDC_11 = m.NDC_11
WHERE
    f.Formulary_Tier BETWEEN 1 AND 5
    AND f.Coverage_Status IS NOT NULL;
GO

--validate--
SELECT COUNT(*) AS Governed_Formulary_Rows
FROM governed.dim_formulary;
GO

--governed pricing load--
INSERT INTO governed.fact_drug_pricing
(
    Pricing_Record_ID,
    Medication_Key,
    Pricing_Methodology,
    Unit_Price,
    Package_Price,
    Effective_Date,
    End_Date,
    Source_System,
    Last_Updated
)
SELECT
    p.Pricing_Record_ID,
    m.Medication_Key,
    p.Pricing_Methodology,
    p.Unit_Price,
    p.Package_Price,
    p.Effective_Date,
    p.End_Date,
    p.Source_System,
    p.Last_Updated
FROM staging.drug_pricing p
INNER JOIN governed.dim_medication m
    ON p.NDC_11 = m.NDC_11
WHERE
    p.Unit_Price > 0
    AND p.Pricing_Methodology IN
    (
        'AWP',
        'WAC',
        'MAC',
        'NADAC',
        'Contract Rate'
    );
GO

--validate--
SELECT COUNT(*) AS Governed_Pricing_Rows
FROM governed.fact_drug_pricing;
GO

--truncate--

TRUNCATE TABLE governed.fact_pharmacy_claim;
GO

--load--
;WITH DedupedClaims AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY Claim_ID
            ORDER BY Staging_Claim_ID
        ) AS rn
    FROM staging.pharmacy_claim
)
INSERT INTO governed.fact_pharmacy_claim
(
    Claim_ID,
    Member_ID,
    Claim_Date,
    Medication_Key,
    Pharmacy_Key,
    Quantity,
    Days_Supply,
    Ingredient_Cost,
    Dispensing_Fee,
    Member_Pay,
    Plan_Pay,
    Paid_Amount,
    Claim_Status,
    Source_System
)
SELECT
    c.Claim_ID,
    c.Member_ID,
    c.Claim_Date,
    m.Medication_Key,
    p.Pharmacy_Key,
    c.Quantity,
    c.Days_Supply,
    c.Ingredient_Cost,
    c.Dispensing_Fee,
    c.Member_Pay,
    c.Plan_Pay,
    c.Paid_Amount,
    c.Claim_Status,
    c.Source_System
FROM DedupedClaims c
INNER JOIN governed.dim_medication m
    ON c.NDC_11 = m.NDC_11
INNER JOIN governed.dim_pharmacy p
    ON c.Pharmacy_ID = p.Pharmacy_Source_ID
WHERE
    c.rn = 1
    AND c.Paid_Amount >= 0
    AND c.Days_Supply BETWEEN 1 AND 365
    AND c.Claim_Status IN ('Paid','Rejected','Reversed')
    AND NOT
    (
        c.Claim_Status = 'Paid'
        AND c.Paid_Amount = 0
    );
GO

--validate--
SELECT COUNT(*) AS Governed_Claims
FROM governed.fact_pharmacy_claim;
GO
