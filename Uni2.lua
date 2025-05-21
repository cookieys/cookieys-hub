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
local CoreGui = game:GetService("CoreGui")    

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

local initialPlayerStats = {
    walkSpeed = 16,
    jumpHeight = 7.2, 
    jumpPower = 50, -- Roblox default JumpPower for older games
    fov = 70,
    lightingBrightness = Lighting.Brightness, -- Store initial brightness
    originalLighting = {} -- For more detailed lighting restoration
}

-- Capture more original lighting settings
for _, prop in ipairs({"Ambient", "Brightness", "GlobalShadows", "OutdoorAmbient", "ShadowSoftness", "FogEnd", "FogStart", "ColorShift_Top"}) do
    initialPlayerStats.originalLighting[prop] = Lighting[prop]
end


local function fetchDynamicInitialStats()
    local humanoid = getHumanoid()
    if humanoid then
        initialPlayerStats.walkSpeed = humanoid.WalkSpeed
        initialPlayerStats.jumpHeight = humanoid.JumpHeight
        initialPlayerStats.jumpPower = humanoid.JumpPower
    else
        if LocalPlayer then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if char then
                humanoid = char:WaitForChild("Humanoid", 5)
                if humanoid then
                    initialPlayerStats.walkSpeed = humanoid.WalkSpeed
                    initialPlayerStats.jumpHeight = humanoid.JumpHeight
                    initialPlayerStats.jumpPower = humanoid.JumpPower
                end
            end
        end
    end
    if Camera then
        initialPlayerStats.fov = Camera.FieldOfView
    end
end

fetchDynamicInitialStats() -- Fetch stats once after player might be ready

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
    Size = UDim2.fromOffset(300, 300), -- Changed UI Size
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 190,
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

local isFlying, flyConnection, bodyGyro, bodyVelocity = false, nil, nil, nil
local flySpeed = 50
local isNoclipping, noclipConnection, originalCollisions = false, nil, {}
local isFullbright = false
local antiAfkConnection, isAntiAfkActive = nil, false
local clickTeleportActive, clickTpConnection = false, nil

Tabs.PhantomTab:Slider({ Title = "WalkSpeed", Value = { Min = 1, Max = 500, Default = initialPlayerStats.walkSpeed }, Callback = function(v) local h=getHumanoid(); if h then h.WalkSpeed=v; initialPlayerStats.walkSpeed = v; end end })
Tabs.PhantomTab:Slider({ 
    Title = "Jump Power/Height", 
    Desc="Adjusts JumpPower (older games) or JumpHeight (modern games).", 
    Value = { Min = 0, Max = 500, Default = initialPlayerStats.jumpPower or initialPlayerStats.jumpHeight }, 
    Callback = function(v) 
        local h = getHumanoid(); 
        if h then 
            -- Attempt to set JumpPower first for broader compatibility
            pcall(function() h.JumpPower = v end) 
            -- Then set JumpHeight for modern games, if it exists
            pcall(function() h.JumpHeight = v * (7.2/50) end) -- Approximate conversion from JumpPower to JumpHeight ratio
            initialPlayerStats.jumpPower = v
            initialPlayerStats.jumpHeight = v * (7.2/50)
        end 
    end 
})
Tabs.PhantomTab:Slider({ Title = "Fly Speed", Value = { Min = 10, Max = 500, Default = 50 }, Callback = function(v) flySpeed = v end })

Tabs.PhantomTab:Toggle({
    Title = "Fly", Value = isFlying,
    Callback = function(state)
        isFlying = state
        local humanoid = getHumanoid()
        local hrp = getHumanoidRootPart()

        if isFlying and hrp and humanoid then
            if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy() end; bodyGyro = nil
            if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy() end; bodyVelocity = nil

            bodyGyro = Instance.new("BodyGyro", hrp)
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 20000; bodyGyro.D = 500
            
            bodyVelocity = Instance.new("BodyVelocity", hrp)
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(0,0,0)
            bodyVelocity.P = 1250 -- Lower P for less jitter, adjust as needed

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
                local cameraLookVector = cam.CFrame.LookVector
                local cameraRightVector = cam.CFrame.RightVector

                -- Normalize vectors to only affect XZ plane for horizontal movement
                local forward = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit
                local right = Vector3.new(cameraRightVector.X, 0, cameraRightVector.Z).Unit

                -- Keyboard input
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - right end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + right end
                
                -- Vertical movement
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then moveVector = moveVector - Vector3.new(0,1,0) end
                
                if moveVector.Magnitude > 0.001 then -- Use a small epsilon
                    bodyVelocity.Velocity = moveVector.Unit * flySpeed
                else
                    bodyVelocity.Velocity = Vector3.new(0,0,0)
                end
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
            Lighting.Ambient = Color3.fromRGB(160, 160, 160)
            Lighting.Brightness = 0.6
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
            -- Temporarily move Atmosphere to CoreGui to "disable" it without destroying
            if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Name = "Atmosphere_DISABLED_BY_FB"; Lighting.Atmosphere.Parent = CoreGui; end
        else
            for prop, value in pairs(initialPlayerStats.originalLighting) do
                    pcall(function() Lighting[prop] = value end)
            end
            -- Find and re-parent atmosphere if it was 'disabled'
            local disabledAtmosphere = CoreGui:FindFirstChild("Atmosphere_DISABLED_BY_FB")
            if disabledAtmosphere then disabledAtmosphere.Parent = Lighting; disabledAtmosphere.Name = "Atmosphere" end
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

local espSettings = { enabled = false, box = false, name = false, health = false, tracer = false, chams = false, color = Color3.fromRGB(0,255,0), fov = initialPlayerStats.fov, removeFog = false, noSky = false, timeOfDay = tonumber(string.sub(tostring(originalClockTime),1,2)) or 12 }
local espDrawings, chamsHighlights, espRenderConnection = {}, {}, nil

Tabs.VisualsTab:Section({ Title = "Player ESP" })
local espMasterToggle = Tabs.VisualsTab:Toggle({Title="Enable Player ESP",Value=espSettings.enabled,Callback=function(v)
    espSettings.enabled=v
    if v then
        if not espRenderConnection then
            if typeof(Drawing) == "nil" then
                WindUI:Notify({Title="ESP Warning",Content="Drawing API not found. ESP will not work.",Icon="alert-triangle",Duration=10})
                espMasterToggle:SetValue(false) -- Turn off the toggle if Drawing API is missing
                espSettings.enabled = false
            else
                espRenderConnection = RunService.RenderStepped:Connect(updateEsp)
                WindUI:Notify({Title="ESP Enabled",Content="Player ESP is now active.",Icon="eye",Duration=3})
            end
        end
    else
        if espRenderConnection then
            espRenderConnection:Disconnect()
            espRenderConnection = nil
        end
        -- Clear all existing drawings and highlights when ESP is disabled
        for player, drawings in pairs(espDrawings) do
            clearEspForPlayer(player)
        end
        for player, highlights in pairs(chamsHighlights) do
            clearEspForPlayer(player)
        end
        WindUI:Notify({Title="ESP Disabled",Content="Player ESP is now inactive.",Icon="eye-off",Duration=3})
    end
end})
Tabs.VisualsTab:Toggle({Title="Box ESP",Value=espSettings.box,Callback=function(v)espSettings.box=v end})
Tabs.VisualsTab:Toggle({Title="Name ESP",Value=espSettings.name,Callback=function(v)espSettings.name=v end})
Tabs.VisualsTab:Toggle({Title="Health ESP",Value=espSettings.health,Callback=function(v)espSettings.health=v end})
Tabs.VisualsTab:Toggle({Title="Tracer ESP",Value=espSettings.tracer,Callback=function(v)espSettings.tracer=v end})
Tabs.VisualsTab:Toggle({Title="Chams",Value=espSettings.chams,Callback=function(v)espSettings.chams=v end})
Tabs.VisualsTab:Colorpicker({Title="ESP Color",Default=espSettings.color,Callback=function(v)espSettings.color=v end})
Tabs.VisualsTab:Section({ Title = "General Visuals" })
Tabs.VisualsTab:Slider({Title="FOV Changer",Value={Min=30,Max=120,Default=espSettings.fov},Callback=function(v)espSettings.fov=v;if Camera then Camera.FieldOfView=v;initialPlayerStats.fov=v;end end})
Tabs.VisualsTab:Toggle({Title="Remove Fog",Value=espSettings.removeFog,Callback=function(v)espSettings.removeFog=v;if espSettings.removeFog then Lighting.FogEnd=1000000;Lighting.FogStart=Lighting.FogEnd-1;Lighting.FogColor=Color3.new(0,0,0) else Lighting.FogEnd=originalFog.End;Lighting.FogStart=originalFog.Start;Lighting.FogColor=originalFog.Color end end})
Tabs.VisualsTab:Section({ Title = "World Visuals" })
Tabs.VisualsTab:Toggle({Title="No Sky",Value=espSettings.noSky,Callback=function(v)espSettings.noSky=v;local currentSky=Lighting:FindFirstChildOfClass("Sky");if espSettings.noSky then if currentSky then currentSky.Name="Sky_DISABLED_BY_NO_SKY";currentSky.Parent=CoreGui end else local disabledSky=CoreGui:FindFirstChild("Sky_DISABLED_BY_NO_SKY");if disabledSky then disabledSky.Parent=Lighting;disabledSky.Name="Sky" end end end})
Tabs.VisualsTab:Slider({Title="Time of Day",Value={Min=0,Max=24,Default=espSettings.timeOfDay},Callback=function(v)espSettings.timeOfDay=v;Lighting.ClockTime=v end})

local function clearEspForPlayer(player)
    if espDrawings[player] then
        for _,d in pairs(espDrawings[player]) do
            if d and typeof(d.Remove)=="function" then
                d:Remove()
            elseif d and d.Parent then
                d.Parent=nil
            end
        end
        espDrawings[player]=nil
    end
    if chamsHighlights[player] then
        for _,h in pairs(chamsHighlights[player]) do
            if h and h.Parent then
                h:Destroy()
            end
        end
        chamsHighlights[player]=nil
    end
end

local function updateEsp()
    if not espSettings.enabled then return end -- Only run if master toggle is on

    local currentPlayers = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") then
            currentPlayers[p] = true
            local char = p.Character
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hd = char:FindFirstChild("Head")

            if not hd or not hrp or not hum then
                clearEspForPlayer(p)
                continue
            end

            if not espDrawings[p] then espDrawings[p] = {} end
            if not chamsHighlights[p] then chamsHighlights[p] = {} end

            local screenPoint, onScreen = Camera:WorldToViewportPoint(hd.Position)

            if onScreen then
                local yOffset = 0

                -- Chams
                if espSettings.chams then
                    if not chamsHighlights[p].main then
                        local hL = Instance.new("Highlight")
                        hL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hL.Parent = char
                        chamsHighlights[p].main = hL
                    end
                    chamsHighlights[p].main.FillColor = espSettings.color
                    chamsHighlights[p].main.OutlineColor = espSettings.color
                    chamsHighlights[p].main.FillTransparency = 0.6
                    chamsHighlights[p].main.OutlineTransparency = 0.3
                elseif chamsHighlights[p].main then
                    chamsHighlights[p].main:Destroy()
                    chamsHighlights[p].main = nil
                end

                -- Box ESP
                if espSettings.box then
                    if not espDrawings[p].box then
                        espDrawings[p].box = Drawing.new("Square")
                        espDrawings[p].box.Thickness = 1
                        espDrawings[p].box.Filled = false
                    end
                    local headPos = hd.Position
                    local hrpPos = hrp.Position
                    local height = (headPos.Y - hrpPos.Y) * 2
                    local width = height / 2

                    local screenHead, _ = Camera:WorldToViewportPoint(headPos)
                    local screenHRP, _ = Camera:WorldToViewportPoint(hrpPos)

                    if screenHead and screenHRP then
                        local boxHeight = math.abs(screenHead.Y - screenHRP.Y) * 2.5 -- Scale based on screen distance
                        local boxWidth = boxHeight / 2
                        local boxY = screenHead.Y - (boxHeight / 2)
                        local boxX = screenHead.X - (boxWidth / 2)

                        espDrawings[p].box.Visible = true
                        espDrawings[p].box.Position = Vector2.new(boxX, boxY)
                        espDrawings[p].box.Size = Vector2.new(boxWidth, boxHeight)
                        espDrawings[p].box.Color = espSettings.color
                    else
                        espDrawings[p].box.Visible = false
                    end
                elseif espDrawings[p].box then
                    espDrawings[p].box.Visible = false
                end

                -- Name ESP
                if espSettings.name then
                    if not espDrawings[p].name then
                        espDrawings[p].name = Drawing.new("Text")
                        espDrawings[p].name.Center = true
                        espDrawings[p].name.Outline = true
                    end
                    espDrawings[p].name.Visible = true
                    espDrawings[p].name.Text = p.DisplayName or p.Name
                    espDrawings[p].name.Position = Vector2.new(screenPoint.X, screenPoint.Y - 30 + yOffset)
                    espDrawings[p].name.Size = 14
                    espDrawings[p].name.Color = espSettings.color
                    espDrawings[p].name.OutlineColor = Color3.new(0,0,0)
                    yOffset = yOffset - 15
                elseif espDrawings[p].name then
                    espDrawings[p].name.Visible = false
                end

                -- Health ESP
                if espSettings.health then
                    if not espDrawings[p].hBBg then
                        espDrawings[p].hBBg = Drawing.new("Square")
                        espDrawings[p].hBBg.Filled = true
                        espDrawings[p].hBBg.Thickness = 0
                    end
                    if not espDrawings[p].hB then
                        espDrawings[p].hB = Drawing.new("Square")
                        espDrawings[p].hB.Filled = true
                        espDrawings[p].hB.Thickness = 0
                    end
                    local barWidth = 50
                    local barHeight = 5
                    local healthPercentage = hum.Health / hum.MaxHealth
                    local barX = screenPoint.X - barWidth / 2
                    local barY = screenPoint.Y - 15 + yOffset

                    espDrawings[p].hBBg.Visible = true
                    espDrawings[p].hBBg.Position = Vector2.new(barX, barY)
                    espDrawings[p].hBBg.Size = Vector2.new(barWidth, barHeight)
                    espDrawings[p].hBBg.Color = Color3.fromRGB(50,50,50)

                    espDrawings[p].hB.Visible = true
                    espDrawings[p].hB.Position = Vector2.new(barX, barY)
                    espDrawings[p].hB.Size = Vector2.new(barWidth * healthPercentage, barHeight)
                    espDrawings[p].hB.Color = Color3.fromHSV(0.33 * healthPercentage, 1, 1)
                elseif espDrawings[p].hB then
                    espDrawings[p].hB.Visible = false
                    espDrawings[p].hBBg.Visible = false
                end

                -- Tracer ESP
                if espSettings.tracer then
                    if not espDrawings[p].tracer then
                        espDrawings[p].tracer = Drawing.new("Line")
                        espDrawings[p].tracer.Thickness = 1
                    end
                    espDrawings[p].tracer.Visible = true
                    espDrawings[p].tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    espDrawings[p].tracer.To = Vector2.new(screenPoint.X, screenPoint.Y)
                    espDrawings[p].tracer.Color = espSettings.color
                elseif espDrawings[p].tracer then
                    espDrawings[p].tracer.Visible = false
                end
            else
                -- Player not on screen, clear their ESP drawings
                clearEspForPlayer(p)
            end
        end
    end

    -- Clean up ESP for players who are no longer in the game or no longer valid
    for player, _ in pairs(espDrawings) do
        if not currentPlayers[player] then
            clearEspForPlayer(player)
        end
    end
    for player, _ in pairs(chamsHighlights) do
        if not currentPlayers[player] then
            clearEspForPlayer(player)
        end
    end
end

-- Initialize ESP if Drawing API is available and the toggle is set
if typeof(Drawing) ~= "nil" and espSettings.enabled then
    espRenderConnection = RunService.RenderStepped:Connect(updateEsp)
elseif typeof(Drawing) == "nil" then
    WindUI:Notify({Title="ESP Warning",Content="Drawing API not found. ESP features will not work.",Icon="alert-triangle",Duration=10})
    espMasterToggle:SetValue(false) -- Turn off the toggle if Drawing API is missing
    espSettings.enabled = false
end


local themeValues={};for tN,_ in pairs(WindUI:GetThemes())do table.insert(themeValues,tN)end;table.sort(themeValues)
local cT=WindUI:GetCurrentTheme()
Tabs.SettingsTab:Dropdown({Title="UI Theme",Values=themeValues,Value=cT,Multi=false,AllowNone=false,Callback=function(sT)if WindUI:GetThemes()[sT]then WindUI:SetTheme(sT);cT=sT;WindUI:Notify({Title="Theme Changed",Content="Set to "..sT,Icon="palette",Duration=3})else WindUI:Notify({Title="Error",Content="Theme '"..sT.."' not found.",Icon="triangle-alert",Duration=5})end end})
Tabs.SettingsTab:Toggle({Title="Window Transparency",Value=Window.Transparent,Callback=function(iT)Window:ToggleTransparency(iT);WindUI:Notify({Title="Transparency "..(iT and"On"or"Off"),Icon=iT and"eye"or"eye-off",Duration=3})end})

local function cleanupFeatures()
    if flyConnection then flyConnection:Disconnect() end;if noclipConnection then noclipConnection:Disconnect() end;if antiAfkConnection then antiAfkConnection:Disconnect() end;if clickTpConnection then clickTpConnection:Disconnect() end;if espRenderConnection then espRenderConnection:Disconnect() end
    for p,_ in pairs(espDrawings)do clearEspForPlayer(p)end;espDrawings={};for p,_ in pairs(chamsHighlights)do clearEspForPlayer(p)end;chamsHighlights={}
    if isFlying and getHumanoid()then getHumanoid().PlatformStand=false end;if bodyGyro and bodyGyro.Parent then bodyGyro:Destroy()end;if bodyVelocity and bodyVelocity.Parent then bodyVelocity:Destroy()end
    if isNoclipping then for p,c in pairs(originalCollisions)do if p and p.Parent then pcall(function()p.CanCollide=c end)end end end
    if isFullbright then
        for prop, value in pairs(initialPlayerStats.originalLighting) do pcall(function() Lighting[prop] = value end) end
        local disAtmo = CoreGui:FindFirstChild("Atmosphere_DISABLED_BY_FB"); if disAtmo then disAtmo.Parent = Lighting; disAtmo.Name = "Atmosphere" end
    end
    if Camera then Camera.FieldOfView=initialPlayerStats.fov end;if espSettings.removeFog then Lighting.FogEnd=originalFog.End;Lighting.FogStart=originalFog.Start;Lighting.FogColor=originalFog.Color end;
    local disabledSky = CoreGui:FindFirstChild("Sky_DISABLED_BY_NO_SKY"); if disabledSky then disabledSky.Parent = Lighting; disabledSky.Name = "Sky" end
    Lighting.ClockTime=originalClockTime
    local h=getHumanoid(); 
    if h then 
        h.WalkSpeed = initialPlayerStats.walkSpeed; 
        pcall(function() h.JumpHeight = initialPlayerStats.jumpHeight end); 
        pcall(function() h.JumpPower = initialPlayerStats.jumpPower end)
    end 
end

local sI=getfenv().script;if sI and typeof(sI.Destroying)=="RBXScriptSignal"then sI.Destroying:Connect(cleanupFeatures)else game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function(_,parent)if not parent then cleanupFeatures()end end)end
