local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(500, 400), -- Reduced size from 580, 460
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180, -- Reduced sidebar width from 200
    --Background = "rbxassetid://13511292247", -- rbxassetid only
    HasOutline = false,
    -- remove it below if you don't want to use the key system in your script.
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678",
        -- Thumbnail = {
        --     Image = "rbxassetid://18220445082", -- rbxassetid only
        --     Title = "Thumbnail"
        -- },
        URL = "https://github.com/Footagesus/WindUI", -- remove this if the key is not obtained from the link.
        SaveKey = true, -- optional
    },
})


Window:EditOpenButton({
    Title = "Open Example UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0,10),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    --Enabled = false,
    Draggable = true,
})


local Tabs = {
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome! Find general information here." }),
    ButtonTab = Window:Tab({ Title = "Button", Icon = "mouse-pointer-2", Desc = "Contains interactive buttons for various actions." }),
    CodeTab = Window:Tab({ Title = "Code", Icon = "code", Desc = "Displays and manages code snippets." }),
    NotificationTab = Window:Tab({ Title = "Notification", Icon = "bell", Desc = "Configure and view notifications." }),
    ToggleTab = Window:Tab({ Title = "Toggle", Icon = "toggle-left", Desc = "Switch settings on and off." }),
    b = Window:Divider(),
    WindowTab = Window:Tab({ Title = "Window and File Configuration", Icon = "settings", Desc = "Manage window settings and file configurations." }),
    CreateThemeTab = Window:Tab({ Title = "Create Theme", Icon = "palette", Desc = "Design and apply custom themes." }),
    be = Window:Divider(),
}

Window:SelectTab(1) -- Select the Home tab

-- Add elements to the Home Tab
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
                    Icon = "clipboard-check", -- Use the requested icon
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


Tabs.ButtonTab:Button({
    Title = "Click Me",
    Desc = "This is a simple button",
    Callback = function() print("Button Clicked!") end
})

Tabs.ButtonTab:Button({
    Title = "Locked Button",
    Desc = "This button is locked",
    Locked = true,
})

Tabs.ButtonTab:Button({
    Title = "Submit",
    Desc = "Click to submit",
    Callback = function() print("Submitted!") end,
    Locked = false
})


Tabs.CodeTab:Code({
    Title = "Example Code",
    Code = [[

local message = "Hello"
print(message)

if message == "Hello" then
    print("Greetings!")
end
    ]],
})

Tabs.CodeTab:Code({
    Title = "Another Code Example",
    Code = [[
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "WindUI Example",
    Icon = "image",
    Author = ".ftgs",
    Folder = "CloudHub",
    Size = UDim2.fromOffset(580, 460),
})
    ]],
})


Tabs.NotificationTab:Button({
    Title = "Click to get Notified",
    Callback = function()
        WindUI:Notify({
            Title = "Notification Example",
            Content = "Content",
            Icon = "droplet-off",
            Duration = 5,
        })
    end
})


Tabs.ToggleTab:Toggle({
    Title = "Enable Feature",
    Default = true,
    Callback = function(state) print("Feature enabled: " .. tostring(state)) end
})

Tabs.ToggleTab:Toggle({
    Title = "Activate Mode",
    Default = false,
    Callback = function(state) print("Mode activated: " .. tostring(state)) end
})
Tabs.ToggleTab:Toggle({
    Title = "Toggle with icon",
    Icon = "check",
    Default = false,
    Callback = function(state) print("Toggle with icon activated: " .. tostring(state)) end
})

-- Configuration

local HttpService = game:GetService("HttpService")

local folderPath = "WindUI"
pcall(makefolder, folderPath) -- Use pcall for safety

local function SaveFile(fileName, data)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    local success, err = pcall(function()
        local jsonData = HttpService:JSONEncode(data)
        writefile(filePath, jsonData)
    end)
    if not success then warn("Failed to save file:", err) end
    return success -- Return success status
end

local function LoadFile(fileName)
    local filePath = folderPath .. "/" .. fileName .. ".json"
    if isfile and isfile(filePath) then -- Check if isfile exists
        local success, result = pcall(function()
             local jsonData = readfile(filePath)
             return HttpService:JSONDecode(jsonData)
        end)
        if success then
            return result
        else
            warn("Failed to load or decode file:", result)
            return nil
        end
    end
    return nil
end

local function ListFiles()
    local files = {}
    if not listfiles or not isfolder then return files end -- Check if functions exist
    local success, result = pcall(function()
        if not isfolder(folderPath) then makefolder(folderPath) end -- Ensure folder exists
        local fileList = listfiles(folderPath)
        if not fileList then return end
        for _, file in ipairs(fileList) do
            local fileName = file:match("([^/]+)%.json$")
            if fileName then
                table.insert(files, fileName)
            end
        end
    end)
    if not success then warn("Failed to list files:", result) end
    return files
end

Tabs.WindowTab:Section({ Title = "Window" })

local themeValues = {}
local successThemes, themesResult = pcall(WindUI.GetThemes, WindUI)
if successThemes and type(themesResult) == "table" then
    for name, _ in pairs(themesResult) do
        table.insert(themeValues, name)
    end
else
    warn("Failed to get themes:", themesResult)
    themeValues = {"Dark", "Light"} -- Fallback if GetThemes fails
end

local currentThemeName = WindUI:GetCurrentTheme() or "Dark" -- Fallback theme

local themeDropdown = Tabs.WindowTab:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = currentThemeName,
    Values = themeValues,
    Callback = function(theme)
        local successSetTheme, errSetTheme = pcall(WindUI.SetTheme, WindUI, theme)
        if not successSetTheme then warn("Failed to set theme:", errSetTheme) end
    end
})
--themeDropdown:Select(currentThemeName) -- Value parameter handles initial selection

local ToggleTransparency = Tabs.WindowTab:Toggle({
    Title = "Window Transparency",
    Callback = function(e)
        local successToggle, errToggle = pcall(Window.ToggleTransparency, Window, e)
        if not successToggle then warn("Failed to toggle transparency:", errToggle) end
    end,
    Default = WindUI:GetTransparency() or false -- Use Default and provide fallback
})

Tabs.WindowTab:Section({ Title = "Save Configuration" })

local fileNameInput = ""
Tabs.WindowTab:Input({
    Title = "Config Name",
    PlaceholderText = "Enter config name",
    Default = "", -- Ensure default is empty string
    Callback = function(text)
        fileNameInput = text
    end
})

Tabs.WindowTab:Button({
    Title = "Save Config",
    Callback = function()
        if fileNameInput and fileNameInput:gsub("%s+", "") ~= "" then -- Check if not nil or empty/whitespace
            local success = SaveFile(fileNameInput, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
            if success then
                WindUI:Notify({ Title = "Saved", Content = "'" .. fileNameInput .. "' saved.", Icon="save", Duration = 3 })
                 -- Refresh file list after saving
                 local newFiles = ListFiles()
                 pcall(filesDropdown.Refresh, filesDropdown, newFiles)
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to save '" .. fileNameInput .. "'.", Icon="alert-triangle", Duration = 3 })
            end
        else
             WindUI:Notify({ Title = "Error", Content = "Please enter a valid file name.", Icon="alert-triangle", Duration = 3 })
        end
    end
})

Tabs.WindowTab:Section({ Title = "Load Configuration" })

local files = ListFiles()
local selectedFileToLoad = nil

local filesDropdown = Tabs.WindowTab:Dropdown({
    Title = "Select Config",
    Multi = false,
    AllowNone = true, -- Allow deselecting
    Values = files,
    Callback = function(selectedFile)
        -- If selectedFile is an empty table (occurs when deselecting), treat as nil
        if type(selectedFile) == "table" and next(selectedFile) == nil then
            selectedFileToLoad = nil
        else
            selectedFileToLoad = selectedFile
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Load Config",
    Callback = function()
        if selectedFileToLoad and selectedFileToLoad ~= "" then
            local data = LoadFile(selectedFileToLoad)
            if data then
                WindUI:Notify({
                    Title = "Config Loaded",
                    Content = "'"..selectedFileToLoad.."' loaded.",
                    Icon = "folder-open",
                    Duration = 3,
                })
                -- Apply transparency setting
                if data.Transparent ~= nil then
                    pcall(Window.ToggleTransparency, Window, data.Transparent)
                    pcall(ToggleTransparency.SetValue, ToggleTransparency, data.Transparent)
                end
                -- Apply theme setting
                if data.Theme and type(data.Theme) == "string" then
                   local successSetTheme, errSetTheme = pcall(WindUI.SetTheme, WindUI, data.Theme)
                   if successSetTheme then
                       currentThemeName = data.Theme -- Update the current theme name tracker
                       pcall(themeDropdown.Select, themeDropdown, data.Theme)
                   else
                       warn("Failed to set theme from file:", errSetTheme)
                       WindUI:Notify({ Title = "Warning", Content = "Could not apply theme '"..data.Theme.."' from config.", Icon="alert-circle", Duration = 4 })
                   end
                end
            else
                 WindUI:Notify({ Title = "Error", Content = "Failed to load '"..selectedFileToLoad.."'.", Icon="alert-triangle", Duration = 3 })
            end
        else
             WindUI:Notify({ Title = "Error", Content = "Please select a config to load.", Icon="alert-triangle", Duration = 3 })
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Overwrite Config",
    Callback = function()
        if selectedFileToLoad and selectedFileToLoad ~= "" then
           local success = SaveFile(selectedFileToLoad, { Transparent = WindUI:GetTransparency(), Theme = WindUI:GetCurrentTheme() })
            if success then
                WindUI:Notify({ Title = "Overwritten", Content = "'" .. selectedFileToLoad .. "' overwritten.", Icon="save", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to overwrite '"..selectedFileToLoad.."'.", Icon="alert-triangle", Duration = 3 })
            end
        else
             WindUI:Notify({ Title = "Error", Content = "Please select a config to overwrite.", Icon="alert-triangle", Duration = 3 })
        end
    end
})

Tabs.WindowTab:Button({
    Title = "Refresh Config List",
    Callback = function()
        local newFiles = ListFiles()
        local successRefresh, errRefresh = pcall(filesDropdown.Refresh, filesDropdown, newFiles)
        if not successRefresh then
            warn("Failed to refresh file list:", errRefresh)
            WindUI:Notify({Title="Error", Content="Could not refresh list.", Icon="alert-triangle", Duration=3})
        else
             WindUI:Notify({Title="Refreshed", Content="Config list updated.", Icon="refresh-cw", Duration=2})
             selectedFileToLoad = nil -- Reset selection after refresh
        end
    end
})

-- Theme Creation Tab Logic
local themeCreationName = currentThemeName
local themesCache = WindUI:GetThemes() or {}
local currentThemeData = themesCache[currentThemeName] or { Accent = "#8A2BE2", Outline = "#1C1C1C", Text = "#FFFFFF", PlaceholderText = "#A9A9A9" } -- Default theme values (example: Purple/Dark)

local themeAccentColor = Color3.fromHex(currentThemeData.Accent)
local themeOutlineColor = Color3.fromHex(currentThemeData.Outline)
local themeTextColor = Color3.fromHex(currentThemeData.Text)
local themePlaceholderColor = Color3.fromHex(currentThemeData.PlaceholderText)

local themeNameInputRef -- Reference to the input field

local function updateThemeFunction()
    if not themeCreationName or themeCreationName:gsub("%s+", "") == "" then
        WindUI:Notify({ Title = "Theme Error", Content = "Theme name cannot be empty.", Icon="alert-triangle", Duration = 3 })
        return
    end

    local themeData = {
        Name = themeCreationName,
        Accent = themeAccentColor:ToHex(),
        Outline = themeOutlineColor:ToHex(),
        Text = themeTextColor:ToHex(),
        PlaceholderText = themePlaceholderColor:ToHex()
    }

    local successAdd, errAdd = pcall(WindUI.AddTheme, WindUI, themeData)
    if not successAdd then
        warn("Failed to add/update theme:", errAdd)
        WindUI:Notify({ Title = "Theme Error", Content = "Could not update theme.", Icon="alert-triangle", Duration = 3 })
        return
    end

    local successSet, errSet = pcall(WindUI.SetTheme, WindUI, themeCreationName)
    if not successSet then
        warn("Failed to set new theme:", errSet)
         WindUI:Notify({ Title = "Theme Error", Content = "Could not apply updated theme.", Icon="alert-triangle", Duration = 3 })
    else
         currentThemeName = themeCreationName -- Update the global tracker
         WindUI:Notify({ Title = "Theme Updated", Content = "'"..themeCreationName.."' updated and applied.", Icon="palette", Duration = 3 })
         -- Refresh theme dropdown in Window tab
         local newThemeValues = {}
         local updatedThemes = WindUI:GetThemes() or {}
         for name, _ in pairs(updatedThemes) do table.insert(newThemeValues, name) end
         pcall(themeDropdown.Refresh, themeDropdown, newThemeValues)
         pcall(themeDropdown.Select, themeDropdown, themeCreationName) -- Select the newly updated/created theme
    end
end

themeNameInputRef = Tabs.CreateThemeTab:Input({
    Title = "Theme Name",
    PlaceholderText = "Enter new or existing theme name",
    Default = themeCreationName, -- Use Default for initial value
    Callback = function(name)
        themeCreationName = name
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Accent Color",
    Desc = "Backgrounds, highlights",
    Default = themeAccentColor,
    Callback = function(color)
        themeAccentColor = color
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Outline Color",
    Desc = "Borders, separators",
    Default = themeOutlineColor,
    Callback = function(color)
        themeOutlineColor = color
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Text Color",
    Desc = "Primary text elements",
    Default = themeTextColor,
    Callback = function(color)
        themeTextColor = color
    end
})

Tabs.CreateThemeTab:Colorpicker({
    Title = "Placeholder Text Color",
    Desc = "Input field hints",
    Default = themePlaceholderColor,
    Callback = function(color)
        themePlaceholderColor = color
    end
})

Tabs.CreateThemeTab:Button({
    Title = "Update / Create Theme",
    Desc = "Saves and applies the current theme settings.",
    Callback = updateThemeFunction
})
