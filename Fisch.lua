-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

-- ===== PLAYER SETUP =====
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Backpack = LocalPlayer:WaitForChild("Backpack")

-- ===== LOAD LATEST WINDUI =====
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ===== STATE MANAGEMENT =====
local State = {
    isAutoClicking = false,
    autoCastEnabled = false,
    autoCastThread = nil,
    isAutoCatching = false,
    reelingMethod = "Safe Reeling Perfect",
}

-- ===== UI CREATION =====
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(300, 320),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "Example Key System.\n\nThe Key is '1234' or '5678'",
        URL = "https://github.com/Footagesus/WindUI",
        SaveKey = true,
    },
})

Window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
    Draggable = true,
})

local Tabs = {
    Home = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    Main = Window:Tab({ Title = "Main", Icon = "fish", Desc = "Main features for the game." })
}
Window:SelectTab(1)

-- ===== HOME TAB =====
Tabs.Home:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        if not setclipboard then
            return WindUI:Notify({ Title = "Error", Content = "setclipboard is not available in this executor.", Icon = "alert-triangle", Duration = 5 })
        end
        pcall(setclipboard, "https://discord.gg/ee4veXxYFZ")
        WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied to clipboard.", Icon = "clipboard-check", Duration = 3 })
    end
})

-- ===== CORE GAME FUNCTIONS =====
local function click_gui_element(element)
    if element and element:IsA("GuiObject") and element.Visible then
        pcall(function()
            GuiService.SelectedObject = element
            if GuiService.SelectedObject == element then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end
        end)
    end
end

local function center_button_on_shakeui(button)
    if State.isAutoClicking and button and button:IsA("ImageButton") then
        pcall(function()
            button.AnchorPoint = Vector2.new(0.5, 0.5)
            button.Position = UDim2.new(0.5, 0, 0.5, 0)
            button.Size = UDim2.new(0, 100, 0, 100)
        end)
    end
end

local function auto_cast_loop()
    while State.autoCastEnabled do
        local character = LocalPlayer.Character
        if character then
            local rod = character:FindFirstChildOfClass("Tool")
            if rod and rod.Name:lower():find("rod") then
                local eventsFolder = rod:FindFirstChild("events")
                if eventsFolder and eventsFolder:FindFirstChild("cast") then
                    pcall(function() eventsFolder.cast:FireServer(99.8, 1) end)
                end
            end
        end
        task.wait(1.5) -- Reasonable delay between casts
    end
end

-- ===== RENDER-STEPPED & EVENT-DRIVEN FUNCTIONS =====
local function handle_auto_click()
    local shakeUI = PlayerGui:FindFirstChild("shakeui")
    if not shakeUI then return end
    local safezone = shakeUI:FindFirstChild("safezone")
    if not safezone then return end
    local button = safezone:FindFirstChild("button")
    if button and button:IsA("ImageButton") then
        click_gui_element(button)
    end
end

local function handle_safe_reeling()
    local reelUI = PlayerGui:FindFirstChild("reel")
    if not reelUI then return end
    local bar = reelUI:FindFirstChild("bar")
    if not bar then return end
    local fish = bar:FindFirstChild("fish")
    local playerBar = bar:FindFirstChild("playerbar")
    if fish and playerBar then
        pcall(function() playerBar.Position = fish.Position end)
    end
end

local function handle_instant_reeling()
    local events = ReplicatedStorage:FindFirstChild("events")
    if not events then return end
    -- NOTE: The space in "reelfinished " is intentional to match the game's remote.
    local reelFinishedEvent = events:FindFirstChild("reelfinished ")
    if reelFinishedEvent then
        pcall(function() reelFinishedEvent:FireServer(100, true) end)
    end
end

-- ===== MAIN TAB UI ELEMENTS =====
Tabs.Main:Toggle({
    Title = "Auto Click (Shake)",
    Value = State.isAutoClicking,
    Callback = function(value)
        State.isAutoClicking = value
        if value then
            local shakeUI = PlayerGui:FindFirstChild("shakeui")
            if shakeUI and shakeUI:FindFirstChild("safezone") and shakeUI.safezone:FindFirstChild("button") then
                center_button_on_shakeui(shakeUI.safezone.button)
            end
        end
    end
})

Tabs.Main:Toggle({
    Title = "Auto Cast",
    Value = State.autoCastEnabled,
    Callback = function(value)
        State.autoCastEnabled = value
        if value and (not State.autoCastThread or coroutine.status(State.autoCastThread) == "dead") then
            State.autoCastThread = task.spawn(auto_cast_loop)
        end
    end
})

Tabs.Main:Toggle({
    Title = "Auto Catch",
    Value = State.isAutoCatching,
    Callback = function(value)
        State.isAutoCatching = value
    end
})

Tabs.Main:Dropdown({
    Title = "Catching Method",
    Values = {"Safe Reeling Perfect", "Instant Perfect"},
    Value = State.reelingMethod,
    Callback = function(value)
        State.reelingMethod = value
    end
})

-- ===== DYNAMIC UI & MAIN LOOP =====
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "shakeui" and State.isAutoClicking then
        task.spawn(function()
            local safezone = child:WaitForChild("safezone", 5)
            if not safezone then return end
            
            local function handle_button(button)
                if button.Name == "button" then center_button_on_shakeui(button) end
            end
            
            for _, descendant in ipairs(safezone:GetChildren()) do handle_button(descendant) end
            safezone.ChildAdded:Connect(handle_button)
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if State.isAutoClicking then
        handle_auto_click()
    end
    if State.isAutoCatching then
        if State.reelingMethod == "Safe Reeling Perfect" then
            handle_safe_reeling()
        elseif State.reelingMethod == "Instant Perfect" then
            handle_instant_reeling()
        end
    end
end)
