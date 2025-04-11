-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Player Setup
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(500, 500), -- Increased height further for new toggle
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
    Title = "Open Example UI",
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
    MainTab = Window:Tab({ Title = "main", Icon = "box" })
}

Window:SelectTab(1) -- Selects the first tab (HomeTab) by default

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

-- Variables to store toggle states and settings
local variables = {
    isAutoShaking = false,
    isAutoCasting = false,
    isAutoReeling = false,
    isInstantReelingToggle = false, -- Kept from previous version, might be redundant depending on desired behavior
    reelingMethod = "Safe Reeling Perfect",
    isFishing = false -- Added for the new Instant Reel function toggle
}

-- Placeholder function for auto-shaking logic
local function autoShakeLogic()
    local shakeUI = PlayerGui:FindFirstChild("shakeui")
    if shakeUI then
        local safezone = shakeUI:FindFirstChild("safezone")
        if safezone then
            local button = safezone:FindFirstChild("button")
            if button and button:IsA("GuiButton") then
                 pcall(function() button.MouseButton1Click:Fire() end)
            end
        end
    end
end

-- Placeholder function for centering the shake button
local function centerButton(button)
     if button and button:IsA("GuiObject") then
         button.AnchorPoint = Vector2.new(0.5, 0.5)
         button.Position = UDim2.new(0.5, 0, 0.5, 0)
     end
end

-- Placeholder functions for reeling (replace with actual implementation if needed for RenderStepped approach)
local function syncPositions()
    --print("Executing Safe Reeling Perfect...")
    -- Add your safe reeling logic here if using the RenderStepped method
end

local function startCatching(isInstant)
    if isInstant then
        --print("Executing Instant Perfect Reeling...")
        -- Add your instant reeling logic here if using the RenderStepped method
    end
end

-- Add the Auto Shake toggle to the MainTab
Tabs.MainTab:Toggle({
    Title = "Auto Shake",
    Default = false,
    Callback = function(value)
        variables.isAutoShaking = value
        print("Auto Shake Toggled:", value)
        if value then
            task.spawn(function()
                while variables.isAutoShaking and task.wait(0.000000000000000000000000000000000001) do
                    pcall(autoShakeLogic)
                end
            end)
            local shakeUI = PlayerGui:FindFirstChild("shakeui")
            if shakeUI then
                local safezone = shakeUI:FindFirstChild("safezone")
                if safezone then
                    local button = safezone:FindFirstChild("button")
                    if button then
                       pcall(centerButton, button)
                    end
                end
            end
        end
    end
})

-- Add Auto Cast toggle
Tabs.MainTab:Toggle({
    Title = "Auto Cast",
    Default = false,
    Callback = function(value)
        variables.isAutoCasting = value
        print("Auto Cast Toggled:", value)
        if value then
            print("Auto Casting Started")
        else
            print("Auto Casting Stopped")
        end
    end
})

-- Add Auto Reel toggle (Controls RenderStepped reeling)
Tabs.MainTab:Toggle({
    Title = "Auto Reel (RenderStepped)", -- Clarified title
    Default = false,
    Callback = function(value)
        variables.isAutoReeling = value
        print("Auto Reel (RenderStepped) Toggled:", value)
    end
})

-- Add Reeling Method Dropdown (For RenderStepped reeling)
Tabs.MainTab:Dropdown({
    Title = "Reeling Method (RenderStepped)", -- Clarified title
    Values = {"Safe Reeling Perfect", "Instant Perfect"},
    Multi = false,
    Default = variables.reelingMethod,
    Callback = function(value)
        variables.reelingMethod = value
        print("Reeling Method Set To:", value)
    end
})

-- Add Instant Reel Toggle (Implements the new periodic re-equip logic)
Tabs.MainTab:Toggle({
    Title = "Instant Reel (Re-Equip)", -- Clarified title
    Desc = "Periodically destroys reel UI & re-equips rod.", -- Updated Description
    Default = false,
    Callback = function(value)
        variables.isFishing = value
        print("Instant Reel (Re-Equip) Toggled:", value)
        if value then
            task.spawn(function()
                while variables.isFishing and task.wait(2) do -- Check variables.isFishing in the loop condition
                    -- Safely get rod name using pcall or chained checks
                    local rodNameValue = nil
                    pcall(function()
                        local playerStats = workspace:FindFirstChild("PlayerStats")
                        if playerStats then
                            local playerFolder = playerStats:FindFirstChild(LocalPlayer.Name)
                            if playerFolder then
                                local tFolder = playerFolder:FindFirstChild("T")
                                if tFolder then
                                     local innerPlayerFolder = tFolder:FindFirstChild(LocalPlayer.Name)
                                     if innerPlayerFolder then
                                         local statsFolder = innerPlayerFolder:FindFirstChild("Stats")
                                         if statsFolder then
                                             local rodValue = statsFolder:FindFirstChild("rod")
                                             if rodValue then
                                                 rodNameValue = rodValue.Value
                                             end
                                         end
                                     end
                                end
                            end
                        end
                    end)
                    local finalRodName = rodNameValue or "Training Rod" -- Default if not found

                    -- Find and destroy reel UI
                    local reel = PlayerGui:FindFirstChild("reel")
                    if reel then
                        pcall(function() reel:Destroy() end)
                        --print("Destroyed reel UI")
                    end

                    -- Re-equip tool (ensure Character and Humanoid exist)
                    if Character and Character:FindFirstChild("Humanoid") then
                        local humanoid = Character.Humanoid
                        local currentTool = humanoid:FindFirstChildOfClass("Tool")
                        local toolToEquip = Backpack:FindFirstChild(finalRodName)

                        -- Only re-equip if necessary or if the correct tool isn't already equipped
                        if toolToEquip and (not currentTool or currentTool.Name ~= finalRodName) then
                             pcall(function() humanoid:UnequipTools() end)
                             task.wait(0.05) -- Small delay might help
                             pcall(function() humanoid:EquipTool(toolToEquip) end)
                             --print("Re-equipped:", finalRodName)
                        elseif not toolToEquip then
                            warn("Could not find rod to equip:", finalRodName)
                        end
                    end
                    -- Added check to exit loop if toggle is turned off during the wait
                    if not variables.isFishing then break end
                end
                print("Instant Reel (Re-Equip) loop stopped.")
            end)
        end
    end
})


-- Connect the ChildAdded event (Primarily for Auto Shake button centering)
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "shakeui" and variables.isAutoShaking then
        task.spawn(function()
            local safezone = child:WaitForChild("safezone", 5)
            if safezone then
                local button = safezone:FindFirstChild("button")
                if button then
                    pcall(centerButton, button)
                end
                local connection
                connection = safezone.ChildAdded:Connect(function(newChild)
                    if newChild.Name == "button" and variables.isAutoShaking then
                        pcall(centerButton, newChild)
                    elseif not variables.isAutoShaking and connection then
                        connection:Disconnect()
                        connection = nil
                    end
                end)
                local checkConnection
                if RunService:IsClient() then
                    checkConnection = RunService.Heartbeat:Connect(function()
                        if not variables.isAutoShaking and connection then
                            if connection then connection:Disconnect() end
                            connection = nil
                            if checkConnection then checkConnection:Disconnect() end
                        end
                    end)
                end
            end
        end)
    end
end)

-- RenderStepped loop for Auto Reeling based on the *first* Auto Reel toggle and dropdown
if RunService:IsClient() then
    RunService.RenderStepped:Connect(function()
        -- Logic for the RenderStepped-based Auto Reel
        if variables.isAutoReeling then
            if variables.reelingMethod == "Safe Reeling Perfect" then
                pcall(syncPositions)
            elseif variables.reelingMethod == "Instant Perfect" then
                pcall(startCatching, true)
            end
        end

        -- Add other RenderStepped logic here if needed
    end)
end