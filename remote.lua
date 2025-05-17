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
    Size = UDim2.fromOffset(300, 300), -- hi
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
    RemoteHookerTab = Window:Tab({ Title = "Remote Tools", Icon = "radio-receiver", Desc = "Hook and manage RemoteEvents." }),
}

Window:SelectTab(1)

-- Home Tab Content (from user)
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
                    Icon = "triangle-alert",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Could not copy link (setclipboard unavailable).",
                Icon = "triangle-alert",
                Duration = 5,
            })
            warn("setclipboard function not available in this environment.")
        end
    end
})

-- Remote Hooker Logic
local new_cclosure = newcclosure or function(f) return f end
local active_hooks = setmetatable({}, { __mode = "k" }) -- Stores { remote = { originalFireServer, originalConnect, name } }
local remote_hook_connections = {} -- To store connections for DescendantAdded to disconnect later if needed

local function serialize_arguments(...)
    local args = {...}
    local serialized_args = {}
    for i, v in ipairs(args) do
        local v_type = typeof(v)
        if v_type == "Instance" then
            table.insert(serialized_args, string.format("%s (%s)", v:GetFullName(), v.ClassName))
        elseif v_type == "table" then
            local t_str = "{"
            local count = 0
            local first_entry = true
            for k_table, v_table in pairs(v) do
                if count >= 5 then
                    t_str = t_str .. "..."
                    break
                end
                if not first_entry then
                    t_str = t_str .. ", "
                end
                t_str = t_str .. tostring(k_table) .. "=" .. tostring(v_table)
                first_entry = false
                count = count + 1
            end
            t_str = t_str .. "}"
            table.insert(serialized_args, t_str)
        elseif v_type == "function" then
            table.insert(serialized_args, "function")
        elseif v_type == "nil" then
            table.insert(serialized_args, "nil")
        else
            table.insert(serialized_args, tostring(v))
        end
    end
    return table.concat(serialized_args, ", ")
end

local function revert_hook_for_remote(remote_event_instance, suppress_notification)
    if not active_hooks[remote_event_instance] then
        return
    end

    local data = active_hooks[remote_event_instance]
    local reverted = false

    -- Revert FireServer
    if data.originalFireServer then
        local success_fs, err_fs = pcall(function()
            if typeof(hookfunction) == "function" and typeof(unhookfunction) == "function" then
                -- Attempt to unhook if possible, though this specific pattern isn't standard for all hookfunction implementations
                -- More commonly, you'd hookfunction(remote_event_instance.FireServer, data.originalFireServer)
                -- or simply rawset if hookfunction modified the direct reference.
                -- For simplicity and broad compatibility, rawset is often the fallback.
                pcall(unhookfunction, remote_event_instance.FireServer) -- Try to unhook the current hook
            end
            rawset(remote_event_instance, "FireServer", data.originalFireServer)
        end)
        if success_fs then
            reverted = true
        else
            warn(string.format("[RemoteHook] Failed to revert FireServer for %s: %s", data.name, tostring(err_fs)))
        end
    end

    -- Revert OnClientEvent.Connect
    local on_client_event_signal = remote_event_instance.OnClientEvent
    if typeof(on_client_event_signal) == "Instance" and on_client_event_signal:IsA("RBXScriptSignal") and data.originalConnect then
         local success_conn, err_conn = pcall(function()
            if typeof(hookfunction) == "function" and typeof(unhookfunction) == "function" then
                 pcall(unhookfunction, on_client_event_signal.Connect)
            end
            rawset(on_client_event_signal, "Connect", data.originalConnect)
        end)
        if success_conn then
            reverted = true
        else
            warn(string.format("[RemoteHook] Failed to revert OnClientEvent.Connect for %s: %s", data.name, tostring(err_conn)))
        end
    end
    
    active_hooks[remote_event_instance] = nil
    if reverted and not suppress_notification then
        WindUI:Notify({
            Title = "Hook Reverted",
            Content = "Reverted hooks for: " .. data.name,
            Icon = "undo-2",
            Duration = 2
        })
    end
    return reverted
end

local function setup_hooks_for_remote(remote_event_instance)
    if not (typeof(remote_event_instance) == "Instance" and remote_event_instance:IsA("RemoteEvent")) then
        return
    end
    if active_hooks[remote_event_instance] then
        return -- Already hooked by this script
    end

    local remote_name = remote_event_instance:GetFullName()
    local hook_data = { name = remote_name }
    local hooked_something = false

    -- Hook :FireServer()
    local original_FireServer = remote_event_instance.FireServer
    if typeof(original_FireServer) == "function" then
        hook_data.originalFireServer = original_FireServer
        
        local hook_FireServer_func = new_cclosure(function(self, ...)
            local args_string = serialize_arguments(...)
            print(string.format("[RemoteHook] FireServer -> Remote: %s | Args: [%s]", self:GetFullName(), args_string))
            if active_hooks[self] and active_hooks[self].originalFireServer then
                return active_hooks[self].originalFireServer(self, ...)
            else -- Fallback if somehow original isn't in active_hooks (should not happen)
                return original_FireServer(self, ...)
            end
        end)

        if typeof(hookfunction) == "function" then
            local success, err_msg_or_original = pcall(hookfunction, remote_event_instance.FireServer, hook_FireServer_func)
            if success then
                -- Some hookfunction versions might return the original, useful if we didn't grab it before.
                -- If it does, and it's a function, we could use err_msg_or_original if original_FireServer wasn't captured right.
                -- However, our current method of capturing original_FireServer before hookfunction is generally safer.
                hooked_something = true
            else
                warn(string.format("[RemoteHook] hookfunction failed for FireServer on %s: %s. Falling back to rawset.", remote_name, tostring(err_msg_or_original)))
                rawset(remote_event_instance, "FireServer", hook_FireServer_func)
                hooked_something = true
            end
        else
            rawset(remote_event_instance, "FireServer", hook_FireServer_func)
            hooked_something = true
        end
    end

    -- Hook .OnClientEvent:Connect()
    local on_client_event_signal = remote_event_instance.OnClientEvent
    if typeof(on_client_event_signal) == "Instance" and on_client_event_signal:IsA("RBXScriptSignal") then
        local original_Connect = on_client_event_signal.Connect
        if typeof(original_Connect) == "function" then
            hook_data.originalConnect = original_Connect

            local hook_Connect_func = new_cclosure(function(signal_self, function_to_connect)
                if typeof(function_to_connect) ~= "function" then
                    if active_hooks[remote_event_instance] and active_hooks[remote_event_instance].originalConnect then
                         return active_hooks[remote_event_instance].originalConnect(signal_self, function_to_connect)
                    else
                        return original_Connect(signal_self, function_to_connect)
                    end
                end

                print(string.format("[RemoteHook] OnClientEvent:Connect -> Remote: %s", remote_name))
                local wrapped_function = new_cclosure(function(...)
                    local args_string = serialize_arguments(...)
                    print(string.format("[RemoteHook] OnClientEvent <- Remote: %s | Args: [%s]", remote_name, args_string))
                    
                    local success, result = pcall(function_to_connect, ...)
                    if not success then
                        warn(string.format("[RemoteHook] Error in original OnClientEvent handler for %s: %s", remote_name, tostring(result)))
                    end
                    return result
                end)
                
                if active_hooks[remote_event_instance] and active_hooks[remote_event_instance].originalConnect then
                    return active_hooks[remote_event_instance].originalConnect(signal_self, wrapped_function)
                else
                    return original_Connect(signal_self, wrapped_function)
                end
            end)

            if typeof(hookfunction) == "function" then
                local success, err_msg_or_original = pcall(hookfunction, on_client_event_signal.Connect, hook_Connect_func)
                if success then
                    hooked_something = true
                else
                    warn(string.format("[RemoteHook] hookfunction failed for Connect on %s.OnClientEvent: %s. Falling back to rawset.", remote_name, tostring(err_msg_or_original)))
                    rawset(on_client_event_signal, "Connect", hook_Connect_func)
                    hooked_something = true
                end
            else
                rawset(on_client_event_signal, "Connect", hook_Connect_func)
                hooked_something = true
            end
        end
    end
    
    if hooked_something then
        active_hooks[remote_event_instance] = hook_data
        -- WindUI:Notify({ Title = "Remote Hooked", Content = "Hooked: " .. remote_name, Duration = 1, Icon = "check" })
    end
end

local function hook_all_existing_remotes()
    local services_to_scan = {
        game:GetService("ReplicatedStorage"),
        game:GetService("Workspace"),
        game:GetService("Players"),
        game:GetService("StarterGui"),
        game:GetService("StarterPlayer") and game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"),
        game:GetService("StarterPack"),
        game:GetService("Chat") -- Added Chat service
    }
    local count = 0
    for _, service_instance in ipairs(services_to_scan) do
        if service_instance and typeof(service_instance.GetDescendants) == "function" then
            for _, descendant_object in ipairs(service_instance:GetDescendants()) do
                if descendant_object:IsA("RemoteEvent") then
                    pcall(setup_hooks_for_remote, descendant_object)
                    count = count + 1
                end
            end
        end
    end
    WindUI:Notify({
        Title = "Remote Hooking",
        Content = "Initial scan complete. Processed " .. count .. " potential remotes.",
        Icon = "scan-search",
        Duration = 3
    })
end

local function start_remote_hooking_system()
    hook_all_existing_remotes()
    
    if remote_hook_connections.descendantAdded then
        remote_hook_connections.descendantAdded:Disconnect()
    end
    remote_hook_connections.descendantAdded = game.DescendantAdded:Connect(function(descendant_object)
        if descendant_object:IsA("RemoteEvent") then
            task.defer(setup_hooks_for_remote, descendant_object)
        end
    end)
    print("[RemoteHook] System initialized. Current and future RemoteEvents will be processed.")
    WindUI:Notify({
        Title = "Remote Hooker Active",
        Content = "Now monitoring and hooking RemoteEvents.",
        Icon = "power",
        Duration = 3
    })
end

local function stop_remote_hooking_system_and_revert_all()
    if remote_hook_connections.descendantAdded then
        remote_hook_connections.descendantAdded:Disconnect()
        remote_hook_connections.descendantAdded = nil
    end

    local reverted_count = 0
    local remotes_to_revert = {} -- Collect keys to avoid issues with modifying table during iteration
    for remote_instance, _ in pairs(active_hooks) do
        table.insert(remotes_to_revert, remote_instance)
    end

    for _, remote_instance in ipairs(remotes_to_revert) do
        if revert_hook_for_remote(remote_instance, true) then -- Suppress individual notifications
            reverted_count = reverted_count + 1
        end
    end
    
    active_hooks = setmetatable({}, { __mode = "k" }) -- Clear all stored hooks
    
    print("[RemoteHook] System stopped. All hooks have been reverted.")
    WindUI:Notify({
        Title = "Remote Hooker Deactivated",
        Content = "All (" .. reverted_count .. ") hooks reverted. Monitoring stopped.",
        Icon = "power-off",
        Duration = 3
    })
end

-- Remote Hooker Tab Content
Tabs.RemoteHookerTab:Button({
    Title = "Start/Refresh Remote Hooking",
    Desc = "Scans for all RemoteEvents and applies hooks. Hooks new ones automatically.",
    Callback = function()
        start_remote_hooking_system()
    end
})

Tabs.RemoteHookerTab:Button({
    Title = "Copy Hooked Remote Paths",
    Desc = "Copies the full paths of all currently hooked RemoteEvents to clipboard.",
    Callback = function()
        local paths = {}
        local count = 0
        for remote, data in pairs(active_hooks) do
            if remote and data and data.name then
                table.insert(paths, data.name)
                count = count + 1
            end
        end

        if count == 0 then
            WindUI:Notify({
                Title = "No Hooks Active",
                Content = "No remotes are currently hooked by this script.",
                Icon = "info",
                Duration = 3
            })
            return
        end

        local text_to_copy = table.concat(paths, "\n")
        if setclipboard then
            local success, err = pcall(setclipboard, text_to_copy)
            if success then
                WindUI:Notify({
                    Title = "Paths Copied!",
                    Content = count .. " hooked remote paths copied to clipboard.",
                    Icon = "clipboard-check",
                    Duration = 3,
                })
            else
                WindUI:Notify({
                    Title = "Error Copying",
                    Content = "Failed to copy paths: " .. tostring(err),
                    Icon = "triangle-alert",
                    Duration = 5,
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "setclipboard is not available in this environment.",
                Icon = "triangle-alert",
                Duration = 5,
            })
        end
    end
})

Tabs.RemoteHookerTab:Button({
    Title = "Revert All Hooks & Stop",
    Desc = "Removes all hooks placed by this script and stops monitoring new remotes.",
    Variant = "Secondary",
    Callback = function()
        stop_remote_hooking_system_and_revert_all()
    end
})

Tabs.RemoteHookerTab:Paragraph({
    Title = "Information",
    Desc = "Hooked remote activity will be printed to your console (F9). " ..
           "Reverting hooks attempts to restore original functionality. " ..
           "Some exploits may offer `unhookfunction` which might be more robust if available.",
    Color = "Grey"
})

-- Automatically start the hooking system when the script runs
-- You might want to trigger this with the button instead, depending on preference.
-- For now, let's make it button-triggered to give user control.
-- start_remote_hooking_system() 
-- (Commented out auto-start, user can click the button)

print("[Cookieys Hub] Remote Hooker module loaded. Use the 'Remote Tools' tab.")