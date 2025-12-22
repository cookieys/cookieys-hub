if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- // Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- // Whitelist Configuration (Using Dictionary for O(1) lookup speed)
local WhitelistedUsers = {
    [7698388491] = true,
    [8174329346] = true,
}

local LocalPlayer = Players.LocalPlayer

-- // Load Library safely
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    warn("Failed to load WindUI.")
    return
end

-- // Whitelist Check
if not WhitelistedUsers[LocalPlayer.UserId] then
    WindUI:Notify({
        Title = "Access Denied",
        Content = "User ID " .. LocalPlayer.UserId .. " is not authorized.",
        Icon = "shield-alert",
        Duration = 10,
    })
    return
end

-- // Create Window
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "orbit", 
    Author = "XyraV",
    Folder = "cookieys-config",
    Size = UDim2.fromOffset(500, 350), -- Increased size for better visibility
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
})

Window:EditOpenButton({
    Title = "Open Hub",
    Icon = "cookie",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Draggable = true,
})

-- // Tabs
local Tabs = {
    Home = Window:Tab({ Title = "Home", Icon = "house" }),
}

Window:SelectTab(1)

-- // Home Section
local HomeSection = Tabs.Home:Section({ Title = "Information" })

HomeSection:Paragraph({
    Title = "Welcome, " .. LocalPlayer.DisplayName,
    Desc = "You have successfully authenticated."
})

HomeSection:Button({
    Title = "Join Discord Server",
    Desc = "Copy the invite link to your clipboard.",
    Icon = "link",
    Callback = function()
        local discordLink = "https://discord.gg/ee4veXxYFZ"
        
        if setclipboard then
            setclipboard(discordLink)
            WindUI:Notify({
                Title = "Success",
                Content = "Discord invite copied to clipboard!",
                Icon = "check",
                Duration = 3,
            })
        else
            WindUI:Notify({
                Title = "Not Supported",
                Content = "Your executor does not support setclipboard.",
                Icon = "triangle-alert",
                Duration = 5,
            })
        end
    end
})

WindUI:Notify({
    Title = "Authenticated",
    Content = "Welcome back, " .. LocalPlayer.Name,
    Icon = "shield-check",
    Duration = 5
})
