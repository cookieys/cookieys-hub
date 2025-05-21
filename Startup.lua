if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Allow further game initialization

local success, windUiLib = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not windUiLib then
    warn("WindUI failed to load:", windUiLib) -- Log error if HttpGet or loadstring fails
    return -- Exit if the UI library cannot be loaded
end

local WindUI = windUiLib

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys", -- Folder for saving configurations
    Size = UDim2.fromOffset(50, 50), -- Adjusted size for more content + fly speed slider
    Transparent = true,
    Theme = "Dark", -- Available themes: "Dark", "Light", "Nord", etc.
    SideBarWidth = 180,
    HasOutline = false, -- Window outline
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678'. \nKeys are case-sensitive.",
        URL = "https://github.com/Footagesus/WindUI", -- URL for key information or acquisition
        SaveKey = true, -- Whether to save the entered key
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
    PhantomTab = Window:Tab({ Title = "Phantom", Icon = "ghost", Desc = "Player modification features." }),
    SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "Configure UI settings." }),
}

Window:SelectTab(1) -- Automatically select the first tab (HomeTab)

-- Player and Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- For Anti-AFK

local LocalPlayer = Players.LocalPlayer

-- Home Tab Content
local DISCORD_INVITE_URL = "https://discord.gg/ee4veXxYFZ"

Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        if typeof(setclipboard) == "function" then
            local successSet, errMessage = pcall(setclipboard, DISCORD_INVITE_URL)
            if successSet then
                WindUI:Notify({
                    Title = "Link Copied!",
                    Content = "Discord invite link copied to clipboard.",
                    Icon = "clipboard-check",
                    Duration = 3,
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to copy link: " .. tostring(errMessage),
                    Icon = "triangle-alert",
                    Duration = 5,
                })
                warn("setclipboard failed:", errMessage)
            end
        else
            WindUI:Notify({
                Title = "Clipboard Unavailable",
                Content = "Could not copy link (setclipboard is not available).",
                Icon = "triangle-alert",
                Duration = 5,
            })
            warn("setclipboard function not available in this environment.")
        end
    end
})

-- Phantom Tab Content
local isFlying = false
local flyConnection = nil
local bodyGyro = nil
local bodyVelocity = nil
local flySpeed = 50 -- Default fly speed, will be controlled by slider

local isNoclipping = false
local noclipConnection = nil
local originalCollisions = {}

local originalLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ShadowSoftness = Lighting.ShadowSoftness,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    ColorShift_Top = Lighting.ColorShift_Top,
}
local isFullbright = false

local antiAfkConnection = nil
local isAntiAfkActive = false

local clickTeleportActive = false
local clickTpConnection = nil

local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHumanoidRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end


Tabs.PhantomTab:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

Tabs.PhantomTab:Slider({
    Title = "JumpHeight",
    Desc = "Controls how high the player jumps.",
    Value = { Min = 0, Max = 200, Default = 7.2 }, -- Standard JumpHeight is 7.2
    Callback = function(value)
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.JumpHeight = value
        end
    end
})

Tabs.PhantomTab:Slider({
    Title = "Fly Speed",
    Value = { Min = 10, Max = 500, Default = 50 },
    Callback = function(value)
        flySpeed = value
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Fly",
    Value = isFlying,
    Callback = function(state)
        isFlying = state
        local humanoid = getHumanoid()
        local hrp = getHumanoidRootPart()

        if isFlying and hrp and humanoid then
            if bodyGyro then bodyGyro:Destroy() end
            if bodyVelocity then bodyVelocity:Destroy() end

            bodyGyro = Instance.new("BodyGyro", hrp)
            bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bodyGyro.P = 20000
            bodyGyro.D = 500 
            
            bodyVelocity = Instance.new("BodyVelocity", hrp)
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.P = 1250

            if flyConnection then flyConnection:Disconnect() end
            flyConnection = RunService.Heartbeat:Connect(function()
                if not isFlying or not hrp or not hrp.Parent or not humanoid or not humanoid.Parent then
                    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
                    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
                    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
                    if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
                    return
                end
                
                local camera = workspace.CurrentCamera
                if not camera then return end

                bodyGyro.CFrame = camera.CFrame -- Player model faces where camera is looking

                local finalMoveVector = Vector3.new()
                
                -- Primary input from Humanoid.MoveDirection (for joystick/standard WASD)
                -- Humanoid.MoveDirection gives X for strafe, Z for forward/back. Z is -1 for forward.
                local playerMoveDirection = humanoid.MoveDirection 
                if playerMoveDirection.Magnitude > 0.01 then
                    finalMoveVector = finalMoveVector + (camera.CFrame.RightVector * playerMoveDirection.X) -- Strafe based on X component
                    finalMoveVector = finalMoveVector + (camera.CFrame.LookVector * -playerMoveDirection.Z) -- Forward/Backward based on Z component
                else 
                    -- Fallback to direct keyboard checks if MoveDirection is zero (e.g., for some specific PC cases or if humanoid is not processing it)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then finalMoveVector = finalMoveVector + camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then finalMoveVector = finalMoveVector - camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then finalMoveVector = finalMoveVector - camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then finalMoveVector = finalMoveVector + camera.CFrame.RightVector end
                end
                
                -- Vertical movement (always from keys, assuming mobile has buttons for these)
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then finalMoveVector = finalMoveVector + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then finalMoveVector = finalMoveVector - Vector3.new(0,1,0) end
                
                if finalMoveVector.Magnitude > 0 then
                    bodyVelocity.Velocity = finalMoveVector.Unit * flySpeed
                else
                    bodyVelocity.Velocity = Vector3.new(0,0,0)
                end
                humanoid.PlatformStand = true -- Helps prevent some physics interactions and standard humanoid behavior
            end)
        else
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
            if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
            if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
            if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Noclip",
    Value = isNoclipping,
    Callback = function(state)
        isNoclipping = state
        local char = getCharacter()
        if not char then return end

        if isNoclipping then
            originalCollisions = {}
            if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = RunService.Stepped:Connect(function()
                if not isNoclipping or not char or not char.Parent then
                    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
                    for part, canCollide in pairs(originalCollisions) do
                        if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
                    end
                    originalCollisions = {}
                    return
                end
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if originalCollisions[part] == nil then
                            originalCollisions[part] = part.CanCollide
                        end
                        pcall(function() part.CanCollide = false end)
                    end
                end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
            for part, canCollide in pairs(originalCollisions) do
                 if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
            end
            originalCollisions = {}
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Fullbright",
    Value = isFullbright,
    Callback = function(state)
        isFullbright = state
        if isFullbright then
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.Brightness = 0.8
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
            Lighting.ShadowSoftness = 0
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Lighting.ColorShift_Top = Color3.fromRGB(255,255,255)
        else
            Lighting.Ambient = originalLighting.Ambient
            Lighting.Brightness = originalLighting.Brightness
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            Lighting.ShadowSoftness = originalLighting.ShadowSoftness
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart
            Lighting.ColorShift_Top = originalLighting.ColorShift_Top
        end
    end
})


Tabs.PhantomTab:Toggle({
    Title = "Anti AFK",
    Value = isAntiAfkActive,
    Callback = function(state)
        isAntiAfkActive = state
        if isAntiAfkActive then
            if antiAfkConnection then antiAfkConnection:Disconnect() end 
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                if isAntiAfkActive and LocalPlayer and LocalPlayer.Parent then
                    pcall(function() 
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                         WindUI:Notify({ Title = "Anti-AFK", Content = "Idle detected, sent keep-alive input.", Duration = 2, Icon = "zap" })
                    end)
                elseif not isAntiAfkActive then -- Double check state inside event
                    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
                end
            end)
            WindUI:Notify({ Title = "Anti-AFK Enabled", Content = "You will no longer be kicked for idling.", Duration = 3, Icon = "shield-check" })
        else
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
            WindUI:Notify({ Title = "Anti-AFK Disabled", Content = "You can now be kicked for idling.", Duration = 3, Icon = "shield-off" })
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Click Teleport",
    Desc = "When active, click anywhere to teleport.",
    Value = clickTeleportActive,
    Callback = function(state)
        clickTeleportActive = state
        local mouse = LocalPlayer:GetMouse()
        if clickTeleportActive then
            if clickTpConnection then clickTpConnection:Disconnect() end 
            clickTpConnection = mouse.Button1Down:Connect(function()
                if clickTeleportActive and LocalPlayer and LocalPlayer.Parent then
                    local hrp = getHumanoidRootPart()
                    if hrp then
                        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) 
                    else
                        WindUI:Notify({ Title = "Click TP Error", Content = "Character or HumanoidRootPart not found.", Duration = 3, Icon="alert-triangle"})
                    end
                elseif not clickTeleportActive then -- Double check state
                     if clickTpConnection then clickTpConnection:Disconnect(); clickTpConnection = nil end
                end
            end)
            WindUI:Notify({ Title = "Click TP Enabled", Content = "Click on the world to teleport.", Duration = 3, Icon = "mouse-pointer-click" })
        else
            if clickTpConnection then
                clickTpConnection:Disconnect()
                clickTpConnection = nil
            end
            WindUI:Notify({ Title = "Click TP Disabled", Content = "Click teleportation is now off.", Duration = 3, Icon = "mouse-pointer-off" })
        end
    end
})


-- Settings Tab Content
local themeValues = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, themeName)
end
table.sort(themeValues)

local currentTheme = WindUI:GetCurrentTheme()

Tabs.SettingsTab:Dropdown({
    Title = "UI Theme",
    Values = themeValues,
    Value = currentTheme,
    Multi = false,
    AllowNone = false,
    Callback = function(selectedTheme)
        if WindUI:GetThemes()[selectedTheme] then
            WindUI:SetTheme(selectedTheme)
            currentTheme = selectedTheme
            WindUI:Notify({
                Title = "Theme Changed",
                Content = "UI theme set to " .. selectedTheme .. ".",
                Icon = "palette",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Selected theme '" .. selectedTheme .. "' not found.",
                Icon = "triangle-alert",
                Duration = 5
            })
        end
    end
})

Tabs.SettingsTab:Toggle({
    Title = "Window Transparency",
    Value = Window.Transparent,
    Callback = function(isTransparent)
        Window:ToggleTransparency(isTransparent)
        WindUI:Notify({
            Title = "Transparency " .. (isTransparent and "Enabled" or "Disabled"),
            Content = "Window transparency has been " .. (isTransparent and "enabled." or "disabled."),
            Icon = isTransparent and "eye" or "eye-off",
            Duration = 3
        })
    end
})

local function cleanupFeatures()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
    if clickTpConnection then clickTpConnection:Disconnect(); clickTpConnection = nil end

    if isFlying then -- Restore fly state
        local humanoid = getHumanoid()
        if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
        if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end; bodyGyro = nil
        if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end; bodyVelocity = nil
        isFlying = false -- Ensure state variable is reset
    end

    if isNoclipping then -- Restore noclip collisions
        for part, canCollide in pairs(originalCollisions) do
            if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
        end
        originalCollisions = {}
        isNoclipping = false
    end
    
    if isFullbright then -- Restore fullbright
        Lighting.Ambient = originalLighting.Ambient
        Lighting.Brightness = originalLighting.Brightness
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.ShadowSoftness = originalLighting.ShadowSoftness
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.FogStart = originalLighting.FogStart
        Lighting.ColorShift_Top = originalLighting.ColorShift_Top
        isFullbright = false
    end

    if isAntiAfkActive then isAntiAfkActive = false end
    if clickTeleportActive then clickTeleportActive = false end
end

-- Cleanup on script removal or error
local currentScript = getfenv().script
if currentScript then
    currentScript.Destroying:Connect(cleanupFeatures)
end
-- Fallback for environments where Destroying might not fire as expected or script is nil
-- game:GetService("ScriptContext").Error:Connect(cleanupFeatures) -- This might be too broad
-- A manual cleanup button in the UI or relying on game rejoining is often more practical for exploits.
-- For now, the Destroying event is the most direct approach.
