-- TODO: Fix bugs.
-- two main bugs: loading new level, e.g. going to act 2 doubles hp - pretty sure I fixed it. We force applied the lone wolf shit on level load
-- Other bug is sit this one out not working. gonna need to test. Maybe add debug prints? :shrug: we'll see later
-- Add mcm menu
-- Make DR optional, make party size configurable, enable toggle and optionally just grant it even if you don't have the feat? maybe more idk?

local LONE_WOLF_STATUS = "GOON_LONE_WOLF_STATUS"
local LONE_WOLF_PASSIVE = "Goon_Lone_Wolf_Passive_Dummy"
local GOON_LONE_WOLF_HPMAX_STATUS = "GOON_LONE_WOLF_HPMAX_STATUS"
local GOON_LONE_WOLF_DR_STATUS = "GOON_LONE_WOLF_DR_STATUS"
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

local function TrimGuid(charID)
    if not charID then return nil end
    return string.sub(charID, -36)
end

local function IsValidPartyMember(charID)
    return Osi.IsPlayer(charID) == 1
        and Osi.IsSummon(charID) == 0
        and Osi.HasActiveStatus(charID, SITOUT_VANISH_STATUS) == 0
end

local function ApplyStatusIfMissing(charID, status)
    if Osi.HasActiveStatus(charID, status) == 1 then return end
    Osi.ApplyStatus(charID, status, -1, 1)
end

local function ApplyStatusPreserveHp(charID, status)
    if Osi.HasActiveStatus(charID, status) == 1 then return end

    local entityHandle = Ext.Entity.UuidToHandle(charID)
    if not (entityHandle and entityHandle.Health) then
        Osi.ApplyStatus(charID, status, -1, 1)
        return
    end

    local currentHp = entityHandle.Health.Hp
    local sub
    ---@diagnostic disable-next-line: param-type-mismatch
    sub = Ext.Entity.Subscribe("Health", function(health, _, _)
        -- Restore HP after the engine applies its changes
        Ext.Timer.WaitFor(50, function()
            health.Health.Hp = currentHp
            health:Replicate("Health")
            Ext.Entity.Unsubscribe(assert(sub)) -- unsubscribe immediately
        end)
    end, entityHandle)

    Osi.ApplyStatus(charID, status, -1, 1)
end

local function ApplyLoneWolf(charID)
    ApplyStatusIfMissing(charID, LONE_WOLF_STATUS)
    ApplyStatusPreserveHp(charID, GOON_LONE_WOLF_HPMAX_STATUS)
    ApplyStatusIfMissing(charID, GOON_LONE_WOLF_DR_STATUS)

    for _, boost in ipairs(statBoosts) do
        if Osi.HasPassive(charID, boost.passive) == 1 then
            ApplyStatusIfMissing(charID, boost.status)
        else
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

local function UpdateLoneWolf()
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
                and Osi.HasPassive(guid, LONE_WOLF_PASSIVE) == 1
                and partySize <= PartyLimit

            if eligible then
                ApplyLoneWolf(guid)
            else
                RemoveLoneWolf(guid)
            end
        end
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", UpdateLoneWolf)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", UpdateLoneWolf)
Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", UpdateLoneWolf)

local function delayedUpdateLoneWolfStatus(character)
    Ext.Timer.WaitFor(500, function()
        UpdateLoneWolf()
    end)
end
Ext.Osiris.RegisterListener("LeveledUp", 1, "after", function(character)
    if Osi.IsPlayer(character) == 1 then
        delayedUpdateLoneWolfStatus(character)
    end
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
