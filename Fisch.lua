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
    Size = UDim2.fromOffset(500, 400),
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
    MainTab = Window:Tab({ Title = "main", Icon = "box" }) -- Added the new "main" tab
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

-- Variables to store toggle states
local variables = {
    isAutoShaking = false, -- Renamed from isAutoClicking for clarity
    isAutoCasting = false,
    isAutoReeling = false,
    isInstantReeling = false
}

-- Placeholder function for auto-clicking/shaking logic
local function autoShakeLogic()
    local shakeUI = PlayerGui:FindFirstChild("shakeui")
    if shakeUI then
        local safezone = shakeUI:FindFirstChild("safezone")
        if safezone then
            local button = safezone:FindFirstChild("button")
            if button and button:IsA("GuiButton") then
                 pcall(function() button.MouseButton1Click:Fire() end)
                 -- or pcall(function() button.Activated:Fire() end)
            end
        end
    end
    --print("Auto-shaking...")
end

-- Placeholder function for centering the shake button
local function centerButton(button)
     if button and button:IsA("GuiObject") then
         button.AnchorPoint = Vector2.new(0.5, 0.5)
         button.Position = UDim2.new(0.5, 0, 0.5, 0)
         --print("Centering button:", button.Name)
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
                    pcall(autoShakeLogic) -- Wrap in pcall to prevent errors stopping the loop
                end
            end)
            -- Attempt to center button immediately if UI exists
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
        -- Placeholder: Add logic for Auto Cast here
        if value then
            -- Start auto casting loop/logic
            print("Auto Casting Started")
        else
            -- Stop auto casting loop/logic
            print("Auto Casting Stopped")
        end
    end
})

-- Add Auto Reel toggle
Tabs.MainTab:Toggle({
    Title = "Auto Reel",
    Default = false,
    Callback = function(value)
        variables.isAutoReeling = value
        print("Auto Reel Toggled:", value)
        -- Placeholder: Add logic for Auto Reel here
        if value then
             -- Start auto reeling loop/logic
            print("Auto Reeling Started")
        else
            -- Stop auto reeling loop/logic
            print("Auto Reeling Stopped")
        end
    end
})

-- Add Instant Reel toggle
Tabs.MainTab:Toggle({
    Title = "Instant Reel",
    Default = false,
    Callback = function(value)
        variables.isInstantReeling = value
        print("Instant Reel Toggled:", value)
        -- Placeholder: Add logic for Instant Reel here
        -- This might involve modifying game functions/remotes when enabled
        if value then
             print("Instant Reel Enabled")
        else
            print("Instant Reel Disabled")
        end
    end
})

-- Connect the ChildAdded event (Primarily for Auto Shake button centering)
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "shakeui" and variables.isAutoShaking then
        task.spawn(function() -- Use task.spawn to avoid yielding
            local safezone = child:WaitForChild("safezone", 5)
            if safezone then
                local button = safezone:FindFirstChild("button")
                if button then
                    pcall(centerButton, button) -- Center existing button if found immediately
                end
                -- Connect to future buttons added to this specific safezone
                local connection
                connection = safezone.ChildAdded:Connect(function(newChild)
                    if newChild.Name == "button" and variables.isAutoShaking then -- Check again if still active
                        pcall(centerButton, newChild)
                    elseif not variables.isAutoShaking and connection then
                        connection:Disconnect() -- Disconnect if auto shake is turned off
                        connection = nil
                    end
                end)
                -- Also disconnect if the main toggle is turned off later
                local checkConnection = RunService.Heartbeat:Connect(function()
                    if not variables.isAutoShaking and connection then
                        connection:Disconnect()
                        connection = nil
                        checkConnection:Disconnect() -- Stop checking
                    end
                end)
            end
        end)
    end
end)