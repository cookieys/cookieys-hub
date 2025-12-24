local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

-- Check Place ID (Optional safety check, can be removed if testing elsewhere)
if game.PlaceId ~= 136431686349723 then
    -- WindUI:Notify({ Title = "Warning", Content = "This script is intended for the Lobby (ID: 136431686349723)", Icon = "alert-triangle" })
end

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "HUNTED Lobby",
    Author = "czjk",
    Folder = "HuntedLobby",
    Icon = "map",
    Size = UDim2.fromOffset(500, 350)
})

local MainTab = Window:Tab({
    Title = "Teleports",
    Icon = "navigation"
})

local ChapterSection = MainTab:Section({
    Title = "Chapter Portals"
})

-- Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Hallways = Workspace:WaitForChild("Hallways", 10)

-- Teleport Function
local function TeleportTo(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe + Vector3.new(0, 3, 0) -- Slight offset up
    end
end

-- Load Chapters dynamically from Workspace.Hallways
if Hallways then
    local foundChapters = false
    
    for _, chapter in pairs(Hallways:GetChildren()) do
        -- Check if it contains a 'Portal' part as shown in the image
        local portal = chapter:FindFirstChild("Portal")
        
        if portal and portal:IsA("BasePart") then
            foundChapters = true
            ChapterSection:Button({
                Title = "TP to " .. chapter.Name,
                Desc = "Teleport to " .. chapter.Name .. " portal",
                Callback = function()
                    TeleportTo(portal.CFrame)
                    WindUI:Notify({
                        Title = "Teleported",
                        Content = "Warped to " .. chapter.Name,
                        Icon = "map-pin"
                    })
                end
            })
        end
    end
    
    if not foundChapters then
        ChapterSection:Paragraph({
            Title = "No Portals Found",
            Desc = "Could not find any objects with a 'Portal' part inside Workspace.Hallways."
        })
    end
else
    ChapterSection:Paragraph({
        Title = "Error",
        Desc = "Workspace.Hallways folder not found."
    })
end

-- Refresh Button (In case items load late)
MainTab:Section({ Title = "Tools" }):Button({
    Title = "Refresh Teleports",
    Desc = "Reload the UI if chapters didn't appear",
    Callback = function()
        Window:Destroy()
        task.wait(0.5)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
        -- Re-executing the script logic (User would re-execute the script, or we implement a complex refresh logic)
        -- Since WindUI doesn't support clearing sections easily in this version, restarting is often cleaner for users.
        WindUI:Notify({ Title = "Restarting", Content = "Please re-execute the script to refresh." })
    end
})
