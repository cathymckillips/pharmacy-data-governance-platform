--First Business KPI Check--

SELECT
    COUNT(*) AS Governed_Claims,
    SUM(Paid_Amount) AS Total_Pharmacy_Spend,
    AVG(Paid_Amount) AS Average_Claim_Paid,
    COUNT(DISTINCT Medication_Key) AS Distinct_Medications,
    COUNT(DISTINCT Pharmacy_Key) AS Distinct_Pharmacies
FROM governed.fact_pharmacy_claim;
GO

--first governance kpi--
SELECT
    CAST(
        100.0 *
        (
            SELECT COUNT(*)
            FROM governed.fact_pharmacy_claim
        )
        /
        NULLIF(
            (
                SELECT COUNT(*)
                FROM raw.pharmacy_claim
            ),
            0
        )
        AS DECIMAL(6,2)
    ) AS Governed_Claim_Percent;
GO


--Executive Governance summary --
USE PharmacyGovernance;
GO

CREATE OR ALTER VIEW reporting.vw_executive_governance
AS
WITH ClaimCounts AS
(
    SELECT
        (SELECT COUNT(*) FROM raw.pharmacy_claim) AS Raw_Claims,
        (SELECT COUNT(*) FROM staging.pharmacy_claim) AS Staging_Claims,
        (SELECT COUNT(*) FROM governed.fact_pharmacy_claim) AS Governed_Claims
),
ExceptionCounts AS
(
    SELECT
        COUNT(*) AS Total_Exceptions,
        SUM(CASE WHEN Status = 'Open' THEN 1 ELSE 0 END) AS Open_Exceptions,
        SUM(CASE WHEN Severity = 'Critical' THEN 1 ELSE 0 END) AS Critical_Exceptions
    FROM governance.data_quality_exception
)
SELECT
    c.Raw_Claims,
    c.Staging_Claims,
    c.Governed_Claims,

    CAST(
        100.0 * c.Governed_Claims /
        NULLIF(c.Raw_Claims, 0)
        AS DECIMAL(6,2)
    ) AS Governed_Claim_Percent,

    e.Total_Exceptions,
    e.Open_Exceptions,
    e.Critical_Exceptions,

    (SELECT COUNT(*) FROM governed.dim_medication) AS Governed_Medications,
    (SELECT COUNT(*) FROM governed.dim_pharmacy) AS Governed_Pharmacies,

    (SELECT SUM(Paid_Amount)
     FROM governed.fact_pharmacy_claim) AS Total_Pharmacy_Spend

FROM ClaimCounts c
CROSS JOIN ExceptionCounts e;
GO

--test it--
SELECT *
FROM reporting.vw_executive_governance;
GO

--Data Qualtiy By Rule --
CREATE OR ALTER VIEW reporting.vw_data_quality_by_rule
AS
SELECT
    r.Rule_ID,
    r.Domain,
    r.Rule_Description,
    r.Severity,
    COUNT(e.Exception_ID) AS Exception_Count,
    SUM(CASE WHEN e.Status = 'Open' THEN 1 ELSE 0 END) AS Open_Count,
    SUM(CASE WHEN e.Status = 'Resolved' THEN 1 ELSE 0 END) AS Resolved_Count
FROM governance.data_quality_rule r
LEFT JOIN governance.data_quality_exception e
    ON r.Rule_ID = e.Rule_ID
GROUP BY
    r.Rule_ID,
    r.Domain,
    r.Rule_Description,
    r.Severity;
GO

--Test it--
SELECT *
FROM reporting.vw_data_quality_by_rule
ORDER BY Exception_Count DESC;
GO

--Create Data Quality by Domain--
CREATE OR ALTER VIEW reporting.vw_data_quality_by_domain
AS
SELECT
    r.Domain,
    COUNT(e.Exception_ID) AS Exception_Count,
    SUM(CASE WHEN e.Severity = 'Critical' THEN 1 ELSE 0 END) AS Critical_Count,
    SUM(CASE WHEN e.Severity = 'High' THEN 1 ELSE 0 END) AS High_Count,
    SUM(CASE WHEN e.Severity = 'Medium' THEN 1 ELSE 0 END) AS Medium_Count,
    SUM(CASE WHEN e.Severity = 'Low' THEN 1 ELSE 0 END) AS Low_Count
FROM governance.data_quality_rule r
LEFT JOIN governance.data_quality_exception e
    ON r.Rule_ID = e.Rule_ID
GROUP BY
    r.Domain;
GO

--test it--
SELECT *
FROM reporting.vw_data_quality_by_domain
ORDER BY Exception_Count DESC;
GO

--Detailted governed claims view--
CREATE OR ALTER VIEW reporting.vw_governed_claims
AS
SELECT
    c.Claim_Key,
    c.Claim_ID,
    c.Member_ID,
    c.Claim_Date,

    m.Governed_Medication_ID,
    m.NDC_11,
    m.Drug_Name,
    m.Generic_Name,
    m.Brand_Name,
    m.Drug_Class,

    p.Governed_Pharmacy_ID,
    p.Pharmacy_Name,
    p.Pharmacy_Type,
    p.City,
    p.State,
    p.Network_Status,

    c.Quantity,
    c.Days_Supply,
    c.Ingredient_Cost,
    c.Dispensing_Fee,
    c.Member_Pay,
    c.Plan_Pay,
    c.Paid_Amount,
    c.Claim_Status,
    c.Source_System

FROM governed.fact_pharmacy_claim c
LEFT JOIN governed.dim_medication m
    ON c.Medication_Key = m.Medication_Key
LEFT JOIN governed.dim_pharmacy p
    ON c.Pharmacy_Key = p.Pharmacy_Key;
GO

--test it--
SELECT TOP 100 *
FROM reporting.vw_governed_claims;
GO

--Medication Governance View --
CREATE OR ALTER VIEW reporting.vw_medication_governance
AS
SELECT
    m.Medication_Key,
    m.Governed_Medication_ID,
    m.NDC_11,
    m.Drug_Name,
    m.Generic_Name,
    m.Brand_Name,
    m.Strength,
    m.Strength_Unit,
    m.Dosage_Form,
    m.Route,
    m.Manufacturer,
    m.Drug_Class,
    m.Active_Flag,
    m.Certification_Status,

    COUNT(DISTINCT c.Claim_ID) AS Claim_Count,
    SUM(c.Paid_Amount) AS Total_Paid_Amount

FROM governed.dim_medication m
LEFT JOIN governed.fact_pharmacy_claim c
    ON m.Medication_Key = c.Medication_Key

GROUP BY
    m.Medication_Key,
    m.Governed_Medication_ID,
    m.NDC_11,
    m.Drug_Name,
    m.Generic_Name,
    m.Brand_Name,
    m.Strength,
    m.Strength_Unit,
    m.Dosage_Form,
    m.Route,
    m.Manufacturer,
    m.Drug_Class,
    m.Active_Flag,
    m.Certification_Status;
GO

--test it--
SELECT TOP 50 *
FROM reporting.vw_medication_governance
ORDER BY Total_Paid_Amount DESC;
GO

--Pharmacy Governance View--
CREATE OR ALTER VIEW reporting.vw_pharmacy_governance
AS
SELECT
    p.Pharmacy_Key,
    p.Governed_Pharmacy_ID,
    p.NPI,
    p.NCPDP_ID,
    p.Pharmacy_Name,
    p.Pharmacy_Type,
    p.City,
    p.State,
    p.Network_Status,
    p.Certification_Status,

    COUNT(DISTINCT c.Claim_ID) AS Claim_Count,
    SUM(c.Paid_Amount) AS Total_Paid_Amount

FROM governed.dim_pharmacy p
LEFT JOIN governed.fact_pharmacy_claim c
    ON p.Pharmacy_Key = c.Pharmacy_Key

GROUP BY
    p.Pharmacy_Key,
    p.Governed_Pharmacy_ID,
    p.NPI,
    p.NCPDP_ID,
    p.Pharmacy_Name,
    p.Pharmacy_Type,
    p.City,
    p.State,
    p.Network_Status,
    p.Certification_Status;
GO

--Test it--
SELECT TOP 50 *
FROM reporting.vw_pharmacy_governance
ORDER BY Total_Paid_Amount DESC;
GO

--Execption Detail View--
CREATE OR ALTER VIEW reporting.vw_data_quality_exception_detail
AS
SELECT
    e.Exception_ID,
    e.Rule_ID,
    r.Domain,
    r.Rule_Description,
    e.Record_ID,
    e.Source_System,
    e.Source_Table,
    e.Source_Field,
    e.Issue_Type,
    e.Issue_Description,
    e.Severity,
    e.Detected_Value,
    e.Expected_Value,
    e.Detection_Date,
    e.Status,
    e.Assigned_Steward,
    e.Resolution_Date,
    e.Resolution_Notes
FROM governance.data_quality_exception e
INNER JOIN governance.data_quality_rule r
    ON e.Rule_ID = r.Rule_ID;
GO

--test it--
SELECT TOP 100 *
FROM reporting.vw_data_quality_exception_detail
ORDER BY Detection_Date DESC;
GO

--linage view--
CREATE OR ALTER VIEW reporting.vw_lineage_impact
AS
SELECT
    Lineage_ID,
    Source_System,
    Source_Object,
    Source_Field,
    Target_Object,
    Target_Field,
    Transformation_Type,
    Transformation_Logic,
    Lineage_Level,
    Active_Flag
FROM governance.lineage
WHERE Active_Flag = 'Y';
GO

--test it--
SELECT *
FROM reporting.vw_lineage_impact
ORDER BY Lineage_ID;
GO

--Final Validation--
SELECT
    s.name AS Schema_Name,
    v.name AS View_Name
FROM sys.views v
INNER JOIN sys.schemas s
    ON v.schema_id = s.schema_id
WHERE s.name = 'reporting'
ORDER BY v.name;
GO