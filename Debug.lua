-- [[ Advanced Debug Hub ]]
-- Improved with: Remote Spy, Auto-Log Capture, Enhanced Script Scanner, and Interactive Tools

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- // Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- // UI Library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- // Window Setup
local Window = WindUI:CreateWindow({
    Title = "Debug Hub // Extended",
    Author = "XyraV",
    Folder = "DebugHubExt",
    Size = UDim2.fromOffset(750, 550),
    Theme = "Dark",
    SideBarWidth = 200,
    Transparent = true
})

Window:EditOpenButton({
    Title = "Debugger",
    Icon = "bug",
    CornerRadius = UDim.new(0, 10),
    Draggable = true,
})

-- // Tabs
local Tabs = {
    Console = Window:Tab({ Title = "Console", Icon = "terminal" }),
    Spy = Window:Tab({ Title = "Remote Spy", Icon = "radio" }),
    Executor = Window:Tab({ Title = "Environment", Icon = "cpu" }),
    Scripts = Window:Tab({ Title = "Script Scanner", Icon = "file-code" }),
    Instance = Window:Tab({ Title = "Instance Tools", Icon = "box" }),
    GC = Window:Tab({ Title = "Garbage Collector", Icon = "trash" })
}
Window:SelectTab(1)

-- // Global Variables
local isSpying = false
local ignoredRemotes = {}
local consoleLogs = {}
local consoleParagraph = nil

-- // Utility Functions
local function formatTable(tbl, indent)
    indent = indent or 0
    local result = ""
    local prefix = string.rep("  ", indent)
    
    if indent > 5 then return prefix .. "... (Max Depth)" end

    for k, v in pairs(tbl) do
        local keyStr = tostring(k)
        if type(k) == "string" then keyStr = '"' .. k .. '"' end
        
        if type(v) == "table" then
            result = result .. prefix .. "[" .. keyStr .. "] = {\n" .. formatTable(v, indent + 1) .. prefix .. "},\n"
        elseif type(v) == "string" then
            result = result .. prefix .. "[" .. keyStr .. '] = "' .. v .. '",\n'
        else
            result = result .. prefix .. "[" .. keyStr .. "] = " .. tostring(v) .. " (" .. typeof(v) .. "),\n"
        end
    end
    return result
end

-- // ==================== CONSOLE TAB ====================
do
    Tabs.Console:Section({ Title = "Output Log" })
    
    consoleParagraph = Tabs.Console:Paragraph({
        Title = "Live Game Output",
        Desc = "Waiting for logs..."
    })

    local function updateLogUI()
        if consoleParagraph and consoleParagraph.SetDesc then
            -- Only show last 30 lines to prevent lag
            local displayLogs = {}
            local count = #consoleLogs
            local start = math.max(1, count - 30)
            for i = start, count do
                table.insert(displayLogs, consoleLogs[i])
            end
            consoleParagraph:SetDesc(table.concat(displayLogs, "\n"))
        end
    end

    local function logMessage(msg, type)
        local time = os.date("%H:%M:%S")
        local color = "#ffffff"
        local prefix = "[INFO]"

        if type == Enum.MessageType.MessageWarning then
            color = "#ffcc00" -- Yellow
            prefix = "[WARN]"
        elseif type == Enum.MessageType.MessageError then
            color = "#ff3333" -- Red
            prefix = "[ERR]"
        elseif type == Enum.MessageType.MessageOutput then
            color = "#cccccc" -- Grey
            prefix = "[PRINT]"
        end

        local formatted = string.format("<font color='#808080'>%s</font> <font color='%s'>%s %s</font>", time, color, prefix, msg)
        table.insert(consoleLogs, formatted)
        
        if #consoleLogs > 200 then table.remove(consoleLogs, 1) end
        updateLogUI()
    end

    -- Hook into Roblox LogService
    LogService.MessageOut:Connect(logMessage)
    
    Tabs.Console:Button({
        Title = "Clear Console",
        Icon = "eraser",
        Callback = function()
            consoleLogs = {}
            updateLogUI()
        end
    })

    Tabs.Console:Section({ Title = "Execution" })
    local sourceCode = ""
    Tabs.Console:Input({
        Title = "Lua Source",
        Type = "Textarea",
        Placeholder = "print('Hello World')",
        Callback = function(v) sourceCode = v end
    })
    
    Tabs.Console:Button({
        Title = "Execute",
        Icon = "play",
        Callback = function()
            if sourceCode ~= "" then
                task.spawn(function()
                    local func, err = loadstring(sourceCode)
                    if func then
                        func()
                    else
                        warn("Syntax Error: " .. tostring(err))
                    end
                end)
            end
        end
    })
end

-- // ==================== REMOTE SPY TAB ====================
do
    local spyOutput
    local remoteLogs = {}

    Tabs.Spy:Section({ Title = "Control" })
    
    Tabs.Spy:Toggle({
        Title = "Enable Spy",
        Desc = "Hooks __namecall to log RemoteEvents/Functions.",
        Callback = function(v) isSpying = v end
    })

    Tabs.Spy:Button({
        Title = "Clear Logs",
        Icon = "trash",
        Callback = function()
            remoteLogs = {}
            if spyOutput then spyOutput:SetCode("-- Logs cleared") end
        end
    })

    Tabs.Spy:Section({ Title = "Captured Calls" })
    spyOutput = Tabs.Spy:Code({
        Title = "Remote Log",
        Code = "-- Enable spy to see calls..."
    })

    -- The Hook
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    if setreadonly then setreadonly(mt, false) end

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if isSpying and (method == "FireServer" or method == "InvokeServer") then
            if not ignoredRemotes[self] then
                task.spawn(function()
                    local path = self:GetFullName()
                    local argsStr = formatTable(args)
                    local entry = string.format("-- [%s] %s\npath: %s\nargs: {\n%s}\n----------------", os.date("%H:%M:%S"), method, path, argsStr)
                    
                    table.insert(remoteLogs, 1, entry)
                    if #remoteLogs > 20 then table.remove(remoteLogs) end
                    
                    if spyOutput and spyOutput.SetCode then
                        spyOutput:SetCode(table.concat(remoteLogs, "\n"))
                    end
                end)
            end
        end

        return old_namecall(self, ...)
    end)
    
    if setreadonly then setreadonly(mt, true) end
end

-- // ==================== EXECUTOR TAB ====================
do
    Tabs.Executor:Section({ Title = "Environment Check" })
    
    local function checkFunc(name)
        return (getfenv()[name] and "✅") or "❌"
    end

    local funcsToCheck = {
        "getgenv", "getrenv", "getgc", "getreg", "getloadedmodules", 
        "checkcaller", "newcclosure", "hookfunction", "getrawmetatable", 
        "setreadonly", "identifyexecutor", "lz4compress"
    }

    for _, fn in ipairs(funcsToCheck) do
        Tabs.Executor:Paragraph({
            Title = fn,
            Desc = "Available: " .. checkFunc(fn)
        })
    end
end

-- // ==================== SCRIPTS TAB ====================
do
    Tabs.Scripts:Section({ Title = "Scanner" })
    
    local scriptList = {}
    local selectedScript = nil
    local scriptContentDisplay

    local function refreshScripts()
        local list = {}
        local rawList = {}
        
        -- Try to get running scripts, fallback to getscripts, fallback to nil
        local success, scripts = pcall(function()
            return getrunningscripts and getrunningscripts() or getscripts()
        end)

        if success and scripts then
            for _, s in ipairs(scripts) do
                if s and s:IsA("LocalScript") or s:IsA("ModuleScript") then
                    local name = (s.Name == "" and "Unnamed") or s.Name
                    table.insert(list, name .. " | " .. s.ClassName)
                    table.insert(rawList, s)
                end
            end
        end
        return list, rawList
    end

    local dropdown
    local sNames, sRefs = refreshScripts()

    dropdown = Tabs.Scripts:Dropdown({
        Title = "Select Script",
        Values = sNames,
        Callback = function(val)
            -- Find index
            for i, name in ipairs(sNames) do
                if name == val then
                    selectedScript = sRefs[i]
                    break
                end
            end
        end
    })

    Tabs.Scripts:Button({
        Title = "Refresh List",
        Callback = function()
            sNames, sRefs = refreshScripts()
            dropdown:Refresh(sNames)
        end
    })

    Tabs.Scripts:Section({ Title = "Actions" })
    
    scriptContentDisplay = Tabs.Scripts:Code({
        Title = "Decompiled Source / Info",
        Code = "-- Select a script and click an action"
    })

    Tabs.Scripts:Button({
        Title = "Decompile",
        Callback = function()
            if not selectedScript then return end
            if not decompile then 
                scriptContentDisplay:SetCode("-- Decompiler not supported on this executor.")
                return 
            end
            
            scriptContentDisplay:SetCode("-- Decompiling... please wait.")
            task.spawn(function()
                local success, src = pcall(decompile, selectedScript)
                scriptContentDisplay:SetCode(success and src or "-- Decompilation failed: " .. tostring(src))
            end)
        end
    })

    Tabs.Scripts:Button({
        Title = "Get Script Hash",
        Callback = function()
            if not selectedScript then return end
            if getscripthash then
                scriptContentDisplay:SetCode("Hash: " .. getscripthash(selectedScript))
            else
                scriptContentDisplay:SetCode("-- getscripthash not supported.")
            end
        end
    })
    
    Tabs.Scripts:Button({
        Title = "Delete Script",
        Callback = function()
            if selectedScript then 
                selectedScript:Destroy() 
                WindUI:Notify({Title="Deleted", Content="Script destroyed locally."})
            end
        end
    })
end

-- // ==================== INSTANCE TOOLS TAB ====================
do
    local targetPath = ""
    local targetInstance = nil

    Tabs.Instance:Section({ Title = "Selection" })
    
    Tabs.Instance:Input({
        Title = "Path to Instance",
        Placeholder = "game.Workspace.Part",
        Callback = function(v) targetPath = v end
    })

    Tabs.Instance:Button({
        Title = "Select Instance",
        Callback = function()
            local segments = targetPath:split(".")
            local current = game
            local valid = true
            
            -- Skip 'game' if user typed it
            local start = (segments[1] == "game") and 2 or 1
            
            for i = start, #segments do
                if current[segments[i]] then
                    current = current[segments[i]]
                else
                    valid = false
                    break
                end
            end
            
            if valid and typeof(current) == "Instance" then
                targetInstance = current
                WindUI:Notify({Title="Selected", Content=current:GetFullName(), Icon="check"})
            else
                WindUI:Notify({Title="Error", Content="Invalid path or not an Instance", Icon="alert-triangle"})
            end
        end
    })

    Tabs.Instance:Section({ Title = "Interaction Tools" })
    
    Tabs.Instance:Button({
        Title = "Fire ClickDetector",
        Callback = function()
            if targetInstance and targetInstance:FindFirstChildWhichIsA("ClickDetector") then
                fireclickdetector(targetInstance:FindFirstChildWhichIsA("ClickDetector"))
                WindUI:Notify({Title="Fired", Content="ClickDetector fired"})
            elseif targetInstance and targetInstance:IsA("ClickDetector") then
                fireclickdetector(targetInstance)
                WindUI:Notify({Title="Fired", Content="ClickDetector fired"})
            else
                WindUI:Notify({Title="Error", Content="No ClickDetector found on selection"})
            end
        end
    })
    
    Tabs.Instance:Button({
        Title = "Fire ProximityPrompt",
        Callback = function()
            if targetInstance and targetInstance:FindFirstChildWhichIsA("ProximityPrompt") then
                fireproximityprompt(targetInstance:FindFirstChildWhichIsA("ProximityPrompt"))
                WindUI:Notify({Title="Fired", Content="ProximityPrompt fired"})
            elseif targetInstance and targetInstance:IsA("ProximityPrompt") then
                fireproximityprompt(targetInstance)
                WindUI:Notify({Title="Fired", Content="ProximityPrompt fired"})
            else
                WindUI:Notify({Title="Error", Content="No ProximityPrompt found on selection"})
            end
        end
    })

    Tabs.Instance:Button({
        Title = "Fire TouchInterest",
        Callback = function()
            if targetInstance and targetInstance:IsA("BasePart") then
                if firetouchinterest then
                    firetouchinterest(Players.LocalPlayer.Character.HumanoidRootPart, targetInstance, 0)
                    task.wait()
                    firetouchinterest(Players.LocalPlayer.Character.HumanoidRootPart, targetInstance, 1)
                    WindUI:Notify({Title="Fired", Content="TouchInterest fired"})
                else
                    -- Fallback
                    local old = Players.LocalPlayer.Character.HumanoidRootPart.CFrame
                    Players.LocalPlayer.Character.HumanoidRootPart.CFrame = targetInstance.CFrame
                    task.wait(0.1)
                    Players.LocalPlayer.Character.HumanoidRootPart.CFrame = old
                end
            else
                WindUI:Notify({Title="Error", Content="Selection must be a Part"})
            end
        end
    })
end

-- // ==================== GC TAB ====================
do
    Tabs.GC:Section({ Title = "Scanner" })
    
    local scanKey = ""
    Tabs.GC:Input({
        Title = "Search Key/Value",
        Placeholder = "e.g. 'Health' or 'WalkSpeed'",
        Callback = function(v) scanKey = v end
    })

    Tabs.GC:Button({
        Title = "Scan GC",
        Desc = "Scans Garbage Collector for tables containing the key.",
        Callback = function()
            if not getgc then return WindUI:Notify({Title="Error", Content="getgc not supported"}) end
            if scanKey == "" then return end

            local foundCount = 0
            logMessage("Starting GC Scan for: " .. scanKey, Enum.MessageType.MessageOutput)
            
            for _, v in pairs(getgc(true)) do
                if type(v) == "table" then
                    -- Check keys and values
                    local success, hasKey = pcall(function() return v[scanKey] ~= nil end)
                    
                    if success and hasKey then
                        foundCount = foundCount + 1
                        -- Log first 5 results to console
                        if foundCount <= 5 then
                            logMessage("Found Table: " .. tostring(v), Enum.MessageType.MessageOutput)
                        end
                    end
                end
            end
            
            WindUI:Notify({Title="Scan Complete", Content="Found " .. foundCount .. " matches."})
        end
    })
end
