-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateVolleyballRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateVolleyballRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateVolleyballRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamRanking', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamRanking;
    END

    -- Create the new view with the ranking results
    EXEC ('
    CREATE VIEW TeamRanking AS
    WITH MatchResults AS (
        -- Team 0 results
        SELECT 
            team_code_0 AS team_code,
            team_name_0 AS team_name,
            CASE 
                WHEN team_score_0 = 3 AND team_score_1 IN (0, 1) THEN 2 -- Straight-set win
                WHEN team_score_0 = 3 AND team_score_1 = 2 THEN 1 -- Win in 4 or 5 sets
                ELSE 0 -- Loss
            END AS points,
            CASE 
                WHEN team_score_0 > team_score_1 THEN 1 -- Win
                ELSE 0 -- Loss
            END AS win,
            CASE 
                WHEN team_score_0 < team_score_1 THEN 1 -- Loss
                ELSE 0 -- Win
            END AS loss,
            team_score_0 + team_score_1 AS total_sets_played -- Total sets played in the match
        FROM [UAAPVball].[dbo].[Game_Details]

        UNION ALL

        -- Team 1 results
        SELECT 
            team_code_1 AS team_code,
            team_name_1 AS team_name,
            CASE 
                WHEN team_score_1 = 3 AND team_score_0 IN (0, 1) THEN 2 -- Straight-set win
                WHEN team_score_1 = 3 AND team_score_0 = 2 THEN 1 -- Win in 4 or 5 sets
                ELSE 0 -- Loss
            END AS points,
            CASE 
                WHEN team_score_1 > team_score_0 THEN 1 -- Win
                ELSE 0 -- Loss
            END AS win,
            CASE 
                WHEN team_score_1 < team_score_0 THEN 1 -- Loss
                ELSE 0 -- Win
            END AS loss,
            team_score_0 + team_score_1 AS total_sets_played -- Total sets played in the match
        FROM [UAAPVball].[dbo].[Game_Details]
    ),

    TeamAggregates AS (
        -- Aggregate results by team
        SELECT 
            team_code,
            team_name,
            SUM(win) AS wins,
            SUM(loss) AS loss,
            SUM(total_sets_played) AS total_sets_played, -- Total sets played by the team
            SUM(points) AS points
        FROM MatchResults
        GROUP BY team_code, team_name
    ),

    TeamRankings AS (
        -- Rank teams based on points and wins
        SELECT 
            RANK() OVER (ORDER BY points DESC, wins DESC) AS rank_no, -- Rank teams by points and wins
            team_code,
            team_name,
            wins,
            loss,
            total_sets_played,
            points
        FROM TeamAggregates
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        team_name,
        wins,
        loss,
        total_sets_played,
        points
    FROM TeamRankings;
    ');
END;
GO