---@diagnostic disable: undefined-field

LoneWolf = LoneWolf or {}
LoneWolf.Config = LoneWolf.Config or {}
local Config = LoneWolf.Config

Config.FILE = "LoneWolfConfig.json"
Config.default = {
    enabled = true,
    partyLimit = 2,
    requirePassive = true,
    enableCoreBuffs = true,
    enableHpMax = true,
    enableDamageReduction = true,
    enableStatBoosts = true,
    hpPercent = 30,
    drPercent = 50,
    drType = "Half",
    abilityBonus = 4,
    actionPoints = 1,
    bonusActionPoints = 1,
    reactionPoints = 1,
    carryMultiplier = 2.0,
}

function Config.DeepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = Config.DeepCopy(value)
    end
    return copy
end

function Config.ApplyDefaults(cfg)
    local data = Config.DeepCopy(Config.default)
    for key in pairs(Config.default) do
        if cfg[key] ~= nil then
            data[key] = cfg[key]
        end
    end

    return data
end

function Config.Read()
    local file = Ext.IO.LoadFile(Config.FILE)
    if not file or file == "" then
        local fresh = Config.DeepCopy(Config.default)
        Ext.IO.SaveFile(Config.FILE, Ext.Json.Stringify(fresh))
        return fresh
    end

    local parsed = Ext.Json.Parse(file)
    return Config.ApplyDefaults(parsed)
end

function Config.Save(cfg)
    Ext.IO.SaveFile(Config.FILE, Ext.Json.Stringify(cfg))
end

return Config
