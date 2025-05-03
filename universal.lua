if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2)

local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

-- Player related variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Detect and Store Default Values
local DEFAULT_WALKSPEED = Humanoid and Humanoid.WalkSpeed or 16
local DEFAULT_JUMPPOWER = Humanoid and Humanoid.JumpPower or 50
local DEFAULT_FOV = 70

print("Detected Default WalkSpeed:", DEFAULT_WALKSPEED)
print("Detected Default JumpPower:", DEFAULT_JUMPPOWER)

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "cookie", -- Changed Icon
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(400, 350), -- Slightly wider window
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
local VirtualUser = game:GetService("VirtualUser")
local AntiAFKEnabled = false
local AntiAFKConnection

local function StartAntiAFK()
    if AntiAFKConnection then AntiAFKConnection:Disconnect() end
    AntiAFKConnection = game:GetService("RunService").Stepped:Connect(function()
        if AntiAFKEnabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    LocalPlayer.Idled:Connect(function()
        if AntiAFKEnabled then
           VirtualUser:CaptureController()
           VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    print("Anti AFK Started")
end

local function StopAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
        print("Anti AFK Stopped")
    end
end

-- Function to safely set humanoid properties
local function SetHumanoidProperty(propName, value)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum[propName] = value
            end)
        end
    end
end

-- Tabs Definition
local Tabs = {
    MainTab = Window:Tab({ Title = "Main", Icon = "star", Desc = "Core features and utilities." }), -- New Main Tab
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "Adjust script settings." })
}

Window:SelectTab(1) -- Select Main tab by default

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
        task.spawn(function() -- Spawn in a new thread to prevent UI freeze
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

-- Settings Tab Content
Tabs.SettingsTab:Toggle({
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

Tabs.SettingsTab:Slider({
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

Tabs.SettingsTab:Slider({
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

Tabs.SettingsTab:Slider({
    Title = "FOV Changer",
    Desc = "Adjust your camera Field of View.",
    Value = {
        Min = 1,
        Max = 120,
        Default = DEFAULT_FOV,
    },
    Callback = function(value)
        if game.Workspace and game.Workspace.CurrentCamera then
            game.Workspace.CurrentCamera.FieldOfView = value
        end
    end
})

-- Function to reset settings to default
local function ResetSettings()
    if AntiAFKEnabled then
        StopAntiAFK()
    end
    SetHumanoidProperty("WalkSpeed", DEFAULT_WALKSPEED)
    SetHumanoidProperty("JumpPower", DEFAULT_JUMPPOWER)
    if game.Workspace and game.Workspace.CurrentCamera then
        game.Workspace.CurrentCamera.FieldOfView = DEFAULT_FOV
    end
end

-- Handle window closing to reset settings
local oldDestroy = Window.Destroy
function Window:Destroy()
    ResetSettings()
    oldDestroy(Window)
end

-- Reset settings if script is destroyed unexpectedly
LocalPlayer.Destroying:Connect(ResetSettings)

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")

    local currentWalkSpeedSliderValue -- Need to get this from the UI element if possible
    local currentJumpPowerSliderValue -- Need to get this from the UI element if possible
    local currentFovSliderValue -- Need to get this from the UI element if possible

    task.wait(0.1) -- Small delay to ensure humanoid properties are stable

    -- Re-apply current settings from sliders (if they exist and values are stored/accessible)
    -- If not accessible, they will retain the value set before death,
    -- and the sliders will re-apply them next time they are moved.
    -- For now, just ensure the humanoid ref is updated. The sliders' callbacks will handle applying values.
    -- Example of re-applying (requires storing the value):
    -- if currentWalkSpeedSliderValue then SetHumanoidProperty("WalkSpeed", currentWalkSpeedSliderValue) end
    -- if currentJumpPowerSliderValue then SetHumanoidProperty("JumpPower", currentJumpPowerSliderValue) end
    -- if currentFovSliderValue and game.Workspace.CurrentCamera then game.Workspace.CurrentCamera.FieldOfView = currentFovSliderValue end

     -- Optionally re-detect defaults if needed, but usually not necessary unless game explicitly changes them.
     -- DEFAULT_WALKSPEED = Humanoid.WalkSpeed
     -- DEFAULT_JUMPPOWER = Humanoid.JumpPower

     -- Reset sliders visually to current humanoid/camera values if they differ from the slider's internal value
     -- (Requires access to slider:SetValue methods)
end)