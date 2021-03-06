USE ZQGameUserDB;
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go





-- 帐号登陆
ALTER PROC [dbo].[GSP_GP_EfficacyAccounts]
	@strAccounts NVARCHAR(31),					-- 用户帐号
	@strPassword NCHAR(32),						-- 用户密码
	@strClientIP NVARCHAR(15),					-- 连接地址
	@strMachineSerial NCHAR(32)					-- 机器标识
AS
-- 属性设置
SET NOCOUNT ON

-- 基本信息
DECLARE @UserID INT
DECLARE @FaceID INT
DECLARE @Accounts NVARCHAR(31)
DECLARE @UnderWrite NVARCHAR(63)

-- 扩展信息
DECLARE @GameID INT
DECLARE @Gender TINYINT
DECLARE @Experience INT
DECLARE @Loveliness INT
DECLARE @MemberOrder INT
DECLARE @MemberOverDate DATETIME
DECLARE @CustomFaceVer TINYINT
DECLARE @ServerID INT

-- 辅助变量
DECLARE @EnjoinLogon AS INT
DECLARE @ErrorDescribe AS NVARCHAR(128)

-- 积分表数据
DECLARE @Money				BIGINT					--藏宝币
DECLARE @WinCount			INT						--胜利盘数
DECLARE @LostCount			INT						--失败盘数
DECLARE @DrawCount			INT						--和局盘数
DECLARE @FleeCount			INT						--断线数目
-- 用户表
DECLARE @NickName			NVARCHAR(32)			--昵称
DECLARE @Gold				BIGINT					--金币
DECLARE @Gem				BIGINT					--宝石
DECLARE @Grade				INT						--等级
DECLARE @IsAndroid			TINYINT					--是否机器人

DECLARE @Nullity BIT
DECLARE @StunDown BIT
DECLARE @LogonPass AS NCHAR(32)
DECLARE	@MachineSerial NCHAR(32)
DECLARE @MoorMachine AS TINYINT

DECLARE @LoginKey			VARCHAR(8)				--登陆Key
DECLARE @SsoMD5				VARCHAR(34)				--游戏嵌套网页验证MD5值
DECLARE @SsoStr				VARCHAR(55)				--转MD5前的字符串

DECLARE @intPropID			INT						--头像道具ID
DECLARE @GiftCoumt			INT						--当天赠送次数
DECLARE	@HashID NVARCHAR(33)						--碎片升的用的版本号

--权限
DECLARE @MasterRight INT							--用户权限
DECLARE @MasterOrder INT							--用户权限等级
DECLARE @GameMasterRight INT						--游戏权限
DECLARE @GameMasterOrder INT						--游戏权限等级

-- 执行逻辑
BEGIN
	-- 效验地址
	SELECT @EnjoinLogon=EnjoinLogon FROM ZQGameUserDB.dbo.ConfineAddress(NOLOCK) WHERE AddrString=@strClientIP AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SELECT [ErrorDescribe]=N'抱歉地通知您，系统禁止了您所在的 IP 地址的登录功能，请联系客户服务中心了解详细情况！'
		RETURN 4
	END
	
	-- 效验机器
	SELECT @EnjoinLogon=EnjoinLogon FROM ZQGameUserDB.dbo.ConfineMachine(NOLOCK) WHERE MachineSerial=@strMachineSerial AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SELECT [ErrorDescribe]=N'抱歉地通知您，系统禁止了您的机器的登录功能，请联系客户服务中心了解详细情况！'
		RETURN 7
	END
 
	-- 查询用户
	SELECT @UserID=UserID, @GameID=GameID,  @Accounts=Accounts, @UnderWrite=UnderWrite, @LogonPass=LogonPass, @FaceID=FaceID,
		@Gender=Gender, @Nullity=Nullity, @StunDown=StunDown, @MemberOrder=MemberOrder, @MemberOverDate=MemberOverDate, 
		@MoorMachine=MoorMachine, @MachineSerial=MachineSerial, @Loveliness=Loveliness,@CustomFaceVer=CustomFaceVer,
		@NickName=NickName,@IsAndroid=IsAndroid,@Money=Money,@MasterRight=MasterRight,@MasterOrder=MasterOrder
	FROM AccountsInfo(NOLOCK) WHERE Accounts=@strAccounts

	--查询积分数据
	SELECT TOP 1 @WinCount=WinCount,@LostCount=LostCount,@DrawCount=DrawCount,@FleeCount=FleeCount,@Experience=Experience,@Gold=Score,@Gem=Gems,@Grade=Grade,
		@GameMasterRight=MasterRight,@GameMasterOrder=MasterOrder
	FROM ZQTreasureDB.dbo.GameScoreInfo WHERE UserID = @UserID

	-- 查询用户
	IF @UserID IS NULL
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号不存在或者密码输入有误，请查证后再次尝试登录！'
		RETURN 1
	END	

	-- 帐号禁止
	IF @Nullity<>0
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号暂时处于冻结状态，请联系客户服务中心了解详细情况！'
		RETURN 2
	END	

	-- 帐号关闭
	IF @StunDown<>0
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号使用了安全关闭功能，必须重新开通后才能继续使用！'
		RETURN 2
	END	
	
	-- 固定机器
	IF @MoorMachine=1
	BEGIN
		IF @MachineSerial<>@strMachineSerial
		BEGIN
			SELECT [ErrorDescribe]=N'您的帐号使用固定机器登陆功能，您现所使用的机器不是所指定的机器！'
			RETURN 1
		END
	END

	-- 密码判断
	IF @LogonPass<>@strPassword
	BEGIN
		SELECT [ErrorDescribe]=N'您的帐号不存在或者密码输入有误，请查证后再次尝试登录！'
		RETURN 3
	END

	-- 固定机器
	IF @MoorMachine=2
	BEGIN
		SET @MoorMachine=1
		SET @ErrorDescribe=N'您的帐号成功使用了固定机器登陆功能！'
		UPDATE AccountsInfo SET MoorMachine=@MoorMachine, MachineSerial=@strMachineSerial WHERE UserID=@UserID
	END
	
	SET @MemberOrder=0
/* 2011-09-30  删除（游戏中没有会员）
	-- 会员等级
	IF GETDATE()>=@MemberOverDate 
	BEGIN 
		SET @MemberOrder=0
		-- 删除过期会员身份
		DELETE FROM MemberInfo WHERE UserID=@UserID
	END
	ELSE 
	BEGIN
		DECLARE @MemberCurDate DATETIME

		-- 当前会员时间
		SELECT @MemberCurDate=MIN(MemberOverDate) FROM MemberInfo WHERE UserID=@UserID

		-- 删除过期会员
		IF GETDATE()>=@MemberCurDate
		BEGIN
			-- 删除会员期限过期的所有会员身份
			DELETE FROM MemberInfo WHERE UserID=@UserID AND MemberOverDate<=GETDATE()

			-- 切换到下一级别会员身份
			SELECT @MemberOrder=MAX(MemberOrder) FROM MemberInfo WHERE UserID=@UserID
			IF @MemberOrder IS NOT NULL
			BEGIN
				UPDATE AccountsInfo SET MemberOrder=@MemberOrder WHERE UserID=@UserID
			END
			ELSE SET @MemberOrder=0
		END
	END
*/
	--权限--2012-03-06
	SET @MasterRight=@MasterRight|@GameMasterRight
	-- 权限等级
	IF @MasterOrder<>0 OR @GameMasterOrder<>0
	BEGIN
		IF @GameMasterOrder>@MasterOrder SET @MasterOrder=@GameMasterOrder
	END
	ELSE SET @MasterRight=0

	-- 被锁游戏ID
	SET @ServerID = 0
	IF((SELECT COUNT(*) FROM ZQTreasureDB.dbo.GameScoreLocker WHERE UserID = @UserID)>0)
	BEGIN
		SELECT TOP 1 @ServerID = ServerID FROM ZQTreasureDB.dbo.GameScoreLocker WHERE UserID = @UserID
	END

	-- 更新信息
	UPDATE AccountsInfo SET MemberOrder=@MemberOrder, GameLogonTimes=GameLogonTimes+1,LastLogonDate=GETDATE(),
		LastLogonIP=@strClientIP,MachineSerial=@strMachineSerial WHERE UserID=@UserID

	--大厅头像
	SELECT @intPropID = A.PropID FROM ZQWebDB.dbo.prop_used AS A 
	INNER JOIN ZQWebDB.dbo.prop_info AS B ON (A.PropID=B.ID) 
	WHERE A.UserID = @UserID AND A.PropID IN (SELECT FaceID FROM ZQGameUserDB.dbo.IndividualDatum WHERE UserID=@UserID)AND A.OverTime >= GETDATE()

	IF(@intPropID IS NOT NULL)--道具购买头像
	BEGIN
		SET @FaceID=@intPropID
	END
	ELSE -- 默认(男女)头像
	BEGIN
		SET @FaceID=0
	END

	-- 嵌套网站验证信息
	SET @LoginKey = RIGHT(NEWID(),8)--生成Key
	IF((SELECT COUNT(*) FROM ZQWebDB.dbo.SSO WHERE UserID=@UserID) > 0)
	BEGIN--更新游戏嵌套网站登陆验证
		UPDATE ZQWebDB.dbo.SSO SET LoginKey=@loginKey, KeyTime=GETDATE(), IP=@strClientIP, Flag=1 WHERE UserID = @UserID
	END
	ELSE
	BEGIN--新增游戏嵌套网站登陆验证
		INSERT ZQWebDB.dbo.SSO (UserID, LoginKey, KeyTime, IP, Flag) VALUES(@UserID, @LoginKey, GETDATE(), @strClientIP, 1)
	END

	SELECT @SsoStr = CAST(UserID AS NVARCHAR(10))+LoginKey+CONVERT(NVARCHAR, KeyTime, 120)+IP+CAST(Flag AS CHAR(1)) FROM ZQWebDB.dbo.SSO WHERE UserID=@UserID
	SELECT @SsoMD5 = sys.fn_VarBinToHexStr(HashBytes('MD5',@SsoStr))
	SET @SsoMD5 = SUBSTRING(@SsoMD5,3,LEN(@SsoMD5)-2)

	--获取赠送当天次数
	/*DECLARE @currMonth varchar(50)
	DECLARE @Sql		nvarchar(200)
	SET @currMonth='ZQWebDB.dbo.UserGoldLog_'+LEFT(CONVERT(NVARCHAR(8),GETDATE(),112),6)
	SET @Sql = 'SELECT @GiftCoumt=COUNT(*) FROM '+@currMonth+' WHERE UserID='+CONVERT(VARCHAR(10),@UserID)+' AND CONVERT(VARCHAR(10),LogTime,120)=CONVERT(VARCHAR(10),GetDate(),120)'
	exec sp_executesql @Sql, N'@GiftCoumt INT OUTPUT', @GiftCoumt output*/
	--SELECT @GiftCoumt=COUNT(*) FROM ZQTreasureDB.dbo.UserNewGift
		--WHERE UserID=@UserID AND Type=4 AND CONVERT(VARCHAR(10),CreateDate,120)=CONVERT(VARCHAR(10),GetDate(),120)

	-- 登录日志
	IF(@IsAndroid=0)
	BEGIN
		-- 记录日志
		DECLARE @DateID INT
		SET @DateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)
		UPDATE SystemStreamInfo SET GameLogonSuccess=GameLogonSuccess+1 WHERE DateID=@DateID
		IF @@ROWCOUNT=0 INSERT SystemStreamInfo (DateID, GameLogonSuccess) VALUES (@DateID, 1)
		-- 登录日志
		INSERT INTO LoggingLog(UserID,LoggingMode,ClientIP) VALUES (@UserID,0,@strClientIP)
	END

    --碎片升的用的版本号
    SET @HashID=NULL
    select TOP 1 @HashID=HashID  from ZQServerInfoDB.dbo.HallVersion order by ID DESC 

	-- 输出变量
	SELECT @UserID AS UserID, @GameID AS GameID, @Accounts AS Accounts, @UnderWrite AS UnderWrite, @FaceID AS FaceID, 
		@Gender AS Gender, @Experience AS Experience, @MemberOrder AS MemberOrder, @MemberOverDate AS MemberOverDate,
		@ErrorDescribe AS ErrorDescribe, @Loveliness AS Loveliness,@CustomFaceVer AS CustomFaceVer,@ServerID AS ServerID,
		@NickName AS NickName,@Money AS lMoney,@Gold AS lGold, @Gem AS lGem,@Grade AS dwGrade,
		@WinCount AS WinCount,@LostCount AS LostCount,@DrawCount AS DrawCount,@FleeCount AS FleeCount,@IsAndroid AS IsAndroid,
		@SsoMD5 AS SsoMD5,@GiftCoumt AS GiftCoumt, @HashID as HashID, @MasterRight AS MasterRight, @MasterOrder AS MasterOrder

	
    
END

RETURN 0




