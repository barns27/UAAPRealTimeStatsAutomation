-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateTeamDigRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateTeamDigRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateTeamDigRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamDigRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamDigRankings;
    END

    -- Create the new view with team dig statistics
    EXEC ('
    CREATE VIEW TeamDigRankings AS
    WITH TeamDigStats AS (
        SELECT 
            ts.team_code,
            SUM(ts.dig_excellent) AS total_digs, -- Total successful digs
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY ts.team_code, tr.total_sets_played
    ),

    TeamDigRankings AS (
        -- Rank teams based on avg_digs_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_digs * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank teams by avg_digs_per_set
            team_code,
            total_digs,
            total_sets_played,
            CAST(total_digs * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_digs_per_set -- Average digs per set
        FROM TeamDigStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        total_digs,
        total_sets_played,
        avg_digs_per_set
    FROM TeamDigRankings;
    ');
END;
GO