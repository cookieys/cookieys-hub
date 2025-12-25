if game.PlaceId ~= 128001665358186 then
    -- return -- Uncomment if you want to restrict to specific game
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Shawarma Anomaly Hub",
    Icon = "chef-hat",
    Author = "Script",
    Folder = "ShawarmaHub",
    Size = UDim2.fromOffset(580, 500),
    Transparent = true,
    Theme = "Dark",
})

local Tabs = {
    Home = Window:Tab({ Title = "Home", Icon = "house" }),
    Auto = Window:Tab({ Title = "Automation", Icon = "cpu" }),
    Teleport = Window:Tab({ Title = "Teleports", Icon = "map-pin" }),
    Visuals = Window:Tab({ Title = "Visuals", Icon = "scan-eye" }),
}

-- [[ Services & Variables ]]
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local State = {
    AutoLavash = false,
    AutoShawarmaD2 = false,
    AutoSoda = false,
    AutoClose = false,
    HitboxesEnabled = false
}

-- [[ Helper Functions ]]

-- Check if a specific customer model is an anomaly based on name
local function IsAnomaly(model)
    if not model then return false end
    local name = model.Name
    -- Patterns provided in previous prompts: "Anom", "Mike", "ManAN"
    if name:find("Anom") or name:find("Mike") or name:find("ManAN") then
        return true
    end
    return false
end

-- Get the current customer from the Hum folder
local function GetCurrentCustomer()
    local HumFolder = Workspace:FindFirstChild("Hum")
    if HumFolder then
        local children = HumFolder:GetChildren()
        if #children > 0 then
            return children[1] -- Return the first customer found
        end
    end
    return nil
end

local function Interact(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
    end
end

local function TeleportTo(cframe)
    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cframe
    end
end

-- [[ Visuals / Hitbox System ]]
local ESPHolder = Instance.new("Folder")
ESPHolder.Name = "ShawarmaVisuals"
ESPHolder.Parent = CoreGui
local VisualsCache = {}

local function ClearVisuals()
    ESPHolder:ClearAllChildren()
    VisualsCache = {}
end

local function ApplyHitboxColor(model)
    if not model then return end
    if VisualsCache[model] then return end 

    local isAnomaly = IsAnomaly(model)
    local color = isAnomaly and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = model
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = ESPHolder
    
    VisualsCache[model] = highlight

    model.AncestryChanged:Connect(function()
        if not model.Parent then
            if highlight then highlight:Destroy() end
            VisualsCache[model] = nil
        end
    end)
end

local function UpdateHitboxes()
    local HumFolder = Workspace:FindFirstChild("Hum")
    if not HumFolder then return end
    for _, child in ipairs(HumFolder:GetChildren()) do
        ApplyHitboxColor(child)
    end
end


-- [[ Home Tab ]]
local MarketplaceService = game:GetService("MarketplaceService")
local Success, GameInfo = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
Tabs.Home:Section({ Title = "Info" })
Tabs.Home:Paragraph({ Title = Success and GameInfo.Name or "Unknown Game", Desc = "Updated: Auto-Close logic & Safe Shawarma mode." })

-- [[ Automation Tab ]]

-- Shawarma Section
Tabs.Auto:Section({ Title = "Kitchen (Smart)" })

Tabs.Auto:Toggle({
    Title = "Auto Lavash (Safe)",
    Desc = "Only wraps if customer is NOT an anomaly.",
    Callback = function(v)
        State.AutoLavash = v
        if v then
            task.spawn(function()
                while State.AutoLavash do
                    local customer = GetCurrentCustomer()
                    -- Only proceed if there is a customer and they are NOT an anomaly
                    if customer and not IsAnomaly(customer) then
                        local prompt = Workspace:FindFirstChild("Kit") and Workspace.Kit:FindFirstChild("Done") and Workspace.Kit.Done:FindFirstChild("Lavash") and Workspace.Kit.Done.Lavash:FindFirstChild("ProximityPrompt")
                        if prompt then Interact(prompt) end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
})

Tabs.Auto:Button({
    Title = "Manual Lavash",
    Icon = "hand",
    Callback = function()
        local prompt = Workspace:FindFirstChild("Kit") and Workspace.Kit:FindFirstChild("Done") and Workspace.Kit.Done:FindFirstChild("Lavash") and Workspace.Kit.Done.Lavash:FindFirstChild("ProximityPrompt")
        if prompt then Interact(prompt) end
    end
})

Tabs.Auto:Toggle({
    Title = "Auto Shawarma D2 (Safe)",
    Desc = "Only serves if customer is NOT an anomaly.",
    Callback = function(v)
        State.AutoShawarmaD2 = v
        if v then
            task.spawn(function()
                while State.AutoShawarmaD2 do
                    local customer = GetCurrentCustomer()
                    -- Only proceed if there is a customer and they are NOT an anomaly
                    if customer and not IsAnomaly(customer) then
                        local prompt = Workspace:FindFirstChild("Kit") and Workspace.Kit:FindFirstChild("shawerma") and Workspace.Kit.shawerma:FindFirstChild("D2") and Workspace.Kit.shawerma.D2:FindFirstChild("ProximityPrompt")
                        if prompt then Interact(prompt) end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
})

-- Anomaly Defense Section
Tabs.Auto:Section({ Title = "Defense" })

Tabs.Auto:Toggle({
    Title = "Auto Close Garage",
    Desc = "Closes door when Anomaly stands on trigger.",
    Callback = function(v)
        State.AutoClose = v
        if v then
            task.spawn(function()
                while State.AutoClose do
                    local customer = GetCurrentCustomer()
                    
                    -- Check if customer is Anomaly
                    if customer and IsAnomaly(customer) then
                        -- Target trigger part
                        local buld = Workspace:FindFirstChild("Buld")
                        -- Using index 23 as requested. Note: Indexing by number in GetChildren is risky if map updates.
                        local triggerPart = buld and buld:GetChildren()[23]
                        
                        local root = customer:FindFirstChild("HumanoidRootPart")
                        
                        if triggerPart and root then
                            -- Check distance (Magnitude)
                            local dist = (root.Position - triggerPart.Position).Magnitude
                            
                            -- If close enough (e.g., 6 studs), fire the close button
                            if dist < 6 then
                                local btnPrompt = Workspace:FindFirstChild("Kit") and Workspace.Kit:FindFirstChild("Garge") and Workspace.Kit.Garge:FindFirstChild("Button") and Workspace.Kit.Garge.Button:FindFirstChild("ProximityPrompt")
                                if btnPrompt then
                                    Interact(btnPrompt)
                                    -- Wait a bit so we don't spam open/close
                                    task.wait(2) 
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- Soda Section
Tabs.Auto:Section({ Title = "Supplies" })
Tabs.Auto:Toggle({
    Title = "Auto Grab Soda",
    Desc = "Spams soda prompts.",
    Callback = function(v)
        State.AutoSoda = v
        if v then
            task.spawn(function()
                while State.AutoSoda do
                    local PromptsFolder = Workspace:FindFirstChild("Cans") and Workspace.Cans:FindFirstChild("Prompts")
                    if PromptsFolder then
                        for _, prompt in ipairs(PromptsFolder:GetChildren()) do
                            if prompt:IsA("ProximityPrompt") then
                                Interact(prompt)
                                break 
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})
Tabs.Auto:Button({
    Title = "Grab Soda (Manual)",
    Icon = "coffee",
    Callback = function()
        local PromptsFolder = Workspace:FindFirstChild("Cans") and Workspace.Cans:FindFirstChild("Prompts")
        if PromptsFolder then
            local children = PromptsFolder:GetChildren()
            local prompt = children[26] or children[1]
            if prompt and prompt:IsA("ProximityPrompt") then Interact(prompt) end
        end
    end
})

-- [[ Teleport Tab ]]
Tabs.Teleport:Section({ Title = "Locations" })
Tabs.Teleport:Button({
    Title = "Bus Stop (End Shift)",
    Icon = "bus",
    Callback = function()
        TeleportTo(CFrame.new(-35.87676239013672, 4.606302738189697, -480.1294860839844))
    end
})

-- [[ Visuals Tab ]]
Tabs.Visuals:Section({ Title = "Customer ESP" })
Tabs.Visuals:Toggle({
    Title = "Enable Hitboxes/ESP",
    Desc = "Green = Normal | Red = Anomaly",
    Callback = function(v)
        State.HitboxesEnabled = v
        if not v then ClearVisuals() else UpdateHitboxes() end
    end
})

task.spawn(function()
    while task.wait(1) do
        if State.HitboxesEnabled then UpdateHitboxes() end
    end
end)
