local a="https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Game%20list.lua"local b,c=pcall(function()return loadstring(game:HttpGet(a))()end)if b and c then local d=game.PlaceId;if c[d]then loadstring(game:HttpGet(c[d]))()else game.Players.LocalPlayer:Kick("This game is not supported by the script.")end else end
