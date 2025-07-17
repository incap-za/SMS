-- Configuration for workflow sms-post-kpnsms-wf in Logic App dev-api-ticket-la
DECLARE @Environment CHAR(3), @ResponseStructureToken NVARCHAR(MAX), @Destination NVARCHAR(50), @EnvAuthBaseUrl NVARCHAR(MAX), @EnvAuthClientId NVARCHAR(MAX), @KeyvaultEntry NVARCHAR(MAX), @KeyvaultTokenEntry NVARCHAR(MAX), @MapName NVARCHAR(MAX)
SET @Environment = (SELECT  
						CASE DB_NAME()
                            WHEN 'kai-dev-sql-db' THEN 'dev'
							WHEN 'kai-acc-sql-db' THEN 'acc'
							WHEN 'kai-prd-sql-db' THEN 'prd'
							ELSE 'unk'
						END);

SET @ResponseStructureToken= '{"token":"return getNewTokenResponse?.outputs?.body?.access_token ?? ''''","tokenExpiry":"return getNewTokenResponse?.outputs?.body?.expires_in ?? ''''"}'
SET @Destination = 'KPN_SMS'
SET @KeyvaultEntry = 'kpn-sms-client-secret'
SET @KeyvaultTokenEntry = 'ws-sms-kpn-token'
SET @MapName = 'kpn-sms-token-json-mp.liquid'
SET @EnvAuthBaseUrl = 'https://api-prd.kpn.com/oauth/client_credential/accesstoken'

-- Client IDs for KPN SMS API
SET @EnvAuthClientId = CASE @Environment
    WHEN 'dev' THEN 'sms-api-dev-client-id'
    WHEN 'acc' THEN 'sms-api-acc-client-id'
    WHEN 'prd' THEN 'sms-api-prd-client-id'
    ELSE 'unknown'
END

IF NOT EXISTS (SELECT 1 FROM [kai].[RoutingTokenConfig] WITH (NOLOCK) WHERE Destination = @Destination)
BEGIN
INSERT INTO [kai].[RoutingTokenConfig]
    ([Destination],[BaseUrl],[UserName],[KeyvaultEntry],[KeyvaultTokenEntry],[KeyvaultSpecEntry],[MapName],[ResponseStructure],[Active])
    VALUES
    (@Destination,@EnvAuthBaseUrl,@EnvAuthClientId,@KeyvaultEntry,@KeyvaultTokenEntry,NULL,@MapName,@ResponseStructureToken,1)
END
ELSE
BEGIN
 UPDATE [kai].[RoutingTokenConfig]
 SET [BaseUrl] = @EnvAuthBaseUrl,
    [UserName] = @EnvAuthClientId,
    [KeyvaultEntry] = @KeyvaultEntry,
    [KeyvaultTokenEntry] = @KeyvaultTokenEntry,
    [KeyvaultSpecEntry] = NULL,
    [MapName] = @MapName,
    [ResponseStructure] = @ResponseStructureToken,
    [Active] = 1
 WHERE Destination = @Destination
END

-- Deactivate old Vonage/Nexmo configuration
UPDATE [kai].[RoutingTokenConfig]
SET [Active] = 0
WHERE Destination IN ('NEXMO', 'VONAGE', 'SMS_NEXMO')