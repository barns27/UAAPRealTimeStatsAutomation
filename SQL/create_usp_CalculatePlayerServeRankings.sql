-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculatePlayerServeRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculatePlayerServeRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculatePlayerServeRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('PlayerServeRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW PlayerServeRankings;
    END

    -- Create the new view with player serve statistics
    EXEC ('
    CREATE VIEW PlayerServeRankings AS
    WITH PlayerServeStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.serve_excellent) AS total_serves, -- Total successful serves
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY p.team_code, p.player_no, p.player_name, tr.total_sets_played
    ),

    PlayerServeRankings AS (
        -- Rank players based on avg_serves_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_serves * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank players by avg_serves_per_set
            team_code,
            player_no,
            player_name,
            total_serves,
            total_sets_played,
            CAST(total_serves * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_serves_per_set -- Average serves per set
        FROM PlayerServeStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        player_no,
        player_name,
        total_serves,
        total_sets_played,
        avg_serves_per_set
    FROM PlayerServeRankings;
    ');
END;
GO