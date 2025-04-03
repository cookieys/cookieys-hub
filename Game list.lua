local Games = {
    [8540346411] = "https://raw.githubusercontent.com/X7N6Y/X7N6Y/main/Rebirth.lua",
    [16732694052] = "https://raw.githubusercontent.com/cookieys/cookieys-hub/main/Fisch.lua",
}

if Games[game.PlaceId] then
    loadstring(game:HttpGet(Games[game.PlaceId]))()
end

return Games
