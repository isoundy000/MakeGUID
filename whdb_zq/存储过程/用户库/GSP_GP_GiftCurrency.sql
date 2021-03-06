USE ZQGameUserDB;
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go






-- =============================================
-- Author:		<chxf>
-- Create date: <2011-12-07>
-- Description:	<赠送金币>
-- =============================================
create PROCEDURE [dbo].[GSP_GP_GiftCurrency]
	@UserID						INT,					--用户ID
	@PassWord					NCHAR(32),				--用户密码		
	@strClientIP				NVARCHAR(15)			--IP
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Score					INT						--用户金币
	DECLARE @ChangeGlod				INT						--变动金币
	DECLARE @currMonth				NVARCHAR(40)			--当前年月份
	DECLARE @GiftCoumt				INT						--当天赠送次数
	
	SET @ChangeGlod = 0

	SELECT @Score=Score FROM ZQGameUserDB.dbo.AccountsInfo a LEFT JOIN ZQTreasureDB.dbo.GameScoreInfo b
		ON a.UserID=b.UserID WHERE a.UserID=@UserID AND a.LogonPass=@PassWord
	IF(@Score IS NOT NULL)
	BEGIN
		--SELECT @GiftCoumt=COUNT(*) FROM ZQTreasureDB.dbo.UserNewGift
		--WHERE UserID=@UserID AND Type=4 AND CONVERT(VARCHAR(10),CreateDate,120)=CONVERT(VARCHAR(10),GetDate(),120)
		IF (@GiftCoumt=0)
		BEGIN
			SELECT @Score=@Score+Gold FROM ZQWebDB.dbo.user_bank WHERE UserID=@UserID
			IF (@Score<3000)
			BEGIN
				SET @ChangeGlod = 10000-@Score
				UPDATE ZQTreasureDB.dbo.GameScoreInfo SET Score=10000 WHERE UserID=@UserID
				SET @currMonth='ZQWebDB.dbo.UserGoldLog_'+LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)
				EXEC ('INSERT INTO '+@currMonth+'(UserID,ChangeType,LastGold,ChangeGold,IpAddress) VALUES
					('+@UserID+',9,10000,'+@ChangeGlod+','''+@strClientIP+''')')

				--INSERT INTO ZQTreasureDB.dbo.UserNewGift(UserID,Type,Gold) VALUES(@UserID,4,@ChangeGlod)
				
				SELECT @ChangeGlod AS ChangeGlod,'恭喜你！领取成功！' AS Describe
				RETURN 1
			END
			ELSE
			BEGIN
				SELECT @ChangeGlod AS ChangeGlod,'领取失败！请查看你银行是否存有金币！' AS Describe
				RETURN -1
			END
		END
		ELSE 
		BEGIN
			SELECT @ChangeGlod AS ChangeGlod,'领取失败！你今天已经领取过了！' AS Describe
			RETURN -2
		END
	END
	ELSE
	BEGIN
		SELECT @ChangeGlod AS ChangeGlod,'领取失败！请重新登录再次尝试！' AS Describe
		RETURN 0
	END

	/*DECLARE @Score					INT						--用户金币3
	DECLARE @ChangeGlod				INT						--变动金币
	DECLARE @currMonth				NVARCHAR(40)			--当前年月份

	SET @ChangeGlod = 0
	--金币数量
	SELECT @Score=Score FROM ZQGameUserDB.dbo.AccountsInfo a LEFT JOIN ZQTreasureDB.dbo.GameScoreInfo b
		ON a.UserID=b.UserID WHERE a.UserID=@UserID AND a.LogonPass=@PassWord
	IF(@Score IS NOT NULL)
	BEGIN
		SELECT @Score=@Score+Gold FROM ZQWebDB.dbo.user_bank WHERE UserID=@UserID
		IF (@Score<3000)
		BEGIN
			SET @ChangeGlod = 10000-@Score
			UPDATE ZQTreasureDB.dbo.GameScoreInfo SET Score=10000 WHERE UserID=@UserID
			SET @currMonth='ZQWebDB.dbo.UserGoldLog_'+LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)
			EXEC ('INSERT INTO '+@currMonth+'(UserID,ChangeType,LastGold,ChangeGold,IpAddress) VALUES
				('+@UserID+',9,10000,'+@ChangeGlod+','''+@strClientIP+''')')
			SELECT @ChangeGlod AS ChangeGlod
			RETURN 1
		END
		ELSE
		BEGIN
			SELECT @ChangeGlod AS ChangeGlod
			RETURN 0
		END
	END
	ELSE
	BEGIN
		SELECT @ChangeGlod AS ChangeGlod
		RETURN 0
	END*/
END






