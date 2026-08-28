SELECT *
FROM governance.data_quality_rule
ORDER BY Rule_ID;

SELECT COUNT(*) AS DataQualityRuleCount
FROM governance.data_quality_rule;

SELECT *
FROM governance.business_glossary;

SELECT *
FROM governance.data_owner;

SELECT *
FROM governance.lineage
ORDER BY Lineage_ID;

SELECT *
FROM reporting.vw_governance_inventory;

SELECT *
FROM reporting.vw_lineage;

SELECT 'DQ Rules' AS ObjectName, COUNT(*) AS RecordCount
FROM governance.data_quality_rule

UNION ALL

SELECT 'Business Glossary', COUNT(*)
FROM governance.business_glossary

UNION ALL

SELECT 'Data Owners', COUNT(*)
FROM governance.data_owner

UNION ALL

SELECT 'Lineage', COUNT(*)
FROM governance.lineage

UNION ALL

SELECT 'DQ Exceptions', COUNT(*)
FROM governance.data_quality_exception;