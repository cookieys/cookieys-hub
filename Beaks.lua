-- Wait for the game to be fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Load latest WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Helper function to safely find remotes
local function findRemote(path)
    local current = ReplicatedStorage
    for _, name in ipairs(path) do
        local success, child = pcall(function() return current:WaitForChild(name, 10) end)
        if not success or not child then
            return nil, "Could not find '" .. name .. "' in " .. current.Name
        end
        current = child
    end
    return current
end

-- Find the remote and handle errors
local buyDartRemote, remoteError = findRemote({"Util", "Net", "RF/BuyDart"})
if remoteError then
    warn("cookieys hub Error: " .. remoteError .. ". The 'Inf Money' feature will be disabled.")
    WindUI:Notify({
        Title = "Remote Not Found",
        Content = "The 'Inf Money' remote could not be found. The feature will be unavailable.",
        Icon = "alert-triangle",
        Duration = 8,
    })
end

-- UI Setup
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(300, 300),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "Example Key System.\nThe Key is '1234' or '5678'",
        URL = "https://github.com/Footagesus/WindUI",
        SaveKey = true,
    },
})

Window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    Draggable = true,
})

-- Tabs
local Tabs = {
    Home = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    Main = Window:Tab({ Title = "Main", Icon = "bolt", Desc = "Core script functionalities." })
}
Window:SelectTab(1)

-- Home Tab Content
Tabs.Home:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/ee4veXxYFZ")
            WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied to clipboard.", Icon = "clipboard-check", Duration = 3 })
        else
            WindUI:Notify({ Title = "Error", Content = "setclipboard is not available in this environment.", Icon = "alert-triangle", Duration = 5 })
        end
    end
})

-- Main Tab Content
local infMoneyConnection = nil
local infMoneyToggleElement = Tabs.Main:Toggle({
    Title = "Inf Money",
    Desc = "Attempts to rapidly add money.",
    Value = false,
    Callback = function(is_enabled)
        if not buyDartRemote then
            WindUI:Notify({ Title = "Error", Content = "Inf Money remote is not available. Cannot enable.", Icon = "alert-triangle", Duration = 5 })
            if infMoneyToggleElement and infMoneyToggleElement.SetValue then
                infMoneyToggleElement:SetValue(false, true) -- Set value without firing callback
            end
            return
        end

        if is_enabled and not infMoneyConnection then
            WindUI:Notify({ Title = "Inf Money", Content = "Enabled", Icon = "check", Duration = 3 })
            infMoneyConnection = RunService.Heartbeat:Connect(function()
                if not buyDartRemote or not buyDartRemote.Parent then
                    if infMoneyConnection then
                        infMoneyConnection:Disconnect()
                        infMoneyConnection = nil
                        WindUI:Notify({ Title = "Inf Money", Content = "Disabled (Remote Lost)", Icon = "alert-triangle", Duration = 4 })
                        if infMoneyToggleElement and infMoneyToggleElement.SetValue then
                            infMoneyToggleElement:SetValue(false, true)
                        end
                    end
                    return
                end
                pcall(buyDartRemote.InvokeServer, buyDartRemote, "Steel", -1e150)
                pcall(buyDartRemote.InvokeServer, buyDartRemote, "Steel", -1e150)
            end)
        elseif not is_enabled and infMoneyConnection then
            WindUI:Notify({ Title = "Inf Money", Content = "Disabled", Icon = "x", Duration = 3 })
            infMoneyConnection:Disconnect()
            infMoneyConnection = nil
        end
    end
})

-- Cleanup
local function cleanup()
    if infMoneyConnection then
        infMoneyConnection:Disconnect()
        infMoneyConnection = nil
        print("Inf. Money connection cleaned up on exit.")
    end
end

LocalPlayer.Destroying:Connect(cleanup)
