local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "MM2 Hub",
    Icon = "skull",
    Author = "Script",
    Folder = "MM2Hub_Config",
    Size = UDim2.fromOffset(580, 480),
    Transparent = true,
    Theme = "Dark",
})

local Tabs = {
    Home = Window:Tab({ Title = "Home", Icon = "house" }),
    Main = Window:Tab({ Title = "Main", Icon = "crosshair" }),
    Visuals = Window:Tab({ Title = "Visuals", Icon = "eye" }),
    Notify = Window:Tab({ Title = "Notify", Icon = "bell" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "sliders" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
}

-- [[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- [[ Remotes ]]
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Gameplay = Remotes:WaitForChild("Gameplay")
local RoleSelect = Gameplay:WaitForChild("RoleSelect")
local Fade = Gameplay:WaitForChild("Fade")

-- [[ State Management ]]
local State = {
    -- Notifications
    RoleRevealer = false,
    NotifyMurder = false,
    NotifySheriff = false,
    NotifyHero = false,
    NotifyPerks = false,
    NotifyGunDrop = false,
    
    -- Gun Interaction
    AutoGrabGun = false,

    -- ESP
    ESPEveryone = false,
    ESPSheriff = false,
    ESPMurder = false,
    ESPGunDrop = false,
    
    -- Misc
    WalkSpeed = 16,
    WalkSpeedEnabled = false,
    JumpPower = 50,
    JumpPowerEnabled = false,
    FOV = 70,
    FOVEnabled = false,
    Fullbright = false,

    -- Internal Data
    CurrentRoles = {}, 
    CurrentHero = nil,
    GunDroppedNotified = false
}

-- [[ ESP System ]]
local ESPHolder = Instance.new("Folder")
ESPHolder.Name = "MM2_ESP_Final"
ESPHolder.Parent = CoreGui

local ESP_Cache = {} 
local GunESP_Object = nil 

local function RemovePlayerESP(player)
    if ESP_Cache[player] then
        if ESP_Cache[player].Highlight then ESP_Cache[player].Highlight:Destroy() end
        ESP_Cache[player] = nil
    end
end

local function UpdateHighlight(player, color, shouldShow)
    if not player.Character then return end
    
    local cached = ESP_Cache[player]
    
    if cached and (not cached.Highlight or cached.Highlight.Parent ~= ESPHolder or cached.Highlight.Adornee ~= player.Character) then
        RemovePlayerESP(player)
        cached = nil
    end

    if not cached and shouldShow then
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name
        highlight.Adornee = player.Character
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = ESPHolder
        
        ESP_Cache[player] = { Highlight = highlight, Color = color, IsActive = true }
        return
    end

    if cached then
        local hl = cached.Highlight
        if hl.Enabled ~= shouldShow then hl.Enabled = shouldShow end
        if shouldShow and cached.Color ~= color then
            hl.FillColor = color
            cached.Color = color
        end
    end
end

-- [[ Logic Functions ]]

local function ScanInventory()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local pName = player.Name
            if not State.CurrentRoles[pName] then State.CurrentRoles[pName] = { Role = "Innocent", Perk = nil } end
            
            local currentRole = State.CurrentRoles[pName].Role
            local hasKnife = false
            local hasGun = false
            
            if player.Character then
                if player.Character:FindFirstChild("Knife") then hasKnife = true end
                if player.Character:FindFirstChild("Gun") then hasGun = true end
            end
            if player.Backpack then
                if player.Backpack:FindFirstChild("Knife") then hasKnife = true end
                if player.Backpack:FindFirstChild("Gun") then hasGun = true end
            end
            
            if hasKnife and currentRole ~= "Murderer" then
                State.CurrentRoles[pName].Role = "Murderer"
                if State.NotifyMurder then WindUI:Notify({ Title="Found Murderer", Content=pName, Icon="skull" }) end
            elseif hasGun and currentRole ~= "Sheriff" and currentRole ~= "Hero" then
                State.CurrentRoles[pName].Role = "Sheriff"
                if State.NotifySheriff then WindUI:Notify({ Title="Found Sheriff", Content=pName, Icon="shield" }) end
            end
        end
    end
end

local function CheckForHero()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local pName = player.Name
            local data = State.CurrentRoles[pName]
            local role = data and data.Role or "Innocent"

            if role ~= "Sheriff" and role ~= "Murderer" and role ~= "Murder" and role ~= "Dead" then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        if char:FindFirstChild("Gun") or (player.Backpack and player.Backpack:FindFirstChild("Gun")) then
                            if role ~= "Hero" then
                                if not State.CurrentRoles[pName] then State.CurrentRoles[pName] = {} end
                                State.CurrentRoles[pName].Role = "Hero"
                                State.CurrentHero = pName
                                if State.NotifyHero then WindUI:Notify({ Title = "Hero Detected!", Content = pName .. " has the gun!", Icon = "star" }) end
                            end
                        end
                    else
                        if State.CurrentRoles[pName] then State.CurrentRoles[pName].Role = "Dead" end
                    end
                end
            end
        end
    end
end

-- [[ Gun Grab Logic ]]
local function AttemptGrabGun()
    local gunDrop = Workspace:FindFirstChild("GunDrop", true)
    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if gunDrop and root then
        -- Method 1: FireTouchInterest (Best - "Brings" gun to inventory instantly)
        if firetouchinterest then
            firetouchinterest(root, gunDrop, 0)
            task.wait()
            firetouchinterest(root, gunDrop, 1)
            WindUI:Notify({ Title = "Success", Content = "Gun grabbed via TouchInterest!", Icon = "check" })
        else
            -- Method 2: Teleport (Fallback)
            local prevPos = root.CFrame
            root.CFrame = gunDrop.CFrame
            task.wait(0.2)
            root.CFrame = prevPos
            WindUI:Notify({ Title = "Success", Content = "Gun grabbed via Teleport!", Icon = "check" })
        end
        return true
    end
    return false
end

local function UpdateGunESP()
    local gunDrop = Workspace:FindFirstChild("GunDrop", true)

    -- Auto Grab Logic
    if gunDrop and State.AutoGrabGun then
        -- We use a simplified check here to avoid spamming the grab function
        -- Only try to grab if we don't already have a gun
        local myChar = Players.LocalPlayer.Character
        local myBackpack = Players.LocalPlayer.Backpack
        if not (myChar and myChar:FindFirstChild("Gun")) and not (myBackpack and myBackpack:FindFirstChild("Gun")) then
            AttemptGrabGun()
        end
    end

    -- Notification Logic
    if gunDrop then
        if not State.GunDroppedNotified and State.NotifyGunDrop then
            WindUI:Notify({ Title="Gun Dropped!", Content="The Sheriff has fallen.", Icon="alert-triangle", Duration=5 })
            State.GunDroppedNotified = true
        end
    else
        State.GunDroppedNotified = false
    end

    -- ESP Logic
    if not State.ESPGunDrop then
        if GunESP_Object then GunESP_Object:Destroy() GunESP_Object = nil end
        return 
    end

    if gunDrop then
        if GunESP_Object and GunESP_Object.Adornee == gunDrop then return end
        if GunESP_Object then GunESP_Object:Destroy() end

        local highlight = Instance.new("Highlight")
        highlight.Name = "GunDrop_ESP"
        highlight.Adornee = gunDrop
        highlight.FillColor = Color3.fromRGB(255, 170, 0)
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.FillTransparency = 0.2
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = ESPHolder

        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = gunDrop
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = highlight

        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = "DROPPED GUN"
        text.TextColor3 = Color3.fromRGB(255, 255, 0)
        text.TextStrokeTransparency = 0
        text.Font = Enum.Font.GothamBlack
        text.TextSize = 14
        text.Parent = billboard

        GunESP_Object = highlight
    else
        if GunESP_Object then GunESP_Object:Destroy() GunESP_Object = nil end
    end
end

local function ProcessVisuals()
    ScanInventory()
    CheckForHero()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            if player.Character:FindFirstChild("HumanoidRootPart") then
                local data = State.CurrentRoles[player.Name]
                local role = data and data.Role or "Innocent"
                
                local shouldDraw = false
                local color = Color3.fromRGB(0, 255, 0)

                if role == "Murderer" or role == "Murder" then
                    color = Color3.fromRGB(255, 0, 0)
                    if State.ESPEveryone or State.ESPMurder then shouldDraw = true end
                elseif role == "Sheriff" then
                    color = Color3.fromRGB(0, 0, 255)
                    if State.ESPEveryone or State.ESPSheriff then shouldDraw = true end
                elseif role == "Hero" then
                    color = Color3.fromRGB(255, 255, 0)
                    if State.ESPEveryone or State.ESPSheriff then shouldDraw = true end
                elseif role == "Dead" then
                    shouldDraw = false
                else
                    if State.ESPEveryone then shouldDraw = true end
                end
                
                UpdateHighlight(player, color, shouldDraw)
            end
        else
            RemovePlayerESP(player)
        end
    end
end

-- [[ Core Role Processing Logic ]]
local function ParseRoleData(playersData)
    if not playersData then return end
    
    State.CurrentRoles = {}
    State.CurrentHero = nil

    local murdererName = "None"
    local sheriffName = "None"
    local murdererPerk = "None"

    for playerName, info in pairs(playersData) do
        State.CurrentRoles[playerName] = { Role = info.Role, Perk = info.Perk }
        if info.Role == "Murderer" or info.Role == "Murder" then
            murdererName = playerName
            murdererPerk = info.Perk
        elseif info.Role == "Sheriff" then
            sheriffName = playerName
        end
    end

    if State.NotifyMurder then WindUI:Notify({ Title="Murderer", Content=murdererName, Icon="skull", Duration=6 }) end
    if State.NotifySheriff then WindUI:Notify({ Title="Sheriff", Content=sheriffName, Icon="shield", Duration=6 }) end
    if State.NotifyPerks and murdererPerk ~= "None" then WindUI:Notify({ Title="Perk", Content=murdererName.." uses "..tostring(murdererPerk), Icon="zap", Duration=6 }) end
    
    ProcessVisuals()
end


-- [[ Event Listeners ]]
Fade.OnClientEvent:Connect(function(...)
    local args = {...}
    if args[1] then
        ParseRoleData(args[1])
    end
end)

RoleSelect.OnClientEvent:Connect(function(...)
    if not State.RoleRevealer then return end
    local args = {...}
    local role = args[1]
    local icon = role == "Murderer" and "skull" or (role == "Sheriff" and "shield" or "user")
    WindUI:Notify({ Title="Role", Content="You are: "..tostring(role), Icon=icon, Duration=5 })
end)

-- [[ Misc Logic ]]
task.spawn(function()
    while task.wait(0.2) do
        local char = Players.LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hum then
            if State.WalkSpeedEnabled then hum.WalkSpeed = State.WalkSpeed end
            if State.JumpPowerEnabled then hum.JumpPower = State.JumpPower end
        end

        if State.FOVEnabled and Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = State.FOV
        end

        if State.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayerESP(player)
    State.CurrentRoles[player.Name] = nil
    if State.CurrentHero == player.Name then State.CurrentHero = nil end
end)

Players.PlayerAdded:Connect(function(player)
    State.CurrentRoles[player.Name] = { Role = "Innocent", Perk = nil }
    player.CharacterAdded:Connect(function()
        task.wait(1)
        ProcessVisuals()
    end)
end)

-- [[ UI Setup ]]

Tabs.Home:Section({ Title = "Info" })
Tabs.Home:Paragraph({ Title = "MM2 Hub", Desc = "New Features:\n- Auto Grab Gun (Teleports gun to you)\n- Manual 'Grab Gun' Button" })

Tabs.Main:Section({ Title = "Notifications" })
Tabs.Main:Toggle({ Title = "Role Revealer (Self)", Flag = "RoleRev", Desc = "Shows your role instantly.", Callback = function(v) State.RoleRevealer = v end })
Tabs.Main:Toggle({ Title = "Notify Murderer", Flag = "NotMurd", Callback = function(v) State.NotifyMurder = v end })
Tabs.Main:Toggle({ Title = "Notify Sheriff", Flag = "NotSher", Callback = function(v) State.NotifySheriff = v end })
Tabs.Main:Toggle({ Title = "Notify Hero", Flag = "NotHero", Desc = "When innocent gets gun.", Callback = function(v) State.NotifyHero = v end })
Tabs.Main:Toggle({ Title = "Notify Dropped Gun", Flag = "NotDrop", Desc = "When Sheriff dies.", Callback = function(v) State.NotifyGunDrop = v end })
Tabs.Main:Toggle({ Title = "Notify Perks", Flag = "NotPerk", Callback = function(v) State.NotifyPerks = v end })

Tabs.Main:Section({ Title = "Gun Interactions" })
Tabs.Main:Toggle({ 
    Title = "Auto Grab Gun", 
    Flag = "AutoGrab", 
    Desc = "Automatically brings the gun to you when it drops.", 
    Callback = function(v) State.AutoGrabGun = v end 
})
Tabs.Main:Button({
    Title = "Grab Gun",
    Desc = "Manually grab the gun if dropped.",
    Icon = "hand",
    Callback = function()
        if not AttemptGrabGun() then
            WindUI:Notify({ Title = "Error", Content = "No gun drop found.", Icon = "alert-circle" })
        end
    end
})

Tabs.Visuals:Section({ Title = "Player ESP" })
Tabs.Visuals:Toggle({ Title = "ESP Everyone", Flag = "ESPEveryone", Callback = function(v) State.ESPEveryone = v ProcessVisuals() end })
Tabs.Visuals:Toggle({ Title = "ESP Murderer Only", Flag = "ESPMurder", Callback = function(v) State.ESPMurder = v ProcessVisuals() end })
Tabs.Visuals:Toggle({ Title = "ESP Sheriff/Hero Only", Flag = "ESPSheriff", Callback = function(v) State.ESPSheriff = v ProcessVisuals() end })
Tabs.Visuals:Section({ Title = "Items" })
Tabs.Visuals:Toggle({ Title = "ESP Dropped Gun", Flag = "ESPGunDrop", Callback = function(v) State.ESPGunDrop = v UpdateGunESP() end })

Tabs.Misc:Section({ Title = "Local Player" })
Tabs.Misc:Toggle({ Title = "Enable WalkSpeed", Flag = "WSEnabled", Callback = function(v) State.WalkSpeedEnabled = v end })
Tabs.Misc:Slider({ Title = "WalkSpeed Amount", Flag = "WSVal", Min = 16, Max = 100, Default = 16, Callback = function(v) State.WalkSpeed = v end })

Tabs.Misc:Toggle({ Title = "Enable JumpPower", Flag = "JPEnabled", Callback = function(v) State.JumpPowerEnabled = v end })
Tabs.Misc:Slider({ Title = "JumpPower Amount", Flag = "JPVal", Min = 50, Max = 200, Default = 50, Callback = function(v) State.JumpPower = v end })

Tabs.Misc:Section({ Title = "Camera" })
Tabs.Misc:Toggle({ Title = "Enable FOV", Flag = "FOVEnabled", Callback = function(v) State.FOVEnabled = v end })
Tabs.Misc:Slider({ Title = "Field of View", Flag = "FOVVal", Min = 70, Max = 120, Default = 70, Callback = function(v) State.FOV = v end })
Tabs.Misc:Toggle({ Title = "Fullbright", Flag = "Fullbright", Callback = function(v) State.Fullbright = v end })

Tabs.Settings:Section({ Title = "Interface" })
local themes = {}
for name, _ in pairs(WindUI:GetThemes()) do table.insert(themes, name) end
table.sort(themes)

Tabs.Settings:Dropdown({
    Title = "Theme",
    Values = themes,
    Value = "Dark",
    Callback = function(t) WindUI:SetTheme(t) end
})
Tabs.Settings:Toggle({
    Title = "Transparency",
    Value = true,
    Callback = function(v) Window:ToggleTransparency(v) end
})
Tabs.Settings:Keybind({
    Title = "Menu Keybind",
    Value = "RightControl",
    Callback = function(key) Window:SetToggleKey(key) end
})

Tabs.Settings:Section({ Title = "Configuration" })
local ConfigName = "Default"
Tabs.Settings:Input({
    Title = "Config Name",
    Default = "Default",
    Callback = function(v) ConfigName = v end
})

Tabs.Settings:Button({
    Title = "Save Config",
    Icon = "save",
    Callback = function()
        local cfg = Window.ConfigManager:CreateConfig(ConfigName)
        cfg:Save()
        WindUI:Notify({ Title="Saved", Content="Config '"..ConfigName.."' saved successfully.", Icon="check" })
    end
})

Tabs.Settings:Button({
    Title = "Load Config",
    Icon = "download",
    Callback = function()
        local cfg = Window.ConfigManager:CreateConfig(ConfigName)
        cfg:Load()
        WindUI:Notify({ Title="Loaded", Content="Config '"..ConfigName.."' loaded successfully.", Icon="check" })
    end
})

-- [[ Master Loop ]]
task.spawn(function()
    while task.wait(0.5) do
        ProcessVisuals()
        UpdateGunESP()
    end
end)
