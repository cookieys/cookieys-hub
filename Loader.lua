loadstring(game:HttpGet("https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Loading.lua"))()
for PlaceID, Execute in pairs(Games)do
if PlaceID==game.PlaceId then
loadstring(game:HttpGet(Execute))()
end
end
