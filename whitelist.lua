if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Whitelist System
local WhitelistedUserIDs = {
    7698388491, -- Replace with actual UserID
    8174329346, -- Replace with another actual UserID
    -- Add more UserIDs here
}

local LocalPlayer = game:GetService("Players").LocalPlayer
local isWhitelisted = false
for _, id in ipairs(WhitelistedUserIDs) do
    if LocalPlayer.UserId == id then
        isWhitelisted = true
        break
    end
end

if not isWhitelisted then
    WindUI:Notify({
        Title = "Access Denied",
        Content = "You are not whitelisted to use this UI.",
        Icon = "lock",
        Duration = 10,
    })
    return -- Stop script execution if not whitelisted
end

-- If whitelisted, proceed to create the UI
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "orbit",
    Author = "XyraV",
    Folder = "Astra V1",
    Size = UDim2.fromOffset(300, 300),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
    -- KeySystem removed
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
}

Window:SelectTab(1)

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
                    Icon = "triangle-alert",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Could not copy link (setclipboard unavailable).",
                Icon = "triangle-alert",
                Duration = 5,
            })
            warn("setclipboard function not available in this environment.")
        end
    end
})
