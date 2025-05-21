if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Allow further game initialization

local success, windUiLib = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not windUiLib then
    warn("WindUI failed to load:", windUiLib)
    return
end

local WindUI = windUiLib

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui") -- For ESP elements if Drawing.new is not available/preferred for some

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function getCharacter(player)
    player = player or LocalPlayer
    return player and player.Character
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHumanoidRootPart(player)
    local char = getCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getInitialPlayerStats()
    local stats = {
        walkSpeed = 16,
        jumpHeight = 7.2, -- Roblox default JumpHeight
        fov = 70, -- Default FOV
    }
    local humanoid = getHumanoid()
    if humanoid then
        stats.walkSpeed = humanoid.WalkSpeed
        stats.jumpHeight = humanoid.JumpHeight
    else
        if LocalPlayer then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if char then
                humanoid = char:WaitForChild("Humanoid", 5)
                if humanoid then
                    stats.walkSpeed = humanoid.WalkSpeed
                    stats.jumpHeight = humanoid.JumpHeight
                end
            end
        end
    end
    if Camera then
        stats.fov = Camera.FieldOfView
    end
    return stats
end

local initialPlayerStats = getInitialPlayerStats()
local originalClockTime = Lighting.ClockTime
local originalSky = Lighting:FindFirstChildOfClass("Sky")
local originalFog = {
    End = Lighting.FogEnd,
    Start = Lighting.FogStart,
    Color = Lighting.FogColor,
}

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(600, 600), -- Adjusted size
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 190, -- Slightly wider sidebar for new tab
    HasOutline = false,
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678'. \nKeys are case-sensitive.",
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
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome!" }),
    PhantomTab = Window:Tab({ Title = "Phantom", Icon = "ghost", Desc = "Player modification features." }),
    VisualsTab = Window:Tab({ Title = "Visual & ESP", Icon = "eye", Desc = "Visual enhancements and ESP." }),
    SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "Configure UI settings." }),
}

Window:SelectTab(1)

-- Home Tab Content
local DISCORD_INVITE_URL = "https://discord.gg/ee4veXxYFZ"
Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        if typeof(setclipboard) == "function" then
            local successSet, errMessage = pcall(setclipboard, DISCORD_INVITE_URL)
            if successSet then WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied.", Icon = "clipboard-check", Duration = 3 })
            else WindUI:Notify({ Title = "Error", Content = "Failed to copy: " .. tostring(errMessage), Icon = "triangle-alert", Duration = 5 }); warn("setclipboard failed:", errMessage) end
        else WindUI:Notify({ Title = "Clipboard Unavailable", Content = "setclipboard not available.", Icon = "triangle-alert", Duration = 5 }); warn("setclipboard function not available.") end
    end
})

-- Phantom Tab Content
local isFlying = false
local flyConnection = nil
local bodyGyro, bodyVelocity = nil, nil
local flySpeed = 50

local isNoclipping = false
local noclipConnection = nil
local originalCollisions = {}

local originalLightingAmbient = Lighting.Ambient -- Store for fullbright
local isFullbright = false
local antiAfkConnection, isAntiAfkActive = nil, false
local clickTeleportActive, clickTpConnection = false, nil

Tabs.PhantomTab:Slider({ Title = "WalkSpeed", Value = { Min = 1, Max = 500, Default = initialPlayerStats.walkSpeed }, Callback = function(v) local h=getHumanoid() if h then h.WalkSpeed=v end end })
Tabs.PhantomTab:Slider({ Title = "JumpHeight", Value = { Min = 0, Max = 300, Default = initialPlayerStats.jumpHeight }, Callback = function(v) local h=getHumanoid() if h then h.JumpHeight=v end end })
Tabs.PhantomTab:Slider({ Title = "Fly Speed", Value = { Min = 10, Max = 500, Default = 50 }, Callback = function(v) flySpeed = v end })

Tabs.PhantomTab:Toggle({
    Title = "Fly", Value = isFlying,
    Callback = function(state)
        isFlying = state
        local humanoid = getHumanoid()
        local hrp = getHumanoidRootPart()

        if isFlying and hrp and humanoid then
            if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end
            if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end

            bodyGyro = Instance.new("BodyGyro", hrp)
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 20000; bodyGyro.D = 500
            
            bodyVelocity = Instance.new("BodyVelocity", hrp)
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(0,0,0)
            bodyVelocity.P = 1250

            humanoid.PlatformStand = true
            if flyConnection then flyConnection:Disconnect() end
            flyConnection = RunService.Heartbeat:Connect(function()
                if not isFlying or not hrp or not hrp.Parent or not humanoid or not humanoid.Parent then
                    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
                    if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy(); bodyGyro = nil end
                    if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy(); bodyVelocity = nil end
                    if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
                    return
                end
                
                local cam = Camera
                if not cam then return end
                bodyGyro.CFrame = cam.CFrame

                local moveVector = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then moveVector = moveVector - Vector3.new(0,1,0) end
                
                if moveVector.Magnitude > 0.01 then bodyVelocity.Velocity = moveVector.Unit * flySpeed
                else bodyVelocity.Velocity = Vector3.new(0,0,0) end
            end)
        else
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
            if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy(); bodyGyro = nil end
            if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy(); bodyVelocity = nil end
            if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Noclip", Value = isNoclipping,
    Callback = function(state)
        isNoclipping = state; local char = getCharacter()
        if not char then return end
        if isNoclipping then
            originalCollisions = {}; if noclipConnection then noclipConnection:Disconnect() end
            noclipConnection = RunService.Stepped:Connect(function()
                if not isNoclipping or not char or not char.Parent then if noclipConnection then noclipConnection:Disconnect(); noclipConnection=nil end for p,c in pairs(originalCollisions) do if p and p.Parent then pcall(function() p.CanCollide=c end) end end; originalCollisions={}; return end
                for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then if originalCollisions[part]==nil then originalCollisions[part]=part.CanCollide end pcall(function() part.CanCollide=false end) end end
            end)
        else
            if noclipConnection then noclipConnection:Disconnect(); noclipConnection=nil end
            for p,c in pairs(originalCollisions) do if p and p.Parent then pcall(function() p.CanCollide=c end) end end; originalCollisions={}
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Fullbright", Value = isFullbright,
    Callback = function(state)
        isFullbright = state
        if isFullbright then
            originalLightingAmbient = Lighting.Ambient -- Save current ambient before changing
            Lighting.Ambient = Color3.fromRGB(128, 128, 128) -- Brighter ambient
            Lighting.Brightness = 0.5 -- Slightly increase brightness
            if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Parent = nil end -- Remove atmosphere for better effect
        else
            Lighting.Ambient = originalLightingAmbient
            Lighting.Brightness = initialPlayerStats.lightingBrightness or Lighting.Brightness -- Restore if saved, or keep current
            -- Potentially restore atmosphere if a copy was kept
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Anti AFK", Value = isAntiAfkActive,
    Callback = function(state)
        isAntiAfkActive = state
        if isAntiAfkActive then
            if antiAfkConnection then antiAfkConnection:Disconnect() end 
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                if isAntiAfkActive then pcall(function() VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game) task.wait(0.1) VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game) WindUI:Notify({Title="Anti-AFK",Content="Idle detected.",Duration=2,Icon="zap"}) end)
                elseif not isAntiAfkActive and antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection=nil end
            end) WindUI:Notify({Title="Anti-AFK Enabled",Content="No longer kicked for idling.",Duration=3,Icon="shield-check"})
        else
            if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection=nil end
            WindUI:Notify({Title="Anti-AFK Disabled",Content="Can be kicked for idling.",Duration=3,Icon="shield-off"})
        end
    end
})

Tabs.PhantomTab:Toggle({
    Title = "Click Teleport", Value = clickTeleportActive,
    Callback = function(state)
        clickTeleportActive = state; local mouse = LocalPlayer:GetMouse()
        if clickTeleportActive then
            if clickTpConnection then clickTpConnection:Disconnect() end
            clickTpConnection = mouse.Button1Down:Connect(function()
                if clickTeleportActive and getHumanoidRootPart() then getHumanoidRootPart().CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
                elseif not clickTeleportActive and clickTpConnection then clickTpConnection:Disconnect(); clickTpConnection=nil end
            end) WindUI:Notify({Title="Click TP Enabled",Content="Click to teleport.",Duration=3,Icon="mouse-pointer-click"})
        else
            if clickTpConnection then clickTpConnection:Disconnect(); clickTpConnection=nil end
            WindUI:Notify({Title="Click TP Disabled",Content="Click TP off.",Duration=3,Icon="mouse-pointer-off"})
        end
    end
})


-- Visuals & ESP Tab
local espSettings = {
    enabled = false, -- Master switch for all ESP drawings
    box = false,
    name = false,
    health = false,
    tracer = false,
    chams = false,
    color = Color3.fromRGB(0, 255, 0),
    fov = initialPlayerStats.fov,
    removeFog = false,
    noSky = false,
    timeOfDay = originalClockTime
}
local espDrawings = {} -- store Drawing.new objects
local chamsHighlights = {} -- store Highlight objects for chams
local espRenderConnection = nil

Tabs.VisualsTab:Section({ Title = "Player ESP" })
local espMasterToggle = Tabs.VisualsTab:Toggle({Title = "Enable Player ESP", Value = espSettings.enabled, Callback = function(v) espSettings.enabled = v end})
Tabs.VisualsTab:Toggle({Title = "Box ESP", Value = espSettings.box, Callback = function(v) espSettings.box = v end})
Tabs.VisualsTab:Toggle({Title = "Name ESP", Value = espSettings.name, Callback = function(v) espSettings.name = v end})
Tabs.VisualsTab:Toggle({Title = "Health ESP", Value = espSettings.health, Callback = function(v) espSettings.health = v end})
Tabs.VisualsTab:Toggle({Title = "Tracer ESP", Value = espSettings.tracer, Callback = function(v) espSettings.tracer = v end})
Tabs.VisualsTab:Toggle({Title = "Chams", Value = espSettings.chams, Callback = function(v) espSettings.chams = v end})
Tabs.VisualsTab:Colorpicker({Title = "ESP Color", Default = espSettings.color, Callback = function(v) espSettings.color = v end})

Tabs.VisualsTab:Section({ Title = "General Visuals" })
Tabs.VisualsTab:Slider({Title = "FOV Changer", Value = {Min = 30, Max = 120, Default = espSettings.fov}, Callback = function(v) espSettings.fov = v; if Camera then Camera.FieldOfView = v end end})
Tabs.VisualsTab:Toggle({Title = "Remove Fog", Value = espSettings.removeFog, Callback = function(v)
    espSettings.removeFog = v
    if espSettings.removeFog then
        Lighting.FogEnd = 1000000; Lighting.FogStart = Lighting.FogEnd - 1
    else
        Lighting.FogEnd = originalFog.End; Lighting.FogStart = originalFog.Start; Lighting.FogColor = originalFog.Color
    end
end})

Tabs.VisualsTab:Section({ Title = "World Visuals" })
Tabs.VisualsTab:Toggle({Title = "No Sky", Value = espSettings.noSky, Callback = function(v)
    espSettings.noSky = v
    local currentSky = Lighting:FindFirstChildOfClass("Sky")
    if espSettings.noSky then
        if currentSky then currentSky.Parent = nil end
    else
        if not currentSky and originalSky then originalSky.Parent = Lighting end
    end
end})
Tabs.VisualsTab:Slider({Title = "Time of Day", Value = {Min = 0, Max = 24, Default = tonumber(string.sub(originalClockTime, 1, 2)) or 12}, Callback = function(v)
    espSettings.timeOfDay = v
    Lighting.ClockTime = v
end})

local function clearEspForPlayer(player)
    if espDrawings[player] then
        for _, drawing in pairs(espDrawings[player]) do
            if drawing and typeof(drawing.Remove) == "function" then drawing:Remove() elseif drawing and drawing.Parent then drawing.Parent = nil end
        end
        espDrawings[player] = nil
    end
    if chamsHighlights[player] then
        for _, highlight in pairs(chamsHighlights[player]) do
            if highlight and highlight.Parent then highlight:Destroy() end
        end
        chamsHighlights[player] = nil
    end
end

local function updateEsp()
    if not espSettings.enabled then
        for player, _ in pairs(espDrawings) do clearEspForPlayer(player) end
        for player, _ in pairs(chamsHighlights) do clearEspForPlayer(player) end
        return
    end

    local currentPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            currentPlayers[player] = true
            if not espDrawings[player] then espDrawings[player] = {} end
            if not chamsHighlights[player] then chamsHighlights[player] = {} end

            local char = player.Character
            local hrp = char.HumanoidRootPart
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")

            -- Chams
            if espSettings.chams then
                if not chamsHighlights[player].main then
                    local highlight = Instance.new("Highlight")
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = char
                    chamsHighlights[player].main = highlight
                end
                chamsHighlights[player].main.FillColor = espSettings.color
                chamsHighlights[player].main.OutlineColor = espSettings.color
                chamsHighlights[player].main.FillTransparency = 0.6
                chamsHighlights[player].main.OutlineTransparency = 0.3
            elseif chamsHighlights[player].main then
                chamsHighlights[player].main:Destroy()
                chamsHighlights[player].main = nil
            end

            if not head then continue end -- Need head for good screen pos

            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local textYOffset = 0

                -- Box ESP
                if espSettings.box then
                    if not espDrawings[player].box then espDrawings[player].box = Drawing.new("Square"); espDrawings[player].box.Thickness = 1; espDrawings[player].box.Filled = false end
                    local size = Vector2.new(math.max(20, 600 / screenPos.Z), math.max(30, 900 / screenPos.Z)) -- Approximate size based on distance
                    espDrawings[player].box.Visible = true
                    espDrawings[player].box.Position = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2 - 10) -- Adjust Y for head
                    espDrawings[player].box.Size = size
                    espDrawings[player].box.Color = espSettings.color
                elseif espDrawings[player].box then espDrawings[player].box.Visible = false end
                
                -- Name ESP
                if espSettings.name then
                    if not espDrawings[player].name then espDrawings[player].name = Drawing.new("Text"); espDrawings[player].name.Center = true; espDrawings[player].name.Outline = true end
                    espDrawings[player].name.Visible = true
                    espDrawings[player].name.Text = player.DisplayName or player.Name
                    espDrawings[player].name.Position = Vector2.new(screenPos.X, screenPos.Y - 30 + textYOffset) -- Above head
                    espDrawings[player].name.Size = 14
                    espDrawings[player].name.Color = espSettings.color
                    espDrawings[player].name.OutlineColor = Color3.new(0,0,0)
                    textYOffset = textYOffset - 15
                elseif espDrawings[player].name then espDrawings[player].name.Visible = false end

                -- Health ESP
                if espSettings.health then
                    if not espDrawings[player].healthBarBg then espDrawings[player].healthBarBg = Drawing.new("Square"); espDrawings[player].healthBarBg.Filled = true; espDrawings[player].healthBarBg.Thickness = 0; end
                    if not espDrawings[player].healthBar then espDrawings[player].healthBar = Drawing.new("Square"); espDrawings[player].healthBar.Filled = true; espDrawings[player].healthBar.Thickness = 0; end
                    
                    local barWidth = 50; local barHeight = 5
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barX = screenPos.X - barWidth/2
                    local barY = screenPos.Y - 15 + textYOffset -- Below name

                    espDrawings[player].healthBarBg.Visible = true
                    espDrawings[player].healthBarBg.Position = Vector2.new(barX, barY)
                    espDrawings[player].healthBarBg.Size = Vector2.new(barWidth, barHeight)
                    espDrawings[player].healthBarBg.Color = Color3.fromRGB(50,50,50)

                    espDrawings[player].healthBar.Visible = true
                    espDrawings[player].healthBar.Position = Vector2.new(barX, barY)
                    espDrawings[player].healthBar.Size = Vector2.new(barWidth * healthPercent, barHeight)
                    espDrawings[player].healthBar.Color = Color3.fromHSV(0.33 * healthPercent, 1, 1) -- Green to Red
                elseif espDrawings[player].healthBar then espDrawings[player].healthBar.Visible = false; espDrawings[player].healthBarBg.Visible = false end

                -- Tracer ESP
                if espSettings.tracer then
                    if not espDrawings[player].tracer then espDrawings[player].tracer = Drawing.new("Line"); espDrawings[player].tracer.Thickness = 1 end
                    espDrawings[player].tracer.Visible = true
                    espDrawings[player].tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Bottom center
                    espDrawings[player].tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    espDrawings[player].tracer.Color = espSettings.color
                elseif espDrawings[player].tracer then espDrawings[player].tracer.Visible = false end
            else -- Player not on screen
                clearEspForPlayer(player) -- Clear drawings if off-screen to avoid clutter, or just set Visible = false
            end
        else
            clearEspForPlayer(player) -- Player left or character died
        end
    end
    -- Cleanup for players who left
    for player, _ in pairs(espDrawings) do if not currentPlayers[player] then clearEspForPlayer(player) end end
    for player, _ in pairs(chamsHighlights) do if not currentPlayers[player] then clearEspForPlayer(player) end end
end

if typeof(Drawing) == "nil" then -- Fallback or warning if Drawing API is not available
    WindUI:Notify({Title="ESP Warning", Content="Drawing API not found. ESP will not function.", Icon="alert-triangle", Duration=10})
    espMasterToggle:SetValue(false)
    espSettings.enabled = false
    -- You could disable the ESP toggles here if Drawing.new is essential and missing
else
    espRenderConnection = RunService.RenderStepped:Connect(updateEsp)
end


-- Settings Tab Content
local themeValues = {}
for themeName, _ in pairs(WindUI:GetThemes()) do table.insert(themeValues, themeName) end; table.sort(themeValues)
local currentTheme = WindUI:GetCurrentTheme()
Tabs.SettingsTab:Dropdown({Title="UI Theme", Values=themeValues, Value=currentTheme, Multi=false, AllowNone=false, Callback=function(sT)
    if WindUI:GetThemes()[sT] then WindUI:SetTheme(sT); currentTheme=sT; WindUI:Notify({Title="Theme Changed",Content="Set to "..sT,Icon="palette",Duration=3})
    else WindUI:Notify({Title="Error",Content="Theme '"..sT.."' not found.",Icon="triangle-alert",Duration=5}) end
end})
Tabs.SettingsTab:Toggle({Title="Window Transparency", Value=Window.Transparent, Callback=function(iT)
    Window:ToggleTransparency(iT); WindUI:Notify({Title="Transparency "..(iT and "On" or "Off"),Icon=iT and "eye" or "eye-off",Duration=3})
end})


local function cleanupFeatures()
    if flyConnection then flyConnection:Disconnect() end; if noclipConnection then noclipConnection:Disconnect() end
    if antiAfkConnection then antiAfkConnection:Disconnect() end; if clickTpConnection then clickTpConnection:Disconnect() end
    if espRenderConnection then espRenderConnection:Disconnect() end

    for player, _ in pairs(espDrawings) do clearEspForPlayer(player) end; espDrawings = {}
    for player, _ in pairs(chamsHighlights) do clearEspForPlayer(player) end; chamsHighlights = {}

    if isFlying and getHumanoid() then getHumanoid().PlatformStand = false end
    if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end; if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end
    
    if isNoclipping then for p,c in pairs(originalCollisions) do if p and p.Parent then pcall(function() p.CanCollide=c end) end end end
    
    if isFullbright then Lighting.Ambient = originalLightingAmbient; Lighting.Brightness = initialPlayerStats.lightingBrightness or Lighting.Brightness end
    
    if Camera then Camera.FieldOfView = initialPlayerStats.fov end -- Restore FOV
    if espSettings.removeFog then Lighting.FogEnd = originalFog.End; Lighting.FogStart = originalFog.Start; Lighting.FogColor = originalFog.Color end -- Restore Fog
    if espSettings.noSky and originalSky then originalSky.Parent = Lighting end -- Restore Sky
    Lighting.ClockTime = originalClockTime -- Restore time

    -- Restore any other modified lighting properties
    local defaultLighting = getInitialPlayerStats().originalLighting
    if defaultLighting then
        for prop, value in pairs(defaultLighting) do
            pcall(function() Lighting[prop] = value end)
        end
    end
end

-- Attempt to get script instance for proper cleanup on destroy
local scriptInstance = getfenv().script 
if scriptInstance and typeof(scriptInstance.Destroying) == "RBXScriptSignal" then
    scriptInstance.Destroying:Connect(cleanupFeatures)
else -- Fallback for environments where script might not be standard
    game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then -- Player is being removed
            cleanupFeatures()
        end
    end)
    -- Also consider adding a manual destroy button or command if scriptInstance is unreliable
end
