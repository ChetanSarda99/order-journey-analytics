IF OBJECT_ID('wwi.dim_stage', 'U') IS NOT NULL
    DROP TABLE wwi.dim_stage;
GO

CREATE TABLE wwi.dim_stage (
    stage_id INT IDENTITY(1,1) PRIMARY KEY,
    stage_name VARCHAR(100) NOT NULL,
    stage_sort INT NOT NULL,
    stage_group VARCHAR(50) NULL
);
GO

INSERT INTO wwi.dim_stage (stage_name, stage_sort, stage_group)
VALUES
('Order Created', 10, 'Pre-Ship'),
('Picked',        20, 'Pre-Ship'),
('Invoiced',      30, 'Pre-Ship'),
('Delivered',     40, 'In-Transit');
GO
