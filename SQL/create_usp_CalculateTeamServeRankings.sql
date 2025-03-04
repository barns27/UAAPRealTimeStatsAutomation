-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateTeamServeRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateTeamServeRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateTeamServeRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamServeRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamServeRankings;
    END

    -- Create the new view with team serve statistics
    EXEC ('
    CREATE VIEW TeamServeRankings AS
    WITH TeamServeStats AS (
        SELECT 
            ts.team_code,
            SUM(ts.serve_excellent) AS total_serves, -- Total successful serves
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY ts.team_code, tr.total_sets_played
    ),

    TeamServeRankings AS (
        -- Rank teams based on avg_serves_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_serves * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank teams by avg_serves_per_set
            team_code,
            total_serves,
            total_sets_played,
            CAST(total_serves * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_serves_per_set -- Average serves per set
        FROM TeamServeStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        total_serves,
        total_sets_played,
        avg_serves_per_set
    FROM TeamServeRankings;
    ');
END;
GO