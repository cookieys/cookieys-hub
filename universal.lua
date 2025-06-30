if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Player
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- UI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- State Management
local State = {
    Defaults = {
        WalkSpeed = 16,
        JumpPower = 50,
        FieldOfView = 70,
        MaxZoom = LocalPlayer.CameraMaxZoomDistance,
    },
    Current = {},
    Elements = {},
    AntiAFKConnection = nil
}
-- Initialize current state and get live defaults
State.Defaults.WalkSpeed = Humanoid.WalkSpeed
State.Defaults.JumpPower = Humanoid.JumpPower
State.Defaults.FieldOfView = Workspace.CurrentCamera.FieldOfView
State.Current = table.clone(State.Defaults)

-- Core Functions
local function SetHumanoidProperty(prop, value)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid[prop] = value
    end
end

local Apply = {}
function Apply.WalkSpeed(value)
    State.Current.WalkSpeed = value
    SetHumanoidProperty("WalkSpeed", value)
end
function Apply.JumpPower(value)
    State.Current.JumpPower = value
    SetHumanoidProperty("JumpPower", value)
end
function Apply.FieldOfView(value)
    State.Current.FieldOfView = value
    Workspace.CurrentCamera.FieldOfView = value
end
function Apply.MaxZoom(enabled)
    State.Current.MaxZoomEnabled = enabled
    LocalPlayer.CameraMaxZoomDistance = enabled and 1e9 or State.Defaults.MaxZoom
end
function Apply.AntiAFK(enabled)
    State.Current.AntiAFKEnabled = enabled
    if enabled and not State.AntiAFKConnection then
        State.AntiAFKConnection = RunService.Stepped:Connect(function()
            pcall(VirtualUser.Button2Down, VirtualUser, Enum.UserInputType.MouseButton2)
            task.wait(0.1)
            pcall(VirtualUser.Button2Up, VirtualUser, Enum.UserInputType.MouseButton2)
        end)
    elseif not enabled and State.AntiAFKConnection then
        State.AntiAFKConnection:Disconnect()
        State.AntiAFKConnection = nil
    end
end
function Apply.All()
    pcall(Apply.WalkSpeed, State.Current.WalkSpeed)
    pcall(Apply.JumpPower, State.Current.JumpPower)
    pcall(Apply.FieldOfView, State.Current.FieldOfView)
    pcall(Apply.MaxZoom, State.Current.MaxZoomEnabled)
    pcall(Apply.AntiAFK, State.Current.AntiAFKEnabled)
end

local function ResetToDefaults()
    State.Current = table.clone(State.Defaults)
    Apply.All()
    -- Update UI elements
    for _, element in pairs(State.Elements) do
        if element.Reset then element:Reset() end
    end
end

-- UI Setup
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "cookie",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(300, 300),
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

-- Home Tab
Tabs.Home:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        setclipboard("https://discord.gg/ee4veXxYFZ")
        WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied to clipboard.", Duration = 3 })
    end
})

-- Main Tab
local function LoadScript(url, name)
    task.spawn(function()
        local success, err = pcall(function() loadstring(game:HttpGet(url))() end)
        WindUI:Notify({
            Title = success and "Success" or "Error",
            Content = success and name .. " loaded." or "Failed to load " .. name .. ".",
            Duration = 4
        })
    end)
end
Tabs.Main:Button({
    Title = "Load Infinite Yield",
    Callback = function() LoadScript("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", "Infinite Yield") end
})
Tabs.Main:Button({
    Title = "Load Nameless Admin",
    Callback = function() LoadScript("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua", "Nameless Admin") end
})

-- Phantom Tab
State.Elements.AntiAFK = Tabs.PhantomTab:Toggle({ Title = "Anti AFK", Desc = "Prevents game kick for inactivity.", Callback = Apply.AntiAFK })
State.Elements.WalkSpeed = Tabs.PhantomTab:Slider({ Title = "Walk Speed", Value = { Min = 16, Max = 500, Default = State.Defaults.WalkSpeed }, Callback = Apply.WalkSpeed })
State.Elements.JumpPower = Tabs.PhantomTab:Slider({ Title = "Jump Power", Value = { Min = 50, Max = 500, Default = State.Defaults.JumpPower }, Callback = Apply.JumpPower })
State.Elements.FieldOfView = Tabs.PhantomTab:Slider({ Title = "FOV Changer", Value = { Min = 1, Max = 120, Default = State.Defaults.FieldOfView }, Callback = Apply.FieldOfView })
State.Elements.MaxZoom = Tabs.PhantomTab:Toggle({ Title = "Infinite Max Zoom", Desc = "Allows zooming out indefinitely.", Callback = Apply.MaxZoom })

-- Settings Tab
local themeValues = {}
for name in pairs(WindUI:GetThemes()) do table.insert(themeValues, name) end
State.Elements.Theme = Tabs.SettingsTab:Dropdown({ Title = "Select Theme", Values = themeValues, Value = WindUI:GetCurrentTheme(), Callback = function(t) WindUI:SetTheme(t) end })
State.Elements.Transparency = Tabs.SettingsTab:Toggle({ Title = "Window Transparency", Value = Window.Transparent, Callback = function(s) Window:ToggleTransparency(s) end })

-- Configuration Management
local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("DefaultSettings")
for name, element in pairs(State.Elements) do
    myConfig:Register(name, element)
end

Tabs.SettingsTab:Button({ Title = "Save Config", Callback = function() myConfig:Save() WindUI:Notify({ Title = "Saved", Content = "Configuration has been saved." }) end })
Tabs.SettingsTab:Button({ Title = "Load Config", Callback = function() myConfig:Load() WindUI:Notify({ Title = "Loaded", Content = "Configuration has been loaded." }) end })

-- Event Handling
LocalPlayer.CharacterAdded:Connect(function(char)
    Humanoid = char:WaitForChild("Humanoid")
    task.wait(0.5) -- Wait for character to fully load
    Apply.All()
end)

game:BindToClose(ResetToDefaults)
LocalPlayer.Destroying:Connect(ResetToDefaults)

-- Initial state application
Apply.All()
