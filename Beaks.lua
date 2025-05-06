if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(2)


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer 


local WindUI = loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()


local buyDartRemote = nil
local remoteFound = pcall(function()
    buyDartRemote = ReplicatedStorage:WaitForChild("Util", 10):WaitForChild("Net", 10):WaitForChild("RF/BuyDart", 10)
end)

if not remoteFound or not buyDartRemote then
    warn("cookieys hub Error: Could not find 'RF/BuyDart' RemoteFunction after waiting. Inf Money will not work.")
    
     WindUI:Notify({
        Title = "Error",
        Content = "Inf Money remote not found. Feature disabled.",
        Icon = "alert-triangle",
        Duration = 7,
     })
    
end


local invokeArgs = {"Steel", -1e150} 


local Window = WindUI:CreateWindow({
    Title = "cookieys hub",
    Icon = "door-open",
    Author = "XyraV",
    Folder = "cookieys",
    Size = UDim2.fromOffset(300, 300),
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
    MainTab = Window:Tab({ Title = "Main", Icon = "bolt", Desc = "Core script functionalities." }) 
}


Window:SelectTab(1)


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


local infMoneyConnection = nil

Tabs.MainTab:Toggle({
    Title = "Inf Money", 
    Desc = "Attempts to rapidly add money (Requires specific game).",
    Default = false, 
    Callback = function(Value)
        
        if not buyDartRemote then
             WindUI:Notify({
                Title = "Error",
                Content = "Inf Money remote not found. Cannot enable.",
                Icon = "alert-triangle",
                Duration = 5,
             })
            
            
            return 
        end

        if Value then
            
            if not infMoneyConnection then
                WindUI:Notify({Title = "Inf Money", Content="Enabled", Duration=3})
                infMoneyConnection = RunService.Heartbeat:Connect(function()
                    
                    if not buyDartRemote or not buyDartRemote.Parent then
                        warn("BuyDart RemoteFunction lost mid-execution! Disabling Inf. Money.")
                        if infMoneyConnection then
                            infMoneyConnection:Disconnect()
                            infMoneyConnection = nil
                        end
                         WindUI:Notify({Title="Inf Money", Content="Disabled (Remote Lost)", Icon="alert-triangle", Duration=4})
                        
                        return
                    end

                    
                    pcall(buyDartRemote.InvokeServer, buyDartRemote, unpack(invokeArgs))
                    pcall(buyDartRemote.InvokeServer, buyDartRemote, unpack(invokeArgs))
                    
                end)
            end
        else
            
            if infMoneyConnection then
                 WindUI:Notify({Title = "Inf Money", Content="Disabled", Duration=3})
                infMoneyConnection:Disconnect()
                infMoneyConnection = nil
            end
        end
    end
})


local function cleanupInfMoney()
    if infMoneyConnection then
        infMoneyConnection:Disconnect()
        infMoneyConnection = nil
        print("Inf. Money connection cleaned up.")
    end
end


if LocalPlayer then
    LocalPlayer.Destroying:Connect(cleanupInfMoney)
else
    Players.PlayerAdded:Connect(function(player) 
        if player == Players.LocalPlayer then
             player.Destroying:Connect(cleanupInfMoney)
        end
    end)
end


