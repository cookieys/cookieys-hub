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
    Title = "Open",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Draggable = true,
})

-- State Variables
local autoClickEnabled = false
local autoRebirthEnabled = false
local selectedRebirthAmount = 1
local autoClickThread = nil
local autoRebirthThread = nil
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local Tabs = {
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    MainTab = Window:Tab({ Title = "Main", Icon = "zap", Desc = "Main farming features." })
}

-- Main Tab Content
Tabs.MainTab:Toggle({
    Title = "Auto Click",
    Desc = "Automatically clicks the button.",
    Default = false, -- WindUI seems to use Default for toggles
    Callback = function(value)
        autoClickEnabled = value
        if autoClickEnabled and not autoClickThread then
            autoClickThread = task.spawn(function()
                while autoClickEnabled do
                    pcall(function() Events.Click4:FireServer() end)
                    task.wait(0.1) -- Adjust delay if needed
                end
                autoClickThread = nil -- Clear thread reference when loop ends
            end)
        elseif not autoClickEnabled and autoClickThread then
             -- The loop check will handle termination
             -- autoClickThread will be set to nil inside the loop when it finishes
        end
    end,
})

local rebirthOptions = {}
for i = 1, 169 do
    table.insert(rebirthOptions, tostring(i))
end

Tabs.MainTab:Dropdown({
    Title = "Rebirth Amount",
    Desc = "Select how many times to rebirth at once.",
    Values = rebirthOptions, -- Use Values as per example
    Value = "1", -- Use Value as per example
    Callback = function(value)
        selectedRebirthAmount = tonumber(value) or 1
    end,
})

Tabs.MainTab:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically rebirths with the selected amount.",
    Default = false, -- WindUI seems to use Default for toggles
    Callback = function(value)
        autoRebirthEnabled = value
         if autoRebirthEnabled and not autoRebirthThread then
            autoRebirthThread = task.spawn(function()
                while autoRebirthEnabled do
                    local args = { [1] = selectedRebirthAmount }
                    pcall(function() Events.Rebirth:FireServer(unpack(args)) end)
                    task.wait(1) -- Adjust delay based on rebirth cooldown/animation
                end
                 autoRebirthThread = nil -- Clear thread reference when loop ends
            end)
        elseif not autoRebirthEnabled and autoRebirthThread then
             -- The loop check will handle termination
             -- autoRebirthThread will be set to nil inside the loop when it finishes
        end
    end,
})

-- Home Tab Content (remains the same)
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

Window:SelectTab(1) -- Select Home tab by default
