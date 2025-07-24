DECLARE @Environment CHAR(3), @ResponseStructureToken NVARCHAR(MAX), @Destination NVARCHAR(50), @EnvAuthBaseUrl NVARCHAR(MAX), @EnvAuthClientId NVARCHAR(MAX), @KeyvaultEntry NVARCHAR(MAX), @KeyvaultTokenEntry NVARCHAR(MAX), @MapName NVARCHAR(MAX)
SET @Environment = (SELECT  
						CASE DB_NAME()
                            WHEN 'kai-dev-sql-db' THEN 'dev'
							WHEN 'kai-acc-sql-db' THEN 'acc'
							WHEN 'kai-prd-sql-db' THEN 'prd'
							ELSE 'unk'
						END);

SET @ResponseStructureToken= '{"token":"return getNewTokenResponse?.outputs?.body?.access_token ?? ''''","tokenExpiry":"return Number(getNewTokenResponse?.outputs?.body?.expires_in ?? 0)"}'
SET @Destination = 'KPN_SMS'
SET @KeyvaultEntry = 'ws-kpn-sms'
SET @KeyvaultTokenEntry = 'ws-kpn-sms-token'
SET @MapName = 'kpn-sms-token-json-mp.liquid'

IF @Environment='dev'
BEGIN
    SET @EnvAuthBaseUrl = 'https://api-prd.kpn.com/oauth/client_credential/accesstoken'
    SET @EnvAuthClientId = '0oactc6kmiNTLV61P1d7'
END

IF @Environment='acc'
BEGIN
    SET @EnvAuthBaseUrl = 'https://api-prd.kpn.com/oauth/client_credential/accesstoken'
    SET @EnvAuthClientId = '0oactc6kmiNTLV61P1d7'
END

IF @Environment='prd'
BEGIN
    SET @EnvAuthBaseUrl = 'https://api-prd.kpn.com/oauth/client_credential/accesstoken'
    SET @EnvAuthClientId = ''
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
    [ResponseStructure] = @ResponseStructureToken
 WHERE Destination = @Destination
END