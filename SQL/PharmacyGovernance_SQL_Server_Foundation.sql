
/*
===============================================================================
Pharmacy Medication Data Governance & Lineage Platform
SQL Server Build Script - Phase 3: Database Foundation
===============================================================================

Purpose
-------
Creates the SQL Server database architecture for the synthetic pharmacy
governance portfolio project.

Creates:
    Database: PharmacyGovernance

Schemas:
    raw
    staging
    governed
    governance
    reporting

Raw source tables:
    raw.pharmacy_claim
    raw.drug_reference
    raw.formulary
    raw.drug_pricing
    raw.pharmacy_master

Governance tables:
    governance.data_quality_rule
    governance.data_quality_exception
    governance.business_glossary
    governance.data_owner
    governance.lineage
    governance.report_inventory
    governance.kpi_definition

Staging tables:
    staging.medication
    staging.pharmacy
    staging.formulary
    staging.drug_pricing
    staging.pharmacy_claim

Governed tables:
    governed.dim_medication
    governed.dim_pharmacy
    governed.dim_formulary
    governed.fact_drug_pricing
    governed.fact_pharmacy_claim

Notes
-----
1. Run this script in SQL Server Management Studio.
2. Load the CSV files into the RAW tables after the database is created.
3. The next project step will populate staging and governed layers and execute
   automated data-quality rules.
===============================================================================
*/

SET NOCOUNT ON;
GO

/* ============================================================================
   1. CREATE DATABASE
   ============================================================================ */

IF DB_ID('PharmacyGovernance') IS NULL
BEGIN
    CREATE DATABASE PharmacyGovernance;
END;
GO

USE PharmacyGovernance;
GO


/* ============================================================================
   2. CREATE SCHEMAS
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'raw')
    EXEC('CREATE SCHEMA raw');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'governed')
    EXEC('CREATE SCHEMA governed');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'governance')
    EXEC('CREATE SCHEMA governance');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'reporting')
    EXEC('CREATE SCHEMA reporting');
GO


/* ============================================================================
   3. RAW TABLES
   Preserve source data as received.
   ============================================================================ */

DROP TABLE IF EXISTS raw.pharmacy_claim;
GO
CREATE TABLE raw.pharmacy_claim
(
    Claim_ID            VARCHAR(50)     NULL,
    Member_ID           VARCHAR(50)     NULL,
    Claim_Date          DATE            NULL,
    NDC                 VARCHAR(50)     NULL,
    Drug_Name           VARCHAR(255)    NULL,
    Pharmacy_ID         VARCHAR(100)    NULL,
    Quantity            DECIMAL(18,4)   NULL,
    Days_Supply         INT             NULL,
    Ingredient_Cost     DECIMAL(18,2)   NULL,
    Dispensing_Fee      DECIMAL(18,2)   NULL,
    Member_Pay          DECIMAL(18,2)   NULL,
    Plan_Pay            DECIMAL(18,2)   NULL,
    Paid_Amount         DECIMAL(18,2)   NULL,
    Claim_Status        VARCHAR(50)     NULL,
    Source_System       VARCHAR(100)    NULL,
    Load_Datetime       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS raw.drug_reference;
GO
CREATE TABLE raw.drug_reference
(
    Drug_Reference_ID   VARCHAR(50)     NULL,
    NDC                 VARCHAR(50)     NULL,
    Drug_Name           VARCHAR(255)    NULL,
    Generic_Name        VARCHAR(255)    NULL,
    Brand_Name          VARCHAR(255)    NULL,
    Strength            DECIMAL(18,4)   NULL,
    Strength_Unit       VARCHAR(50)     NULL,
    Dosage_Form         VARCHAR(100)    NULL,
    Route               VARCHAR(100)    NULL,
    Manufacturer        VARCHAR(255)    NULL,
    Drug_Class          VARCHAR(255)    NULL,
    Active_Flag         VARCHAR(10)     NULL,
    Effective_Date      DATE            NULL,
    End_Date            DATE            NULL,
    Source_System       VARCHAR(100)    NULL,
    Load_Datetime       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS raw.formulary;
GO
CREATE TABLE raw.formulary
(
    Formulary_Record_ID         VARCHAR(50)   NULL,
    Plan_ID                     VARCHAR(50)   NULL,
    NDC                         VARCHAR(50)   NULL,
    Drug_Name                   VARCHAR(255)  NULL,
    Formulary_Tier              INT           NULL,
    Coverage_Status             VARCHAR(100)  NULL,
    Prior_Authorization_Flag    VARCHAR(10)   NULL,
    Step_Therapy_Flag           VARCHAR(10)   NULL,
    Quantity_Limit_Flag         VARCHAR(10)   NULL,
    Effective_Date              DATE          NULL,
    End_Date                    DATE          NULL,
    Source_System               VARCHAR(100)  NULL,
    Load_Datetime               DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS raw.drug_pricing;
GO
CREATE TABLE raw.drug_pricing
(
    Pricing_Record_ID       VARCHAR(50)     NULL,
    NDC                     VARCHAR(50)     NULL,
    Pricing_Methodology     VARCHAR(100)    NULL,
    Unit_Price              DECIMAL(18,4)   NULL,
    Package_Price           DECIMAL(18,2)   NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Last_Updated            DATETIME2(0)    NULL,
    Load_Datetime           DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS raw.pharmacy_master;
GO
CREATE TABLE raw.pharmacy_master
(
    Pharmacy_Source_ID      VARCHAR(50)     NULL,
    NPI                     VARCHAR(50)     NULL,
    NCPDP_ID                VARCHAR(50)     NULL,
    Pharmacy_Name           VARCHAR(255)    NULL,
    Pharmacy_Type           VARCHAR(100)    NULL,
    Address                 VARCHAR(255)    NULL,
    City                    VARCHAR(100)    NULL,
    State                   VARCHAR(20)     NULL,
    ZIP                     VARCHAR(20)     NULL,
    Network_Status          VARCHAR(100)    NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Load_Datetime           DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


/* ============================================================================
   4. STAGING TABLES
   Standardized, cleansed, and validated representations.
   ============================================================================ */

DROP TABLE IF EXISTS staging.medication;
GO
CREATE TABLE staging.medication
(
    Staging_Medication_ID   BIGINT IDENTITY(1,1) PRIMARY KEY,
    Drug_Reference_ID       VARCHAR(50)     NULL,
    Source_NDC              VARCHAR(50)     NULL,
    NDC_11                  VARCHAR(11)     NULL,
    Drug_Name               VARCHAR(255)    NULL,
    Generic_Name            VARCHAR(255)    NULL,
    Brand_Name              VARCHAR(255)    NULL,
    Strength                DECIMAL(18,4)   NULL,
    Strength_Unit           VARCHAR(50)     NULL,
    Dosage_Form             VARCHAR(100)    NULL,
    Route                   VARCHAR(100)    NULL,
    Manufacturer            VARCHAR(255)    NULL,
    Drug_Class              VARCHAR(255)    NULL,
    Active_Flag             CHAR(1)         NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    NDC_Valid_Flag          BIT             NULL,
    Data_Quality_Status     VARCHAR(50)     NULL,
    Processed_Datetime      DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS staging.pharmacy;
GO
CREATE TABLE staging.pharmacy
(
    Staging_Pharmacy_ID     BIGINT IDENTITY(1,1) PRIMARY KEY,
    Pharmacy_Source_ID      VARCHAR(50)     NULL,
    NPI                     VARCHAR(10)     NULL,
    NCPDP_ID                VARCHAR(7)      NULL,
    Pharmacy_Name           VARCHAR(255)    NULL,
    Pharmacy_Type           VARCHAR(100)    NULL,
    Address                 VARCHAR(255)    NULL,
    City                    VARCHAR(100)    NULL,
    State                   VARCHAR(2)      NULL,
    ZIP                     VARCHAR(10)     NULL,
    Network_Status          VARCHAR(100)    NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Data_Quality_Status     VARCHAR(50)     NULL,
    Processed_Datetime      DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS staging.formulary;
GO
CREATE TABLE staging.formulary
(
    Staging_Formulary_ID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    Formulary_Record_ID         VARCHAR(50)   NULL,
    Plan_ID                     VARCHAR(50)   NULL,
    Source_NDC                  VARCHAR(50)   NULL,
    NDC_11                      VARCHAR(11)   NULL,
    Drug_Name                   VARCHAR(255)  NULL,
    Formulary_Tier              INT           NULL,
    Coverage_Status             VARCHAR(100)  NULL,
    Prior_Authorization_Flag    CHAR(1)       NULL,
    Step_Therapy_Flag           CHAR(1)       NULL,
    Quantity_Limit_Flag         CHAR(1)       NULL,
    Effective_Date              DATE          NULL,
    End_Date                    DATE          NULL,
    Source_System               VARCHAR(100)  NULL,
    Data_Quality_Status         VARCHAR(50)   NULL,
    Processed_Datetime          DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS staging.drug_pricing;
GO
CREATE TABLE staging.drug_pricing
(
    Staging_Pricing_ID      BIGINT IDENTITY(1,1) PRIMARY KEY,
    Pricing_Record_ID       VARCHAR(50)     NULL,
    Source_NDC              VARCHAR(50)     NULL,
    NDC_11                  VARCHAR(11)     NULL,
    Pricing_Methodology     VARCHAR(100)    NULL,
    Unit_Price              DECIMAL(18,4)   NULL,
    Package_Price           DECIMAL(18,2)   NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Last_Updated            DATETIME2(0)    NULL,
    Data_Quality_Status     VARCHAR(50)     NULL,
    Processed_Datetime      DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS staging.pharmacy_claim;
GO
CREATE TABLE staging.pharmacy_claim
(
    Staging_Claim_ID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    Claim_ID                VARCHAR(50)     NULL,
    Member_ID               VARCHAR(50)     NULL,
    Claim_Date              DATE            NULL,
    Source_NDC              VARCHAR(50)     NULL,
    NDC_11                  VARCHAR(11)     NULL,
    Drug_Name               VARCHAR(255)    NULL,
    Pharmacy_ID             VARCHAR(100)    NULL,
    Quantity                DECIMAL(18,4)   NULL,
    Days_Supply             INT             NULL,
    Ingredient_Cost         DECIMAL(18,2)   NULL,
    Dispensing_Fee          DECIMAL(18,2)   NULL,
    Member_Pay              DECIMAL(18,2)   NULL,
    Plan_Pay                DECIMAL(18,2)   NULL,
    Paid_Amount             DECIMAL(18,2)   NULL,
    Claim_Status            VARCHAR(50)     NULL,
    Source_System           VARCHAR(100)    NULL,
    Data_Quality_Status     VARCHAR(50)     NULL,
    Processed_Datetime      DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


/* ============================================================================
   5. GOVERNED TABLES
   Enterprise-trusted records.
   ============================================================================ */

DROP TABLE IF EXISTS governed.dim_medication;
GO
CREATE TABLE governed.dim_medication
(
    Medication_Key          INT IDENTITY(1,1) PRIMARY KEY,
    Governed_Medication_ID  VARCHAR(50)     NOT NULL,
    NDC_11                  VARCHAR(11)     NOT NULL,
    Drug_Name               VARCHAR(255)    NULL,
    Generic_Name            VARCHAR(255)    NULL,
    Brand_Name              VARCHAR(255)    NULL,
    Strength                DECIMAL(18,4)   NULL,
    Strength_Unit           VARCHAR(50)     NULL,
    Dosage_Form             VARCHAR(100)    NULL,
    Route                   VARCHAR(100)    NULL,
    Manufacturer            VARCHAR(255)    NULL,
    Drug_Class              VARCHAR(255)    NULL,
    Active_Flag             CHAR(1)         NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Certification_Status    VARCHAR(50)     NOT NULL DEFAULT 'Certified',
    Created_Datetime        DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    Updated_Datetime        DATETIME2(0)    NULL,
    CONSTRAINT UQ_dim_medication_NDC11 UNIQUE (NDC_11)
);
GO


DROP TABLE IF EXISTS governed.dim_pharmacy;
GO
CREATE TABLE governed.dim_pharmacy
(
    Pharmacy_Key            INT IDENTITY(1,1) PRIMARY KEY,
    Governed_Pharmacy_ID    VARCHAR(50)     NOT NULL,
    Pharmacy_Source_ID      VARCHAR(50)     NULL,
    NPI                     VARCHAR(10)     NULL,
    NCPDP_ID                VARCHAR(7)      NULL,
    Pharmacy_Name           VARCHAR(255)    NULL,
    Pharmacy_Type           VARCHAR(100)    NULL,
    Address                 VARCHAR(255)    NULL,
    City                    VARCHAR(100)    NULL,
    State                   VARCHAR(2)      NULL,
    ZIP                     VARCHAR(10)     NULL,
    Network_Status          VARCHAR(100)    NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Certification_Status    VARCHAR(50)     NOT NULL DEFAULT 'Certified',
    Created_Datetime        DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    Updated_Datetime        DATETIME2(0)    NULL
);
GO


DROP TABLE IF EXISTS governed.dim_formulary;
GO
CREATE TABLE governed.dim_formulary
(
    Formulary_Key               INT IDENTITY(1,1) PRIMARY KEY,
    Formulary_Record_ID         VARCHAR(50)   NOT NULL,
    Plan_ID                     VARCHAR(50)   NULL,
    Medication_Key              INT           NULL,
    Formulary_Tier              INT           NULL,
    Coverage_Status             VARCHAR(100)  NULL,
    Prior_Authorization_Flag    CHAR(1)       NULL,
    Step_Therapy_Flag           CHAR(1)       NULL,
    Quantity_Limit_Flag         CHAR(1)       NULL,
    Effective_Date              DATE          NULL,
    End_Date                    DATE          NULL,
    Source_System               VARCHAR(100)  NULL,
    Created_Datetime            DATETIME2(0)  NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_formulary_medication
        FOREIGN KEY (Medication_Key)
        REFERENCES governed.dim_medication(Medication_Key)
);
GO


DROP TABLE IF EXISTS governed.fact_drug_pricing;
GO
CREATE TABLE governed.fact_drug_pricing
(
    Pricing_Key             BIGINT IDENTITY(1,1) PRIMARY KEY,
    Pricing_Record_ID       VARCHAR(50)     NOT NULL,
    Medication_Key          INT             NULL,
    Pricing_Methodology     VARCHAR(100)    NULL,
    Unit_Price              DECIMAL(18,4)   NULL,
    Package_Price           DECIMAL(18,2)   NULL,
    Effective_Date          DATE            NULL,
    End_Date                DATE            NULL,
    Source_System           VARCHAR(100)    NULL,
    Last_Updated            DATETIME2(0)    NULL,
    Created_Datetime        DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_pricing_medication
        FOREIGN KEY (Medication_Key)
        REFERENCES governed.dim_medication(Medication_Key)
);
GO


DROP TABLE IF EXISTS governed.fact_pharmacy_claim;
GO
CREATE TABLE governed.fact_pharmacy_claim
(
    Claim_Key               BIGINT IDENTITY(1,1) PRIMARY KEY,
    Claim_ID                VARCHAR(50)     NOT NULL,
    Member_ID               VARCHAR(50)     NULL,
    Claim_Date              DATE            NULL,
    Medication_Key          INT             NULL,
    Pharmacy_Key            INT             NULL,
    Quantity                DECIMAL(18,4)   NULL,
    Days_Supply             INT             NULL,
    Ingredient_Cost         DECIMAL(18,2)   NULL,
    Dispensing_Fee          DECIMAL(18,2)   NULL,
    Member_Pay              DECIMAL(18,2)   NULL,
    Plan_Pay                DECIMAL(18,2)   NULL,
    Paid_Amount             DECIMAL(18,2)   NULL,
    Claim_Status            VARCHAR(50)     NULL,
    Source_System           VARCHAR(100)    NULL,
    Created_Datetime        DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_claim_medication
        FOREIGN KEY (Medication_Key)
        REFERENCES governed.dim_medication(Medication_Key),
    CONSTRAINT FK_claim_pharmacy
        FOREIGN KEY (Pharmacy_Key)
        REFERENCES governed.dim_pharmacy(Pharmacy_Key)
);
GO


/* ============================================================================
   6. GOVERNANCE METADATA TABLES
   Governance itself becomes queryable data.
   ============================================================================ */

DROP TABLE IF EXISTS governance.data_quality_rule;
GO
CREATE TABLE governance.data_quality_rule
(
    Rule_ID             VARCHAR(20)     PRIMARY KEY,
    Domain              VARCHAR(100)    NOT NULL,
    Rule_Description    VARCHAR(500)    NOT NULL,
    Severity            VARCHAR(20)     NOT NULL,
    Active_Flag         CHAR(1)         NOT NULL DEFAULT 'Y',
    Rule_Owner          VARCHAR(150)    NULL,
    Review_Frequency    VARCHAR(50)     NULL,
    Created_Datetime    DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS governance.data_quality_exception;
GO
CREATE TABLE governance.data_quality_exception
(
    Exception_ID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    Rule_ID             VARCHAR(20)     NOT NULL,
    Record_ID           VARCHAR(100)    NULL,
    Source_System       VARCHAR(100)    NULL,
    Source_Table        VARCHAR(150)    NULL,
    Source_Field        VARCHAR(150)    NULL,
    Issue_Type          VARCHAR(255)    NULL,
    Issue_Description   VARCHAR(1000)   NULL,
    Severity            VARCHAR(20)     NULL,
    Detected_Value      VARCHAR(1000)   NULL,
    Expected_Value      VARCHAR(1000)   NULL,
    Detection_Date      DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    Status              VARCHAR(50)     NOT NULL DEFAULT 'Open',
    Assigned_Steward    VARCHAR(150)    NULL,
    Resolution_Date     DATETIME2(0)    NULL,
    Resolution_Notes    VARCHAR(2000)   NULL,
    CONSTRAINT FK_exception_rule
        FOREIGN KEY (Rule_ID)
        REFERENCES governance.data_quality_rule(Rule_ID)
);
GO


DROP TABLE IF EXISTS governance.business_glossary;
GO
CREATE TABLE governance.business_glossary
(
    Business_Term_ID        INT IDENTITY(1,1) PRIMARY KEY,
    Business_Term           VARCHAR(255)    NOT NULL,
    Business_Definition     VARCHAR(2000)   NOT NULL,
    Data_Domain             VARCHAR(100)    NULL,
    Data_Owner              VARCHAR(150)    NULL,
    Data_Steward            VARCHAR(150)    NULL,
    System_Of_Record        VARCHAR(150)    NULL,
    Calculation_Logic       VARCHAR(2000)   NULL,
    Sensitivity             VARCHAR(50)     NULL,
    Certification_Status    VARCHAR(50)     NOT NULL DEFAULT 'Draft',
    Effective_Date          DATE            NULL,
    Review_Date             DATE            NULL,
    Created_Datetime        DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS governance.data_owner;
GO
CREATE TABLE governance.data_owner
(
    Ownership_ID            INT IDENTITY(1,1) PRIMARY KEY,
    Data_Domain             VARCHAR(100)    NOT NULL,
    Business_Data_Owner     VARCHAR(150)    NULL,
    Data_Steward            VARCHAR(150)    NULL,
    Technical_Owner         VARCHAR(150)    NULL,
    System_Of_Record        VARCHAR(150)    NULL,
    DQ_Threshold_Percent    DECIMAL(5,2)    NULL,
    Review_Frequency        VARCHAR(50)     NULL,
    Active_Flag             CHAR(1)         NOT NULL DEFAULT 'Y'
);
GO


DROP TABLE IF EXISTS governance.lineage;
GO
CREATE TABLE governance.lineage
(
    Lineage_ID              BIGINT IDENTITY(1,1) PRIMARY KEY,
    Source_System           VARCHAR(150)    NULL,
    Source_Object           VARCHAR(255)    NOT NULL,
    Source_Field            VARCHAR(255)    NULL,
    Target_Object           VARCHAR(255)    NOT NULL,
    Target_Field            VARCHAR(255)    NULL,
    Transformation_Type     VARCHAR(100)    NULL,
    Transformation_Logic    VARCHAR(2000)   NULL,
    Lineage_Level           VARCHAR(50)     NULL,
    Active_Flag             CHAR(1)         NOT NULL DEFAULT 'Y',
    Created_Datetime        DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME()
);
GO


DROP TABLE IF EXISTS governance.report_inventory;
GO
CREATE TABLE governance.report_inventory
(
    Report_ID               INT IDENTITY(1,1) PRIMARY KEY,
    Report_Name             VARCHAR(255)    NOT NULL,
    Report_Type             VARCHAR(100)    NULL,
    Business_Owner          VARCHAR(150)    NULL,
    Technical_Owner         VARCHAR(150)    NULL,
    Workspace_Name          VARCHAR(255)    NULL,
    Certification_Status    VARCHAR(50)     NULL,
    Refresh_Frequency       VARCHAR(50)     NULL,
    Active_Flag             CHAR(1)         NOT NULL DEFAULT 'Y'
);
GO


DROP TABLE IF EXISTS governance.kpi_definition;
GO
CREATE TABLE governance.kpi_definition
(
    KPI_ID                  INT IDENTITY(1,1) PRIMARY KEY,
    KPI_Name                VARCHAR(255)    NOT NULL,
    KPI_Definition          VARCHAR(2000)   NOT NULL,
    Calculation_Logic       VARCHAR(2000)   NULL,
    Source_Object           VARCHAR(255)    NULL,
    Source_Field            VARCHAR(255)    NULL,
    Business_Owner          VARCHAR(150)    NULL,
    Certification_Status    VARCHAR(50)     NOT NULL DEFAULT 'Draft',
    Effective_Date          DATE            NULL,
    Review_Date             DATE            NULL
);
GO


/* ============================================================================
   7. SEED THE 20 DATA QUALITY RULES
   ============================================================================ */

INSERT INTO governance.data_quality_rule
(
    Rule_ID,
    Domain,
    Rule_Description,
    Severity,
    Rule_Owner,
    Review_Frequency
)
VALUES
('DQ001','Medication','NDC is missing','Critical','Pharmacy Data Steward','Monthly'),
('DQ002','Medication','NDC cannot be standardized to NDC-11','Critical','Pharmacy Data Steward','Monthly'),
('DQ003','Medication','NDC not found in medication master','Critical','Pharmacy Data Steward','Monthly'),
('DQ004','Medication','Duplicate active NDC','Critical','Pharmacy Data Steward','Monthly'),
('DQ005','Medication','Drug name conflicts with governed medication','High','Pharmacy Data Steward','Monthly'),
('DQ006','Medication','Missing generic name','Medium','Pharmacy Data Steward','Monthly'),
('DQ007','Pricing','No active pricing record','High','Pricing Data Steward','Monthly'),
('DQ008','Pricing','Multiple active prices','High','Pricing Data Steward','Monthly'),
('DQ009','Pricing','Price is zero or negative','Critical','Pricing Data Steward','Monthly'),
('DQ010','Formulary','NDC missing from drug master','High','Formulary Data Steward','Monthly'),
('DQ011','Formulary','Invalid formulary tier','Medium','Formulary Data Steward','Monthly'),
('DQ012','Formulary','Effective dates overlap','High','Formulary Data Steward','Monthly'),
('DQ013','Claims','Duplicate claim','High','Claims Data Steward','Weekly'),
('DQ014','Claims','Paid amount is unexpectedly negative','High','Claims Data Steward','Weekly'),
('DQ015','Claims','Pharmacy not found','High','Claims Data Steward','Weekly'),
('DQ016','Pharmacy','Duplicate NPI','Critical','Provider Data Steward','Monthly'),
('DQ017','Pharmacy','Missing NPI','Medium','Provider Data Steward','Monthly'),
('DQ018','Pharmacy','Invalid state code','Low','Provider Data Steward','Monthly'),
('DQ019','Claims','Paid claim has zero paid amount','Medium','Claims Data Steward','Weekly'),
('DQ020','Claims','Days supply outside accepted range','Medium','Claims Data Steward','Weekly');
GO


/* ============================================================================
   8. SEED GOVERNANCE OWNERSHIP
   Synthetic ownership roles for portfolio demonstration.
   ============================================================================ */

INSERT INTO governance.data_owner
(
    Data_Domain,
    Business_Data_Owner,
    Data_Steward,
    Technical_Owner,
    System_Of_Record,
    DQ_Threshold_Percent,
    Review_Frequency
)
VALUES
('Medication','Director, Pharmacy Analytics','Pharmacy Data Steward','Data Engineering','Governed Medication Master',98.00,'Monthly'),
('Pharmacy','Director, Network Operations','Provider Data Steward','Data Engineering','Governed Pharmacy Master',98.00,'Monthly'),
('Claims','Director, Claims Analytics','Claims Data Steward','Data Engineering','PBM Claims Feed',99.00,'Weekly'),
('Pricing','Director, Pharmacy Finance','Pricing Data Steward','Data Engineering','Drug Pricing Feed',98.00,'Monthly'),
('Formulary','Director, Formulary Management','Formulary Data Steward','Data Engineering','Formulary Management System',98.00,'Monthly');
GO


/* ============================================================================
   9. SEED BUSINESS GLOSSARY
   ============================================================================ */

INSERT INTO governance.business_glossary
(
    Business_Term,
    Business_Definition,
    Data_Domain,
    Data_Owner,
    Data_Steward,
    System_Of_Record,
    Calculation_Logic,
    Sensitivity,
    Certification_Status,
    Effective_Date
)
VALUES
(
    'NDC-11',
    'Standardized 11-digit National Drug Code representation used as the enterprise medication business identifier.',
    'Medication',
    'Director, Pharmacy Analytics',
    'Pharmacy Data Steward',
    'Governed Medication Master',
    'Remove formatting characters and standardize eligible source NDC values to an 11-digit representation.',
    'Internal',
    'Certified',
    '2026-01-01'
),
(
    'Paid Amount',
    'Total adjudicated amount associated with a pharmacy claim after member and plan payment components are calculated.',
    'Claims',
    'Director, Claims Analytics',
    'Claims Data Steward',
    'PBM Claims Feed',
    'Member_Pay + Plan_Pay',
    'Confidential',
    'Certified',
    '2026-01-01'
),
(
    'Formulary Tier',
    'Benefit tier assigned to a covered medication for a specific plan and effective period.',
    'Formulary',
    'Director, Formulary Management',
    'Formulary Data Steward',
    'Formulary Management System',
    'Controlled value from 1 through 5.',
    'Internal',
    'Certified',
    '2026-01-01'
),
(
    'Unit Price',
    'Price associated with one unit of a medication under a specified pricing methodology and effective period.',
    'Pricing',
    'Director, Pharmacy Finance',
    'Pricing Data Steward',
    'Drug Pricing Feed',
    'Source unit price validated to be greater than zero.',
    'Confidential',
    'Certified',
    '2026-01-01'
),
(
    'Network Status',
    'Current relationship of a pharmacy to the health plan or PBM network.',
    'Pharmacy',
    'Director, Network Operations',
    'Provider Data Steward',
    'Governed Pharmacy Master',
    'Controlled values: In Network, Preferred, Out of Network.',
    'Internal',
    'Certified',
    '2026-01-01'
);
GO


/* ============================================================================
   10. INITIAL KPI DEFINITIONS
   ============================================================================ */

INSERT INTO governance.kpi_definition
(
    KPI_Name,
    KPI_Definition,
    Calculation_Logic,
    Source_Object,
    Source_Field,
    Business_Owner,
    Certification_Status,
    Effective_Date
)
VALUES
(
    'Total Pharmacy Spend',
    'Total paid amount for governed pharmacy claims included in analytical reporting.',
    'SUM(governed.fact_pharmacy_claim.Paid_Amount)',
    'governed.fact_pharmacy_claim',
    'Paid_Amount',
    'Director, Pharmacy Analytics',
    'Certified',
    '2026-01-01'
),
(
    'NDC Match Rate',
    'Percentage of pharmacy claim records whose standardized NDC maps to the governed medication master.',
    'Matched medication claims / eligible claims * 100',
    'governed.fact_pharmacy_claim',
    'Medication_Key',
    'Director, Pharmacy Analytics',
    'Certified',
    '2026-01-01'
),
(
    'Data Quality Score',
    'Percentage of evaluated records that pass all applicable active data-quality rules.',
    'Passing evaluated records / total evaluated records * 100',
    'governance.data_quality_exception',
    'Rule_ID',
    'Director, Data Governance',
    'Certified',
    '2026-01-01'
);
GO


/* ============================================================================
   11. INITIAL LINEAGE RECORDS
   These will be expanded later into field-level lineage.
   ============================================================================ */

INSERT INTO governance.lineage
(
    Source_System,
    Source_Object,
    Source_Field,
    Target_Object,
    Target_Field,
    Transformation_Type,
    Transformation_Logic,
    Lineage_Level
)
VALUES
('PBM Feed','raw.pharmacy_claim','NDC','staging.pharmacy_claim','NDC_11','Standardization','Remove formatting and standardize eligible NDC to NDC-11','Field'),
('Drug Reference Hub','raw.drug_reference','NDC','staging.medication','NDC_11','Standardization','Remove formatting and standardize eligible NDC to NDC-11','Field'),
('Staging','staging.medication','NDC_11','governed.dim_medication','NDC_11','Mastering','Retain one trusted governed medication record per valid NDC-11','Field'),
('Staging','staging.pharmacy_claim','NDC_11','governed.fact_pharmacy_claim','Medication_Key','Lookup','Map standardized NDC-11 to governed medication surrogate key','Field'),
('Governed','governed.fact_pharmacy_claim','Paid_Amount','Power BI Semantic Model','Total Pharmacy Spend','Aggregation','SUM(Paid_Amount)','Field'),
('Power BI Semantic Model','Total Pharmacy Spend',NULL,'Executive Governance Dashboard','Total Pharmacy Spend KPI','Presentation','Display certified KPI in executive report','Metric');
GO


/* ============================================================================
   12. REPORTING VIEWS
   Empty initially until governed data is populated.
   ============================================================================ */

CREATE OR ALTER VIEW reporting.vw_data_quality_summary
AS
SELECT
    r.Domain,
    r.Severity,
    COUNT(e.Exception_ID) AS Exception_Count,
    SUM(CASE WHEN e.Status = 'Open' THEN 1 ELSE 0 END) AS Open_Exception_Count,
    SUM(CASE WHEN e.Status = 'Resolved' THEN 1 ELSE 0 END) AS Resolved_Exception_Count
FROM governance.data_quality_rule r
LEFT JOIN governance.data_quality_exception e
    ON r.Rule_ID = e.Rule_ID
GROUP BY
    r.Domain,
    r.Severity;
GO


CREATE OR ALTER VIEW reporting.vw_data_quality_exceptions
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


CREATE OR ALTER VIEW reporting.vw_lineage
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


CREATE OR ALTER VIEW reporting.vw_governance_inventory
AS
SELECT
    Data_Domain,
    Business_Data_Owner,
    Data_Steward,
    Technical_Owner,
    System_Of_Record,
    DQ_Threshold_Percent,
    Review_Frequency
FROM governance.data_owner
WHERE Active_Flag = 'Y';
GO


/* ============================================================================
   13. VALIDATION
   ============================================================================ */

SELECT
    s.name AS Schema_Name,
    t.name AS Table_Name
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name IN ('raw','staging','governed','governance')
ORDER BY
    s.name,
    t.name;
GO


SELECT *
FROM governance.data_quality_rule
ORDER BY Rule_ID;
GO

PRINT 'PharmacyGovernance database foundation created successfully.';
GO


/* ============================================================================
   CSV LOAD OPTIONS
   ============================================================================

OPTION A - Recommended for this portfolio:
-----------------------------------------
Use SQL Server Management Studio:
Database > PharmacyGovernance > Tasks > Import Flat File

Import each CSV into its matching RAW table:

    pharmacy_claims_raw.csv  -> raw.pharmacy_claim
    drug_reference_raw.csv   -> raw.drug_reference
    formulary_raw.csv        -> raw.formulary
    drug_pricing_raw.csv     -> raw.drug_pricing
    pharmacy_master_raw.csv  -> raw.pharmacy_master

IMPORTANT:
Do NOT import the CSV directly over the tables created above if the Import
Flat File wizard insists on creating a new table. Instead, create temporary
import tables and INSERT into the raw tables, or use BULK INSERT.

OPTION B - BULK INSERT examples:
---------------------------------
Replace the paths below with your actual local CSV paths. SQL Server must have
permission to read the folder.

BULK INSERT raw.pharmacy_claim
FROM 'C:\YOUR_PATH\pharmacy_claims_raw.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    TABLOCK
);

BULK INSERT raw.drug_reference
FROM 'C:\YOUR_PATH\drug_reference_raw.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    TABLOCK
);

BULK INSERT raw.formulary
FROM 'C:\YOUR_PATH\formulary_raw.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    TABLOCK
);

BULK INSERT raw.drug_pricing
FROM 'C:\YOUR_PATH\drug_pricing_raw.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    TABLOCK
);

BULK INSERT raw.pharmacy_master
FROM 'C:\YOUR_PATH\pharmacy_master_raw.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    TABLOCK
);

===============================================================================
*/
