-- Wait for the game to be fully loaded, if necessary
if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

-- Load the UI library
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create the main window
local Window = WindUI:CreateWindow({
    Title = "Debug Hub",
    Author = "XyraV",
    Folder = "DebugUI",
    Size = UDim2.fromOffset(600, 500),
    Theme = "Dark",
    SideBarWidth = 220,
})

-- Customize the open/close button
Window:EditOpenButton({
    Title = "Debug",
    Icon = "bug",
    Draggable = true,
})

-- Create the main tabs
local Tabs = {
    Console = Window:Tab({ Title = "Console", Icon = "terminal", Desc = "Execute code and view logs from other tabs." }),
    Executor = Window:Tab({ Title = "Executor", Icon = "cpu", Desc = "Information and functions related to your executor." }),
    Scripts = Window:Tab({ Title = "Scripts", Icon = "file-code-2", Desc = "Inspect, decompile, and analyze running scripts." }),
    Instance = Window:Tab({ Title = "Instance Explorer", Icon = "box", Desc = "Inspect instances and their properties/metatables." }),
    GC = Window:Tab({ Title = "Garbage Collector", Icon = "trash-2", Desc = "Scan and filter items in memory." })
}
Window:SelectTab(1)

-- ===== Console Tab & Logging System =====
local consoleLog = {}
local consoleParagraph

local function logToConsole(prefix, ...)
    local args = {...}
    local message = ""
    for i, v in ipairs(args) do
        message = message .. tostring(v) .. (i == #args and "" or " ")
    end
    local timestamp = os.date("[%H:%M:%S]")
    local fullLog = string.format("%s <font color='#808080'>[%s]:</font> %s", timestamp, prefix, message)
    table.insert(consoleLog, 1, fullLog)
    if #consoleLog > 150 then -- Keep log size reasonable
        table.remove(consoleLog)
    end
    if consoleParagraph and consoleParagraph.SetDesc then
        consoleParagraph:SetDesc(table.concat(consoleLog, "\n"))
    end
end

do -- Console Tab
    Tabs.Console:Section({ Title = "Log Output" })
    consoleParagraph = Tabs.Console:Paragraph({
        Title = "Live Log",
        Desc = "Logs from other tabs will appear here."
    })
    Tabs.Console:Button({ Title = "Clear Log", Callback = function()
        consoleLog = {}
        consoleParagraph:SetDesc("")
    end})
    Tabs.Console:Section({ Title = "Execute Code" })
    local codeToRun = ""
    Tabs.Console:Input({
        Title = "Lua Code",
        Type = "Textarea",
        Placeholder = "-- Your code here...\nprint('Hello, Debugger!')",
        Callback = function(text) codeToRun = text end
    })
    Tabs.Console:Button({ Title = "Execute", Callback = function()
        if codeToRun and codeToRun ~= "" then
            local func, err = loadstring(codeToRun)
            if func then
                logToConsole("EXEC", "Executing code...")
                local success, result = pcall(func)
                if success then
                    logToConsole("EXEC", "Success!", "Result:", result)
                else
                    logToConsole("ERROR", "Execution failed:", result)
                end
            else
                logToConsole("ERROR", "Loadstring failed:", err)
            end
        end
    end})
end

-- ===== Executor Tab =====
do
    Tabs.Executor:Section({ Title = "Information" })
    Tabs.Executor:Button({
        Title = "Identify Executor",
        Desc = "Runs identifyexecutor() and prints to the console.",
        Callback = function()
            if identifyexecutor then
                local executorName, version = identifyexecutor()
                logToConsole("EXEC", "Executor:", executorName, "| Version:", version or "N/A")
                WindUI:Notify({Title = "Executor", Content = executorName})
            else
                logToConsole("ERROR", "identifyexecutor() not available.")
            end
        end
    })
    Tabs.Executor:Button({
        Title = "Get Thread Identity",
        Desc = "Gets the current script's security level.",
        Callback = function()
            if getthreadidentity then
                logToConsole("EXEC", "Current thread identity:", getthreadidentity())
            else
                logToConsole("ERROR", "getthreadidentity() not available.")
            end
        end
    })
end

-- ===== Scripts Tab =====
do
    Tabs.Scripts:Section({ Title = "Script Inspector" })
    local allScripts = getscripts and getscripts() or {}
    local scriptNames = {}
    for _, script in ipairs(allScripts) do
        local name = script.Name and #script.Name > 0 and script.Name or "(Unnamed Script)"
        table.insert(scriptNames, name .. " (" .. tostring(script) .. ")")
    end

    local selectedScript = nil
    local scriptOutput = Tabs.Scripts:Code({ Title = "Script Output", Code = "-- Select a script from the dropdown and an action below."})

    Tabs.Scripts:Dropdown({
        Title = "Running Scripts",
        Values = scriptNames,
        AllowNone = true,
        Callback = function(selection)
            if not selection then selectedScript = nil return end
            local indexStr = selection:match("%(([^)]+)%)")
            for _, script in ipairs(allScripts) do
                if tostring(script) == indexStr then
                    selectedScript = script
                    logToConsole("SCRIPT", "Selected script:", script.Name)
                    break
                end
            end
        end
    })

    Tabs.Scripts:Button({ Title = "Decompile", Callback = function()
        if not selectedScript then return WindUI:Notify({Title="Error", Content="No script selected."}) end
        if not decompile then return logToConsole("ERROR", "decompile() not available.") end
        local success, result = pcall(decompile, selectedScript)
        if success then if scriptOutput.SetCode then scriptOutput:SetCode(result or "-- Decompilation returned nil") end else logToConsole("ERROR", "Decompilation failed:", result) end
    end})
    Tabs.Scripts:Button({ Title = "Get Bytecode", Callback = function()
        if not selectedScript then return WindUI:Notify({Title="Error", Content="No script selected."}) end
        if not getscriptbytecode then return logToConsole("ERROR", "getscriptbytecode() not available.") end
        local success, result = pcall(getscriptbytecode, selectedScript)
        if success then if scriptOutput.SetCode then scriptOutput:SetCode(result) end else logToConsole("ERROR", "getscriptbytecode failed:", result) end
    end})
    Tabs.Scripts:Button({ Title = "Get Hash", Callback = function()
        if not selectedScript then return WindUI:Notify({Title="Error", Content="No script selected."}) end
        if not getscripthash then return logToConsole("ERROR", "getscripthash() not available.") end
        local success, result = pcall(getscripthash, selectedScript)
        if success then if scriptOutput.SetCode then scriptOutput:SetCode(result) end else logToConsole("ERROR", "getscripthash failed:", result) end
    end})
end

-- ===== Instance Tab =====
do
    local function prettyPrint(tbl, indent)
        indent = indent or 0
        local result = ""
        local indentStr = string.rep("  ", indent)
        for k, v in pairs(tbl) do
            result = result .. indentStr .. "[" .. tostring(k) .. "] = "
            if type(v) == "table" and next(v) then
                result = result .. "{\n" .. prettyPrint(v, indent + 1) .. indentStr .. "},\n"
            else
                result = result .. tostring(v) .. ",\n"
            end
        end
        return result
    end

    local function findInstance(path)
        local segments = path:split(".")
        local current = getfenv()
        for _, segment in ipairs(segments) do
            if (type(current) == "table" or typeof(current) == "Instance") and current[segment] then
                current = current[segment]
            else
                return nil
            end
        end
        return current
    end

    local instancePath = ""
    local selectedInstance = nil

    Tabs.Instance:Section({ Title = "Instance Finder" })
    Tabs.Instance:Input({
        Title = "Instance Path",
        Placeholder = "game.Players.LocalPlayer.Character",
        Callback = function(text) instancePath = text end
    })
    Tabs.Instance:Button({
        Title = "Find & Select Instance",
        Callback = function()
            selectedInstance = findInstance(instancePath)
            if selectedInstance then logToConsole("INSTANCE", "Selected:", tostring(selectedInstance)) WindUI:Notify({Title="Success", Content="Instance found and selected."})
            else logToConsole("ERROR", "Instance not found at path:", instancePath) WindUI:Notify({Title="Error", Content="Instance not found."}) end
        end
    })

    Tabs.Instance:Section({ Title = "Actions (on Selected Instance)" })
    Tabs.Instance:Button({ Title = "Get Raw Metatable", Callback = function()
        if not selectedInstance then return WindUI:Notify({Title="Error", Content="No instance selected."}) end
        if not getrawmetatable then return logToConsole("ERROR", "getrawmetatable() not available.") end
        local mt = getrawmetatable(selectedInstance)
        if mt then logToConsole("INSTANCE", "Metatable for", tostring(selectedInstance) .. ":\n" .. prettyPrint(mt))
        else logToConsole("INSTANCE", "No metatable found for", tostring(selectedInstance)) end
    end})

    local hiddenPropName = ""
    Tabs.Instance:Input({Title="Hidden Property Name", Callback = function(v) hiddenPropName=v end})
    Tabs.Instance:Button({ Title = "Get Hidden Property", Callback = function()
        if not selectedInstance then return WindUI:Notify({Title="Error", Content="No instance selected."}) end
        if not gethiddenproperty then return logToConsole("ERROR", "gethiddenproperty() not available.") end
        if hiddenPropName == "" then return WindUI:Notify({Title="Error", Content="No property name entered."}) end
        local success, value = pcall(gethiddenproperty, selectedInstance, hiddenPropName)
        if success then logToConsole("INSTANCE", "Hidden property '"..hiddenPropName.."' value:", tostring(value))
        else logToConsole("ERROR", "Failed to get hidden property:", value) end
    end})
end

-- ===== GC Tab =====
do
    Tabs.GC:Section({ Title = "Garbage Collector" })
    Tabs.GC:Button({ Title = "Get Full GC Count", Desc = "Counts all items in the garbage collector.", Callback = function()
        if not getgc then return logToConsole("ERROR", "getgc() not available.") end
        logToConsole("GC", "Scanning... this may take a moment.")
        task.spawn(function()
            local gc = getgc(true)
            logToConsole("GC", "Total table items in GC:", #gc)
            WindUI:Notify({Title="GC Scan Complete", Content="Found "..#gc.." table items."})
        end)
    end})
    local filterKeyword = ""
    Tabs.GC:Input({ Title = "Filter Keyword", Placeholder = "Humanoid, function, Part...", Callback = function(text) filterKeyword = text end})
    Tabs.GC:Button({ Title = "Filter GC & Count", Callback = function()
        if not getgc then return logToConsole("ERROR", "getgc() is required for this operation.") end
        if filterKeyword == "" then return WindUI:Notify({Title="Error", Content="Filter keyword is empty."}) end
        
        logToConsole("GC", "Filtering for '"..filterKeyword.."'...")
        task.spawn(function()
            local gc = getgc(true) -- getgc(true) is more efficient as it only returns tables/userdata
            local filtered = {}
            local lowerKeyword = filterKeyword:lower()

            for _, item in ipairs(gc) do
                local match = false
                pcall(function()
                    if typeof(item):lower():find(lowerKeyword) then
                        match = true
                    elseif typeof(item) == "Instance" and item.ClassName:lower():find(lowerKeyword) then
                        match = true
                    end
                end)
                if match then
                    table.insert(filtered, item)
                end
            end
            
            logToConsole("GC", "Found", #filtered, "items matching '"..filterKeyword.."'.")
            WindUI:Notify({Title="GC Filter Complete", Content="Found "..#filtered.." items."})
        end)
    end})
end
