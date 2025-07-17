DECLARE @Environment CHAR(3), @ResponseStructureToken NVARCHAR(MAX), @Destination NVARCHAR(50), @EnvAuthBaseUrl NVARCHAR(MAX), @EnvAuthClientId NVARCHAR(MAX), @KeyvaultEntry NVARCHAR(MAX), @KeyvaultTokenEntry NVARCHAR(MAX), @MapName NVARCHAR(MAX)
SET @Environment = (SELECT  
						CASE DB_NAME()
                            WHEN 'kai-dev-sql-db' THEN 'dev'
							WHEN 'kai-acc-sql-db' THEN 'acc'
							WHEN 'kai-prd-sql-db' THEN 'prd'
							ELSE 'unk'
						END);

SET @ResponseStructureToken= '{"token":"return getNewTokenResponse?.outputs?.body?.access_token ?? ''''","tokenExpiry":"return getNewTokenResponse?.outputs?.body?.expires_in ?? ''''"}'
SET @Destination = 'GENESYS'
SET @KeyvaultEntry = 'ws-genesys'
SET @KeyvaultTokenEntry = 'ws-genesys-token'
SET @MapName = 'kpnsngr-token-2-genesys-json-mp.liquid'
SET @EnvAuthBaseUrl = 'https://login.mypurecloud.de/oauth/token'
SET @EnvAuthClientId = '8f29c020-a394-4f98-b434-0f50ef9c55d4'


IF @Environment='prd'
BEGIN
    SET @EnvAuthClientId = '0d28016b-e313-4014-8881-597e148a8e48'
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