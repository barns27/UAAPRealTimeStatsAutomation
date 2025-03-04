-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculatePlayerAttackRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculatePlayerAttackRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculatePlayerAttackRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('PlayerAttackRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW PlayerAttackRankings;
    END

    -- Create the new view with the player attack statistics
    EXEC ('
    CREATE VIEW PlayerAttackRankings AS
    WITH PlayerAttackStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.attack_excellent) AS total_attacks, -- Total successful attacks
            SUM(ts.attack_attempts) AS total_attempts, -- Total attack attempts
            CASE 
                WHEN SUM(ts.attack_attempts) = 0 THEN 0 -- Avoid division by zero
                ELSE CAST(SUM(ts.attack_excellent) * 1.0 / SUM(ts.attack_attempts) * 100 AS DECIMAL(5, 2)) -- Player attack percentage
            END AS attack_percentage
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        GROUP BY p.team_code, p.player_no, p.player_name
    ),

    TeamAttackTotals AS (
        SELECT 
            team_code,
            SUM(attack_excellent) AS team_total_attacks -- Total attacks by the team
        FROM [UAAPVball].[dbo].[Team_Stats]
        GROUP BY team_code
    ),

    PlayerAttackRankings AS (
        -- Rank players based on attack_percentage
        SELECT 
            RANK() OVER (ORDER BY attack_percentage DESC) AS rank_no, -- Rank players by attack_percentage
            pas.team_code,
            pas.player_no,
            pas.player_name,
            pas.total_attacks,
            pas.total_attempts,
            pas.attack_percentage
        FROM PlayerAttackStats pas
        INNER JOIN TeamAttackTotals tat
            ON pas.team_code = tat.team_code
        WHERE pas.total_attacks >= tat.team_total_attacks * 0.15 -- 15% limit
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        player_no,
        player_name,
        total_attacks,
        total_attempts,
        attack_percentage
    FROM PlayerAttackRankings;
    ');
END;
GO