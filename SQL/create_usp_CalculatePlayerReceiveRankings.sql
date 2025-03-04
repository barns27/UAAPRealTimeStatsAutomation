-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculatePlayerReceiveRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculatePlayerReceiveRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculatePlayerReceiveRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('PlayerReceiveRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW PlayerReceiveRankings;
    END

    -- Create the new view with the player receive statistics
    EXEC ('
    CREATE VIEW PlayerReceiveRankings AS
    WITH PlayerReceiveStats AS (
        SELECT 
            p.team_code,
            p.player_no,
            p.player_name,
            SUM(ts.receive_excellent) AS total_receives, -- Total successful receives
            SUM(ts.receive_attempts) AS total_attempts, -- Total receive attempts
            CASE 
                WHEN SUM(ts.receive_attempts) = 0 THEN 0 -- Avoid division by zero
                ELSE CAST(SUM(ts.receive_excellent) * 1.0 / SUM(ts.receive_attempts) * 100 AS DECIMAL(5, 2)) -- Receive percentage
            END AS receive_percentage
        FROM [UAAPVball].[dbo].[Team_Stats] ts
        INNER JOIN [UAAPVball].[dbo].[Players] p
            ON ts.team_code = p.team_code
            AND ts.player_no = p.player_no
        GROUP BY p.team_code, p.player_no, p.player_name
    ),

    TeamReceiveTotals AS (
        SELECT 
            team_code,
            SUM(receive_excellent) AS team_total_receives -- Total receives by the team
        FROM [UAAPVball].[dbo].[Team_Stats]
        GROUP BY team_code
    ),

    PlayerReceiveRankings AS (
        -- Rank players based on receive_percentage
        SELECT 
            RANK() OVER (ORDER BY receive_percentage DESC) AS rank_no, -- Rank players by receive_percentage
            prs.team_code,
            prs.player_no,
            prs.player_name,
            prs.total_receives,
            prs.total_attempts,
            prs.receive_percentage
        FROM PlayerReceiveStats prs
        INNER JOIN TeamReceiveTotals trt
            ON prs.team_code = trt.team_code
        WHERE prs.total_receives >= trt.team_total_receives * 0.25 -- 25% limit
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        player_no,
        player_name,
        total_receives,
        total_attempts,
        receive_percentage
    FROM PlayerReceiveRankings;
    ');
END;
GO