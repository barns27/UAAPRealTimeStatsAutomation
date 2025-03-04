-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateTeamSetRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateTeamSetRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateTeamSetRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamSetRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamSetRankings;
    END

    -- Create the new view with team set statistics
    EXEC ('
    CREATE VIEW TeamSetRankings AS
    WITH TeamSetStats AS (
        SELECT 
            ts.team_code,
            SUM(ts.set_excellent) AS total_sets, -- Total successful sets
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY ts.team_code, tr.total_sets_played
    ),

    TeamSetRankings AS (
        -- Rank teams based on avg_sets_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_sets * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank teams by avg_sets_per_set
            team_code,
            total_sets,
            total_sets_played,
            CAST(total_sets * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_sets_per_set -- Average sets per set
        FROM TeamSetStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        total_sets,
        total_sets_played,
        avg_sets_per_set
    FROM TeamSetRankings;
    ');
END;
GO