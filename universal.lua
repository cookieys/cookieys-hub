-- Wait for the game to be fully loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

-- Player and Character setup
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Load UI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- State Management
local State = {
    Defaults = {
        WalkSpeed = Humanoid.WalkSpeed,
        JumpPower = Humanoid.JumpPower,
        FieldOfView = Workspace.CurrentCamera.FieldOfView,
        MaxZoom = LocalPlayer.CameraMaxZoomDistance,
        AntiAFKEnabled = false,
        MaxZoomEnabled = false,
    },
    Current = {},
    Elements = {},
    AntiAFKConnection = nil
}
State.Current = table.clone(State.Defaults)

-- Core Functions to Apply Settings
local Apply = {}
function Apply.WalkSpeed(value)
    State.Current.WalkSpeed = value
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
end
function Apply.JumpPower(value)
    State.Current.JumpPower = value
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = value
    end
end
function Apply.FieldOfView(value)
    State.Current.FieldOfView = value
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = value
    end
end
function Apply.MaxZoom(enabled)
    State.Current.MaxZoomEnabled = enabled
    LocalPlayer.CameraMaxZoomDistance = enabled and 1e9 or State.Defaults.MaxZoom
end
function Apply.AntiAFK(enabled)
    State.Current.AntiAFKEnabled = enabled
    if enabled and not State.AntiAFKConnection then
        State.AntiAFKConnection = RunService.Stepped:Connect(function()
            pcall(function() VirtualUser:Button2Down(Vector2.new()) end)
            task.wait(0.1)
            pcall(function() VirtualUser:Button2Up(Vector2.new()) end)
        end)
    elseif not enabled and State.AntiAFKConnection then
        State.AntiAFKConnection:Disconnect()
        State.AntiAFKConnection = nil
    end
end
function Apply.AllCurrentSettings()
    Apply.WalkSpeed(State.Current.WalkSpeed)
    Apply.JumpPower(State.Current.JumpPower)
    Apply.FieldOfView(State.Current.FieldOfView)
    Apply.MaxZoom(State.Current.MaxZoomEnabled)
    Apply.AntiAFK(State.Current.AntiAFKEnabled)
end

-- Reset Function
local function ResetToDefaults()
    State.Current = table.clone(State.Defaults)
    Apply.AllCurrentSettings()

    if State.Elements.WalkSpeed and State.Elements.WalkSpeed.SetValue then State.Elements.WalkSpeed:SetValue(State.Defaults.WalkSpeed) end
    if State.Elements.JumpPower and State.Elements.JumpPower.SetValue then State.Elements.JumpPower:SetValue(State.Defaults.JumpPower) end
    if State.Elements.FieldOfView and State.Elements.FieldOfView.SetValue then State.Elements.FieldOfView:SetValue(State.Defaults.FieldOfView) end
    if State.Elements.MaxZoom and State.Elements.MaxZoom.SetValue then State.Elements.MaxZoom:SetValue(State.Defaults.MaxZoomEnabled) end
    if State.Elements.AntiAFK and State.Elements.AntiAFK.SetValue then State.Elements.AntiAFK:SetValue(State.Defaults.AntiAFKEnabled) end
end

-- UI Setup
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "cookie",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
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
    Home = Window:Tab({ Title = "Home", Icon = "house" }),
    Main = Window:Tab({ Title = "Main", Icon = "star" }),
    Phantom = Window:Tab({ Title = "Phantom", Icon = "ghost" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}
Window:SelectTab(1)

-- Home Tab Content
Tabs.Home:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/ee4veXxYFZ")
            WindUI:Notify({ Title = "Link Copied!", Icon = "clipboard-check", Content = "Discord invite link copied to clipboard.", Duration = 3 })
        end
    end
})

-- Main Tab Content
local function LoadScript(url, name)
    task.spawn(function()
        local code, err = pcall(game.HttpGet, game, url)
        if not code or err then
            return WindUI:Notify({ Title = "Error", Icon = "alert-triangle", Content = "Failed to download " .. name .. ".", Duration = 4 })
        end
        local success, err2 = pcall(loadstring(err))
        if success then
            WindUI:Notify({ Title = "Success", Icon = "check", Content = name .. " loaded successfully.", Duration = 4 })
        else
            WindUI:Notify({ Title = "Error", Icon = "alert-triangle", Content = "Failed to execute " .. name .. ": " .. tostring(err2), Duration = 5 })
        end
    end)
end
Tabs.Main:Button({ Title = "Load Infinite Yield", Callback = function() LoadScript("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", "Infinite Yield") end })
Tabs.Main:Button({ Title = "Load Nameless Admin", Callback = function() LoadScript("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua", "Nameless Admin") end })

-- Phantom Tab Content
State.Elements.AntiAFK = Tabs.Phantom:Toggle({ Title = "Anti AFK", Desc = "Prevents game kick for inactivity.", Value = State.Current.AntiAFKEnabled, Callback = Apply.AntiAFK })
State.Elements.WalkSpeed = Tabs.Phantom:Slider({ Title = "Walk Speed", Value = { Min = 16, Max = 500, Default = State.Defaults.WalkSpeed }, Callback = Apply.WalkSpeed })
State.Elements.JumpPower = Tabs.Phantom:Slider({ Title = "Jump Power", Value = { Min = 50, Max = 500, Default = State.Defaults.JumpPower }, Callback = Apply.JumpPower })
State.Elements.FieldOfView = Tabs.Phantom:Slider({ Title = "FOV Changer", Value = { Min = 1, Max = 120, Default = State.Defaults.FieldOfView }, Callback = Apply.FieldOfView })
State.Elements.MaxZoom = Tabs.Phantom:Toggle({ Title = "Infinite Max Zoom", Desc = "Allows zooming out indefinitely.", Value = State.Current.MaxZoomEnabled, Callback = Apply.MaxZoom })

-- Settings Tab Content
local themeValues = {}
for name in pairs(WindUI:GetThemes()) do table.insert(themeValues, name) end
State.Elements.Theme = Tabs.Settings:Dropdown({ Title = "Select Theme", Values = themeValues, Value = WindUI:GetCurrentTheme(), Callback = function(t) WindUI:SetTheme(t) end })
State.Elements.Transparency = Tabs.Settings:Toggle({ Title = "Window Transparency", Value = Window.Transparent, Callback = function(s) Window:ToggleTransparency(s) end })

-- Configuration Management
if Window.ConfigManager then
    local myConfig = Window.ConfigManager:CreateConfig("DefaultSettings")
    myConfig:Register("AntiAFK", State.Elements.AntiAFK)
    myConfig:Register("WalkSpeed", State.Elements.WalkSpeed)
    myConfig:Register("JumpPower", State.Elements.JumpPower)
    myConfig:Register("FieldOfView", State.Elements.FieldOfView)
    myConfig:Register("MaxZoom", State.Elements.MaxZoom)
    myConfig:Register("Theme", State.Elements.Theme)
    myConfig:Register("Transparency", State.Elements.Transparency)
    Tabs.Settings:Button({ Title = "Save Config", Callback = function() myConfig:Save(); WindUI:Notify({ Title = "Saved", Content = "Configuration has been saved." }) end })
    Tabs.Settings:Button({ Title = "Load Config", Callback = function() myConfig:Load(); WindUI:Notify({ Title = "Loaded", Content = "Configuration has been loaded." }) end })
end

-- Event Handling
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    task.wait(0.2)
    Apply.AllCurrentSettings()
end)

-- This is the correct client-side way to handle cleanup when the player leaves.
LocalPlayer.Destroying:Connect(ResetToDefaults)

-- Initial application of settings
Apply.AllCurrentSettings()
