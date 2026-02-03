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
    if type(cfg) ~= "table" then
        return data
    end

    if cfg.enabled ~= nil then data.enabled = cfg.enabled end
    if cfg.partyLimit ~= nil then data.partyLimit = cfg.partyLimit end
    if cfg.requirePassive ~= nil then data.requirePassive = cfg.requirePassive end
    if cfg.enableCoreBuffs ~= nil then data.enableCoreBuffs = cfg.enableCoreBuffs end
    if cfg.enableHpMax ~= nil then data.enableHpMax = cfg.enableHpMax end
    if cfg.enableDamageReduction ~= nil then data.enableDamageReduction = cfg.enableDamageReduction end
    if cfg.enableStatBoosts ~= nil then data.enableStatBoosts = cfg.enableStatBoosts end

    return data
end

function Config.Read()
    local file = Ext.IO.LoadFile(Config.FILE)
    if not file or file == "" then
        local fresh = Config.DeepCopy(Config.default)
        Ext.IO.SaveFile(Config.FILE, Ext.Json.Stringify(fresh))
        return fresh
    end

    local ok, parsed = pcall(Ext.Json.Parse, file)
    if ok then
        return Config.ApplyDefaults(parsed)
    end

    return Config.DeepCopy(Config.default)
end

function Config.Save(cfg)
    Ext.IO.SaveFile(Config.FILE, Ext.Json.Stringify(cfg))
end

return Config
