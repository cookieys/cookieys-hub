Made with ♡ by XyraV

To use this just execute:

```lua
local a,b=pcall(game.HttpGet,game,"https://raw.githubusercontent.com/cookieys/loader/refs/heads/main/Loader.lua",true)local c,d=a and loadstring(b,"=loader")if c then task.spawn(c)else warn("[loader] failed: "..tostring(d or b))end
