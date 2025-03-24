--[[

discord.gg/25ms

--]]
local E="https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Game%20list.lua"local F,N=pcall(function()return(loadstring(game:HttpGet(E)))()end)if F and N then local E=game.PlaceId if N[E]then(loadstring(game:HttpGet(N[E])))()else print("Game not supported. Kicking player.")game.Players.LocalPlayer:Kick("This game is not supported by the script.")end else print("Error loading games list:",N)end
