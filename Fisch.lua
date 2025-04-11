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
    Size = UDim2.fromOffset(500, 450), -- Slightly reduced height after removing a toggle
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
    isAutoClicking = false,
    autoCastEnabled = false,
    isAutoCatch = false,
    reelingMethod = "Safe Reeling Perfect",
    -- isFishing variable removed as the toggle is gone
}

-- ===== FUNCTIONS =====
local function click_this_gui(to_click)
    if to_click and to_click:IsA("GuiObject") and to_click.Visible then
        pcall(function()
            GuiService.SelectedObject = to_click
            if GuiService.SelectedObject == to_click then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait() -- Small delay might be needed
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end
        end)
    end
end

local function centerButton(button)
     if variables.isAutoClicking and button and button:IsA("ImageButton") then
         pcall(function()
             button.AnchorPoint = Vector2.new(0.5, 0.5)
             button.Position = UDim2.new(0.5, 0, 0.5, 0)
             button.Size = UDim2.new(0, 100, 0, 100)
         end)
     end
end

local function autoClick()
    local shakeUI = PlayerGui:FindFirstChild("shakeui")
    if not shakeUI then return end
    local safezone = shakeUI:FindFirstChild("safezone")
    if not safezone then return end
    local button = safezone:FindFirstChild("button")
    if button and button:IsA("ImageButton") and variables.isAutoClicking then
        click_this_gui(button)
    end
end

local function getEquippedRod()
    if not Character then return nil end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    return tool and tool.Name:lower():find("rod") and tool
end

local function equipRod()
    local rodFound = false
    for _, tool in ipairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("rod") then
            local eventsFolder = tool:FindFirstChild("events")
            if eventsFolder and eventsFolder:FindFirstChild("reset") then
                pcall(function() eventsFolder.reset:FireServer() end)
            end

            if Character and Character:FindFirstChildOfClass("Humanoid") then
                local humanoid = Character.Humanoid
                local currentTool = humanoid:FindFirstChildOfClass("Tool")

                if currentTool then
                    pcall(function() humanoid:UnequipTools() end)
                    task.wait(0.05)
                end
                pcall(function() humanoid:EquipTool(tool) end)
                rodFound = true
                break
            end
        end
    end
    if not rodFound then
        WindUI:Notify({
            Title = "Equip Error",
            Content = "No rod found in backpack!",
            Icon = "alert-triangle",
            Duration = 3
        })
    end
    return rodFound
end


local autoCastThread = nil
local function autoCast()
    local castArgs = { [1] = 99.79999999999994, [2] = 1 }
    while variables.autoCastEnabled and task.wait(0.01) do
        local rod = getEquippedRod()
        if rod then
            local eventsFolder = rod:FindFirstChild("events")
            if eventsFolder and eventsFolder:FindFirstChild("cast") then
                 pcall(function() eventsFolder.cast:FireServer(unpack(castArgs)) end)
            end
        else
             -- Optionally try to equip if none is held
             -- equipRod()
             -- task.wait(0.5)
        end
    end
end

local function startCatching(perfect)
    if not variables.isAutoCatch then return end

    local reel = PlayerGui:FindFirstChild("reel")
    if not reel then return end
    local bar = reel:FindFirstChild("bar")
    if not bar then return end

    local events = ReplicatedStorage:FindFirstChild("events")
    if not events then return end
    local reelfinished = events:FindFirstChild("reelfinished ")
    if reelfinished then
        pcall(function()
            reelfinished:FireServer(100, perfect)
        end)
    else
        warn("reelfinished event not found!")
    end
end

local function syncPositions()
    if not variables.isAutoCatch then return end

    local reel = PlayerGui:FindFirstChild("reel")
    if not reel then return end
    local bar = reel:FindFirstChild("bar")
    if not bar then return end
    local fish = bar:FindFirstChild("fish")
    local playerBar = bar:FindFirstChild("playerbar")

    if fish and playerBar then
        pcall(function()
            playerBar.Position = fish.Position
        end)
    end
end

-- ===== END FUNCTIONS =====


-- Add the Auto Click toggle to the MainTab
Tabs.MainTab:Toggle({
    Title = "Auto Click (Shake)",
    Default = false,
    Callback = function(value)
        variables.isAutoClicking = value
        print("Auto Click Toggled:", value)
        if value then
            task.spawn(function()
                while variables.isAutoClicking and task.wait(0.000000000000000000000000000000000001) do
                    pcall(autoClick)
                end
                print("Auto Click loop stopped.")
            end)
             local shakeUI = PlayerGui:FindFirstChild("shakeui")
             if shakeUI then
                 local safezone = shakeUI:FindFirstChild("safezone")
                 if safezone then
                     local button = safezone:FindFirstChild("button")
                     if button then
                        centerButton(button)
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
        variables.autoCastEnabled = value
        print("Auto Cast Toggled:", value)
        if value then
            if not autoCastThread or coroutine.status(autoCastThread) == "dead" then
                autoCastThread = task.spawn(autoCast)
                print("Auto Casting Started")
            end
        else
            print("Auto Casting Stopped (will cease on next check)")
        end
    end
})

-- Add Auto Catch toggle (Controls RenderStepped reeling)
Tabs.MainTab:Toggle({
    Title = "Auto Catch (RenderStepped)",
    Default = false,
    Callback = function(value)
        variables.isAutoCatch = value
        print("Auto Catch (RenderStepped) Toggled:", value)
    end
})

-- Add Reeling Method Dropdown (For RenderStepped reeling)
Tabs.MainTab:Dropdown({
    Title = "Catching Method (RenderStepped)",
    Values = {"Safe Reeling Perfect", "Instant Perfect"},
    Multi = false,
    Default = variables.reelingMethod,
    Callback = function(value)
        variables.reelingMethod = value
        print("Catching Method Set To:", value)
    end
})

--[[ Removed Instant Reel (Re-Equip) Toggle
Tabs.MainTab:Toggle({
    Title = "Instant Reel (Re-Equip)",
    Desc = "Periodically re-equips rod.",
    Default = false,
    Callback = function(value)
        -- Removed functionality
    end
})
]]

-- Connect the ChildAdded event (For Auto Click button centering)
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "shakeui" and variables.isAutoClicking then
        task.spawn(function()
            local safezone = child:WaitForChild("safezone", 5)
            if safezone then
                local button = safezone:FindFirstChild("button")
                if button then
                    centerButton(button)
                end

                local connection
                connection = safezone.ChildAdded:Connect(function(newChild)
                    if newChild.Name == "button" and variables.isAutoClicking then
                        centerButton(newChild)
                    end
                end)

                local checkConnection
                if RunService:IsClient() then
                    checkConnection = RunService.Heartbeat:Connect(function()
                        if not variables.isAutoClicking or not safezone or not safezone.Parent then
                            if connection then connection:Disconnect(); connection = nil end
                            if checkConnection then checkConnection:Disconnect(); checkConnection = nil end
                        end
                    end)
                end
            end
        end)
    end
end)

-- RenderStepped loop for Auto Catching based on the Auto Catch toggle and dropdown
if RunService:IsClient() then
    RunService.RenderStepped:Connect(function()
        if variables.isAutoCatch then
            if variables.reelingMethod == "Safe Reeling Perfect" then
                pcall(syncPositions)
            elseif variables.reelingMethod == "Instant Perfect" then
                pcall(startCatching, true)
            end
        end
    end)
end