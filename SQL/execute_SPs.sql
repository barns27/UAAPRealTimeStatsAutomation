use UAAPVball

EXEC usp_RefinePlayersTable;

EXEC [dbo].[usp_CalculateVolleyballRankings]

EXEC [dbo].[usp_CalculateTeamAttackRankings]
EXEC [dbo].usp_CalculateTeamBlockRankings;
EXEC [dbo].usp_CalculateTeamServeRankings;
EXEC [dbo].usp_CalculateTeamDigRankings;
EXEC [dbo].usp_CalculateTeamReceiveRankings;
EXEC [dbo].usp_CalculateTeamSetRankings;

EXEC usp_CalculatePlayerAttackRankings;
EXEC usp_CalculatePlayerBlockRankings;
EXEC usp_CalculatePlayerServeRankings;
EXEC usp_CalculatePlayerDigRankings;
EXEC usp_CalculatePlayerReceiveRankings;
EXEC usp_CalculatePlayerSetRankings;

EXEC usp_CalculateMVPRankings;