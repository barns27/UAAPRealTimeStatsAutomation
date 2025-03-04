-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculatePlayerSetRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculatePlayerSetRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculatePlayerSetRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('PlayerSetRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW PlayerSetRankings;
    END

    -- Create the new view with player set statistics
    EXEC ('
    CREATE VIEW PlayerSetRankings AS
    WITH PlayerSetStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.set_excellent) AS total_sets, -- Total successful sets
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY p.team_code, p.player_no, p.player_name, tr.total_sets_played
    ),

    PlayerSetRankings AS (
        -- Rank players based on avg_sets_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_sets * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank players by avg_sets_per_set
            team_code,
            player_no,
            player_name,
            total_sets,
            total_sets_played,
            CAST(total_sets * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_sets_per_set -- Average sets per set
        FROM PlayerSetStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        player_no,
        player_name,
        total_sets,
        total_sets_played,
        avg_sets_per_set
    FROM PlayerSetRankings;
    ');
END;
GO