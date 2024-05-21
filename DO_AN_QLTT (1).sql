CREATE DATABASE DO_AN_QLTT
use DO_AN_QLTT


CREATE TABLE PLAYER (
    playerID INT PRIMARY KEY,
    playerName NVARCHAR(100),
    playerBirthDate DATETIME,
    playerHomeTown NVARCHAR(100)
);

CREATE TABLE PLAYER_TEAM_ESPORT (
    playerID INT,
    teamID INT,
    NickName NVARCHAR(100),
    Lane NVARCHAR(50),
    DateStart DATETIME,
    DateEnd DATETIME,
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    PRIMARY KEY (playerID, teamID)
);

CREATE TABLE COACH (
    coachID INT PRIMARY KEY,
    coachName NVARCHAR(100),
    coachBirthDate DATETIME,
    coachHomeTown NVARCHAR(100)
);

CREATE TABLE COACH_TEAM_ESPORT (
    coachID INT,
    teamID INT,
    NickName NVARCHAR(100),
    DateStart DATETIME,
    DateEnd DATETIME,
    FOREIGN KEY (coachID) REFERENCES COACH(coachID),
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    PRIMARY KEY (coachID, teamID)
);

CREATE TABLE TEAM_ESPORT (
    teamID INT PRIMARY KEY,
    teamName NVARCHAR(100),
    teamYearEstablished INT,
    teamOwner NVARCHAR(100),
    teamLogo NVARCHAR(255)
);

CREATE TABLE MATCH (
    matchID INT PRIMARY KEY,
    teamoneID INT,
    teamtwoID INT,
    teamoneScore INT,
    teamtwoScore INT,
    matchDate DATETIME,
    stadiumID INT,
    seasonID INT,
    matchtypeID INT,
    FOREIGN KEY (teamoneID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (teamtwoID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (stadiumID) REFERENCES STADIUM(stadiumID),
    FOREIGN KEY (seasonID) REFERENCES SEASON(seasonID),
    FOREIGN KEY (matchtypeID) REFERENCES MATCHTYPE(matchtypeID)
);

CREATE TABLE STADIUM (
    stadiumID INT PRIMARY KEY,
    stadiumName NVARCHAR(100),
    stadiumAddress NVARCHAR(255),
    stadiumCapacity INT
);

CREATE TABLE SEASON (
    seasonID INT PRIMARY KEY,
    seasonName NVARCHAR(100),
    seasonSponsor NVARCHAR(100),
    seasonDateStart DATETIME
);

CREATE TABLE MATCHTYPE (
    matchtypeID INT PRIMARY KEY,
    matchtypeName NVARCHAR(100),
    matchtypeQuantity INT
);

CREATE TABLE PLAYER_MATCH (
    playerID INT,
    matchID INT,
    Champion NVARCHAR(100),
    NUMKill INT,
    Die INT,
    Support INT,
    FOREIGN KEY (playerID) REFERENCES PLAYER(playerID),
    FOREIGN KEY (matchID) REFERENCES MATCH(matchID),
    PRIMARY KEY (playerID, matchID)
);

CREATE TABLE TEAM_ESPORT_SEASON (
    teamID INT,
    seasonID INT,
    teamTotalScore INT,
    FOREIGN KEY (teamID) REFERENCES TEAM_ESPORT(teamID),
    FOREIGN KEY (seasonID) REFERENCES SEASON(seasonID),
    PRIMARY KEY (teamID, seasonID)
);

GO
/*ngay bat dau mua giai<= matchDatePlayed a*/
CREATE TRIGGER CHECK_START_SEASON ON SEASON
FOR INSERT
AS	
BEGIN
	-- kiểm tra xem ngày bắt đầu mùa giải có lớn hơn ngày thi đấu hay không
	IF (SELECT COUNT(*) FROM INSERTED I, MATCH M
		WHERE I.seasonDateStart > M.matchDate AND I.seasonID = M.seasonID) > 0
	BEGIN
		PRINT N'NGÀY BẮT ĐẦU MÙA GIẢI PHẢI BÉ HƠN NGÀY THI ĐẤU' 
		ROLLBACK TRAN
	END
END
GO
/*ngay bat dau mua giai <=  matchDatePlayed a*/
CREATE TRIGGER CHECK_START_MATCH ON MATCH
FOR INSERT
AS	

BEGIN
	-- kiểm tra ngày bắt đầu mùa giải lớn hơn ngày thi đấu hay không
	IF (SELECT COUNT(*) FROM INSERTED I, SEASON S
		WHERE S.seasonDateStart > I.matchDate AND I.seasonID = S.seasonID) > 0
	BEGIN
		PRINT N' NGÀY THI ĐẤU >= NGÀY BẮT ĐẦU MÙA GIẢI' 
		ROLLBACK TRAN
	END
END

GO
/* khi xóa thông tin đội tuyển thì xóa hết thông tin liên quan đến đội tuyển đó*/

CREATE TRIGGER DELETE_TEAM ON TEAM_ESPORT 
INSTEAD OF DELETE
AS
BEGIN
	DECLARE @ID_TEAM INT
	SELECT @ID_TEAM = TEAMID FROM DELETED
	-- xóa thông tin của team ở bảng PLAYER_TEAM_ESPORT
	DELETE FROM PLAYER_TEAM_ESPORT WHERE TEAMID = @ID_TEAM
	-- xóa thông tin của team ở bảng COACH_TEAM_ESPORTT
	DELETE FROM COACH_TEAM_ESPORT WHERE TEAMID = @ID_TEAM
	-- xóa thông tin của team ở bảng TEAM_ESPORT_SEASON
	DELETE FROM TEAM_ESPORT_SEASON WHERE TEAMID = @ID_TEAM
	-- xóa thông tin của team ở bảng TEAM_ESPORT
	DELETE FROM TEAM_ESPORT WHERE TEAMID = @ID_TEAM
END

GO
/* khi xóa thông tin tuyển thủ thì xóa hết thông tin liên quan đến tuyển thủ đó*/

CREATE TRIGGER DELETE_PLAYER ON PLAYER
INSTEAD OF DELETE
AS
BEGIN
    -- Khai báo biến @DELETE_ID_PLAYER để lưu trữ PLAYERID của bản ghi sẽ bị xóa
    DECLARE @DELETE_ID_PLAYER INT
    -- Lấy PLAYERID của bản ghi sẽ bị xóa từ bảng DELETED và gán vào biến @DELETE_ID_PLAYER
    SELECT @DELETE_ID_PLAYER = PLAYERID FROM DELETED
    
    -- Xóa thông tin của player trong bảng PLAYER_TEAM_ESPORT 
    -- dựa trên PLAYERID được lưu trong biến @DELETE_ID_PLAYER
    DELETE FROM PLAYER_TEAM_ESPORT WHERE PLAYERID = @DELETE_ID_PLAYER
    
    -- Xóa thông tin của player trong bảng PLAYER_MATCH 
    -- dựa trên PLAYERID được lưu trong biến @DELETE_ID_PLAYER
    DELETE FROM PLAYER_MATCH WHERE PLAYERID = @DELETE_ID_PLAYER
    
    -- Xóa thông tin của player trong bảng PLAYER 
    -- dựa trên PLAYERID được lưu trong biến @DELETE_ID_PLAYER
    DELETE FROM PLAYER WHERE PLAYERID = @DELETE_ID_PLAYER
END

GO
/* khi xóa thông tin COACH thì xóa hết thông tin liên quan đến COACH đó*/
CREATE TRIGGER DELETE_COACH ON COACH
INSTEAD OF DELETE
AS
BEGIN
    -- Khai báo biến @DELETE_ID_COACH để lưu trữ COACHID của bản ghi sẽ bị xóa
    DECLARE @DELETE_ID_COACH INT
    -- Lấy COACHID của bản ghi sẽ bị xóa từ bảng DELETED và gán vào biến @DELETE_ID_COACH
    SELECT @DELETE_ID_COACH = COACHID FROM DELETED
    
    -- Xóa thông tin của coach trong bảng COACH_TEAM_ESPORT 
    -- dựa trên COACHID được lưu trong biến @DELETE_ID_COACH
    DELETE FROM COACH_TEAM_ESPORT WHERE COACHID = @DELETE_ID_COACH
    
    -- Xóa thông tin của coach trong bảng COACH 
    -- dựa trên COACHID được lưu trong biến @DELETE_ID_COACH
    DELETE FROM COACH WHERE COACHID = @DELETE_ID_COACH
END

GO
/*+ update điểm thắng  thì cộng 1 . delete thì -1*/
CREATE TRIGGER UPDATE_DIEM ON MATCH
FOR UPDATE,INSERT
AS
BEGIN
	IF EXISTS (SELECT * FROM INSERTED I ,TEAM_ESPORT_SEASON T WHERE I.TEAMONESCORE = '2' AND I.teamoneID = T.TEAMID)
	BEGIN
		UPDATE TEAM_ESPORT_SEASON
		SET TEAMTOTALSCORE = TEAMTOTALSCORE + 1 
	END

END

GO
/*+ NGÀY THÀNH LẬP TEAM PHẢI NHỎ HƠN NGÀY TUYỂN THỦ GIA NHẬP*/
CREATE TRIGGER CHECK_NGTL ON TEAM_ESPORT
FOR INSERT
AS
BEGIN
 -- Kiểm tra nếu tồn tại một cầu thủ có ngày bắt đầu trước năm thành lập của đội
	IF EXISTS (SELECT * FROM PLAYER_TEAM_ESPORT PTE, TEAM_ESPORT T
				WHERE PTE.TEAMID = T.TEAMID AND PTE.DateStart < T.teamYearEstablished)
	BEGIN
		PRINT 'NGÀY THÀNH LẬP TEAM PHẢI NHỎ HƠN NGÀY TUYỂN THỦ GIA NHẬP TEAM NÀY'
		ROLLBACK TRAN
	END
	ELSE
	BEGIN
		PRINT N'THÊM THÀNH CÔNG'
	END
END

go
/* store procedure*/
/*Đưa vào TÊN CẦU THỦ cầu thủ xuất ra toàn bộ thông tin cầu thủ đó*/
CREATE PROC PRINT_TT_PLAYER @playerName NVARCHAR(100)
AS 
BEGIN 
 -- Kiểm tra xem tên tuyển thủ (@playerName) có tồn tại trong bảng PLAYER hay không
	IF EXISTS ( SELECT * FROM PLAYER WHERE PLAYERNAME = @PLAYERNAME)
	BEGIN
	-- Nếu tồn tại, in ra thông tin của tuyển thủ
		SELECT P.playerName AS 'TÊN TUYỂN THỦ',P.playerBirthDate AS 'NGÀY SINH',P.playerHomeTown AS 'QUÊ QUÁN', PTE.NickName AS 'BIỆT DANH',
		PTE.Lane,TE.teamName AS 'ĐỘI TUYỂN HIỆN TẠI'
		from PLAYER P, PLAYER_TEAM_ESPORT PTE, TEAM_ESPORT TE
		WHERE P.PLAYERNAME = @PLAYERNAME AND P.PLAYERID = PTE.PLAYERID AND PTE.TEAMID = TE.TEAMID	
	END
	ELSE 
	BEGIN	
		PRINT N'KHÔNG TÌM THẤY THÔNG TIN TUYỂN THỦ ĐÓ'
		RETURN 0
	END
END

/*In ra thứ hạng của đội có số điểm nằm trong top 10(BXH) TRONG CAC MUA GIAI */
go
CREATE PROC BXH_SEASON @season_name NVARCHAR(100)
AS
BEGIN
-- Kiểm tra xem tên mùa giải (@season_name) có tồn tại trong bảng SEASON hay không
	IF EXISTS (SELECT * FROM SEASON WHERE seasonName = @season_name)
	BEGIN
	 -- Nếu tồn tại, lấy thông tin xếp hạng của các đội trong mùa giải đó
		SELECT ROW_NUMBER() OVER (ORDER BY TES.TEAMTOTALSCORE DESC) AS 'RANKING',
			   T.TEAMNAME ,
			   TES.TEAMTOTALSCORE 
		FROM TEAM_ESPORT_SEASON tes, TEAM_ESPORT t, SEASON S
		WHERE tes.teamID = t.teamID AND TES.SEASONID = S.SEASONID AND S.season_name = @seasonName
		GROUP BY T.TEAMNAME ,TES.TEAMTOTALSCORE,S.SEASONNAME
		ORDER BY TES.TEAMTOTALSCORE DESC
	END

END

go
/*đưa vào tên mùa giải và xuất ra lịch thi đấu*/
CREATE PROCEDURE SP_LICH_THI_DAU (@seasonName NVARCHAR(100))
AS
BEGIN
    -- Kiểm tra xem mùa giải có tồn tại hay không
    IF EXISTS (SELECT * FROM SEASON WHERE seasonName = @seasonName)
    BEGIN
        -- Xuất ra lịch thi đấu
        SELECT 
            M.matchDate AS 'NGÀY THI ĐẤU',
            T1.teamName AS 'ĐỘI 1',
            M.teamoneScore AS 'ĐIỂM ĐỘI 1',
            T2.teamName AS 'ĐỘI 2',
            M.teamtwoScore AS 'ĐIỂM ĐỘI 2',
            ST.stadiumName AS 'SÂN VẬN ĐỘNG'
        FROM 
            MATCH M
        INNER JOIN 
            TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
        INNER JOIN 
            TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
        INNER JOIN 
            SEASON S ON M.seasonID = S.seasonID
        INNER JOIN 
            STADIUM ST ON M.stadiumID = ST.stadiumID
        WHERE 
            S.seasonName = @seasonName
        ORDER BY 
            M.matchDate;
    END
    ELSE
    BEGIN
        -- Nếu mùa giải không tồn tại, in ra thông báo lỗi
        PRINT N'Mùa giải không tồn tại.'
    END
END


--Tìm một trận đấu trong lịch thi đấu
--Đưa vào lịch trận đấu, xuất ra Team1 (kq--kq) Team2
CREATE PROC matchFound @DATE smalldatetime, @teamone int out, @teamtwo int out, @res varchar(3) out
AS
BEGIN
	IF Exists (Select * from matches where @date = matchDate)
		(IF (teamoneScore or teamtwoScore is not NULL)
			select @teamone = T1.teamName, @teamtwo = T2.teamName, @res = concat(teamoneScore,':',teamtwoScore)
			from matches M
			INNER JOIN 
            TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
			INNER JOIN 
            TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
			where @date = M.matchDate
		 else
			select @teamone = T1.teamName, @teamtwo = T2.teamName, @res = concat(-,':',-)
			from matches M
			INNER JOIN 
            TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
			INNER JOIN 
            TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
			where @date = matchDate )
	Else
		begin 
			select 'Khong tim thay lich thi dau'
			return 0
		end
END

declare @id11 int, @id22 int, @result varchar(3)
exec LICHTHIDAU @date = '1/1/2021', @idss ='1', @id1 = @id11 out, @id2 = @id22 out, @res = @result out
print @id11
print @id22
print @result


--Tính KDA của tuyển thủ
CREATE PROC KDA @idMatch INT, @idPlayer INT, @RES FLOAT OUT
AS
BEGIN
	IF EXISTS (SELECT * FROM PLAYER_MATCH WHERE @idPlayer = PLAYERID AND @idMatch = MATCHID
		(UPDATE PLAYER_MATCH
		SET @RES = (NUMKILL + SUPPORT)/DIE
		WHERE @idPlayer = PLAYERID AND @idMatch = MATCHID)
	ELSE
		BEGIN
			PRINT 'KHONG TIM THAY TUYEN THU'
			RETURN 0
		END
END

DECLARE @RESULT FLOAT
EXEC TINHKDA '1', '2', @RES = @RESULT OUT
PRINT @RESULT
--IN THONG TIN HIEUSO CUA CAC DOI TUYEN
CREATE PROC HIEUSO @IDSS INT, @IDT INT, @DIFFER NVARCHAR(10) OUT
AS
BEGIN
	IF EXISTS (SELECT * FROM SEASON S, TEAM_ESPORT_SEASON TES WHERE S.SEASONID = @IDSS AND @IDT = TEAMID AND S.SEASONID = TES.SEASONID )
	BEGIN
		BEGIN
			SELECT WIN = (SUM(TEAMONESCORE) + SUM(TEAMTWOSCORE))
			FROM MATCHES M WHERE (TEAMID = M.TEAMONEID OR TEAMID = M.TEAMTWOID)
			AND TEAMID = @IDT AND (TEAMONESCORE = 2 OR TEAMTWOSCORE = 2)
		END
		BEGIN
			SELECT LOSE = (SUM(TEAMONESCORE) + SUM(TEAMTWOSCORE))
			FROM MATCHES M WHERE (TEAMID = M.TEAMONEID OR TEAMID = M.TEAMTWOID)
			AND TEAMID = @IDT AND (TEAMONESCORE = 1 OR TEAMTWOSCORE = 1)
		END
		BEGIN
			UPDATE MATCHES
			SET @DIFFER = CONCAT(WIN,'-',LOSE)
			WHERE TEAMID = @IDT
		END
	END
	ELSE
		BEGIN
			PRINT 'KHONG TIM THAY'
			RETURN 0
		END
END
GO
/* FUNCTION */

/*+ đưa vào tên đội viết hàm in ra danh sách thông tin liên quan đến team đó*/
GO

CREATE FUNCTION FC_IN_THONG_TIN_DOI (@teamName NVARCHAR(100))
RETURNS TABLE
AS
	RETURN (SELECT P.PLAYERNAME, T.TEAMNAME, T.teamYearEstablished,T.teamOwner,T.teamLogo
			FROM PLAYER P, PLAYER_TEAM_ESPORT PTE, TEAM_ESPORT T
			WHERE P.PLAYERID = PTE.PLAYERID AND PTE.TEAMID = T.TEAMID AND T.teamName = @teamName)

/* ĐƯA VÀO TÊN TUYỂN THỦ VÀ TÊN MÙA GIẢI IN RA SỐ LƯỢNG TƯỚNG MÀ NGƯỜI ĐÓ ĐÃ CHƠI */

CREATE FUNCTION FC_SL_TUONG (@PLAYERNAME NVARCHAR(100), @NAME_SEASON NVARCHAR(100))
RETURNS INT
AS
BEGIN
 -- Kiểm tra xem cầu thủ có tồn tại trong mùa giải cụ thể hay không
	IF EXISTS ( SELECT * 
				FROM SEASON S,PLAYER P, PLAYER_TEAM_ESPORT PTE, TEAM_ESPORT_SEASON TES
				WHERE playerName = @PLAYERNAME AND S.seasonName = @NAME_SEASON AND P.playerID = PTE.playerID AND 
				PTE.teamID = TES.teamID AND S.seasonID = TES.seasonID)
		BEGIN
		 -- Trả về số lượng tướng (Champion) đã sử dụng bởi cầu thủ trong mùa giải đó
		RETURN (SELECT COUNT(DISTINCT Champion) 
				FROM PLAYER_MATCH PM, SEASON S,PLAYER P, PLAYER_TEAM_ESPORT PTE, TEAM_ESPORT_SEASON TES
				WHERE playerName = @PLAYERNAME AND S.seasonName = @NAME_SEASON AND P.playerID = PTE.playerID AND 
				PTE.teamID = TES.teamID AND S.seasonID = TES.seasonID AND PM.playerID = P.playerID)
		END
		 -- Nếu cầu thủ không tồn tại trong mùa giải, trả về -1
	RETURN -1
END




--VIEW
--THONG TIN DOI TUYEN

CREATE OR REPLACE VIEW THONGTINTEAMSPORT
AS
	SELECT teamID, teamName, teamYearEstablished, teamOwner, teamLogo
    FROM TEAM_ESPORT
GO
--THONG TIN TUYEN THU	
CREATE OR REPLACE VIEW THONGTINPLAYER
AS 
BEGIN 
	SELECT P.playerName AS 'TÊN TUYỂN THỦ',P.playerBirthDate AS 'NGÀY SINH',P.playerHomeTown AS 'QUÊ QUÁN', PTE.NickName AS 'BIỆT DANH',
	PTE.Lane AS 'VỊ TRÍ',TE.teamName AS 'ĐỘI TUYỂN HIỆN TẠI', PTE.dateEND AS 'HẠN HỢP ĐỒNG'
	from PLAYER P, PLAYER_TEAM_ESPORT PTE, TEAM_ESPORT TE
	WHERE P.PLAYERID = PTE.PLAYERID AND PTE.TEAMID = TE.TEAMID	
END
GO

--BANG XEP HANG
CREATE OR REPLACE VIEW BXH_SEASON 
AS
BEGIN
	SELECT ROW_NUMBER() OVER (ORDER BY TES.TEAMTOTALSCORE DESC) AS 'RANKING',
	T.TEAMNAME ,TES.TEAMTOTALSCORE 
	FROM TEAM_ESPORT_SEASON tes, TEAM_ESPORT t, SEASON S
	WHERE tes.teamID = t.teamID AND TES.SEASONID = S.SEASONID
	GROUP BY T.TEAMNAME ,TES.TEAMTOTALSCORE,S.SEASONNAME
	ORDER BY TES.TEAMTOTALSCORE DESC
END
GO

--LICHTHIDAU

CREATE OR REPLACE VIEW vLICHTHIDAU
AS
BEGIN
	SELECT 
	M.matchDate AS 'NGÀY THI ĐẤU',
	T1.teamName AS 'ĐỘI 1',
	M.teamoneScore AS 'ĐIỂM ĐỘI 1',
	T2.teamName AS 'ĐỘI 2',
	M.teamtwoScore AS 'ĐIỂM ĐỘI 2',
	ST.stadiumName AS 'SÂN VẬN ĐỘNG'
	FROM 
            MATCH M
        INNER JOIN 
            TEAM_ESPORT T1 ON M.teamoneID = T1.teamID
        INNER JOIN 
            TEAM_ESPORT T2 ON M.teamtwoID = T2.teamID
        INNER JOIN 
            SEASON S ON M.seasonID = S.seasonID
        INNER JOIN 
            STADIUM ST ON M.stadiumID = ST.stadiumID
        ORDER BY 
            M.matchDate;
END

--THONG TINH NGUOI DUNG

CREATE OR REPLACE VIEW USERS 
AS
	SELECT  FAVOR, USERBIRTH, EMAIL, USERNAME, COIN
	FROM USERS
GO

--LICH SU CA CUOC

CREATE OR REPLACE VIEW BET88
AS
	SELECT ID_BET, ID_CUS, ID_MATCH, T1_PREDICT, T2_PREDICT, COIN_NUM, DAY_BET 
	FROM BET, CUSTOMER
	WHERE BET.ID_CUS = CUSTOMER.ID_CUS
GO

