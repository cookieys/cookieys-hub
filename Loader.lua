--[[

discord.gg/25ms

--]]
local m="https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Game%20list.lua"local X="https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Get%20executor.lua"local H,M=pcall(function()return(loadstring(game:HttpGet(m)))()end)if H and M then local m,H=pcall(function()return(loadstring(game:HttpGet(X)))()end)if m then H()else print("Error loading executor level script:",H)end local c=game.PlaceId if M[c]then local m,X=pcall(function()return(loadstring(game:HttpGet(M[c])))()end)if not m then print("Error loading game script:",X)game.Players.LocalPlayer:Kick("Error loading game script.")end else print("Game not supported. Kicking player.")game.Players.LocalPlayer:Kick("This game is not supported by the script.")end else print("Error loading games list:",M)end
