local gamesListURL = "https://raw.githubusercontent.com/cookieys/cookieys-hub/refs/heads/main/Game%20list.lua"

local success, Games = pcall(function()
    return loadstring(game:HttpGet(gamesListURL))()
end)

if success and Games then
    local currentPlaceId = game.PlaceId
    if Games[currentPlaceId] then
        loadstring(game:HttpGet(Games[currentPlaceId]))()
    else
        print("Game not supported. Kicking player.")
        game.Players.LocalPlayer:Kick("This game is not supported by the script.")
    end
else
    print("Error loading games list:", Games)
end
