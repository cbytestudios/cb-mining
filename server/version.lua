local resourceName = 'cb-mining'
local currentVersion = GetResourceMetadata(resourceName, 'version', 0)
local versionUrl = 'https://raw.githubusercontent.com/cbytestudios/cb-mining/main/version.txt'

Citizen.CreateThread(function()
    PerformHttpRequest(versionUrl, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local remoteVersion = response:gsub('[\r\n]', '')
            if remoteVersion ~= currentVersion then
                print(string.format('[%s] WARNING: A new version is available! Current: %s, Latest: %s. Please update from GitHub.', resourceName, currentVersion, remoteVersion))
            else
                print(string.format('[%s] You are running the latest version: %s', resourceName, currentVersion))
            end
        else
            print(string.format('[%s] ERROR: Failed to check for updates. HTTP Status: %d', resourceName, statusCode))
        end
    end, 'GET', '', { ['User-Agent'] = 'cb-mining' })
end)