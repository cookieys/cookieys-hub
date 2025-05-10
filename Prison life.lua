if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(1) -- Short delay for game to load

local WindUI_PrisonLife = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local PrisonLifeWindow = WindUI_PrisonLife:CreateWindow({
    Title = "Prison Life GUI",
    Icon = "shield-alert", -- Example icon, change if needed
    Author = "YourName",
    Folder = "PrisonLifeHelper",
    Size = UDim2.fromOffset(300, 200),
    Transparent = true,
    Theme = "Dark", -- Or any theme you prefer
    SideBarWidth = 150,
    HasOutline = true,
    -- No KeySystem for this example, can be added if needed
})

PrisonLifeWindow:EditOpenButton({
    Title = "Open Prison Life UI",
    Icon = "layout-grid", -- Example icon
    CornerRadius = UDim.new(0, 8),
    StrokeThickness = 1,
    Color = ColorSequence.new(Color3.fromHex("FFA500")), -- Orange-like color
    Draggable = true,
    Position = UDim2.new(0, 10, 0, 120) -- Position it differently from other UIs if they are open
})

local PrisonLifeTabs = {
    MainTab = PrisonLifeWindow:Tab({ Title = "Main", Icon = "zap", Desc = "Main features for Prison Life." }),
}

PrisonLifeWindow:SelectTab(1)

-- Function for infinite ammo (adapted to use the current UI's notification system if needed,
-- but WindUI:Notify is generally global from the library instance)
local function attemptInfiniteMaxAmmo_PrisonLife()
    local foundCount = 0
    local modifiedCount = 0
    local start_time = tick()

    WindUI_PrisonLife:Notify({
        Title = "Scanning Memory...",
        Content = "Searching for 'MaxAmmo' in tables...",
        Icon = "loader-circle",
        Duration = 7
    })

    task.wait(0.1) -- Allow notification to show

    -- Ensure getgc is available in the execution environment
    if not getgc then
        WindUI_PrisonLife:Notify({
            Title = "Error",
            Content = "'getgc' function is not available in this environment.",
            Icon = "alert-triangle",
            Duration = 5
        })
        warn("[PrisonLife InfiniteAmmo] 'getgc' is not available.")
        return
    end

    local all_gc_items = getgc(true)

    for i, item_table in ipairs(all_gc_items) do
        if typeof(item_table) == "table" then
            -- Using rawget to bypass metamethods if any
            local current_max_ammo = rawget(item_table, "MaxAmmo")
            if current_max_ammo ~= nil then
                foundCount = foundCount + 1
                if typeof(current_max_ammo) == "number" then
                    -- Using rawset to bypass metamethods if any
                    local success, err = pcall(rawset, item_table, "MaxAmmo", math.huge)
                    if success then
                        modifiedCount = modifiedCount + 1
                    else
                        print("[PrisonLife InfiniteAmmo] Error setting MaxAmmo for a table:", err)
                    end
                end
            end
        end
        if i % 3000 == 0 then task.wait() end -- Yield periodically
    end
    
    local time_taken = string.format("%.2f", tick() - start_time)

    if modifiedCount > 0 then
        WindUI_PrisonLife:Notify({
            Title = "Max Ammo Applied",
            Content = string.format("Found %d 'MaxAmmo' keys. Modified %d. (Scan: %s s)", foundCount, modifiedCount, time_taken),
            Icon = "check-circle",
            Duration = 5
        })
    elseif foundCount > 0 then
         WindUI_PrisonLife:Notify({
            Title = "Max Ammo Found (Partial)",
            Content = string.format("Found %d 'MaxAmmo' keys, modified %d. Some might not be numbers or writable. (Scan: %s s)", foundCount, modifiedCount, time_taken),
            Icon = "alert-circle",
            Duration = 6
        })
    else
        WindUI_PrisonLife:Notify({
            Title = "Max Ammo Not Found",
            Content = string.format("'MaxAmmo' key not found in accessible tables. (Scan: %s s)", time_taken),
            Icon = "search-x", 
            Duration = 5
        })
    end
end

PrisonLifeTabs.MainTab:Button({
    Title = "Click for Infinite Ammo",
    Desc = "Attempts to find and set 'MaxAmmo' values to infinite. This is game-dependent.",
    Callback = attemptInfiniteMaxAmmo_PrisonLife
})

WindUI_PrisonLife:Notify({
    Title = "Prison Life UI Loaded",
    Content = "The Prison Life specific UI is ready.",
    Icon = "info",
    Duration = 3
})
