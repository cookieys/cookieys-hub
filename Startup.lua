if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2) -- Allow further game initialization

local success, windUiLib = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not windUiLib then
    warn("WindUI failed to load:", windUiLib) -- Log error if HttpGet or loadstring fails
    return -- Exit if the UI library cannot be loaded
end

local WindUI = windUiLib
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys", -- Folder for saving configurations
    Size = UDim2.fromOffset(300, 300), -- perfect size don't change.
    Transparent = true,
    Theme = "Dark", -- Available themes: "Dark", "Light", "Nord", etc.
    SideBarWidth = 180,
    HasOutline = false, -- Window outline
    KeySystem = {
        Key = { "1234", "5678" },
        Note = "The Key is '1234' or '5678'. \nKeys are case-sensitive.",
        URL = "https://github.com/Footagesus/WindUI", -- URL for key information or acquisition
        SaveKey = true, -- Whether to save the entered key
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
    SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "Configure UI and anti-lag settings." }),
}

Window:SelectTab(1) -- Automatically select the first tab (HomeTab)

local DISCORD_INVITE_URL = "https://discord.gg/ee4veXxYFZ"

Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        if typeof(setclipboard) == "function" then
            local successSet, errMessage = pcall(setclipboard, DISCORD_INVITE_URL)
            if successSet then
                WindUI:Notify({
                    Title = "Link Copied!",
                    Content = "Discord invite link copied to clipboard.",
                    Icon = "clipboard-check", -- Success icon
                    Duration = 3,
                })
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to copy link: " .. tostring(errMessage),
                    Icon = "triangle-alert", -- Error icon
                    Duration = 5,
                })
                warn("setclipboard failed:", errMessage)
            end
        else
            WindUI:Notify({
                Title = "Clipboard Unavailable",
                Content = "Could not copy link (setclipboard is not available).",
                Icon = "triangle-alert",
                Duration = 5,
            })
            warn("setclipboard function not available in this environment.")
        end
    end
})

-- Settings Tab Content
Tabs.SettingsTab:Section({ Title = "UI Customization" })

local themeValues = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, themeName)
end
table.sort(themeValues) -- Optional: sort theme names alphabetically

local currentTheme = WindUI:GetCurrentTheme()

Tabs.SettingsTab:Dropdown({
    Title = "UI Theme",
    Values = themeValues,
    Value = currentTheme, -- Set default to the current theme
    Multi = false,
    AllowNone = false,
    Callback = function(selectedTheme)
        if WindUI:GetThemes()[selectedTheme] then
            WindUI:SetTheme(selectedTheme)
            currentTheme = selectedTheme -- Update our tracked current theme
            WindUI:Notify({
                Title = "Theme Changed",
                Content = "UI theme set to " .. selectedTheme .. ".",
                Icon = "palette",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Selected theme '" .. selectedTheme .. "' not found.",
                Icon = "triangle-alert",
                Duration = 5
            })
        end
    end
})

Tabs.SettingsTab:Toggle({
    Title = "Window Transparency",
    Value = Window.Transparent, -- Initial value based on window creation
    Callback = function(isTransparent)
        Window:ToggleTransparency(isTransparent)
        WindUI:Notify({
            Title = "Transparency " .. (isTransparent and "Enabled" or "Disabled"),
            Content = "Window transparency has been " .. (isTransparent and "enabled." or "disabled."),
            Icon = isTransparent and "eye" or "eye-off",
            Duration = 3
        })
    end
})

Tabs.SettingsTab:Section({ Title = "Anti-Lag Options" })

-- Store original settings to revert
local originalLightingSettings = {
    GlobalShadows = Lighting.GlobalShadows,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor
}

local originalTerrainSettings = nil
if Terrain then
    originalTerrainSettings = {
        WaterWaveSize = Terrain.WaterWaveSize,
        WaterWaveSpeed = Terrain.WaterWaveSpeed,
        WaterReflectance = Terrain.WaterReflectance,
        WaterTransparency = Terrain.WaterTransparency,
        Decoration = Terrain.Decoration
    }
end

-- 1. Disable Shadows
Tabs.SettingsTab:Toggle({
    Title = "Disable Shadows",
    Desc = "Toggles global shadows for performance.",
    Value = not originalLightingSettings.GlobalShadows, -- If shadows are on, this is false (not disabled)
    Callback = function(disable)
        Lighting.GlobalShadows = not disable
        WindUI:Notify({
            Title = "Shadows " .. (disable and "Disabled" or "Enabled"),
            Content = "Global shadows have been " .. (disable and "disabled." or "enabled."),
            Icon = "lightbulb-off",
            Duration = 3
        })
    end
})

-- 2. Disable Particle Effects
local particleEmittersCache = {}
local function scanAndCacheParticleEmitters()
    particleEmittersCache = {}
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") then
            table.insert(particleEmittersCache, {Emitter = descendant, OriginalState = descendant.Enabled})
        end
    end
end
scanAndCacheParticleEmitters() -- Initial scan

Tabs.SettingsTab:Toggle({
    Title = "Disable Particle Effects",
    Desc = "Disables all particle emitters in the workspace.",
    Value = false, -- Start with particles assumed to be enabled by default effect of toggle
    Callback = function(disable)
        -- Re-scan could be added here if games add many particles dynamically post-load
        -- For simplicity, using cached ones. If new ones appear, they won't be affected until next toggle.
        -- scanAndCacheParticleEmitters() -- Uncomment to rescan on every toggle.

        for _, item in ipairs(particleEmittersCache) do
            if item.Emitter and item.Emitter.Parent then -- Check if emitter still exists
                item.Emitter.Enabled = not disable
            end
        end
        WindUI:Notify({
            Title = "Particle Effects " .. (disable and "Disabled" or "Enabled"),
            Content = "Particle emitters have been " .. (disable and "disabled." or "enabled."),
            Icon = "droplet-off",
            Duration = 3
        })
    end
})

-- 3. Low Water Quality (if Terrain exists)
if Terrain and originalTerrainSettings then
    Tabs.SettingsTab:Toggle({
        Title = "Low Water Quality",
        Desc = "Reduces water detail for performance.",
        Value = false, -- Start with original water quality
        Callback = function(lowQuality)
            if lowQuality then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1 -- Max transparency for low quality
            else
                Terrain.WaterWaveSize = originalTerrainSettings.WaterWaveSize
                Terrain.WaterWaveSpeed = originalTerrainSettings.WaterWaveSpeed
                Terrain.WaterReflectance = originalTerrainSettings.WaterReflectance
                Terrain.WaterTransparency = originalTerrainSettings.WaterTransparency
            end
            WindUI:Notify({
                Title = "Water Quality",
                Content = "Water quality set to " .. (lowQuality and "Low." or "Default."),
                Icon = "waves",
                Duration = 3
            })
        end
    })

    -- 4. Disable Terrain Decoration (Grass, etc.)
    Tabs.SettingsTab:Toggle({
        Title = "Disable Terrain Decoration",
        Desc = "Removes grass and other terrain decorations.",
        Value = not originalTerrainSettings.Decoration, -- If decoration is on, this is false
        Callback = function(disable)
            Terrain.Decoration = not disable
            WindUI:Notify({
                Title = "Terrain Decoration " .. (disable and "Disabled" or "Enabled"),
                Content = "Terrain decoration (e.g., grass) has been " .. (disable and "disabled." or "enabled."),
                Icon = "trees",
                Duration = 3
            })
        end
    })
end

-- 5. Reduce Render Distance (via Fog)
local FOG_END_REDUCED = 150
local FOG_START_REDUCED = 10

Tabs.SettingsTab:Toggle({
    Title = "Reduce Render Distance (Fog)",
    Desc = "Uses fog to limit perceived render distance.",
    Value = false, -- Start with default fog
    Callback = function(reduce)
        if reduce then
            Lighting.FogStart = FOG_START_REDUCED
            Lighting.FogEnd = FOG_END_REDUCED
            -- Optionally set Lighting.FogColor to something like Lighting.Sky.SkyboxBkColor or a grey
        else
            Lighting.FogStart = originalLightingSettings.FogStart
            Lighting.FogEnd = originalLightingSettings.FogEnd
            Lighting.FogColor = originalLightingSettings.FogColor
        end
        WindUI:Notify({
            Title = "Render Distance (Fog)",
            Content = "Fog-based render distance " .. (reduce and "Reduced." or "Default."),
            Icon = "eye-off",
            Duration = 3
        })
    end
})
