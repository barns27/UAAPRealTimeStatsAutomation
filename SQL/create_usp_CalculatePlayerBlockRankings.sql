-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculatePlayerBlockRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculatePlayerBlockRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculatePlayerBlockRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('PlayerBlockRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW PlayerBlockRankings;
    END

    -- Create the new view with player block statistics
    EXEC ('
    CREATE VIEW PlayerBlockRankings AS
    WITH PlayerBlockStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.block_excellent) AS total_blocks, -- Total successful blocks
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY p.team_code, p.player_no, p.player_name, tr.total_sets_played
    ),

    PlayerBlockRankings AS (
        -- Rank players based on avg_blocks_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_blocks * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank players by avg_blocks_per_set
            team_code,
            player_no,
            player_name,
            total_blocks,
            total_sets_played,
            CAST(total_blocks * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_blocks_per_set -- Average blocks per set
        FROM PlayerBlockStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        player_no,
        player_name,
        total_blocks,
        total_sets_played,
        avg_blocks_per_set
    FROM PlayerBlockRankings;
    ');
END;
GO