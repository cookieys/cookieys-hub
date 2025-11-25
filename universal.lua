-- [[ 1. Environment & Safety Checks ]]
if getgenv().CookieysHubLoaded then
    warn("Cookieys Hub is already running!")
    return
end
getgenv().CookieysHubLoaded = true

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- [[ 2. Services ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- [[ 3. Player Setup ]]
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [[ 4. UI Library Initialization ]]
local Success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not Success or not WindUI then
    warn("Failed to load WindUI.")
    return
end

-- [[ 5. State Management ]]
local State = {
    Connections = {},
    Values = {
        WalkSpeed = 16,
        JumpPower = 50,
        FOV = 70,
        InfiniteZoom = false,
        AntiAFK = false
    },
    Elements = {} -- UI Element references
}

-- [[ 6. Core Logic Functions ]]
local function ApplySettings()
    local Char = LocalPlayer.Character
    local Hum = Char and Char:FindFirstChild("Humanoid")

    if Hum then
        -- Only apply if changed from default to avoid fighting other scripts
        if State.Values.WalkSpeed ~= 16 then Hum.WalkSpeed = State.Values.WalkSpeed end
        if State.Values.JumpPower ~= 50 then Hum.JumpPower = State.Values.JumpPower end
    end
    
    if Camera then
        Camera.FieldOfView = State.Values.FOV
    end

    LocalPlayer.CameraMaxZoomDistance = State.Values.InfiniteZoom and 9e9 or 128
end

local function ToggleAntiAFK(state)
    State.Values.AntiAFK = state
    if State.Connections.AntiAFK then
        State.Connections.AntiAFK:Disconnect()
        State.Connections.AntiAFK = nil
    end

    if state then
        State.Connections.AntiAFK = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0))
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0, 0))
            WindUI:Notify({
                Title = "Anti-AFK",
                Content = "Prevented Kick due to inactivity.",
                Icon = "shield",
                Duration = 2
            })
        end)
    end
end

-- Character Added Hook (Persist Settings)
LocalPlayer.CharacterAdded:Connect(function(newChar)
    local hum = newChar:WaitForChild("Humanoid", 10)
    if hum then
        -- Wait a tick for Roblox default scripts to run first
        task.wait(0.1) 
        ApplySettings()
        
        -- Loop to keep stats if game tries to reset them
        task.spawn(function()
            while newChar and newChar.Parent and hum.Health > 0 do
                if State.Values.WalkSpeed ~= 16 and hum.WalkSpeed ~= State.Values.WalkSpeed then
                    hum.WalkSpeed = State.Values.WalkSpeed
                end
                task.wait(1)
            end
        end)
    end
end)

-- [[ 7. UI Creation ]]
local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "cookie",
    Author = "XyraV",
    Folder = "cookieys-config", -- Unique folder name
    Size = UDim2.fromOffset(500, 380),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true
})

Window:EditOpenButton({
    Title = "Open Hub",
    Icon = "cookie",
    CornerRadius = UDim.new(0, 10),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    Draggable = true,
})

-- [[ 8. Tabs ]]
local Tabs = {
    Home = Window:Tab({ Title = "Home", Icon = "house" }),
    Scripts = Window:Tab({ Title = "Scripts", Icon = "scroll" }),
    Local = Window:Tab({ Title = "Local Player", Icon = "user" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

-- [[ 9. Tab Content ]]

-- :: Home Tab ::
Tabs.Home:Section({ Title = "Information" })
Tabs.Home:Paragraph({
    Title = "Welcome, " .. LocalPlayer.Name,
    Desc = "This is the improved version of cookieys hub.\nCurrent Game ID: " .. game.PlaceId
})

Tabs.Home:Button({
    Title = "Copy Discord Invite",
    Desc = "Join our community!",
    Icon = "link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/ee4veXxYFZ")
            WindUI:Notify({ Title = "Success", Content = "Copied to clipboard!", Icon = "check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Your executor doesn't support clipboard.", Icon = "alert-triangle" })
        end
    end
})

-- :: Scripts Tab ::
local function RunExternalScript(url, name)
    WindUI:Notify({ Title = "Loading...", Content = "Fetching " .. name, Duration = 2 })
    task.spawn(function()
        local success, body = pcall(function() return game:HttpGet(url) end)
        if success and body then
            local func, err = loadstring(body)
            if func then
                pcall(func)
                WindUI:Notify({ Title = "Success", Content = name .. " Executed.", Icon = "check" })
            else
                WindUI:Notify({ Title = "Error", Content = "Syntax Error: " .. tostring(err), Icon = "alert-triangle" })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Failed to download script.", Icon = "alert-triangle" })
        end
    end)
end

Tabs.Scripts:Button({
    Title = "Infinite Yield",
    Desc = "The best admin command script.",
    Icon = "terminal",
    Callback = function() RunExternalScript("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", "Infinite Yield") end
})

Tabs.Scripts:Button({
    Title = "Nameless Admin",
    Desc = "Lightweight admin commands.",
    Icon = "shield-check",
    Callback = function() RunExternalScript("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua", "Nameless Admin") end
})

-- :: Local Player Tab ::
State.Elements.WalkSpeed = Tabs.Local:Slider({
    Title = "Walk Speed",
    Icon = "footprints",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(v)
        State.Values.WalkSpeed = v
        ApplySettings()
    end
})

State.Elements.JumpPower = Tabs.Local:Slider({
    Title = "Jump Power",
    Icon = "arrow-up",
    Step = 1,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v)
        State.Values.JumpPower = v
        ApplySettings()
    end
})

State.Elements.FOV = Tabs.Local:Slider({
    Title = "Field of View",
    Icon = "eye",
    Step = 1,
    Value = { Min = 70, Max = 120, Default = 70 },
    Callback = function(v)
        State.Values.FOV = v
        ApplySettings()
    end
})

Tabs.Local:Divider()

State.Elements.InfiniteZoom = Tabs.Local:Toggle({
    Title = "Infinite Zoom",
    Desc = "Scroll out as far as you want.",
    Callback = function(v)
        State.Values.InfiniteZoom = v
        ApplySettings()
    end
})

State.Elements.AntiAFK = Tabs.Local:Toggle({
    Title = "Anti-AFK",
    Desc = "Prevents being kicked for idling.",
    Callback = ToggleAntiAFK
})


-- :: Settings Tab (Config System) ::
Tabs.Settings:Section({ Title = "Interface" })

local Themes = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(Themes, name)
end
table.sort(Themes)

State.Elements.Theme = Tabs.Settings:Dropdown({
    Title = "Theme",
    Values = Themes,
    Value = "Dark",
    Callback = function(t) WindUI:SetTheme(t) end
})

State.Elements.Transparency = Tabs.Settings:Toggle({
    Title = "Transparent Background",
    Value = true,
    Callback = function(v) Window:ToggleTransparency(v) end
})

Tabs.Settings:Divider()
Tabs.Settings:Section({ Title = "Configuration" })

-- Helper for File System
local ConfigFolder = "WindUI/cookieys-config"
if not isfolder("WindUI") then makefolder("WindUI") end
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local ConfigNameInput = "default"

Tabs.Settings:Input({
    Title = "Config Name",
    Placeholder = "Type name here...",
    Callback = function(txt) ConfigNameInput = txt end
})

local function GetConfigs()
    local list = {}
    if listfiles then
        for _, path in ipairs(listfiles(ConfigFolder)) do
            local name = path:match("([^/]+)%.json$") or path:match("([^/]+)$") -- Extract filename
            if name then table.insert(list, name) end
        end
    end
    return list
end

local ConfigDropdown = Tabs.Settings:Dropdown({
    Title = "Load Config",
    Values = GetConfigs(),
    AllowNone = true,
    Callback = function(val)
        ConfigNameInput = val
    end
})

Tabs.Settings:Button({
    Title = "Save Config",
    Icon = "save",
    Callback = function()
        if ConfigNameInput == "" then return end
        
        -- Register elements manually to ensure we only save what we want
        local Config = Window.ConfigManager:CreateConfig(ConfigNameInput)
        
        -- Manually link state values to the config system if needed, 
        -- but WindUI usually handles registered elements.
        -- We re-register here just in case.
        Config:Register("Theme", State.Elements.Theme)
        Config:Register("Transparency", State.Elements.Transparency)
        Config:Register("WS", State.Elements.WalkSpeed)
        Config:Register("JP", State.Elements.JumpPower)
        Config:Register("FOV", State.Elements.FOV)
        Config:Register("InfZoom", State.Elements.InfiniteZoom)
        Config:Register("AntiAFK", State.Elements.AntiAFK)

        Config:Save()
        
        WindUI:Notify({ Title = "Saved", Content = "Config saved as " .. ConfigNameInput, Icon = "save" })
        ConfigDropdown:Refresh(GetConfigs())
    end
})

Tabs.Settings:Button({
    Title = "Load Config",
    Icon = "download",
    Callback = function()
        if ConfigNameInput == "" then return end
        
        local Config = Window.ConfigManager:CreateConfig(ConfigNameInput)
        
        Config:Register("Theme", State.Elements.Theme)
        Config:Register("Transparency", State.Elements.Transparency)
        Config:Register("WS", State.Elements.WalkSpeed)
        Config:Register("JP", State.Elements.JumpPower)
        Config:Register("FOV", State.Elements.FOV)
        Config:Register("InfZoom", State.Elements.InfiniteZoom)
        Config:Register("AntiAFK", State.Elements.AntiAFK)

        Config:Load()
        ApplySettings() -- Force re-apply after loading
        
        WindUI:Notify({ Title = "Loaded", Content = "Config loaded: " .. ConfigNameInput, Icon = "check" })
    end
})

-- [[ 10. Initialization ]]
Window:SelectTab(1)
ApplySettings()

-- Cleanup on script re-execution or close
Window.OnClose:Connect(function()
    getgenv().CookieysHubLoaded = nil
end)