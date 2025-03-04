-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateMVPRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateMVPRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateMVPRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('MVPRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW MVPRankings;
    END

    -- Create the new view with MVP points calculation and global ranking
    EXEC ('
    CREATE VIEW MVPRankings AS
    WITH PlayerStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.attack_excellent) AS attack_points, -- Attack points (spikes)
            SUM(ts.block_excellent) AS block_points, -- Block points
            SUM(ts.serve_excellent) AS serve_points, -- Service aces
            SUM(ts.dig_excellent) AS digs, -- Digs
            SUM(ts.set_excellent) AS sets, -- Sets
            SUM(ts.receive_excellent) AS receptions -- Excellent receptions
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        GROUP BY p.team_code, p.player_no, p.player_name
    ),
    RankedPlayers AS (
        SELECT 
            team_code,
            player_no,
            player_name,
            attack_points,
            block_points,
            serve_points,
            digs,
            sets,
            receptions,
            (attack_points + block_points + serve_points + (digs * 0.1) + (sets * 0.1) + (receptions * 0.1)) AS mvp_points, -- Total MVP points
            ROW_NUMBER() OVER (ORDER BY (attack_points + block_points + serve_points + (digs * 0.1) + (sets * 0.1) + (receptions * 0.1)) DESC) AS rank_no -- Global rank for MVP race
        FROM PlayerStats
    )
    SELECT 
        rank_no, -- Global ranking for MVP race
        team_code,
        player_no,
        player_name,
        attack_points,
        block_points,
        serve_points,
        digs,
        sets,
        receptions,
        mvp_points
    FROM RankedPlayers;
    ');
END;
GO