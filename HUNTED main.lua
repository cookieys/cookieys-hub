local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "HUNTED Script",
    Author = ".ftgs",
    Folder = "HuntedScript",
    Icon = "skull",
    Size = UDim2.fromOffset(550, 400)
})

-- Variables
getgenv().AutoCollect = false
getgenv().ShardESP = false
getgenv().EnemyESP = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Paths
local ShardsFolder = Workspace:WaitForChild("Shards", 5) or Workspace
local EnemiesFolder = Workspace:WaitForChild("Terrain"):WaitForChild("Enemies", 5)

-- Store ESP Objects to clean up later
local ESP_Storage = {
    Shards = {},
    Enemies = {}
}

-- Functions
local function FireTouch(part)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 0)
        task.wait()
        firetouchinterest(LocalPlayer.Character.HumanoidRootPart, part, 1)
    end
end

-- Helper to create formatted text for enemies
local function GetEnemyInfo(model)
    local humanoid = model:FindFirstChild("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    
    local name = model.Name
    local hp = "N/A"
    local dist = "N/A"
    
    if humanoid then
        hp = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
    end
    
    if root and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local d = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
        dist = math.floor(d) .. " studs"
    end
    
    return string.format("%s | %s HP | %s", name, hp, dist)
end

local function CreateHighlight(target, color, text, storage)
    if target:FindFirstChild("WindUI_ESP_Highlight") then return end
    
    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "WindUI_ESP_Highlight"
    hl.Adornee = target
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0.2
    hl.Parent = target
    table.insert(storage, hl)

    -- Text (BillboardGui)
    local bg = Instance.new("BillboardGui")
    bg.Name = "WindUI_ESP_Text"
    bg.Adornee = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextStrokeTransparency = 0
    label.TextColor3 = color
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Text = text or target.Name
    label.Parent = bg
    
    bg.Parent = target
    table.insert(storage, bg)
end

local function UpdateEnemyESP()
    if not EnemiesFolder then return end
    
    for _, enemy in pairs(EnemiesFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("Humanoid").Health > 0 then
            -- Check/Create ESP
            if not enemy:FindFirstChild("WindUI_ESP_Highlight") then
                CreateHighlight(enemy, Color3.fromRGB(255, 170, 0), enemy.Name, ESP_Storage.Enemies)
            end
            
            -- Update Text
            local bg = enemy:FindFirstChild("WindUI_ESP_Text")
            if bg and bg:FindFirstChild("TextLabel") then
                bg.TextLabel.Text = GetEnemyInfo(enemy)
                -- Dynamic Color based on distance (optional tweak)
                bg.TextLabel.TextColor3 = Color3.fromRGB(255, 170, 0) 
            end
        elseif enemy:FindFirstChild("WindUI_ESP_Highlight") then
            -- Cleanup dead enemies
            enemy.WindUI_ESP_Highlight:Destroy()
            if enemy:FindFirstChild("WindUI_ESP_Text") then enemy.WindUI_ESP_Text:Destroy() end
        end
    end
end

local function ClearESP(storage)
    for i, v in pairs(storage) do
        if v and v.Parent then v:Destroy() end
    end
    table.clear(storage)
    
    -- Deep Clean in case of stragglers
    if ShardsFolder then
        for _, v in pairs(ShardsFolder:GetChildren()) do
            if v:FindFirstChild("WindUI_ESP_Highlight") then v.WindUI_ESP_Highlight:Destroy() end
        end
    end
    if EnemiesFolder then
        for _, v in pairs(EnemiesFolder:GetChildren()) do
            if v:FindFirstChild("WindUI_ESP_Highlight") then v.WindUI_ESP_Highlight:Destroy() end
            if v:FindFirstChild("WindUI_ESP_Text") then v.WindUI_ESP_Text:Destroy() end
        end
    end
end

-- Tabs
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })

-- Main Tab: Auto Collect
local CollectSection = MainTab:Section({ Title = "Collection" })

CollectSection:Toggle({
    Title = "Auto Collect Shards",
    Desc = "Automatically collects shards via TouchInterest",
    Callback = function(val)
        getgenv().AutoCollect = val
    end
})

-- Main Tab: Information
local InfoSection = MainTab:Section({ Title = "Shard Information" })
InfoSection:Paragraph({
    Title = "Red Shard (Reveal)",
    Desc = '<font color="#FF0000">Reveals enemy locations for 60 seconds</font>',
})
InfoSection:Paragraph({
    Title = "Orange Shard (Stun)",
    Desc = '<font color="#FFA500">Stuns enemies for 15 seconds</font>',
})

-- Visuals Tab: ESP
local EspSection = VisualsTab:Section({ Title = "ESP Settings" })

EspSection:Toggle({
    Title = "Shard ESP",
    Callback = function(val)
        getgenv().ShardESP = val
        if not val then ClearESP(ESP_Storage.Shards) end
    end
})

EspSection:Toggle({
    Title = "Enemy ESP",
    Desc = "Highlights enemies in Terrain/Enemies",
    Callback = function(val)
        getgenv().EnemyESP = val
        if not val then ClearESP(ESP_Storage.Enemies) end
    end
})

-- Logic Loops

-- Auto Collect Loop
task.spawn(function()
    while true do
        if getgenv().AutoCollect and ShardsFolder then
            for _, v in pairs(ShardsFolder:GetChildren()) do
                if v:IsA("BasePart") or v:IsA("Model") then
                    local part = v:IsA("Model") and (v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")) or v
                    if part then
                        FireTouch(part)
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)

-- ESP Render Loop
RunService.RenderStepped:Connect(function()
    -- Shard ESP
    if getgenv().ShardESP and ShardsFolder then
        for _, v in pairs(ShardsFolder:GetChildren()) do
            local color = Color3.fromRGB(200, 200, 200)
            if v.Name:find("RedShard") then color = Color3.fromRGB(255, 0, 0)
            elseif v.Name:find("OrangeShard") then color = Color3.fromRGB(255, 165, 0) end
            
            if not v:FindFirstChild("WindUI_ESP_Highlight") then
                CreateHighlight(v, color, v.Name, ESP_Storage.Shards)
            end
        end
    end

    -- Enemy ESP
    if getgenv().EnemyESP then
        UpdateEnemyESP()
    end
end)
