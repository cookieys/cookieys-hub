loadstring(game:HttpGet("https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Loading.lua"))()
for pid, Execute in pairs(Games)do
if pid==game.PlaceId then
loadstring(game:HttpGet(Execute))()
end
end
