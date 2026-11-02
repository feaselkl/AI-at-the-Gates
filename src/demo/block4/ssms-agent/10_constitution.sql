/* =============================================================================
   10_constitution.sql   (LIVE DEMO -- run between beat 1 and beat 2)

   Gives GitHub Copilot in SSMS its own identity and its own rules for
   WakeCountyFood:
     1. CopilotReader, a database user with no login, that can SELECT the three
        tables but NOT the inspector-name columns.
     2. A CONSTITUTION.md extended property on the database. Its front matter
        (agentExecuteAsUser) makes SSMS run every Copilot query as CopilotReader
        through EXECUTE AS; its body carries the business rules the prompt
        makeover had to type by hand (what "critical" means, the join keys).

   The signed-in SSMS user needs IMPERSONATE on CopilotReader. A sysadmin (sa)
   has it already. For any other login, run the GRANT at the bottom. Without
   it, Copilot refuses to run queries in this database instead of falling back
   to the user's own permissions.

   Copilot reads the constitution when a chat session opens, so start a NEW
   chat after running this.

   Undo with 90_reset.sql. Docs (checked 2026-11-01):
   https://learn.microsoft.com/ssms/github-copilot/execution-context
   ============================================================================= */

USE WakeCountyFood;
GO

/* 1. The identity Copilot runs as. */
IF DATABASE_PRINCIPAL_ID(N'CopilotReader') IS NULL
    CREATE USER CopilotReader WITHOUT LOGIN;
GO
GRANT SELECT ON dbo.Restaurant              TO CopilotReader;
GRANT SELECT ON dbo.FoodInspection          TO CopilotReader;
GRANT SELECT ON dbo.FoodInspectionViolation TO CopilotReader;

-- Inspector names are people's names: keep them away from the assistant.
-- A column-level DENY beats the table-level GRANT.
DENY SELECT ON dbo.FoodInspection (Inspector)            TO CopilotReader;
DENY SELECT ON dbo.FoodInspectionViolation (InspectedBy) TO CopilotReader;
GO

/* 2. The constitution. Front matter between the --- lines; rules after.
      An extended property is a sql_variant capped at 7,500 bytes, so the whole
      constitution has to fit in NVARCHAR(3750). NVARCHAR(MAX) fails (Msg 206). */
DECLARE @constitution NVARCHAR(3750) = N'---
agentExecuteAsUser: CopilotReader
---
# WakeCountyFood: rules for every Copilot query

- Data: Wake County, NC food inspections, September 2012 to December 2025. Dates are UTC.
- dbo.FoodInspection has one row per inspection; dbo.FoodInspectionViolation has one row per violation.
- Join everything on HSISID. dbo.Restaurant covers only current restaurants, so LEFT JOIN to it
  and expect NULL names.
- Severity is Core, Priority, Priority Foundation, or NULL. A "critical" violation means
  Severity IN (''Priority'', ''Priority Foundation''). There is no ''Critical'' value.
- City values are upper case, for example RALEIGH and CARY.
- Count violations per HSISID in a derived table before joining to inspections; joining the
  two detail tables directly multiplies rows.
- Never use SELECT *. Return at most 25 rows unless asked for more.
- Inspector names are off limits. Do not try to work around a permission error.';

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'CONSTITUTION.md')
    EXEC sp_updateextendedproperty @name = N'CONSTITUTION.md', @value = @constitution;
ELSE
    EXEC sp_addextendedproperty    @name = N'CONSTITUTION.md', @value = @constitution;
GO

/* 3. Only for a presenter login that isn't sysadmin. Replace the name first.
GRANT IMPERSONATE ON USER::CopilotReader TO [<your database user>];
*/

-- Show what Copilot will read.
SELECT name, CAST(value AS NVARCHAR(MAX)) AS constitution
FROM sys.extended_properties
WHERE class = 0 AND name = N'CONSTITUTION.md';
GO
