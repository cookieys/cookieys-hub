-- Helper function to generate the enchantment data table
local function Enchant(exalted, song)
    return { 
        IsExalted = exalted == true, 
        IsSongOfTheDeep = song == true 
    }
end

return {
    ["Abyssal"]        = Enchant(false),
    ["Anomalous"]      = Enchant(true),       -- Exalted
    ["Blessed"]        = Enchant(false),
    ["Blessed Song"]   = Enchant(false, true), -- Song of the Deep
    ["Breezed"]        = Enchant(false),
    ["Clever"]         = Enchant(false),
    ["Controlled"]     = Enchant(false),
    ["Divine"]         = Enchant(false),
    ["Ghastly"]        = Enchant(false),
    ["Hasty"]          = Enchant(false),
    ["Herculean"]      = Enchant(false),
    ["Immortal"]       = Enchant(true),       -- Exalted
    ["Insight"]        = Enchant(false),
    ["Invincible"]     = Enchant(true),       -- Exalted
    ["Long"]           = Enchant(false),
    ["Lucky"]          = Enchant(false),
    ["Mystical"]       = Enchant(true),       -- Exalted
    ["Mutated"]        = Enchant(false),
    ["Noir"]           = Enchant(false),
    ["Piercing"]       = Enchant(true),       -- Exalted
    ["Quality"]        = Enchant(false),
    ["Quantum"]        = Enchant(true),       -- Exalted
    ["Resilient"]      = Enchant(false),
    ["Scrapper"]       = Enchant(false),
    ["Sea King"]       = Enchant(false),
    ["Sea Overlord"]   = Enchant(true),       -- Exalted
    ["Steady"]         = Enchant(false),
    ["Storming"]       = Enchant(false),
    ["Swift"]          = Enchant(false),
    ["Unbreakable"]    = Enchant(false),
    ["Wormhole"]       = Enchant(false),
}
