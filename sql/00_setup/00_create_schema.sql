IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'wwi')
    EXEC('CREATE SCHEMA wwi');
GO
