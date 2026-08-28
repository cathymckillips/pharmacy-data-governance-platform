--insert Formulary data--
INSERT INTO raw.formulary
(
    Formulary_Record_ID,
    Plan_ID,
    NDC,
    Drug_Name,
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
    Formulary_Record_ID,
    Plan_ID,
    NDC,
    Drug_Name,
    Formulary_Tier,
    Coverage_Status,
    Prior_Authorization_Flag,
    Step_Therapy_Flag,
    Quantity_Limit_Flag,
    Effective_Date,
    End_Date,
    Source_System
FROM dbo.import_formulary;
GO

--Verify Load--
SELECT COUNT(*) AS RawFormularyRows
FROM raw.formulary;
GO

SELECT TOP 10 *
FROM raw.formulary;
GO

--Check invalid--
SELECT
    Formulary_Record_ID,
    Plan_ID,
    NDC,
    Drug_Name,
    Formulary_Tier
FROM raw.formulary
WHERE Formulary_Tier NOT BETWEEN 1 AND 5
ORDER BY Formulary_Tier;
GO

--Check Missing Status--
SELECT
    Formulary_Record_ID,
    Plan_ID,
    NDC,
    Drug_Name,
    Formulary_Tier,
    Coverage_Status
FROM raw.formulary
WHERE
    Coverage_Status IS NULL
    OR LTRIM(RTRIM(Coverage_Status)) = '';
GO

--Find drug-name conflicts --
SELECT
    Formulary_Record_ID,
    Plan_ID,
    NDC,
    Drug_Name
FROM raw.formulary
WHERE Drug_Name = 'FORMULARY NAME MISMATCH';
GO

--Find duplicate formulary records--
SELECT *
FROM raw.formulary
WHERE Formulary_Record_ID LIKE 'FRM_DUP%';
GO

--Find overlapping records--
SELECT *
FROM raw.formulary
WHERE Formulary_Record_ID LIKE 'FRM_OVR%';
GO

--Check NDCs--
SELECT
    f.Formulary_Record_ID,
    f.Plan_ID,
    f.NDC,
    f.Drug_Name,
    f.Formulary_Tier
FROM raw.formulary f
LEFT JOIN raw.drug_reference d
    ON f.NDC = d.NDC
WHERE d.NDC IS NULL;
GO