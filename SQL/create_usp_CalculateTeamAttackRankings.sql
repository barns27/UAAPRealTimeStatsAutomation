-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_CalculateTeamAttackRankings', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_CalculateTeamAttackRankings;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_CalculateTeamAttackRankings
AS
BEGIN
    -- Check if the view exists and drop it if it does
    IF OBJECT_ID('TeamAttackRankings', 'V') IS NOT NULL
    BEGIN
        DROP VIEW TeamAttackRankings;
    END

    -- Create the new view with the attacking statistics
    EXEC ('
    CREATE VIEW TeamAttackRankings AS
    WITH AttackStats AS (
        SELECT 
            team_code,
            SUM(attack_excellent) AS total_attacks, -- Total successful attacks
            SUM(attack_attempts) AS total_attempts, -- Total attack attempts
            CASE 
                WHEN SUM(attack_attempts) = 0 THEN 0 -- Avoid division by zero
                ELSE CAST(SUM(attack_excellent) * 1.0 / SUM(attack_attempts) * 100 AS DECIMAL(5, 2)) -- Attack percentage
            END AS attack_percentage
        FROM [UAAPVball].[dbo].[Team_Stats]
        GROUP BY team_code
    ),

    TeamAttackRankings AS (
        -- Rank teams based on attack_percentage
        SELECT 
            RANK() OVER (ORDER BY attack_percentage DESC) AS rank_no, -- Rank teams by attack_percentage
            team_code,
            total_attacks,
            total_attempts,
            attack_percentage
        FROM AttackStats
    )

    -- Select the final results
    SELECT 
        rank_no,
        team_code,
        total_attacks,
        total_attempts,
        attack_percentage
    FROM TeamAttackRankings;
    ');
END;
GO