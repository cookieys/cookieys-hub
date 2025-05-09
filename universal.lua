if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Allow game to settle

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService") -- Added for potential future use, good practice

-- Player related variables
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then -- Fallback if script runs before LocalPlayer is set
    LocalPlayer = Players.PlayerAdded:Wait()
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Load UI Library (Updated URL from WindUI example)
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

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

-- Variables to store current settings, initialized to defaults
local currentWalkSpeed = DEFAULT_WALKSPEED
local currentJumpPower = DEFAULT_JUMPPOWER
local currentFov = DEFAULT_FOV
local AntiAFKEnabled = false -- This variable already tracks Anti-AFK state

-- UI Element References (will be assigned when elements are created)
local AntiAFKToggleElement = nil
local WalkSpeedSliderElement = nil
local JumpPowerSliderElement = nil
local FovSliderElement = nil

-- Window Creation
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "cookie", -- Assuming "cookie" is a valid icon name in the new WindUI or you have it custom
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(400, 350),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678'", -- Minor text consistency with example
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
local AntiAFKConnection

local function StartAntiAFK()
    if AntiAFKConnection then AntiAFKConnection:Disconnect() end
    AntiAFKConnection = RunService.Stepped:Connect(function()
        if AntiAFKEnabled and LocalPlayer and LocalPlayer.Character then -- Add checks
            pcall(VirtualUser.Button2Down, VirtualUser, Enum.UserInputType.MouseButton2)
            task.wait(0.1) -- Short delay between down and up
            pcall(VirtualUser.Button2Up, VirtualUser, Enum.UserInputType.MouseButton2)
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
    else -- Try to get current character if previous reference is invalid
        local currentPlayer = Players.LocalPlayer
        if currentPlayer and currentPlayer.Character then
            local currentHumanoid = currentPlayer.Character:FindFirstChildOfClass("Humanoid")
            if currentHumanoid then
                 pcall(function()
                    currentHumanoid[propName] = value
                end)
            end
        end
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
            Icon = "loader-circle", -- Assuming this is a valid icon
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
                    Icon = "check-circle", -- Assuming this is a valid icon
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
    Value = AntiAFKEnabled, -- Changed from Default to Value, uses the state variable
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
        currentWalkSpeed = value -- Update stored value
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
        currentJumpPower = value -- Update stored value
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
        currentFov = value -- Update stored value
    end
})

-- Function to reset settings to default and update UI
local function ResetSettingsAndUI()
    -- Set Anti-AFK toggle and stop functionality
    AntiAFKEnabled = false -- Directly update state variable
    if AntiAFKToggleElement and AntiAFKToggleElement.SetValue then
        AntiAFKToggleElement:SetValue(false) -- This should trigger its callback to update AntiAFKEnabled and stop functionality
    else -- Fallback if SetValue isn't available or toggle element is nil
        StopAntiAFK() -- Ensure it's stopped
    end

    -- Reset WalkSpeed
    currentWalkSpeed = DEFAULT_WALKSPEED -- Update state variable
    SetHumanoidProperty("WalkSpeed", DEFAULT_WALKSPEED)
    if WalkSpeedSliderElement and WalkSpeedSliderElement.SetValue then
        WalkSpeedSliderElement:SetValue(DEFAULT_WALKSPEED) -- Assumed to trigger callback
    end

    -- Reset JumpPower
    currentJumpPower = DEFAULT_JUMPPOWER -- Update state variable
    SetHumanoidProperty("JumpPower", DEFAULT_JUMPPOWER)
    if JumpPowerSliderElement and JumpPowerSliderElement.SetValue then
        JumpPowerSliderElement:SetValue(DEFAULT_JUMPPOWER) -- Assumed to trigger callback
    end

    -- Reset FOV
    currentFov = DEFAULT_FOV -- Update state variable
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = DEFAULT_FOV
        if FovSliderElement and FovSliderElement.SetValue then
            FovSliderElement:SetValue(DEFAULT_FOV) -- Assumed to trigger callback
        end
    end
end

-- Reset settings if script is destroyed unexpectedly or player leaves
game:BindToClose(ResetSettingsAndUI)

-- Properly disconnect player-specific connections when player leaves
local playerRemovingConnection
playerRemovingConnection = LocalPlayer.Destroying:Connect(function()
    ResetSettingsAndUI()
    StopAntiAFK() -- Ensure AntiAFK is stopped
    if playerRemovingConnection then playerRemovingConnection:Disconnect() end
    -- Any other player-specific cleanup
end)


-- Handle character respawn to re-apply settings
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")

    task.wait(0.1) -- Small delay for stability

    -- Re-apply settings from the stored current values
    SetHumanoidProperty("WalkSpeed", currentWalkSpeed)
    SetHumanoidProperty("JumpPower", currentJumpPower)

    if Workspace.CurrentCamera then
         Workspace.CurrentCamera.FieldOfView = currentFov
    end
    -- Anti-AFK state is managed by its toggle and AntiAFKEnabled,
    -- if it was on, StartAntiAFK would have been called and connection exists
    -- or if it was off, StopAntiAFK would have been called.
    -- Re-calling StartAntiAFK if AntiAFKEnabled is true might be needed if connection is lost across respawns
    if AntiAFKEnabled then
        StartAntiAFK() -- Refresh Anti-AFK on new character if it was enabled
    end
end)

-- Initial application of FOV:
-- If the FovSliderElement is created and CurrentCamera exists,
-- set the slider's value to the current camera's FOV.
-- This also updates `currentFov` via the callback if SetValue triggers it.
task.defer(function() -- Defer to ensure UI elements are fully initialized
    if Workspace.CurrentCamera and FovSliderElement and FovSliderElement.SetValue then
        FovSliderElement:SetValue(Workspace.CurrentCamera.FieldOfView)
    end
end)
