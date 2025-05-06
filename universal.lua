if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Allow game to settle

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

-- Player related variables
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then -- Fallback if script runs before LocalPlayer is set
    LocalPlayer = Players.PlayerAdded:Wait()
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Load UI Library
local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

-- Store Default Values (fetch once, ensure Humanoid and Camera are valid)
local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local DEFAULT_FOV = 70 -- Roblox default FOV

if Humanoid and Humanoid.Parent then -- Check Humanoid is still valid
    DEFAULT_WALKSPEED = Humanoid.WalkSpeed
    DEFAULT_JUMPPOWER = Humanoid.JumpPower
end
if Workspace.CurrentCamera then
    DEFAULT_FOV = Workspace.CurrentCamera.FieldOfView
end

-- UI Element References (will be assigned when elements are created)
local AntiAFKToggleElement = nil
local WalkSpeedSliderElement = nil
local JumpPowerSliderElement = nil
local FovSliderElement = nil

-- Window Creation
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "cookie",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(400, 350),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678",
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

-- Anti AFK Logic
local AntiAFKEnabled = false
local AntiAFKConnection

local function StartAntiAFK()
    if AntiAFKConnection then AntiAFKConnection:Disconnect() end
    AntiAFKConnection = RunService.Stepped:Connect(function()
        if AntiAFKEnabled then
            pcall(VirtualUser.Button2Click, VirtualUser) -- Simpler click
        end
    end)
end

local function StopAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

-- Function to safely set humanoid properties
local function SetHumanoidProperty(propName, value)
    if Character and Character.Parent and Humanoid and Humanoid.Parent then
        pcall(function()
            Humanoid[propName] = value
        end)
    end
end

-- Tabs Definition
local Tabs = {
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    MainTab = Window:Tab({ Title = "Main", Icon = "star", Desc = "Core features and utilities." }),
    SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "Adjust script settings." })
}

Window:SelectTab(1)

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

-- Main Tab Content
Tabs.MainTab:Button({
    Title = "Load Infinite Yield",
    Desc = "Loads the Infinite Yield admin script.",
    Callback = function()
        WindUI:Notify({
            Title = "Loading...",
            Content = "Loading Infinite Yield. Please wait.",
            Icon = "loader-circle",
            Duration = 3,
        })
        task.spawn(function() -- Use task.spawn for non-yielding operations
            local success, err = pcall(function()
                 loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
            end)
            if not success then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to load Infinite Yield: " .. tostring(err),
                    Icon = "alert-triangle",
                    Duration = 5,
                })
                warn("Infinite Yield load error:", err)
            else
                WindUI:Notify({
                    Title = "Success",
                    Content = "Infinite Yield loaded successfully.",
                    Icon = "check-circle",
                    Duration = 3,
                })
            end
        end)
    end
})

-- Settings Tab Content
AntiAFKToggleElement = Tabs.SettingsTab:Toggle({
    Title = "Anti AFK",
    Desc = "Prevents the game from kicking you for inactivity.",
    Default = false,
    Callback = function(state)
        AntiAFKEnabled = state
        if AntiAFKEnabled then
            StartAntiAFK()
        else
            StopAntiAFK()
        end
    end
})

WalkSpeedSliderElement = Tabs.SettingsTab:Slider({
    Title = "Walk Speed",
    Desc = "Adjust your character's movement speed.",
    Value = {
        Min = 0,
        Max = 200,
        Default = DEFAULT_WALKSPEED,
    },
    Callback = function(value)
        SetHumanoidProperty("WalkSpeed", value)
    end
})

JumpPowerSliderElement = Tabs.SettingsTab:Slider({
    Title = "Jump Power",
    Desc = "Adjust your character's jump height.",
    Value = {
        Min = 0,
        Max = 200,
        Default = DEFAULT_JUMPPOWER,
    },
    Callback = function(value)
        SetHumanoidProperty("JumpPower", value)
    end
})

FovSliderElement = Tabs.SettingsTab:Slider({
    Title = "FOV Changer",
    Desc = "Adjust your camera Field of View.",
    Value = {
        Min = 1,
        Max = 120,
        Default = DEFAULT_FOV,
    },
    Callback = function(value)
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = value
        end
    end
})

-- Function to reset settings to default and update UI
local function ResetSettingsAndUI()
    -- Set Anti-AFK toggle and stop functionality
    if AntiAFKToggleElement and AntiAFKToggleElement.SetValue then
        AntiAFKToggleElement:SetValue(false) -- This should trigger its callback
    elseif AntiAFKEnabled then -- Fallback if SetValue isn't available or toggle element is nil
        AntiAFKEnabled = false
        StopAntiAFK()
    end

    -- Reset WalkSpeed
    SetHumanoidProperty("WalkSpeed", DEFAULT_WALKSPEED)
    if WalkSpeedSliderElement and WalkSpeedSliderElement.SetValue then
        WalkSpeedSliderElement:SetValue(DEFAULT_WALKSPEED)
    end

    -- Reset JumpPower
    SetHumanoidProperty("JumpPower", DEFAULT_JUMPPOWER)
    if JumpPowerSliderElement and JumpPowerSliderElement.SetValue then
        JumpPowerSliderElement:SetValue(DEFAULT_JUMPPOWER)
    end

    -- Reset FOV
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = DEFAULT_FOV
        if FovSliderElement and FovSliderElement.SetValue then
            FovSliderElement:SetValue(DEFAULT_FOV)
        end
    end
end

-- Reset settings if script is destroyed unexpectedly or player leaves
game:BindToClose(ResetSettingsAndUI)
LocalPlayer.Destroying:Connect(ResetSettingsAndUI)

-- Handle character respawn to re-apply settings from UI elements
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")

    task.wait(0.1) -- Small delay for stability

    -- Re-apply settings from the current UI values if elements exist
    if WalkSpeedSliderElement and WalkSpeedSliderElement.GetValue then
        SetHumanoidProperty("WalkSpeed", WalkSpeedSliderElement:GetValue())
    else
        SetHumanoidProperty("WalkSpeed", DEFAULT_WALKSPEED) -- Fallback
    end

    if JumpPowerSliderElement and JumpPowerSliderElement.GetValue then
        SetHumanoidProperty("JumpPower", JumpPowerSliderElement:GetValue())
    else
        SetHumanoidProperty("JumpPower", DEFAULT_JUMPPOWER) -- Fallback
    end

    if Workspace.CurrentCamera then
        if FovSliderElement and FovSliderElement.GetValue then
             Workspace.CurrentCamera.FieldOfView = FovSliderElement:GetValue()
        else
             Workspace.CurrentCamera.FieldOfView = DEFAULT_FOV -- Fallback
        end
    end
    -- Anti-AFK state is managed by its toggle and should persist as is
end)

-- Initial application of default FOV if camera exists and UI element is ready
if Workspace.CurrentCamera and FovSliderElement and FovSliderElement.SetValue then
    -- Ensure slider matches the actual default FOV at start
    FovSliderElement:SetValue(Workspace.CurrentCamera.FieldOfView)
end
