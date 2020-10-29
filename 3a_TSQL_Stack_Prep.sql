--Demo 
--and example based on Jonathan Kehayias's Pluralsight course
--https://www.sqlskills.com/blogs/jonathan/category/extended-events/

USE master;
GO
IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = 'XE_tsql_stack_demo2')
	BEGIN
		DROP DATABASE [XE_tsql_stack_demo2]
	END
CREATE DATABASE XE_tsql_stack_demo2
GO
IF EXISTS (SELECT 1 FROM sys.server_event_sessions WHERE name = 'TSQL_Stack_XE')
	BEGIN
		DROP EVENT SESSION TSQL_Stack_XE ON server
	END

GO
USE XE_tsql_stack_demo2;
GO
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Important_Table')
BEGIN
	CREATE TABLE [dbo].[Important_Table](
		[Num_of_updates] [int] NOT NULL,
		[ColumnThatWillBeUpdated] [int]  NOT NULL,
		[ModifiedBY] VARCHAR(100) NOT NULL

	) ON [PRIMARY]
END
GO
INSERT [dbo].[Important_Table] ([Num_of_updates], [ColumnThatWillBeUpdated],[ModifiedBY]) VALUES (1, 20,'DBA')
GO		
IF EXISTS(SELECT 1 FROM sys.triggers WHERE name = 'tracing_table_update')
BEGIN
	DROP TRIGGER dbo.tracing_table_update 
END
GO
CREATE TRIGGER [dbo].[tracing_table_update]
ON [dbo].[Important_Table]
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON
END
	
 
GO
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'TestTable')
BEGIN
	CREATE TABLE [dbo].[TestTable](
		[Testtable_id] [int] IDENTITY(1,1) NOT NULL,
		[TestTable_name] [nchar](10) NOT NULL,
		[InsertedBy] VARCHAR(128) NOT NULL
	 CONSTRAINT [PK_TestTable_Testtable_id] PRIMARY KEY CLUSTERED 
	(
		[Testtable_id] ASC
	)
	)
END
GO

CREATE TRIGGER [dbo].[TriggersBeTriggering] 
   ON  [dbo].[TestTable] 
   AFTER INSERT
AS 
BEGIN
    SET NOCOUNT ON;

UPDATE [dbo].[Important_Table]
   SET [Num_of_updates] = [Num_of_updates]+1
   ,ModifiedBY = CURRENT_USER

END
GO

CREATE PROCEDURE [dbo].[Shouldnt_Happen]
AS
BEGIN
INSERT INTO [dbo].[TestTable]
           (
           [TestTable_name],[InsertedBy])
     VALUES
           ('Customers',CURRENT_USER)
END

GO

CREATE PROCEDURE [dbo].[Why_Are_we_here]
AS
BEGIN

EXEC dbo.[Shouldnt_Happen] -- comments again
END
GO

CREATE PROCEDURE [dbo].[Something_Good]
AS
BEGIN
EXEC dbo.[Why_Are_we_here]--more comments
END
GO

CREATE PROCEDURE [dbo].[Important_Proc]
AS
BEGIN
--Adding additional code here. 
SET NOCOUNT ON
EXEC dbo.[Something_Good] -- with some comments

END

GO
--SELECT * FROM dbo.[Important_Table]
--SELECT * FROM dbo.[TestTable]
--Working on building what we want Traced
GO

--To begin start running what is above to build what is needed. 
--Using default values for Create Database. Modify if needed


