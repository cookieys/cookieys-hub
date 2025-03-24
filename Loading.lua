loadstring(game:HttpGet("https://raw.githubusercontent.com/NOOBHUBX/Game/refs/heads/main/Loading"))()
for pid, Execute in pairs(Games)do
if pid==game.PlaceId then
loadstring(game:HttpGet(Execute))()
end
end
