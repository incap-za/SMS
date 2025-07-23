-- =====================================================================
-- SMS API Migration: Configure KPN SMS Token instead of Vonage/Nexmo
-- For workflow sms-post-kpnsms-wf in Logic App dev-api-ticket-la
-- =====================================================================
DECLARE @Environment CHAR(3), @ResponseStructureToken NVARCHAR(MAX), @Destination NVARCHAR(50), 
        @EnvAuthBaseUrl NVARCHAR(MAX), @EnvAuthClientId NVARCHAR(MAX), @KeyvaultEntry NVARCHAR(MAX), 
        @KeyvaultTokenEntry NVARCHAR(MAX), @MapName NVARCHAR(MAX)

SET @Environment = (SELECT  
    CASE DB_NAME()
        WHEN 'kai-dev-sql-db' THEN 'dev'
        WHEN 'kai-acc-sql-db' THEN 'acc'
        WHEN 'kai-prd-sql-db' THEN 'prd'
        ELSE 'unk'
    END);

-- Token response structure following the same pattern as Genesys
SET @ResponseStructureToken = '{"token":"return getNewTokenResponse?.outputs?.body?.access_token ?? ''''","tokenExpiry":"return getNewTokenResponse?.outputs?.body?.expires_in ?? ''''"}'
SET @Destination = 'KPN_SMS'
SET @KeyvaultEntry = 'kpn-sms-client-secret'
SET @KeyvaultTokenEntry = 'ws-kpn-sms-token'
SET @MapName = 'kpn-sms-token-json-mp.liquid'

-- KPN SMS OAuth endpoint
SET @EnvAuthBaseUrl = 'https://api-prd.kpn.com/oauth/client_credential/accesstoken'

-- Environment-specific client IDs for KPN SMS API
SET @EnvAuthClientId = CASE @Environment
    WHEN 'dev' THEN 'YOUR-DEV-KPN-SMS-CLIENT-ID'  -- Replace with actual client ID
    WHEN 'acc' THEN 'YOUR-ACC-KPN-SMS-CLIENT-ID'  -- Replace with actual client ID
    WHEN 'prd' THEN 'YOUR-PRD-KPN-SMS-CLIENT-ID'  -- Replace with actual client ID
    ELSE 'unknown'
END

IF NOT EXISTS (SELECT 1 FROM [kai].[RoutingTokenConfig] WITH (NOLOCK) WHERE Destination = @Destination)
BEGIN
    INSERT INTO [kai].[RoutingTokenConfig]
        ([Destination],[BaseUrl],[UserName],[KeyvaultEntry],[KeyvaultTokenEntry],[KeyvaultSpecEntry],[MapName],[ResponseStructure],[Active])
    VALUES
        (@Destination,@EnvAuthBaseUrl,@EnvAuthClientId,@KeyvaultEntry,@KeyvaultTokenEntry,NULL,@MapName,@ResponseStructureToken,1)
    
    PRINT 'KPN SMS token configuration inserted successfully.'
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
    
    PRINT 'KPN SMS token configuration updated successfully.'
END

-- Note: Old Vonage/Nexmo configuration remains active for now
-- Will be deactivated after successful testing and production deployment
PRINT 'KPN SMS configuration complete. Vonage/Nexmo remains active for parallel running.'
