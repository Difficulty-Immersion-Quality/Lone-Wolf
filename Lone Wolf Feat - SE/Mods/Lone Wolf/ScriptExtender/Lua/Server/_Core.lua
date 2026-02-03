---@diagnostic disable: missing-parameter
--TODO: add panic attack toggle from ice mage
local LONE_WOLF_STATUS = "GOON_LONE_WOLF_STATUS"
local LONE_WOLF_PASSIVE = "Goon_Lone_Wolf_Passive_Dummy"
local GOON_LONE_WOLF_HPMAX_STATUS = "GOON_LONE_WOLF_HPMAX_STATUS"
local GOON_LONE_WOLF_DR_STATUS = "GOON_LONE_WOLF_DR_STATUS"
local SITOUT_VANISH_STATUS = "SITOUT_ONCOMBATSTART_APPLIER_TECHNICAL"
local DR_DESC_FLAT_STATUS = "h9fc14e28bc9a4cbfb84bf641e5a4219c01f1"
local DR_DESC_FLAT_PASSIVE = "h086dd109gcbdbg4d36gbf9cg6e402b7d1e92"
local DR_DESC_HALF = "h2377f8ab5a4f494fbae516af149a60964ffb"
local DR_DESC_THRESHOLD = "hfd2328037f8842f2a62ac858311c93ec27e3"
local DR_BOOST_HALF = "DamageReduction(All,Half)"
local DR_BOOST_FLAT_PREFIX = "DamageReduction(All,Flat,"
local DR_BOOST_THRESHOLD_PREFIX = "DamageReduction(All,Threshold,"
local statBoosts = {
    { ability = "Strength",     passive = "Goon_Lone_Wolf_Strength",     status = "GOON_LONE_WOLF_STRENGTH_STATUS" },
    { ability = "Dexterity",    passive = "Goon_Lone_Wolf_Dexterity",    status = "GOON_LONE_WOLF_DEXTERITY_STATUS" },
    { ability = "Constitution", passive = "Goon_Lone_Wolf_Constitution", status = "GOON_LONE_WOLF_CONSTITUTION_STATUS" },
    { ability = "Intelligence", passive = "Goon_Lone_Wolf_Intelligence", status = "GOON_LONE_WOLF_INTELLIGENCE_STATUS" },
    { ability = "Wisdom",       passive = "Goon_Lone_Wolf_Wisdom",       status = "GOON_LONE_WOLF_WISDOM_STATUS" },
    { ability = "Charisma",     passive = "Goon_Lone_Wolf_Charisma",     status = "GOON_LONE_WOLF_CHARISMA_STATUS" },
}
local abilityStatus = {
    Strength = "GOON_LONE_WOLF_STRENGTH_STATUS",
    Dexterity = "GOON_LONE_WOLF_DEXTERITY_STATUS",
    Constitution = "GOON_LONE_WOLF_CONSTITUTION_STATUS",
    Intelligence = "GOON_LONE_WOLF_INTELLIGENCE_STATUS",
    Wisdom = "GOON_LONE_WOLF_WISDOM_STATUS",
    Charisma = "GOON_LONE_WOLF_CHARISMA_STATUS",
}

local Config = LoneWolf.Config
local config = Config.Read()

local function TrimGuid(charID)
    if not charID then return nil end
    return string.sub(charID, -36)
end

local function IsValidPartyMember(charID)
    if not charID then return false end
    return Osi.IsPlayer(charID) == 1
        and Osi.IsSummon(charID) == 0
        and Osi.HasActiveStatus(charID, SITOUT_VANISH_STATUS) == 0
end

local function ApplyStatusIfMissing(charID, status, force)
    if not force and Osi.HasActiveStatus(charID, status) == 1 then return end
    if force and Osi.HasActiveStatus(charID, status) == 1 then
        Osi.RemoveStatus(charID, status)
    end
    Osi.ApplyStatus(charID, status, -1, 1)
end

local function ApplyStatusPreserveHp(charID, status, force)
    if not force and Osi.HasActiveStatus(charID, status) == 1 then return end
    if force and Osi.HasActiveStatus(charID, status) == 1 then
        Osi.RemoveStatus(charID, status)
    end

    local entityHandle = Ext.Entity.UuidToHandle(charID)
    if not (entityHandle and entityHandle.Health) then
        Osi.ApplyStatus(charID, status, -1, 1)
        return
    end

    local currentHp = entityHandle.Health.Hp
    local sub
    ---@diagnostic disable-next-line: param-type-mismatch
    sub = Ext.Entity.Subscribe("Health", function(health, _, _)
        health.Health.Hp = currentHp
        health:Replicate("Health")
        Ext.Entity.Unsubscribe(assert(sub)) -- unsubscribe immediately
    end, entityHandle)

    Osi.ApplyStatus(charID, status, -1, 1)
end

local function ApplyOverrideStatuses(charID, force)
    for _, boost in ipairs(statBoosts) do
        Osi.RemoveStatus(charID, boost.status)
    end

    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    vars.LoneWolfData = vars.LoneWolfData or {}
    vars.LoneWolfData.AbilityOverrides = vars.LoneWolfData.AbilityOverrides or {}
    local data = vars.LoneWolfData
    if not data or not data.AbilityOverrides then
        return
    end

    local override = data.AbilityOverrides[TrimGuid(charID)] or data.AbilityOverrides[charID]
    if not override then
        return
    end

    local first = override.first or override[1]
    local second = override.second or override[2]

    if abilityStatus[first] then
        ApplyStatusIfMissing(charID, abilityStatus[first], force)
    end
    if abilityStatus[second] and second ~= first then
        ApplyStatusIfMissing(charID, abilityStatus[second], force)
    end
end

local function ApplyLoneWolf(charID, force)
    if config.enableCoreBuffs then
        ApplyStatusIfMissing(charID, LONE_WOLF_STATUS, force)
    else
        Osi.RemoveStatus(charID, LONE_WOLF_STATUS)
    end

    if config.enableHpMax then
        ApplyStatusPreserveHp(charID, GOON_LONE_WOLF_HPMAX_STATUS, force)
    else
        Osi.RemoveStatus(charID, GOON_LONE_WOLF_HPMAX_STATUS)
    end

    if config.enableDamageReduction then
        ApplyStatusIfMissing(charID, GOON_LONE_WOLF_DR_STATUS, force)
    else
        Osi.RemoveStatus(charID, GOON_LONE_WOLF_DR_STATUS)
    end

    if config.enableStatBoosts then
        if config.requirePassive then
            for _, boost in ipairs(statBoosts) do
                if Osi.HasPassive(charID, boost.passive) == 1 then
                    ApplyStatusIfMissing(charID, boost.status, force)
                else
                    Osi.RemoveStatus(charID, boost.status)
                end
            end
        else
            ApplyOverrideStatuses(charID, force)
        end
    else
        for _, boost in ipairs(statBoosts) do
            Osi.RemoveStatus(charID, boost.status)
        end
    end
end

local function RemoveLoneWolf(charID)
    Osi.RemoveStatus(charID, LONE_WOLF_STATUS)
    Osi.RemoveStatus(charID, GOON_LONE_WOLF_HPMAX_STATUS)
    Osi.RemoveStatus(charID, GOON_LONE_WOLF_DR_STATUS)
    for _, boost in ipairs(statBoosts) do
        Osi.RemoveStatus(charID, boost.status)
    end
end

local function UpdateLoneWolf(force)
    config = Config.Read()
    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    vars.LoneWolfData = vars.LoneWolfData or {}
    vars.LoneWolfData.AbilityOverrides = vars.LoneWolfData.AbilityOverrides or {}

    if not Osi or not Osi.DB_Players then
        return
    end

    if force then
        ---@type StatusData
        local hpStatus = Ext.Stats.Get(GOON_LONE_WOLF_HPMAX_STATUS)
        if hpStatus then
            hpStatus.Boosts = "IncreaseMaxHP(" .. config.hpPercent .. "%)"
            hpStatus.DescriptionParams = tostring(config.hpPercent) .. "%"
            hpStatus:Sync()
        end

        local drBoost = DR_BOOST_HALF
        local drParam = "50%"
        local drDescStatus = DR_DESC_HALF
        local drDescPassive = DR_DESC_HALF
        if config.drType == "Flat" then
            drBoost = DR_BOOST_FLAT_PREFIX .. tostring(config.drPercent) .. ")"
            drParam = tostring(config.drPercent)
            drDescStatus = DR_DESC_FLAT_STATUS
            drDescPassive = DR_DESC_FLAT_PASSIVE
        elseif config.drType == "Threshold" then
            drBoost = DR_BOOST_THRESHOLD_PREFIX .. tostring(config.drPercent) .. ")"
            drParam = tostring(config.drPercent)
            drDescStatus = DR_DESC_THRESHOLD
            drDescPassive = DR_DESC_THRESHOLD
        end
        ---@type StatusData
        local drStatus = Ext.Stats.Get(GOON_LONE_WOLF_DR_STATUS)
        if drStatus then
            drStatus.Boosts = drBoost
            drStatus.Description = drDescStatus
            drStatus.DescriptionParams = drParam
            drStatus:Sync()
        end

        for _, boost in ipairs(statBoosts) do
            ---@type StatusData
            local status = Ext.Stats.Get(boost.status)
            if status then
                status.Boosts = "Ability(" .. boost.ability .. "," .. config.abilityBonus ..
                    ");ProficiencyBonus(SavingThrow," .. boost.ability .. ")"
                status.DescriptionParams = tostring(config.abilityBonus)
                status:Sync()
            end
            ---@type PassiveData
            local passive = Ext.Stats.Get(boost.passive)
            if passive then
                passive.DescriptionParams = tostring(config.abilityBonus)
                passive:Sync()
            end
        end
        ---@type PassiveData
        local extraHpPassive = Ext.Stats.Get("Goon_Lone_Wolf_Extra_HP")
        if extraHpPassive then
            extraHpPassive.DescriptionParams = tostring(config.hpPercent) .. "%"
            extraHpPassive:Sync()
        end
        ---@type PassiveData
        local extraDrPassive = Ext.Stats.Get("Goon_Lone_Wolf_Extra_DR")
        if extraDrPassive then
            extraDrPassive.Description = drDescPassive
            extraDrPassive.DescriptionParams = drParam
            extraDrPassive:Sync()
        end
        ---@type PassiveData
        local mainPassive = Ext.Stats.Get(LONE_WOLF_PASSIVE)
        if mainPassive then
            mainPassive.DescriptionParams = tostring(config.hpPercent) .. "%;" .. tostring(config.abilityBonus) ..
                ";" .. drParam
            mainPassive:Sync()
        end
        ---@type StatusData
        local mainStatus = Ext.Stats.Get(LONE_WOLF_STATUS)
        if mainStatus then
            local coreBoosts = {}
            if config.actionPoints > 0 then
                table.insert(coreBoosts, "ActionResource(ActionPoint," .. config.actionPoints .. ",0)")
            end
            if config.bonusActionPoints > 0 then
                table.insert(coreBoosts, "ActionResource(BonusActionPoint," .. config.bonusActionPoints .. ",0)")
            end
            if config.reactionPoints > 0 then
                table.insert(coreBoosts, "ActionResource(ReactionActionPoint," .. config.reactionPoints .. ",0)")
            end
            if config.carryMultiplier > 0 then
                table.insert(coreBoosts, "CarryCapacityMultiplier(" .. tostring(config.carryMultiplier) .. ")")
            end
            mainStatus.Boosts = table.concat(coreBoosts, ";")
            mainStatus.DescriptionParams = tostring(config.hpPercent) .. "%;" .. tostring(config.abilityBonus) ..
                ";" .. drParam
            mainStatus:Sync()
        end
    end

    if not config.enabled then
        local players = Osi.DB_Players:Get(nil) or {}
        for _, entry in pairs(players) do
            local guid = TrimGuid(entry[1])
            if guid then
                RemoveLoneWolf(guid)
            end
        end
        return
    end

    local players = Osi.DB_Players:Get(nil) or {}
    local validParty = {}

    for _, entry in pairs(players) do
        local guid = TrimGuid(entry[1])
        if guid and IsValidPartyMember(guid) then
            table.insert(validParty, guid)
        end
    end

    local partySize = #validParty

    for _, entry in pairs(players) do
        local guid = TrimGuid(entry[1])
        if guid then
            local eligible = IsValidPartyMember(guid)
                and ((tonumber(config.partyLimit) or 0) <= 0 or partySize <= config.partyLimit)

            if eligible and config.requirePassive then
                eligible = (Osi.HasPassive(guid, LONE_WOLF_PASSIVE) == 1)
            end

            if eligible then
                ApplyLoneWolf(guid, force)
            else
                RemoveLoneWolf(guid)
            end
        end
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function()
    config = Config.Read()
    UpdateLoneWolf(true)
end)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function()
    UpdateLoneWolf()
end)
Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function()
    UpdateLoneWolf()
end)

Ext.Osiris.RegisterListener("LeveledUp", 1, "after", function(character)
    if Osi.IsPlayer(character) == 1 then
        Ext.Timer.WaitFor(500, UpdateLoneWolf)
    end
end)

local pendingUpdateToken = 0
Ext.RegisterNetListener("LoneWolf_ConfigChanged", function()
    pendingUpdateToken = pendingUpdateToken + 1
    local token = pendingUpdateToken
    Ext.Timer.WaitFor(50, function()
        if token == pendingUpdateToken then
            UpdateLoneWolf(true)
        end
    end)
end)

-- sit this one out compat
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, cause, _)
    if status == SITOUT_VANISH_STATUS then
        UpdateLoneWolf()
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, cause, _)
    if status == SITOUT_VANISH_STATUS then
        UpdateLoneWolf()
    end
end)
