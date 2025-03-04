-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateTeamBlockRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateTeamBlockRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateTeamBlockRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamBlockRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamBlockRankings;
    END

    -- Create the new view with team block statistics
    EXEC ('
    CREATE VIEW TeamBlockRankings AS
    WITH TeamBlockStats AS (
        SELECT 
            ts.team_code,
            SUM(ts.block_excellent) AS total_blocks, -- Total successful blocks
            tr.total_sets_played -- Total sets played by the team
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN TeamRanking tr
            ON ts.team_code = tr.team_code
        GROUP BY ts.team_code, tr.total_sets_played
    ),

    TeamBlockRankings AS (
        -- Rank teams based on avg_blocks_per_set
        SELECT 
            RANK() OVER (ORDER BY (total_blocks * 1.0 / total_sets_played) DESC) AS rank_no, -- Rank teams by avg_blocks_per_set
            team_code,
            total_blocks,
            total_sets_played,
            CAST(total_blocks * 1.0 / total_sets_played AS DECIMAL(5, 2)) AS avg_blocks_per_set -- Average blocks per set
        FROM TeamBlockStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        total_blocks,
        total_sets_played,
        avg_blocks_per_set
    FROM TeamBlockRankings;
    ');
END;
GO