/* =============================================================================
   90_reset.sql   Puts WakeCountyFood back the way it was before the demo:
   no constitution, no CopilotReader. Copilot then runs as the signed-in user.
   ============================================================================= */

USE WakeCountyFood;
GO

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'CONSTITUTION.md')
    EXEC sp_dropextendedproperty @name = N'CONSTITUTION.md';
GO

IF DATABASE_PRINCIPAL_ID(N'CopilotReader') IS NOT NULL
    DROP USER CopilotReader;
GO

SELECT
    (SELECT COUNT(*) FROM sys.extended_properties WHERE class = 0 AND name = N'CONSTITUTION.md') AS constitutions_left,
    CASE WHEN DATABASE_PRINCIPAL_ID(N'CopilotReader') IS NULL THEN 0 ELSE 1 END                 AS copilot_user_left;
GO
