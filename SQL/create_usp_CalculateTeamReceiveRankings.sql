-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateTeamReceiveRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateTeamReceiveRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateTeamReceiveRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamReceiveRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamReceiveRankings;
    END

    -- Create the new view with the receive statistics
    EXEC ('
    CREATE VIEW TeamReceiveRankings AS
    WITH ReceiveStats AS (
        SELECT 
            team_code,
            SUM(receive_excellent) AS total_receives, -- Total successful receives
            SUM(receive_attempts) AS total_attempts, -- Total receive attempts
            CASE 
                WHEN SUM(receive_attempts) = 0 THEN 0 -- Avoid division by zero
                ELSE CAST(SUM(receive_excellent) * 1.0 / SUM(receive_attempts) * 100 AS DECIMAL(5, 2)) -- Receive percentage
            END AS receive_percentage
        FROM [UAAPVball].[dbo].[Team_Stats]
        GROUP BY team_code
    ),

    TeamReceiveRankings AS (
        -- Rank teams based on receive_percentage
        SELECT 
            RANK() OVER (ORDER BY receive_percentage DESC) AS rank_no, -- Rank teams by receive_percentage
            team_code,
            total_receives,
            total_attempts,
            receive_percentage
        FROM ReceiveStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        total_receives,
        total_attempts,
        receive_percentage
    FROM TeamReceiveRankings;
    ');
END;
GO