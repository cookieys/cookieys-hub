local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()

-- Roblox Services & Variables
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Initialize Global Flags (used by toggles)
_G.AutoShake = false
_G.AutoCast = false
_G.PerfectCast = false
_G.AutoFarm = false

-- UI Setup
local Window = WindUI:CreateWindow({
    Title = "cookieys hub | fisch",
    Icon = "fish", -- Changed Icon
    Author = "XyraV",
    Folder = "cookieys_fisch", -- Changed Folder
    Size = UDim2.fromOffset(500, 400),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
    -- Key System (Optional)
    -- KeySystem = { ... },
})

Window:EditOpenButton({
    Title = "Open Fish Sim UI", -- Changed Title
    Icon = "anchor", -- Changed Icon
    CornerRadius = UDim.new(0,10),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("0077FF"), -- Blue-ish Gradient
        Color3.fromHex("00C4FF")
    ),
    Draggable = true,
})

local Tabs = {
    HomeTab = Window:Tab({ Title = "Home", Icon = "house", Desc = "Welcome & Info" }),
    MainTab = Window:Tab({ Title = "Main", Icon = "settings-2", Desc = "Core farming features" }),
}

Window:SelectTab(1)

-- Home Tab Elements
Tabs.HomeTab:Button({
    Title = "Discord Invite",
    Desc = "Click to copy the Discord server invite link.",
    Callback = function()
        local discordLink = "https://discord.gg/ee4veXxYFZ" -- Keep your link or update if needed
        if setclipboard then
             local success, err = pcall(setclipboard, discordLink)
             if success then
                WindUI:Notify({ Title = "Link Copied!", Content = "Discord invite link copied.", Icon = "clipboard-check", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to copy link: " .. tostring(err), Icon = "triangle-alert", Duration = 5 })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Could not copy link.", Icon = "file-warning", Duration = 5 })
            warn("setclipboard function not available.")
        end
    end
})
Tabs.HomeTab:Label({ Text = "Fish Simulator Script by XyraV" })
Tabs.HomeTab:Label({ Text = "Uses bdokxk/diddy fish farm logic." })

-- Main Tab Elements
Tabs.MainTab:Toggle({
    Title = "AutoShake (within AutoFarm)",
    Desc = "Automatically handles the shake mechanic.",
    Default = _G.AutoShake,
    Callback = function(state)
        _G.AutoShake = state
        print("AutoShake state:", state)
        -- Note: The provided farm logic handles shaking implicitly.
        -- This toggle might be redundant unless logic is separated.
    end
})

Tabs.MainTab:Toggle({
    Title = "AutoCast (within AutoFarm)",
    Desc = "Automatically casts the fishing rod.",
    Default = _G.AutoCast,
    Callback = function(state)
        _G.AutoCast = state
        print("AutoCast state:", state)
         -- Note: The provided farm logic handles casting implicitly.
    end
})

Tabs.MainTab:Toggle({
    Title = "PerfectCast (within AutoFarm)",
    Desc = "Attempts to always get a perfect cast/reel.",
    Default = _G.PerfectCast,
    Callback = function(state)
        _G.PerfectCast = state
        print("PerfectCast state:", state)
         -- Note: The provided farm logic tries perfect reel implicitly.
    end
})

Tabs.MainTab:Divider() -- Separator

Tabs.MainTab:Toggle({
    Title = "Auto Farm Fish",
    Desc = "Enables the main fishing loop.",
    Default = _G.AutoFarm,
    Callback = function(state)
        _G.AutoFarm = state
        print("Auto Farm state:", state)
        if not state then
            -- Optional: Add logic here to immediately stop actions if needed
             pcall(function()
                 local char = LocalPlayer.Character
                 if char then
                    local rod = char:FindFirstChildWhichIsA("Tool")
                    if rod and rod:FindFirstChild("bobber") then
                        -- May need specific logic to cancel cast/reel if API exists
                    end
                 end
            end)
        end
    end
})

-- Auto Farm Logic (Based on provided script)
task.spawn(function()
    while task.wait(0.1) do -- Check every 0.1 seconds
        if _G.AutoFarm then
            local character = LocalPlayer.Character
            local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

            if not character or not playerGui or not backpack then
                warn("AutoFarm: Waiting for Character/PlayerGui/Backpack")
                task.wait(1)
                continue -- Skip this iteration if essential components are missing
            end

            local rodNameValue = ReplicatedStorage:FindFirstChild("playerstats", true) and ReplicatedStorage.playerstats:FindFirstChild(LocalPlayer.Name) and ReplicatedStorage.playerstats[LocalPlayer.Name]:FindFirstChild("Stats") and ReplicatedStorage.playerstats[LocalPlayer.Name].Stats:FindFirstChild("rod")
            if not rodNameValue then
                 --print("AutoFarm: Waiting for Rod Stat")
                 WindUI:Notify({ Title = "Farm Error", Content = "Cannot find Rod stat value.", Icon = "alert-circle", Duration = 4 })
                 _G.AutoFarm = false -- Disable farming if rod stat missing
                 -- Potentially update the toggle UI state here if the library supports it externally
                 -- Example: farmToggle:SetValue(false) -- If you have a reference `farmToggle`
                 task.wait(2)
                 continue
            end
            local RodName = rodNameValue.Value

            local currentTool = character:FindFirstChildWhichIsA("Tool")
            local rodInBackpack = backpack:FindFirstChild(RodName)
            local rodEquipped = currentTool and currentTool.Name == RodName

            -- Equip Rod if not equipped
            if not rodEquipped then
                if rodInBackpack then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:EquipTool(rodInBackpack)
                        task.wait(0.5) -- Wait a bit for equip animation
                        rodEquipped = character:FindFirstChild(RodName) -- Re-check if equipped
                    end
                else
                    --print("AutoFarm: Rod not found in backpack!")
                    WindUI:Notify({ Title = "Farm Error", Content = "Rod '"..RodName.."' not found in backpack!", Icon = "alert-triangle", Duration = 5 })
                    _G.AutoFarm = false -- Stop farming if rod is missing
                    task.wait(2)
                    continue
                end
            end

            -- Main Fishing Logic (only if rod is equipped)
            if rodEquipped then
                local rodTool = character:FindFirstChild(RodName)
                local values = rodTool and rodTool:FindFirstChild("values")
                local events = rodTool and rodTool:FindFirstChild("events")
                local bobber = rodTool and rodTool:FindFirstChild("bobber")
                local biteValue = values and values:FindFirstChild("bite")

                if not values or not events or not biteValue then
                    warn("AutoFarm: Rod missing required components (values/events/bite).")
                    task.wait(1)
                    continue
                end

                -- Check if currently fishing (bobber exists)
                if bobber then
                    -- Handle Shaking (AutoShake logic is integrated here)
                    local shakeUi = playerGui:FindFirstChild("shakeui")
                    local safezone = shakeUi and shakeUi:FindFirstChild("safezone")
                    local button = safezone and safezone:FindFirstChild("button")

                    if not biteValue.Value then -- Only shake if no bite yet
                         if button then
                            local shakeSuccess, shakeError = pcall(function()
                                -- Ensure the button size modification is safe
                                -- Using large size to cover area seems intended by original script
                                button.Size = UDim2.new(5, 0, 5, 0) -- Use a large relative size instead of huge offset
                                button.Position = UDim2.fromScale(0.5, 0.5) -- Center it
                                button.AnchorPoint = Vector2.new(0.5, 0.5)
                                VirtualUser:Button1Down(Vector2.new(playerGui.AbsoluteSize.X / 2, playerGui.AbsoluteSize.Y / 2)) -- Click center screen approx
                                task.wait(0.05) -- Short delay between down/up
                                VirtualUser:Button1Up(Vector2.new(playerGui.AbsoluteSize.X / 2, playerGui.AbsoluteSize.Y / 2))
                            end)
                            if not shakeSuccess then
                                warn("AutoFarm: Error during shake click:", shakeError)
                            end
                         else
                             warn("AutoFarm: Could not find shake button.")
                         end
                    end

                    -- Handle Reeling (PerfectCast logic integrated here)
                    if biteValue.Value then
                        --print("AutoFarm: BITE DETECTED! Reeling...")
                        local reelSuccess, reelError = pcall(function()
                            local reelEvent = events:FindFirstChild("reelfinished")
                            if reelEvent then
                                -- Fire with large number and 'true' for perfect reel attempt
                                reelEvent:FireServer(1e24, true)
                            else
                                warn("AutoFarm: reelfinished event not found.")
                            end
                        end)
                        if not reelSuccess then
                            warn("AutoFarm: Error firing reelfinished:", reelError)
                        end
                        task.wait(0.75) -- Wait after reeling attempt
                    end

                -- If not fishing (no bobber), cast the rod (AutoCast logic integrated here)
                else
                    --print("AutoFarm: Casting rod...")
                    local castSuccess, castError = pcall(function()
                        local castEvent = events:FindFirstChild("cast")
                        if castEvent then
                            -- Fire with large number for potential distance/power bonus?
                            castEvent:FireServer(1e24)
                        else
                            warn("AutoFarm: cast event not found.")
                        end
                    end)
                     if not castSuccess then
                        warn("AutoFarm: Error firing cast:", castError)
                     end
                    task.wait(2) -- Wait for cast animation/bobber to appear
                end
            end
        else
            task.wait(0.5) -- Wait longer if auto farm is disabled
        end
    end
end)
