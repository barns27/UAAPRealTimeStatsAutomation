-- Check if the stored procedure exists and drop it if it does
IF OBJECT_ID('usp_RefinePlayersTable', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE usp_RefinePlayersTable;
END
GO

-- Create the stored procedure
CREATE PROCEDURE usp_RefinePlayersTable
AS
BEGIN
    -- Create a temporary table to store refined results
    IF OBJECT_ID('tempdb..#RefinedPlayers') IS NOT NULL
    BEGIN
        DROP TABLE #RefinedPlayers;
    END

    -- Select the first occurrence of each player_no per team_code
    SELECT 
        player_no,
        MIN(player_name) AS player_name, -- Keep the first occurrence of the player_name
        team_code
    INTO #RefinedPlayers
    FROM [UAAPVball].[dbo].[Players]
    GROUP BY team_code, player_no;

    -- Truncate the original Players table
    TRUNCATE TABLE [UAAPVball].[dbo].[Players];

    -- Insert the refined results back into the Players table (excluding the id column)
    INSERT INTO [UAAPVball].[dbo].[Players] (player_no, player_name, team_code)
    SELECT player_no, player_name, team_code
    FROM #RefinedPlayers;

    -- Drop the temporary table
    DROP TABLE #RefinedPlayers;
END;
GO