if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Initial delay, potentially for game/UI assets to fully settle

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId -- Capture PlaceId at script start
local actualGameMaxPlayers = Players.MaxPlayers -- Auto-detect game's max players

-- Server Finder Variables
local isSearchingServers = false
local currentFoundJobId = nil
local maxPlayersTarget = 5 -- Default value for max players in a server (for finding "small" servers)
local serverSearchCursor = "" -- For API pagination

-- UI Element References for Server Finder (will be assigned by WindUI)
local serverFinderStatusLabel = nil
local foundServerDisplay = nil
local findServerButtonInstance = nil 

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(350, 430), -- Slightly taller to accommodate new info
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678'",
        URL = "https://github.com/Footagesus/WindUI",
        SaveKey = true,
    },
})

Window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Draggable = true,
})

local Tabs = {
    HomeTab = Window:Tab({ Title = "Home", Icon = "home", Desc = "Welcome! Find general information here." }),
    ServerFinderTab = Window:Tab({ Title = "Server Finder", Icon = "search", Desc = "Find old or small public servers."})
}

Window:SelectTab(1)

Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        local discordLink = "https://discord.gg/ee4veXxYFZ"
        if typeof(setclipboard) == "function" then
            local success, err = pcall(setclipboard, discordLink)
            if success then
                WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied to clipboard.", Icon = "clipboard-check", Duration = 3 })
            else
                WindUI:Notify({ Title = "Copy Error", Content = "Failed to copy link: " .. tostring(err), Icon = "alert-triangle", Duration = 5 })
            end
        else
            WindUI:Notify({ Title = "Clipboard Error", Content = "setclipboard function is not available.", Icon = "alert-triangle", Duration = 5 })
            warn("setclipboard function not available.")
        end
    end
})

-- Server Finder Tab Content
Tabs.ServerFinderTab:Paragraph({Title = "Server Search Settings"})

local gameMaxPlayersDisplayValue = tostring(actualGameMaxPlayers)
local gameInfoParagraphDesc = "This game's Max Players: "
if actualGameMaxPlayers <= 0 then
    gameMaxPlayersDisplayValue = "N/A (or Studio)"
    gameInfoParagraphDesc = gameInfoParagraphDesc .. gameMaxPlayersDisplayValue .. "\n(Search target limit will be 200)"
else
    gameInfoParagraphDesc = gameInfoParagraphDesc .. gameMaxPlayersDisplayValue
end
Tabs.ServerFinderTab:Paragraph({
    Title = "Current Game Info",
    Desc = gameInfoParagraphDesc
})

local placeholderMaxForInput = actualGameMaxPlayers > 0 and actualGameMaxPlayers or 50 -- Fallback for placeholder text
local maxPlayersInput = Tabs.ServerFinderTab:Input({
    Title = "Target Max Players (for Search)",
    Value = tostring(maxPlayersTarget), -- Default is 5
    PlaceholderText = "e.g., 1-" .. placeholderMaxForInput,
    Callback = function(input)
        local num = tonumber(input)
        -- Let 200 be a general practical upper limit for this tool's input,
        -- as searching for servers with more players isn't the primary goal of "small server finder".
        if num and num > 0 and num <= 200 then 
            maxPlayersTarget = num
            WindUI:Notify({Title = "Setting Updated", Content = "Search target max players: " .. maxPlayersTarget, Icon = "settings-2", Duration = 3})
            
            if actualGameMaxPlayers > 0 and num > actualGameMaxPlayers then
                 WindUI:Notify({
                    Title = "Heads Up", 
                    Content = "Search target (" .. num .. ") is higher than this game's max players (" .. actualGameMaxPlayers .. "). Actual search will be limited by the game's max.", 
                    Icon = "info", 
                    Duration = 5
                })
            end
        else
            if maxPlayersInput and typeof(maxPlayersInput.SetValue) == "function" then
                 maxPlayersInput:SetValue(tostring(maxPlayersTarget)) -- Revert to last valid target
            end
            local reason = "Target must be a number > 0 and <= 200."
            WindUI:Notify({
                Title = "Invalid Input", 
                Content = reason, 
                Icon = "alert-triangle", 
                Duration = 4
            })
        end
    end
})

serverFinderStatusLabel = Tabs.ServerFinderTab:Paragraph({
    Title = "Status",
    Desc = "Idle. Configure Target Max Players and click 'Find Server'."
})

foundServerDisplay = Tabs.ServerFinderTab:Paragraph({
    Title = "Found Server Details",
    Desc = "N/A"
})

Tabs.ServerFinderTab:Button({
    Title = "Join Found Server",
    Desc = "Teleports you to the server displayed above.",
    Callback = function()
        if currentFoundJobId then
            WindUI:Notify({Title = "Teleporting...", Content = "Attempting to join server: " .. currentFoundJobId, Icon = "loader-2", Duration = 5})
            local success, err = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, PlaceId, currentFoundJobId, LocalPlayer)
            if not success then
                 WindUI:Notify({Title = "Teleport Failed", Content = "Error: " .. tostring(err), Icon = "alert-circle", Duration = 5})
            end
        else
            WindUI:Notify({Title = "No Server Found", Content = "No server has been found or selected to join.", Icon = "info", Duration = 3})
        end
    end
})

local function updateButtonAndStatus(buttonTitle, statusDesc, isSearching)
    isSearchingServers = isSearching
    if findServerButtonInstance and typeof(findServerButtonInstance.SetTitle) == "function" then
        findServerButtonInstance:SetTitle(buttonTitle)
    end
    if serverFinderStatusLabel and typeof(serverFinderStatusLabel.SetDesc) == "function" then
        serverFinderStatusLabel:SetDesc(statusDesc)
    end
end

local function stopSearch(statusMessageOverride)
    local finalMessage = statusMessageOverride or "Search stopped by user or error."
    updateButtonAndStatus("Find Server", finalMessage, false)
end

local function searchForServer()
    if isSearchingServers then
        stopSearch("Search manually stopped.")
        return
    end

    if PlaceId == 0 then
        if serverFinderStatusLabel and typeof(serverFinderStatusLabel.SetDesc) == "function" then
            serverFinderStatusLabel:SetDesc("Error: Invalid PlaceId (0). Cannot search in Studio or local server.")
        end
        return
    end

    currentFoundJobId = nil
    if foundServerDisplay and typeof(foundServerDisplay.SetDesc) == "function" then foundServerDisplay:SetDesc("N/A") end
    updateButtonAndStatus("Stop Search", "Searching for servers...", true)
    
    serverSearchCursor = "" 

    task.spawn(function()
        local attempts = 0
        local maxApiPages = 10 

        while isSearchingServers and attempts < maxApiPages do
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=10&cursor=%s", PlaceId, serverSearchCursor)
            
            local responseBody
            local requestSuccess, requestResult = pcall(function() return WindUI.Creator.Request({Url = url, Method = "GET"}) end)

            if not requestSuccess or not requestResult or not requestResult.Body then
                local errMsg = "API Request Failed: "
                if not requestSuccess then errMsg = errMsg .. "pcall error (" .. tostring(requestResult) .. ")"
                elseif not requestResult then errMsg = errMsg .. "No response object."
                else errMsg = errMsg .. (requestResult.StatusMessage or "No response body/unknown error.") end
                
                stopSearch(errMsg)
                print("Server API Request Error:", requestResult or "pcall failure")
                return 
            end
            responseBody = requestResult.Body

            local decodedResponseData
            local decodeSuccess, decodedResult = pcall(HttpService.JSONDecode, HttpService, responseBody)
            
            if not decodeSuccess then
                stopSearch("Error decoding server data: " .. tostring(decodedResult))
                print("Server API JSON Decode Error on Body:", responseBody, "Error:", decodedResult)
                return 
            end
            decodedResponseData = decodedResult

            if decodedResponseData and decodedResponseData.data and #decodedResponseData.data > 0 then
                for _, serverInfo in ipairs(decodedResponseData.data) do
                    if not isSearchingServers then break end 

                    if type(serverInfo) == "table" and serverInfo.playing ~= nil and serverInfo.maxPlayers ~= nil and serverInfo.id ~= nil then
                        -- Core logic: server has fewer players than target AND fewer players than its own max capacity
                        if serverInfo.playing < maxPlayersTarget and serverInfo.playing < serverInfo.maxPlayers then
                            currentFoundJobId = serverInfo.id
                            local serverDetails = string.format("Job ID: %s\nPlayers: %d/%d", serverInfo.id, serverInfo.playing, serverInfo.maxPlayers)
                            
                            if foundServerDisplay and typeof(foundServerDisplay.SetDesc) == "function" then foundServerDisplay:SetDesc(serverDetails) end
                            WindUI:Notify({Title = "Server Found!", Content = serverDetails, Icon = "check-circle-2", Duration = 5})
                            stopSearch("Server found!") 
                            return 
                        end
                    else
                        print("Warning: Received malformed serverInfo object:", serverInfo)
                    end
                end

                if decodedResponseData.nextPageCursor then
                    serverSearchCursor = decodedResponseData.nextPageCursor
                    if serverFinderStatusLabel and typeof(serverFinderStatusLabel.SetDesc) == "function" then serverFinderStatusLabel:SetDesc("Fetching next page (" .. (attempts + 1) .. "/" .. maxApiPages .. ")...") end
                else
                    stopSearch("Reached end of server list. No suitable server found.")
                    break 
                end
            else 
                local reason = "No servers found on this page"
                if decodedResponseData and decodedResponseData.errors and #decodedResponseData.errors > 0 then
                    reason = "API Error: " .. (decodedResponseData.errors[1].message or "Unknown API error")
                elseif not (decodedResponseData and decodedResponseData.data) then
                    reason = "Invalid data structure from API"
                end
                stopSearch(reason .. ".")
                break 
            end
            
            attempts = attempts + 1
            if isSearchingServers then task.wait(1.2) end 
        end

        if isSearchingServers then 
            stopSearch("Search completed. No server found matching criteria after checking " .. attempts .. " page(s).")
        end
    end)
end

findServerButtonInstance = Tabs.ServerFinderTab:Button({
    Title = "Find Server",
    Desc = "Searches for a public server with fewer players than your Target Max Players setting.",
    Callback = searchForServer
})
