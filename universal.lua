local env = getgenv()
if env.CookieysHubLoaded then
    warn("Cookieys Hub is already running!")
    return
end
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Pin to a release tag instead of "latest" when you can
local WINDUI_URL = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"

local EXTERNAL_SCRIPTS = {
    {
        "Infinite Yield",
        "The best admin command script.",
        "terminal",
        "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
    },
    {
        "Nameless Admin",
        "Lightweight admin commands.",
        "shield-check",
        "https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"
    }
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function httpGet(url, tries)
    tries = tries or 3
    for i = 1, tries do
        local ok, body = pcall(game.HttpGet, game, url, true)
        if ok and type(body) == "string" and body ~= "" and not body:match("^%s*<") then
            return body
        end
        if i < tries then
            task.wait(i)
        end
    end
end

----------------------------------------------------------------
-- UI library (flag is set only after a successful load)
----------------------------------------------------------------
local WindUI
do
    local src = httpGet(WINDUI_URL)
    local fn = src and loadstring(src, "=WindUI")
    local ok, lib = false, nil
    if fn then
        ok, lib = pcall(fn)
    end
    if not ok or type(lib) ~= "table" then
        warn("[Cookieys Hub] Failed to load WindUI.")
        return
    end
    WindUI = lib
end
env.CookieysHubLoaded = true

local function notify(title, content, icon, duration)
    WindUI:Notify({Title = title, Content = content, Icon = icon, Duration = duration or 3})
end

----------------------------------------------------------------
-- State
----------------------------------------------------------------
local Connections = {} -- named, long-lived
local CharConns = {} -- per-character
local Overrides = {} -- nil = untouched, game stays in control
local DEFAULT_ZOOM = LocalPlayer.CameraMaxZoomDistance
local infiniteZoom = false
local Window

----------------------------------------------------------------
-- Core logic
----------------------------------------------------------------
local function applyHumanoid(hum)
    local ws, jp = Overrides.WalkSpeed, Overrides.JumpPower
    if ws and hum.WalkSpeed ~= ws then
        hum.WalkSpeed = ws
    end
    if jp then
        if not hum.UseJumpPower then
            hum.UseJumpPower = true
        end -- JumpPower is ignored otherwise
        if hum.JumpPower ~= jp then
            hum.JumpPower = jp
        end
    end
end

local function applyFOV()
    local cam = Workspace.CurrentCamera
    local fov = Overrides.FOV
    if cam and fov and cam.FieldOfView ~= fov then
        cam.FieldOfView = fov
    end
end

local function applyAll()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        applyHumanoid(hum)
    end
    applyFOV()
end

-- Slider at its default value = release control back to the game
local function setOverride(key, value, default)
    if value == default then
        if Overrides[key] ~= nil then
            Overrides[key] = default
            applyAll()
            Overrides[key] = nil
        end
    else
        Overrides[key] = value
        applyAll()
    end
end

local function setInfiniteZoom(on)
    infiniteZoom = on
    LocalPlayer.CameraMaxZoomDistance = on and 9e9 or DEFAULT_ZOOM
end

local function setAntiAFK(on)
    if Connections.AntiAFK then
        Connections.AntiAFK:Disconnect()
        Connections.AntiAFK = nil
    end
    if not on then
        return
    end
    Connections.AntiAFK =
        LocalPlayer.Idled:Connect(
        function()
            local cf = (Workspace.CurrentCamera or {}).CFrame or CFrame.new()
            VirtualUser:Button2Down(Vector2.zero, cf)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.zero, cf)
        end
    )
end

-- Re-apply instantly when the game resets a value (no 1s polling loop)
local function bindCharacter(char)
    for _, c in CharConns do
        c:Disconnect()
    end
    table.clear(CharConns)

    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then
        return
    end
    applyHumanoid(hum)

    for _, prop in {"WalkSpeed", "JumpPower", "UseJumpPower"} do
        table.insert(
            CharConns,
            hum:GetPropertyChangedSignal(prop):Connect(
                function()
                    applyHumanoid(hum)
                end
            )
        )
    end
end

Connections.Char = LocalPlayer.CharacterAdded:Connect(bindCharacter)
if LocalPlayer.Character then
    task.spawn(bindCharacter, LocalPlayer.Character)
end

Connections.FOV = RunService.RenderStepped:Connect(applyFOV)

Connections.Zoom =
    LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(
    function()
        if infiniteZoom and LocalPlayer.CameraMaxZoomDistance ~= 9e9 then
            LocalPlayer.CameraMaxZoomDistance = 9e9
        end
    end
)

local function Unload()
    for _, c in Connections do
        c:Disconnect()
    end
    for _, c in CharConns do
        c:Disconnect()
    end
    table.clear(Connections)
    table.clear(CharConns)
    table.clear(Overrides)
    setInfiniteZoom(false)
    env.CookieysHubLoaded = nil
    pcall(
        function()
            Window:Destroy()
        end
    )
end

local function runExternalScript(url, name)
    notify("Loading...", "Fetching " .. name, nil, 2)
    task.spawn(
        function()
            local src = httpGet(url)
            if not src then
                return notify("Error", "Failed to download " .. name, "alert-triangle")
            end

            local fn, err = loadstring(src, "=" .. name)
            if not fn then
                return notify("Error", "Syntax error: " .. tostring(err), "alert-triangle")
            end

            local ok, runErr = xpcall(fn, debug.traceback)
            if ok then
                notify("Success", name .. " executed.", "check")
            else
                warn("[Cookieys Hub] " .. name .. " errored:\n" .. tostring(runErr))
                notify("Error", name .. " errored. See console.", "alert-triangle")
            end
        end
    )
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
Window =
    WindUI:CreateWindow(
    {
        Title = "cookieys hub",
        Icon = "cookie",
        Author = "XyraV",
        Folder = "cookieys-config",
        Size = UDim2.fromOffset(500, 380),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 170,
        HasOutline = true
    }
)

Window:EditOpenButton(
    {
        Title = "Open Hub",
        Icon = "cookie",
        CornerRadius = UDim.new(0, 10),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        Draggable = true
    }
)

local Tabs = {
    Home = Window:Tab({Title = "Home", Icon = "house"}),
    Scripts = Window:Tab({Title = "Scripts", Icon = "scroll"}),
    Player = Window:Tab({Title = "Local Player", Icon = "user"}),
    Settings = Window:Tab({Title = "Settings", Icon = "settings"})
}

----------------------------------------------------------------
-- Home
----------------------------------------------------------------
Tabs.Home:Section({Title = "Information"})
Tabs.Home:Paragraph(
    {
        Title = "Welcome, " .. LocalPlayer.Name,
        Desc = ("PlaceId: %d\nGameId: %d"):format(game.PlaceId, game.GameId)
    }
)

Tabs.Home:Button(
    {
        Title = "Copy Discord Invite",
        Desc = "Join our community!",
        Icon = "link",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/ee4veXxYFZ")
                notify("Success", "Copied to clipboard!", "check")
            else
                notify("Error", "Your executor doesn't support clipboard.", "alert-triangle")
            end
        end
    }
)

----------------------------------------------------------------
-- Scripts
----------------------------------------------------------------
for _, s in EXTERNAL_SCRIPTS do
    local name, desc, icon, url = s[1], s[2], s[3], s[4]
    Tabs.Scripts:Button(
        {
            Title = name,
            Desc = desc,
            Icon = icon,
            Callback = function()
                runExternalScript(url, name)
            end
        }
    )
end

----------------------------------------------------------------
-- Local player
----------------------------------------------------------------
local Elements = {}

Elements.WalkSpeed =
    Tabs.Player:Slider(
    {
        Title = "Walk Speed",
        Icon = "footprints",
        Step = 1,
        Value = {Min = 16, Max = 300, Default = 16},
        Callback = function(v)
            setOverride("WalkSpeed", v, 16)
        end
    }
)

Elements.JumpPower =
    Tabs.Player:Slider(
    {
        Title = "Jump Power",
        Icon = "arrow-up",
        Step = 1,
        Value = {Min = 50, Max = 300, Default = 50},
        Callback = function(v)
            setOverride("JumpPower", v, 50)
        end
    }
)

Elements.FOV =
    Tabs.Player:Slider(
    {
        Title = "Field of View",
        Icon = "eye",
        Step = 1,
        Value = {Min = 70, Max = 120, Default = 70},
        Callback = function(v)
            setOverride("FOV", v, 70)
        end
    }
)

Tabs.Player:Divider()

Elements.InfiniteZoom =
    Tabs.Player:Toggle(
    {
        Title = "Infinite Zoom",
        Desc = "Scroll out as far as you want.",
        Callback = setInfiniteZoom
    }
)

Elements.AntiAFK =
    Tabs.Player:Toggle(
    {
        Title = "Anti-AFK",
        Desc = "Prevents being kicked for idling.",
        Callback = setAntiAFK
    }
)

----------------------------------------------------------------
-- Settings
----------------------------------------------------------------
Tabs.Settings:Section({Title = "Interface"})

local themes = {}
for name in pairs(WindUI:GetThemes()) do
    table.insert(themes, name)
end
table.sort(themes)

Elements.Theme =
    Tabs.Settings:Dropdown(
    {
        Title = "Theme",
        Values = themes,
        Value = "Dark",
        Callback = function(t)
            WindUI:SetTheme(t)
        end
    }
)

Elements.Transparency =
    Tabs.Settings:Toggle(
    {
        Title = "Transparent Background",
        Value = true,
        Callback = function(v)
            Window:ToggleTransparency(v)
        end
    }
)

Tabs.Settings:Divider()
Tabs.Settings:Section({Title = "Configuration"})

-- Keys kept the same as before so old configs still load
local Registry = {
    Theme = Elements.Theme,
    Transparency = Elements.Transparency,
    WS = Elements.WalkSpeed,
    JP = Elements.JumpPower,
    FOV = Elements.FOV,
    InfZoom = Elements.InfiniteZoom,
    AntiAFK = Elements.AntiAFK
}

local configName = "default"

local function listConfigs()
    local cm = Window.ConfigManager
    if cm and cm.AllConfigs then
        local ok, list = pcall(cm.AllConfigs, cm)
        if ok and type(list) == "table" then
            return list
        end
    end
    return {}
end

local function getConfig()
    local name = tostring(configName or ""):gsub("[^%w_%- ]", "")
    if name == "" then
        notify("Error", "Enter a config name first.", "alert-triangle")
        return
    end
    local cfg = Window.ConfigManager:CreateConfig(name)
    for key, element in pairs(Registry) do
        cfg:Register(key, element)
    end
    return cfg, name
end

Tabs.Settings:Input(
    {
        Title = "Config Name",
        Placeholder = "Type name here...",
        Callback = function(txt)
            configName = txt
        end
    }
)

local ConfigDropdown =
    Tabs.Settings:Dropdown(
    {
        Title = "Saved Configs",
        Values = listConfigs(),
        AllowNone = true,
        Callback = function(val)
            if type(val) == "string" and val ~= "" then
                configName = val
            end
        end
    }
)

Tabs.Settings:Button(
    {
        Title = "Save Config",
        Icon = "save",
        Callback = function()
            local cfg, name = getConfig()
            if not cfg then
                return
            end
            local ok, err = pcall(cfg.Save, cfg)
            if ok then
                notify("Saved", "Config saved as " .. name, "save")
                ConfigDropdown:Refresh(listConfigs())
            else
                notify("Error", "Save failed: " .. tostring(err), "alert-triangle")
            end
        end
    }
)

Tabs.Settings:Button(
    {
        Title = "Load Config",
        Icon = "download",
        Callback = function()
            local cfg, name = getConfig()
            if not cfg then
                return
            end
            local ok, err = pcall(cfg.Load, cfg)
            if ok then
                applyAll()
                notify("Loaded", "Config loaded: " .. name, "check")
            else
                notify("Error", "Load failed: " .. tostring(err), "alert-triangle")
            end
        end
    }
)

Tabs.Settings:Divider()
Tabs.Settings:Button(
    {
        Title = "Unload Hub",
        Icon = "power",
        Desc = "Disconnects everything and closes the window.",
        Callback = Unload
    }
)

----------------------------------------------------------------
-- Init
----------------------------------------------------------------
Window:SelectTab(1)
