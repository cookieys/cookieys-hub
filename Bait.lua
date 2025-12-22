--!strict

-- 1. Define Types for Autocomplete (Optional, but recommended for Roblox)
export type BaitStats = {
    LureSpeed: number,
    Luck: number,
    GeneralLuck: number,
    Rarity: string,
    Resilience: number,
    ProgressSpeed: number?,
    Mutation: string?
}

-- 2. Define Rarities (Prevents typo bugs)
local Rarity = {
    Common = "Common",
    Uncommon = "Uncommon",
    Unusual = "Unusual",
    Rare = "Rare",
    Legendary = "Legendary",
    Mythical = "Mythical"
}

-- 3. Define Default Values (Used if a stat is missing)
local DefaultStats = {
    LureSpeed = 0,
    Luck = 0,
    GeneralLuck = 0,
    Resilience = 0,
    ProgressSpeed = 0,
    Mutation = nil
}

-- 4. The Data Table
local BaitData = {
    -- Common
    ["Worm"]            = { LureSpeed =  15, Luck =  25, GeneralLuck =    0, Resilience =  0, Rarity = Rarity.Common },
    ["Bagel"]           = { LureSpeed =   0, Luck =  25, GeneralLuck =    0, Resilience = 15, Rarity = Rarity.Common },
    ["Insect"]          = { LureSpeed =   5, Luck =  35, GeneralLuck =    0, Resilience =  0, Rarity = Rarity.Common },
    ["Flakes"]          = { LureSpeed =  10, Luck =  55, GeneralLuck =    0, Resilience = -3, Rarity = Rarity.Common },
    ["Garbage"]         = { LureSpeed =  -5, Luck =   0, GeneralLuck = -250, Resilience = 50, Rarity = Rarity.Common },

    -- Uncommon
    ["Shrimp"]          = { LureSpeed =   0, Luck =  45, GeneralLuck =   25, Resilience = -5, Rarity = Rarity.Uncommon },
    ["Maggot"]          = { LureSpeed = -10, Luck =   0, GeneralLuck =   35, Resilience =  0, Rarity = Rarity.Uncommon },

    -- Unusual
    ["Magnet"]          = { LureSpeed =   0, Luck = 200, GeneralLuck =    0, Resilience =  0, Rarity = Rarity.Unusual },
    ["Peppermint Worm"] = { LureSpeed =  -5, Luck =  50, GeneralLuck =   30, Resilience = 20, Rarity = Rarity.Unusual },
    ["Squid"]           = { LureSpeed = -25, Luck =  55, GeneralLuck =   45, Resilience =  0, Rarity = Rarity.Unusual },
    ["Seaweed"]         = { LureSpeed =  20, Luck =  35, GeneralLuck =    0, Resilience = 10, Rarity = Rarity.Unusual },
    ["Coral"]           = { LureSpeed =  20, Luck =   0, GeneralLuck =    0, Resilience = 20, Rarity = Rarity.Unusual },
    ["Minnow"]          = { LureSpeed =   0, Luck =  65, GeneralLuck =    0, Resilience =-10, Rarity = Rarity.Unusual },

    -- Rare
    ["Coal"]            = { LureSpeed =   0, Luck =  45, GeneralLuck =    0, Resilience =-10, Rarity = Rarity.Rare },
    ["Super Flakes"]    = { LureSpeed =   0, Luck =   0, GeneralLuck =   70, Resilience =-15, Rarity = Rarity.Rare },
    ["Rapid Catcher"]   = { LureSpeed =  35, Luck =   0, GeneralLuck =    0, Resilience =-15, Rarity = Rarity.Rare },

    -- Legendary
    ["Fish Head"]       = { LureSpeed =  10, Luck = 150, GeneralLuck =    0, Resilience =-10, Rarity = Rarity.Legendary },
    ["Night Shrimp"]    = { LureSpeed =  15, Luck =   0, GeneralLuck =   90, Resilience =  0, Rarity = Rarity.Legendary },
    ["Instant Catcher"] = { LureSpeed =  65, Luck =   0, GeneralLuck =  -20, Resilience =-15, Rarity = Rarity.Legendary },
    ["Kraken Tentacle"] = { LureSpeed =  35, Luck = 100, GeneralLuck =   35, Resilience = 15, Rarity = Rarity.Legendary },
    ["Holly Berry"]     = { LureSpeed =  -5, Luck =  80, GeneralLuck =   30, Resilience = 10, Rarity = Rarity.Legendary },
    ["Deep Coral"]      = { LureSpeed =   0, Luck = -10, GeneralLuck =    0, Resilience = 50, Rarity = Rarity.Legendary },
    ["Weird Algae"]     = { LureSpeed = -35, Luck =   0, GeneralLuck =  200, Resilience =  0, Rarity = Rarity.Legendary },
    ["Truffle Worm"]    = { LureSpeed = -10, Luck = 300, GeneralLuck =    0, Resilience =  0, Rarity = Rarity.Legendary },

    -- Mythical
    ["Chocolate Fish"]  = { LureSpeed =  20, Luck = 200, GeneralLuck =  150, Resilience = 15, Rarity = Rarity.Mythical, Mutation = "Chocolate" },
    ["Hangman's Hook"]  = { LureSpeed =  -5, Luck = 150, GeneralLuck =   35, Resilience = 20, Rarity = Rarity.Mythical, ProgressSpeed = 45 },
    ["Shark Head"]      = { LureSpeed =  -5, Luck = 225, GeneralLuck =   30, Resilience = 10, Rarity = Rarity.Mythical },
    ["Aurora Bait"]     = { LureSpeed =  -5, Luck = 100, GeneralLuck =   30, Resilience = 10, Rarity = Rarity.Mythical },
}

-- 5. Apply Metatables
-- This ensures that if you try to read a value that isn't there (like ProgressSpeed on a Worm),
-- it returns 0 instead of nil, preventing script errors.
for _, stats in pairs(BaitData) do
    setmetatable(stats, { __index = DefaultStats })
end

return BaitData
