local LONE_WOLF_STATUS = "GOON_LONE_WOLF_STATUS"
local LONE_WOLF_PASSIVE = "Goon_Lone_Wolf_Passive_Dummy"
local GOON_LONE_WOLF_SE_BUFFS = "GOON_LONE_WOLF_SE_BUFFS"
local PartyLimit = 2
local SITOUT_VANISH_STATUS = "SITOUT_ONCOMBATSTART_APPLIER_TECHNICAL"

local statBoosts = {
    { passive = "Goon_Lone_Wolf_Strength", status = "GOON_LONE_WOLF_STRENGTH_STATUS" },
    { passive = "Goon_Lone_Wolf_Dexterity", status = "GOON_LONE_WOLF_DEXTERITY_STATUS" },
    { passive = "Goon_Lone_Wolf_Constitution", status = "GOON_LONE_WOLF_CONSTITUTION_STATUS" },
    { passive = "Goon_Lone_Wolf_Intelligence", status = "GOON_LONE_WOLF_INTELLIGENCE_STATUS" },
    { passive = "Goon_Lone_Wolf_Wisdom", status = "GOON_LONE_WOLF_WISDOM_STATUS" },
    { passive = "Goon_Lone_Wolf_Charisma", status = "GOON_LONE_WOLF_CHARISMA_STATUS" },
}

local loneWolfBoosts = {
    { boost = "IncreaseMaxHP(30%)" },
}

-- Persistent vars for tracking boosted characters
local function LoneWolfVars()
    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    vars.LoneWolf = vars.LoneWolf or {}
    return vars.LoneWolf
end

-- Utility: find in table
function table.find(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

-- Get all valid party members (not vanished)
local function GetValidParty()
    local valid = {}
    local players = Osi.DB_Players:Get(nil) or {}
    for _, entry in pairs(players) do
        local charID = entry[1]
        if Osi.IsPlayer(charID) == 1 and Osi.HasActiveStatus(charID, SITOUT_VANISH_STATUS) == 0 then
            table.insert(valid, charID)
        end
    end
    return valid
end

-- Apply Lone Wolf boosts, preserving HP if first application
local function ApplyLoneWolf(charID, forceApply)
    local vars = LoneWolfVars()
    if not forceApply and vars[charID] then return end -- Skip if already applied, unless forcing

    -- Apply statuses immediately
    Osi.ApplyStatus(charID, LONE_WOLF_STATUS, -1, 1)
    Osi.ApplyStatus(charID, GOON_LONE_WOLF_SE_BUFFS, -1, 1)
    for _, boost in ipairs(statBoosts) do
        if Osi.HasPassive(charID, boost.passive) == 1 then
            Osi.ApplyStatus(charID, boost.status, -1, 1)
        end
    end

    -- Preserve HP before applying Lone Wolf HP boosts
    local entityHandle = Ext.Entity.Get(charID)
    if entityHandle and entityHandle.Health then
        local currentHp = entityHandle.Health.Hp
        local subscription

        -- Apply Lone Wolf boosts
        for _, boost in ipairs(loneWolfBoosts) do
            Osi.AddBoosts(charID, boost.boost, charID, charID)
        end

        -- Subscribe to entity health changes so we can restore HP
        subscription = Ext.Entity.Subscribe("Health", function(health, _, _)
            -- Wait a tick longer to ensure engine recalcs max HP
            Ext.Timer.WaitFor(100, function()
                health.Health.Hp = currentHp
                health:Replicate("Health")
                if subscription then
                    Ext.Entity.Unsubscribe(subscription)
                end
            end)
        end, entityHandle)
    else
        -- Fallback if entity/health not found
        for _, boost in ipairs(loneWolfBoosts) do
            Osi.AddBoosts(charID, boost.boost, charID, charID)
        end
    end

    vars[charID] = true
end

-- Remove Lone Wolf boosts
local function RemoveLoneWolf(charID)
    local vars = LoneWolfVars()
    Osi.RemoveStatus(charID, LONE_WOLF_STATUS)
    Osi.RemoveStatus(charID, GOON_LONE_WOLF_SE_BUFFS)
    for _, boost in ipairs(statBoosts) do
        Osi.RemoveStatus(charID, boost.status)
    end
    for _, boost in ipairs(loneWolfBoosts) do
        Osi.RemoveBoosts(charID, boost.boost, 0, charID, charID)
    end
    vars[charID] = nil
end

-- Incremental check/update function
local function CheckAndUpdateLoneWolfBoosts()
    local vars = LoneWolfVars()
    local valid = GetValidParty()
    local partySize = #valid

    -- Apply to eligible characters
    for _, charID in ipairs(valid) do
        local hasPassive = Osi.HasPassive(charID, LONE_WOLF_PASSIVE) == 1
        local alreadyBoosted = vars[charID] or Osi.HasActiveStatus(charID, LONE_WOLF_STATUS) == 1

        if hasPassive and partySize <= PartyLimit then
            -- If not yet boosted this session AND status not present, preserve HP; otherwise just mark vars
            if not alreadyBoosted then
                ApplyLoneWolf(charID, true)
            else
                -- Ensure vars tracks them so incremental updates work
                vars[charID] = true
            end
        elseif vars[charID] then
            RemoveLoneWolf(charID)
        end
    end

    -- Clean up vars for anyone no longer in the party
    for charID in pairs(vars) do
        if not table.find(valid, charID) then
            RemoveLoneWolf(charID)
        end
    end
end


-- Special reload-only check
local function ForceReapplyLoneWolfOnReload()
    local valid = GetValidParty()
    for _, charID in ipairs(valid) do
        if Osi.HasPassive(charID, LONE_WOLF_PASSIVE) == 1 then
            ApplyLoneWolf(charID, true) -- forceApply ensures HP-preserve logic runs
        end
    end
end

-- Listeners
Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", ForceReapplyLoneWolfOnReload)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", CheckAndUpdateLoneWolfBoosts)
Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", CheckAndUpdateLoneWolfBoosts)

-- Delay update for levelups
local function delayedUpdateLoneWolfStatus(character)
    Ext.Timer.WaitFor(500, function()
        CheckAndUpdateLoneWolfBoosts()
    end)
end
Ext.Osiris.RegisterListener("LeveledUp", 1, "after", function(character)
    if Osi.IsPlayer(character) == 1 then
        delayedUpdateLoneWolfStatus(character)
    end
end)

-- React to vanish status changes
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, cause, _)
    if status == SITOUT_VANISH_STATUS then
        CheckAndUpdateLoneWolfBoosts()
    end
end)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, cause, _)
    if status == SITOUT_VANISH_STATUS then
        CheckAndUpdateLoneWolfBoosts()
    end
end)
