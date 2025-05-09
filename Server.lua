if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Server Finder Variables
local isSearchingServers = false
local currentFoundJobId = nil
local maxPlayersTarget = 5 -- Default value for max players in a server
local serverSearchCursor = "" -- For API pagination

-- UI Element References for Server Finder (will be assigned)
local serverFinderStatusLabel = nil
local foundServerDisplay = nil
local joinFoundServerButton = nil -- Kept for reference, but its action is always available
local findServerButtonInstance = nil -- To potentially change its title if supported and desired

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open", -- Assuming 'door-open' is a valid icon like in the WindUI example
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(350, 400), -- Slightly wider for more server info
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
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    ServerFinderTab = Window:Tab({ Title = "Server Finder", Icon = "search", Desc = "Find old/small servers."})
}

Window:SelectTab(1) -- Select HomeTab by default

-- Home Tab Content
Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        local discordLink = "https://discord.gg/ee4veXxYFZ"
        if setclipboard then
            local success, err = pcall(setclipboard, discordLink)
            if success then
                WindUI:Notify({
                    Title = "Link Copied!",
                    Content = "Discord invite link copied to clipboard.",
                    Icon = "clipboard-check",
                    Duration = 3,
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to copy link: " .. tostring(err),
                    Icon = "alert-triangle",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Could not copy link (setclipboard unavailable).",
                Icon = "alert-triangle",
                Duration = 5,
            })
            warn("setclipboard function not available in this environment.")
        end
    end
})

-- Server Finder Tab Content
Tabs.ServerFinderTab:Paragraph({Title = "Server Search Criteria"})

local maxPlayersInput = Tabs.ServerFinderTab:Input({
    Title = "Max Players in Server",
    Value = tostring(maxPlayersTarget),
    PlaceholderText = "e.g., 5", -- Using PlaceholderText as per WindUI example
    Callback = function(input)
        local num = tonumber(input)
        if num and num > 0 then
            maxPlayersTarget = num
        else
            if maxPlayersInput and typeof(maxPlayersInput.SetValue) == "function" then
                 maxPlayersInput:SetValue(tostring(maxPlayersTarget))
            end
            WindUI:Notify({Title = "Invalid Input", Content = "Max players must be a positive number.", Icon = "alert-triangle", Duration = 3})
        end
    end
})

serverFinderStatusLabel = Tabs.ServerFinderTab:Paragraph({
    Title = "Status",
    Desc = "Idle."
})

foundServerDisplay = Tabs.ServerFinderTab:Paragraph({
    Title = "Found Server Details",
    Desc = "N/A"
})

joinFoundServerButton = Tabs.ServerFinderTab:Button({
    Title = "Join Found Server",
    Desc = "Teleports you to the server displayed above.",
    Callback = function()
        if currentFoundJobId then
            WindUI:Notify({Title = "Teleporting", Content = "Attempting to join server: " .. currentFoundJobId, Icon = "loader-circle", Duration = 5})
            local success, err = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, PlaceId, currentFoundJobId, LocalPlayer)
            if not success then
                 WindUI:Notify({Title = "Teleport Failed", Content = tostring(err), Icon = "alert-triangle", Duration = 5})
            end
        else
            WindUI:Notify({Title = "No Server Found", Content = "No server has been found or selected to join.", Icon = "alert-triangle", Duration = 3})
        end
    end
})

local function stopSearch(statusMessageOverride)
    isSearchingServers = false
    if findServerButtonInstance and typeof(findServerButtonInstance.SetTitle) == "function" then -- Check if method exists
        findServerButtonInstance:SetTitle("Find Server")
    end
    if statusMessageOverride then
        serverFinderStatusLabel:SetDesc(statusMessageOverride)
    else
        serverFinderStatusLabel:SetDesc("Search stopped.")
    end
end

local function searchForServer()
    if isSearchingServers then
        stopSearch("Search manually stopped.")
        return
    end

    if PlaceId == 0 then
        serverFinderStatusLabel:SetDesc("Error: Invalid PlaceId (0). Cannot search in Studio or local server.")
        return
    end

    isSearchingServers = true
    currentFoundJobId = nil
    foundServerDisplay:SetDesc("N/A")
    serverFinderStatusLabel:SetDesc("Searching...")
    if findServerButtonInstance and typeof(findServerButtonInstance.SetTitle) == "function" then
        findServerButtonInstance:SetTitle("Stop Search")
    end

    serverSearchCursor = "" -- Reset cursor for a new search

    task.spawn(function()
        local attempts = 0
        local maxApiPages = 10 -- Limit number of API pages to fetch

        while isSearchingServers and attempts < maxApiPages do
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=10&cursor=%s", PlaceId, serverSearchCursor)
            
            local decodedResponseData
            local requestSuccess, result = pcall(WindUI.Creator.Request, { -- Using WindUI.Creator.Request as per example
                Url = url,
                Method = "GET"
            })

            if requestSuccess and result and result.Body then
                local decodeSuccess, decoded = pcall(HttpService.JSONDecode, HttpService, result.Body)
                if decodeSuccess then
                    decodedResponseData = decoded
                else
                    serverFinderStatusLabel:SetDesc("Error decoding server data: " .. tostring(decoded))
                    print("Server API JSON Decode Error on Body:", result.Body)
                    stopSearch()
                    break
                end
            else
                local err_msg = "API Error: "
                if result and result.StatusMessage then err_msg = err_msg .. result.StatusMessage
                elseif result and result.Body then err_msg = err_msg .. " Received non-JSON body."
                elseif not requestSuccess then err_msg = err_msg .. " Request function pcall failed: " .. tostring(result)
                else err_msg = err_msg .. " Unknown error or no response body." end
                serverFinderStatusLabel:SetDesc(err_msg)
                if result then print("Server API Raw Response/Error:", result) end
                stopSearch()
                break
            end

            if decodedResponseData and decodedResponseData.data and #decodedResponseData.data > 0 then
                for _, serverInfo in ipairs(decodedResponseData.data) do
                    if not isSearchingServers then break end 

                    if serverInfo.playing < maxPlayersTarget and serverInfo.playing < serverInfo.maxPlayers then
                        currentFoundJobId = serverInfo.id
                        foundServerDisplay:SetDesc("Job ID: " .. serverInfo.id .. "\nPlayers: " .. serverInfo.playing .. "/" .. serverInfo.maxPlayers)
                        serverFinderStatusLabel:SetDesc("Server found!")
                        WindUI:Notify({Title = "Server Found!", Content = "Job ID: " .. serverInfo.id .. " (" .. serverInfo.playing .. " players)", Icon = "check-circle", Duration = 5})
                        stopSearch("Server found!") 
                        return
                    end
                end

                if decodedResponseData.nextPageCursor then
                    serverSearchCursor = decodedResponseData.nextPageCursor
                    serverFinderStatusLabel:SetDesc("Fetching next page of servers...")
                else
                    stopSearch("Reached end of server list. No suitable server found.")
                    break
                end
            else
                stopSearch("No servers found on this page or invalid data.")
                break
            end
            attempts = attempts + 1
            task.wait(1.5) -- Delay between API requests
        end

        if isSearchingServers then -- Loop finished (e.g. maxApiPages reached)
            stopSearch("Search finished. No server found matching criteria after " .. attempts .. " pages.")
        end
    end)
end

findServerButtonInstance = Tabs.ServerFinderTab:Button({
    Title = "Find Server",
    Desc = "Searches for a public server with fewer players than your Max Players setting.",
    Callback = searchForServer
})

-- Initial state for labels if needed
serverFinderStatusLabel:SetDesc("Idle. Configure Max Players and click 'Find Server'.")
foundServerDisplay:SetDesc("No server found yet.")
