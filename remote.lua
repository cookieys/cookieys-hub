if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2)

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(580, 560), -- Increased Y size for new elements
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
    Title = "Open UI",
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
    RemoteHookerTab = Window:Tab({ Title = "Remote Tools", Icon = "radio-receiver", Desc = "Hook, block, and manage RemoteEvents." }),
}

Window:SelectTab(1)

-- Home Tab Content
Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        local discordLink = "https://discord.gg/ee4veXxYFZ"
        if setclipboard then
            local success, err = pcall(setclipboard, discordLink)
            if success then
                WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied to clipboard.", Icon = "clipboard-check", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to copy link: " .. tostring(err), Icon = "triangle-alert", Duration = 5 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Could not copy link (setclipboard unavailable).", Icon = "triangle-alert", Duration = 5 })
            warn("setclipboard function not available in this environment.")
        end
    end
})

-- Remote Hooker Logic
local new_cclosure = newcclosure or function(f) return f end
local active_hooks = setmetatable({}, { __mode = "k" })
local remote_hook_connections = {}
local blocked_remotes_paths = {} -- Stores full paths of remotes to be blocked: { ["path"] = true }
local remote_path_input_value = "" -- Stores text from the input field

local blockedRemotesDisplayParagraph -- UI element to show blocked remotes
local isHookingSystemActive = false

local function serialize_arguments(...)
    local args = {...}
    local serialized_args = {}
    for i, v in ipairs(args) do
        local v_type = typeof(v)
        if v_type == "Instance" then
            table.insert(serialized_args, string.format("%s (%s)", v:GetFullName(), v.ClassName))
        elseif v_type == "table" then
            local t_str = "{" ; local count = 0 ; local first_entry = true
            for k_table, v_table in pairs(v) do
                if count >= 5 then t_str = t_str .. "..."; break end
                if not first_entry then t_str = t_str .. ", " end
                t_str = t_str .. tostring(k_table) .. "=" .. tostring(v_table)
                first_entry = false; count = count + 1
            end
            t_str = t_str .. "}"
            table.insert(serialized_args, t_str)
        elseif v_type == "function" then table.insert(serialized_args, "function")
        elseif v_type == "nil" then table.insert(serialized_args, "nil")
        else table.insert(serialized_args, tostring(v))
        end
    end
    return table.concat(serialized_args, ", ")
end

local function update_blocked_remotes_display()
    if not blockedRemotesDisplayParagraph then return end
    local paths = {}
    for path, _ in pairs(blocked_remotes_paths) do
        table.insert(paths, path)
    end
    if #paths == 0 then
        blockedRemotesDisplayParagraph:SetDesc("No remotes are currently manually blocked.")
    else
        blockedRemotesDisplayParagraph:SetDesc(table.concat(paths, "\n"))
    end
end

local function revert_hook_for_remote(remote_event_instance, suppress_notification)
    if not active_hooks[remote_event_instance] then return false end

    local data = active_hooks[remote_event_instance]
    local reverted_fs, reverted_conn = false, false

    if data.originalFireServer then
        local success = pcall(function()
            if typeof(hookfunction) == "function" and typeof(unhookfunction) == "function" then
                pcall(unhookfunction, remote_event_instance.FireServer)
            end
            rawset(remote_event_instance, "FireServer", data.originalFireServer)
        end)
        reverted_fs = success
        if not success then warn(string.format("[RemoteHook] Failed to revert FireServer for %s", data.name)) end
    end

    local on_client_event_signal = remote_event_instance.OnClientEvent
    if typeof(on_client_event_signal) == "Instance" and on_client_event_signal:IsA("RBXScriptSignal") and data.originalConnect then
        local success = pcall(function()
            if typeof(hookfunction) == "function" and typeof(unhookfunction) == "function" then
                pcall(unhookfunction, on_client_event_signal.Connect)
            end
            rawset(on_client_event_signal, "Connect", data.originalConnect)
        end)
        reverted_conn = success
        if not success then warn(string.format("[RemoteHook] Failed to revert OnClientEvent.Connect for %s", data.name)) end
    end
    
    active_hooks[remote_event_instance] = nil
    if (reverted_fs or reverted_conn) and not suppress_notification then
        WindUI:Notify({ Title = "Hook Reverted", Content = "Reverted: " .. data.name, Icon = "undo-2", Duration = 2 })
    end
    return (reverted_fs or reverted_conn)
end

local function setup_hooks_for_remote(remote_event_instance)
    if not (typeof(remote_event_instance) == "Instance" and remote_event_instance:IsA("RemoteEvent")) then return end
    if active_hooks[remote_event_instance] then return end -- Already hooked by this script

    local remote_name_at_hook_time = remote_event_instance:GetFullName() -- For initial logging
    local hook_data = { name = remote_name_at_hook_time }
    local hooked_something = false

    local original_FireServer = remote_event_instance.FireServer
    if typeof(original_FireServer) == "function" then
        hook_data.originalFireServer = original_FireServer
        local hook_FireServer_func = new_cclosure(function(self, ...)
            local current_remote_path = self:GetFullName()
            if blocked_remotes_paths[current_remote_path] then
                print(string.format("[RemoteHook] Blocked FireServer -> Remote: %s", current_remote_path))
                return
            end
            local args_string = serialize_arguments(...)
            print(string.format("[RemoteHook] FireServer -> Remote: %s | Args: [%s]", current_remote_path, args_string))
            if active_hooks[self] and active_hooks[self].originalFireServer then
                return active_hooks[self].originalFireServer(self, ...)
            else return original_FireServer(self, ...) end
        end)
        if typeof(hookfunction) == "function" then
            local s,e = pcall(hookfunction, remote_event_instance.FireServer, hook_FireServer_func)
            if s then hooked_something = true else warn("[RemoteHook] hookfunction FireServer fail: "..tostring(e)); rawset(remote_event_instance, "FireServer", hook_FireServer_func); hooked_something = true end
        else rawset(remote_event_instance, "FireServer", hook_FireServer_func); hooked_something = true end
    end

    local on_client_event_signal = remote_event_instance.OnClientEvent
    if typeof(on_client_event_signal) == "Instance" and on_client_event_signal:IsA("RBXScriptSignal") then
        local original_Connect = on_client_event_signal.Connect
        if typeof(original_Connect) == "function" then
            hook_data.originalConnect = original_Connect
            local hook_Connect_func = new_cclosure(function(signal_self, function_to_connect)
                if typeof(function_to_connect) ~= "function" then
                    if active_hooks[remote_event_instance] and active_hooks[remote_event_instance].originalConnect then
                        return active_hooks[remote_event_instance].originalConnect(signal_self, function_to_connect)
                    else return original_Connect(signal_self, function_to_connect) end
                end
                print(string.format("[RemoteHook] OnClientEvent:Connect -> Remote: %s", remote_event_instance:GetFullName()))
                local wrapped_function = new_cclosure(function(...)
                    local current_remote_path = remote_event_instance:GetFullName() -- Path at call time
                    if blocked_remotes_paths[current_remote_path] then
                        print(string.format("[RemoteHook] Blocked OnClientEvent <- Remote: %s", current_remote_path))
                        return
                    end
                    local args_string = serialize_arguments(...)
                    print(string.format("[RemoteHook] OnClientEvent <- Remote: %s | Args: [%s]", current_remote_path, args_string))
                    local s, r = pcall(function_to_connect, ...)
                    if not s then warn(string.format("[RemoteHook] Error in OnClientEvent handler for %s: %s", current_remote_path, tostring(r))) end
                    return r
                end)
                if active_hooks[remote_event_instance] and active_hooks[remote_event_instance].originalConnect then
                    return active_hooks[remote_event_instance].originalConnect(signal_self, wrapped_function)
                else return original_Connect(signal_self, wrapped_function) end
            end)
            if typeof(hookfunction) == "function" then
                local s,e = pcall(hookfunction, on_client_event_signal.Connect, hook_Connect_func)
                if s then hooked_something = true else warn("[RemoteHook] hookfunction Connect fail: "..tostring(e)); rawset(on_client_event_signal, "Connect", hook_Connect_func); hooked_something = true end
            else rawset(on_client_event_signal, "Connect", hook_Connect_func); hooked_something = true end
        end
    end
    
    if hooked_something then active_hooks[remote_event_instance] = hook_data end
end

local function hook_all_existing_remotes()
    local services_to_scan = { game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game:GetService("Players"), game:GetService("StarterGui"), game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"), game:GetService("StarterPack"), game:GetService("Chat") }
    local count = 0
    for _, service in ipairs(services_to_scan) do
        if service and typeof(service.GetDescendants) == "function" then
            for _, descendant in ipairs(service:GetDescendants()) do
                if descendant:IsA("RemoteEvent") then pcall(setup_hooks_for_remote, descendant); count = count + 1 end
            end
        end
    end
    WindUI:Notify({ Title = "Remote Hooking Scan", Content = "Processed " .. count .. " existing remotes.", Icon = "scan-search", Duration = 3 })
end

local function start_remote_hooking_system()
    if isHookingSystemActive then
        WindUI:Notify({ Title = "System Active", Content = "Hooking system is already running. Re-scanning existing remotes.", Icon = "info", Duration = 3})
        hook_all_existing_remotes() -- Re-scan if called again
        return
    end
    isHookingSystemActive = true
    hook_all_existing_remotes()
    if remote_hook_connections.descendantAdded then remote_hook_connections.descendantAdded:Disconnect() end
    remote_hook_connections.descendantAdded = game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") then task.defer(setup_hooks_for_remote, descendant) end
    end)
    print("[RemoteHook] System initialized.")
    WindUI:Notify({ Title = "Remote Hooker Active", Content = "Monitoring and hooking RemoteEvents.", Icon = "power", Duration = 3 })
end

local function stop_remote_hooking_system_and_revert_all()
    if not isHookingSystemActive and #table.pack(pairs(active_hooks)) == 0 and #table.pack(pairs(blocked_remotes_paths)) == 0 then
         WindUI:Notify({ Title = "System Inactive", Content = "Hooking system is not active or no hooks/blocks to revert.", Icon = "info", Duration = 3})
        return
    end

    if remote_hook_connections.descendantAdded then
        remote_hook_connections.descendantAdded:Disconnect()
        remote_hook_connections.descendantAdded = nil
    end

    local reverted_count = 0
    local remotes_to_revert = {}
    for r, _ in pairs(active_hooks) do table.insert(remotes_to_revert, r) end
    for _, r_inst in ipairs(remotes_to_revert) do if revert_hook_for_remote(r_inst, true) then reverted_count = reverted_count + 1 end end
    
    active_hooks = setmetatable({}, { __mode = "k" })
    blocked_remotes_paths = {}
    update_blocked_remotes_display()
    isHookingSystemActive = false
    
    print("[RemoteHook] System stopped. All hooks/blocks reverted.")
    WindUI:Notify({ Title = "Remote Hooker Deactivated", Content = "Reverted " .. reverted_count .. " hooks. Blocks cleared. Monitoring stopped.", Icon = "power-off", Duration = 3 })
end

local function block_remote_by_input_path()
    local path = remote_path_input_value
    if path == "" then WindUI:Notify({ Title = "Input Empty", Content = "Enter remote path to block.", Icon = "alert-circle", Duration = 3 }); return end
    if blocked_remotes_paths[path] then WindUI:Notify({ Title = "Already Blocked", Content = path .. " is already blocked.", Icon = "info", Duration = 3 }); return end
    blocked_remotes_paths[path] = true
    update_blocked_remotes_display()
    WindUI:Notify({ Title = "Remote Blocked", Content = "Blocked: " .. path, Icon = "shield-off", Duration = 3 })
end

local function unblock_remote_by_input_path()
    local path = remote_path_input_value
    if path == "" then WindUI:Notify({ Title = "Input Empty", Content = "Enter remote path to unblock.", Icon = "alert-circle", Duration = 3 }); return end
    if not blocked_remotes_paths[path] then WindUI:Notify({ Title = "Not Blocked", Content = path .. " not found in block list.", Icon = "info", Duration = 3 }); return end
    blocked_remotes_paths[path] = nil
    update_blocked_remotes_display()
    WindUI:Notify({ Title = "Remote Unblocked", Content = "Unblocked: " .. path, Icon = "shield-check", Duration = 3 })
end

local function unblock_all_manually_blocked_remotes()
    local count = 0; for _ in pairs(blocked_remotes_paths) do count = count + 1 end
    if count == 0 then WindUI:Notify({ Title = "No Remotes Blocked", Content = "Block list is empty.", Icon = "info", Duration = 3 }); return end
    blocked_remotes_paths = {}
    update_blocked_remotes_display()
    WindUI:Notify({ Title = "All Unblocked", Content = "Cleared " .. count .. " remotes from block list.", Icon = "shield-check", Duration = 3 })
end

-- Remote Hooker Tab Content
Tabs.RemoteHookerTab:Button({
    Title = "Start/Refresh Remote Hooking",
    Desc = "Scans all RemoteEvents and applies hooks. Hooks new ones automatically.",
    Callback = start_remote_hooking_system
})

Tabs.RemoteHookerTab:Button({
    Title = "Copy Hooked Remote Paths",
    Desc = "Copies paths of all currently hooked RemoteEvents to clipboard.",
    Callback = function()
        if not isHookingSystemActive and #table.pack(pairs(active_hooks)) == 0 then
             WindUI:Notify({ Title = "System Inactive", Content = "Start hooking system to see hooked remotes.", Icon = "info", Duration = 3 }); return
        end
        local paths = {}; local count = 0
        for _, data in pairs(active_hooks) do if data and data.name then table.insert(paths, data.name); count = count + 1 end end
        if count == 0 then WindUI:Notify({ Title = "No Hooks Active", Content = "No remotes are actively hooked by this script instance.", Icon = "info", Duration = 3 }); return end
        local text = table.concat(paths, "\n")
        if setclipboard then
            local s,e = pcall(setclipboard, text)
            if s then WindUI:Notify({ Title = "Paths Copied!", Content = count .. " paths copied.", Icon = "clipboard-check", Duration = 3 })
            else WindUI:Notify({ Title = "Error Copying", Content = "Failed: " .. tostring(e), Icon = "triangle-alert", Duration = 5 }) end
        else WindUI:Notify({ Title = "Error", Content = "setclipboard unavailable.", Icon = "triangle-alert", Duration = 5 }) end
    end
})

Tabs.RemoteHookerTab:Section({ Title = "Remote Blocking Control" })
Tabs.RemoteHookerTab:Input({
    Title = "Remote Path (Case-Sensitive)",
    Placeholder = "e.g., Workspace.Events.DamageEvent", Value = "",
    Callback = function(text) remote_path_input_value = text end
})
Tabs.RemoteHookerTab:Button({ Title = "Block Remote by Path", Callback = block_remote_by_input_path })
Tabs.RemoteHookerTab:Button({ Title = "Unblock Remote by Path", Callback = unblock_remote_by_input_path })
Tabs.RemoteHookerTab:Button({ Title = "Unblock All Manually Blocked", Variant = "Tertiary", Callback = unblock_all_manually_blocked_remotes })

blockedRemotesDisplayParagraph = Tabs.RemoteHookerTab:Paragraph({
    Title = "Manually Blocked Remote Paths:",
    Desc = "No remotes are currently manually blocked."
})
task.defer(update_blocked_remotes_display) -- Initialize display

Tabs.RemoteHookerTab:Divider()
Tabs.RemoteHookerTab:Button({
    Title = "Revert All Hooks & Stop System",
    Desc = "Removes ALL hooks, clears ALL blocks, and stops monitoring.",
    Variant = "Secondary", Callback = stop_remote_hooking_system_and_revert_all
})
Tabs.RemoteHookerTab:Paragraph({
    Title = "Information",
    Desc = "Hooked remote activity is printed to console (F9). Blocking is case-sensitive for paths. Reverting hooks attempts to restore original RemoteEvent functions.",
    Color = "Grey"
})

print("[Cookieys Hub] Remote Hooker module loaded. Use the 'Remote Tools' tab.")