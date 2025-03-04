-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculatePlayerDigRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculatePlayerDigRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculatePlayerDigRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('PlayerDigRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW PlayerDigRankings;
    END

    -- Create the new view with player dig statistics
    EXEC ('
    CREATE VIEW PlayerDigRankings AS
    WITH PlayerDigStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.dig_excellent) AS total_digs, -- Total successful digs
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY p.team_code, p.player_no, p.player_name, tr.total_sets_played
    ),

    PlayerDigRankings AS (
        -- Rank players based on avg_digs_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_digs * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank players by avg_digs_per_set
            team_code,
            player_no,
            player_name,
            total_digs,
            total_sets_played,
            CAST(total_digs * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_digs_per_set -- Average digs per set
        FROM PlayerDigStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        player_no,
        player_name,
        total_digs,
        total_sets_played,
        avg_digs_per_set
    FROM PlayerDigRankings;
    ');
END;
GO