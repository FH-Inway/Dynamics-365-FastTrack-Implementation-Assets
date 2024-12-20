/**
 * SAMPLE CODE NOTICE
 * 
 * THIS SAMPLE CODE IS MADE AVAILABLE AS IS.  MICROSOFT MAKES NO WARRANTIES, WHETHER EXPRESS OR IMPLIED,
 * OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY OR COMPLETENESS OF RESPONSES, OF RESULTS, OR CONDITIONS OF MERCHANTABILITY.
 * THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS SAMPLE CODE REMAINS WITH THE USER.
 * NO TECHNICAL SUPPORT IS PROVIDED.  YOU MAY NOT DISTRIBUTE THIS CODE UNLESS YOU HAVE A LICENSE AGREEMENT WITH MICROSOFT THAT ALLOWS YOU TO DO SO.
 */

 -- Create the extension table to store the custom fields.

IF (SELECT OBJECT_ID('[ext].[COMMERCEEVENTSTABLE]')) IS NULL 
BEGIN
    CREATE TABLE
        [ext].[COMMERCEEVENTSTABLE]
    (
        [EVENTTRANSACTIONID]  [nvarchar](44) NOT NULL,
        [EVENTDATETIME]     [datetime] NOT NULL,
        [EVENTTYPE]         [nvarchar](20) NOT NULL,
        [EVENTCUSTOMERID]   [nvarchar](38) NOT NULL DEFAULT (('')),
        [EVENTSTAFFID]      [nvarchar](25) NOT NULL DEFAULT (('')),
        [EVENTCHANNELID]    [bigint] NOT NULL,
        [EVENTTERMINALID]   [nvarchar](10) NOT NULL DEFAULT (('')),
        [EVENTDATA]         [nvarchar](64) NOT NULL DEFAULT (('')),
        [REPLICATIONCOUNTERFROMORIGIN] [int] IDENTITY(1,1) NOT NULL,
        [ROWVERSION] [timestamp] NOT NULL,
        [DATAAREAID] [nvarchar](4) NOT NULL,
        CONSTRAINT [I_COMMERCEEVENTSTABLE_EVENTTRANSACTIONID] PRIMARY KEY CLUSTERED 
        (
            [EVENTTRANSACTIONID] ASC,
            [EVENTTYPE] ASC,
            [EVENTDATETIME] ASC,
            [DATAAREAID] ASC
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY]

END
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::[ext].[COMMERCEEVENTSTABLE] TO [UsersRole]
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::[ext].[COMMERCEEVENTSTABLE] TO [DeployExtensibilityRole]
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::[ext].[COMMERCEEVENTSTABLE] TO [DataSyncUsersRole]
GO

-- Create a stored procedure CRT can use to add entries to the custom table.

IF OBJECT_ID(N'[ext].[INSERTCOMMERCEEVENT]', N'P') IS NOT NULL
    DROP PROCEDURE [ext].[INSERTCOMMERCEEVENT]
GO

CREATE PROCEDURE [ext].[INSERTCOMMERCEEVENT]
    @s_EventTransactionId   NVARCHAR(44),
    @d_EventDateTime        datetime,
    @s_EventType            NVARCHAR(20),
    @s_EventCustomerId      NVARCHAR(38),
    @s_EventStaffId         NVARCHAR(25),
    @b_EventChannelId       bigint,
    @s_EventTerminalId      NVARCHAR(10),
    @s_EventData            NVARCHAR(64),
    @s_DataAreaId           [nvarchar](4)
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO
         ext.COMMERCEEVENTSTABLE
        (EVENTTRANSACTIONID, EVENTDATETIME,EVENTTYPE,EVENTCUSTOMERID,EVENTSTAFFID,EVENTCHANNELID,EVENTTERMINALID,EVENTDATA,DATAAREAID)
    OUTPUT
        INSERTED.EVENTTRANSACTIONID,INSERTED.EVENTDATETIME,INSERTED.EVENTTYPE,INSERTED.DATAAREAID
    VALUES
        (@s_EventTransactionId, @d_EventDateTime,@s_EventType,@s_EventCustomerId,@s_EventStaffId,@b_EventChannelId,@s_EventTerminalId,@s_EventData,@s_DataAreaId)
END;
GO

GRANT EXECUTE ON [ext].[INSERTCOMMERCEEVENT] TO [UsersRole];
GO

GRANT EXECUTE ON [ext].[INSERTCOMMERCEEVENT] TO [DeployExtensibilityRole];
GO

GRANT EXECUTE ON [ext].[INSERTCOMMERCEEVENT] TO [PublishersRole];
GO

-- Create the custom view that can query a complete Commerce Event Entity.

IF (SELECT OBJECT_ID('[ext].[COMMERCEEVENTSVIEW]')) IS NOT NULL
    DROP VIEW [ext].[COMMERCEEVENTSVIEW]
GO

CREATE VIEW [ext].[COMMERCEEVENTSVIEW] AS
(
    SELECT
        et.EVENTTRANSACTIONID,
        et.EVENTDATETIME,
        et.EVENTTYPE,
        et.EVENTCUSTOMERID,
        et.EVENTSTAFFID,
        et.EVENTCHANNELID,
        et.EVENTTERMINALID,
        et.EVENTDATA,
        et.DATAAREAID as EVENTDATAAREAID
    FROM
        [ext].[COMMERCEEVENTSTABLE] et
)
GO

GRANT SELECT ON OBJECT::[ext].[COMMERCEEVENTSVIEW] TO [UsersRole];
GO

GRANT SELECT ON OBJECT::[ext].[COMMERCEEVENTSVIEW] TO [DeployExtensibilityRole];
GO

