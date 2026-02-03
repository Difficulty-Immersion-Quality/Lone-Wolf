---@diagnostic disable: undefined-field, inject-field

local Translator = LoneWolf.Translator
local Config = LoneWolf.Config
local settings = Config.Read()
local widgets = {}
local LoneWolfTab = nil
local overridesSectionUI = nil
local syncToken = 0
local DR_TYPE_OPTIONS = { "Half", "Flat", "Threshold" }
local ABILITY_OPTIONS = { "None", "Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma" }

local function SyncToServer(debounceMs)
    local doSync = function()
        settings = Config.ApplyDefaults(settings)
        Config.Save(settings)
        Ext.Net.PostMessageToServer("LoneWolf_ConfigChanged", Ext.Json.Stringify(settings))
    end

    if debounceMs and debounceMs > 0 then
        syncToken = syncToken + 1
        local token = syncToken
        Ext.Timer.WaitFor(debounceMs, function()
            if token == syncToken then doSync() end
        end)
    else
        doSync()
    end
end

local function GetOptionIndex(options, value)
    for i, option in ipairs(options) do
        if option == value then
            return i - 1
        end
    end
    return 0
end

local function GetSliderValue(slider, fallback)
    if not slider then return fallback end
    local value = slider.Value
    if type(value) == "table" then
        return value[1] ~= nil and value[1] or fallback
    end
    if type(value) == "number" then
        return value
    end
    return fallback
end

local function SetSliderValue(slider, value)
    if not slider then return end
    if type(slider.Value) == "table" then
        slider.Value[1] = value
    else
        slider.Value = value
    end
end

local function TrimGuid(uuid)
    if type(uuid) ~= "string" then return nil end
    return string.sub(uuid, -36)
end

local function GetAbilityOverrides()
    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    vars.LoneWolfData = vars.LoneWolfData or {}
    vars.LoneWolfData.AbilityOverrides = vars.LoneWolfData.AbilityOverrides or {}
    return vars.LoneWolfData.AbilityOverrides
end

local function GetPartyMembers()
    local list = {}
    local partyMembers = Ext.Entity.GetAllEntitiesWithComponent("PartyMember")
    for _, entity in ipairs(partyMembers) do
        if entity.Uuid and entity.Uuid.EntityUuid then
            local name = entity.Uuid.EntityUuid
            if entity.DisplayName and entity.DisplayName.Name then
                local ok, result = pcall(function() return entity.DisplayName.Name:Get() end)
                if ok and result and result ~= "" then
                    name = result
                end
            end
            table.insert(list, { uuid = entity.Uuid.EntityUuid, name = name })
        end
    end
    table.sort(list, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)
    return list
end

local function ClearOverridesChildren()
    if not (overridesSectionUI and overridesSectionUI.Children) then return end
    local toDestroy = {}
    for _, child in ipairs(overridesSectionUI.Children) do
        local ok, hasHeaders = pcall(function() return child.Headers end)
        if not (ok and hasHeaders == true) then
            table.insert(toDestroy, child)
        end
    end
    for _, child in ipairs(toDestroy) do child:Destroy() end
end

local function SavePlayerOverride(abilityOverrides, key, firstCombo, secondCombo)
    local first = ABILITY_OPTIONS[firstCombo.SelectedIndex + 1]
    local second = ABILITY_OPTIONS[secondCombo.SelectedIndex + 1]
    if (first == "None" or first == nil) and (second == "None" or second == nil) then
        abilityOverrides[key] = nil
    else
        abilityOverrides[key] = { first = first, second = second }
    end
    local vars = Ext.Vars.GetModVariables(ModuleUUID)
    vars.LoneWolfData = vars.LoneWolfData or {}
    vars.LoneWolfData.AbilityOverrides = abilityOverrides
    SyncToServer()
end

local function RebuildOverridesSection()
    if not overridesSectionUI then return end
    ClearOverridesChildren()

    local note = overridesSectionUI:AddText(Translator:translate("AbilityOverridesNote"))
    note.TextWrapPos = 0

    local refreshBtn = overridesSectionUI:AddButton(Translator:translate("Button_RefreshParty"))
    refreshBtn.OnClick = function() RebuildOverridesSection() end

    local players = GetPartyMembers()
    if not players or #players == 0 then
        overridesSectionUI:AddText(Translator:translate("AbilityOverridesEmpty"))
        return
    end

    local abilityOverrides = GetAbilityOverrides()
    local tableObj = overridesSectionUI:AddTable("LoneWolfAbilityOverrides", 4)
    tableObj.Borders = true
    tableObj.RowBg = true
    tableObj:AddColumn(Translator:translate("OverridesHeader_Name"), "WidthStretch", 1.0)
    tableObj:AddColumn(Translator:translate("OverridesHeader_First"), "WidthFixed", 180)
    tableObj:AddColumn(Translator:translate("OverridesHeader_Second"), "WidthFixed", 180)
    tableObj:AddColumn("", "WidthFixed", 70)

    local header = tableObj:AddRow()
    header.Headers = true
    header:AddCell():AddText(Translator:translate("OverridesHeader_Name"))
    header:AddCell():AddText(Translator:translate("OverridesHeader_First"))
    header:AddCell():AddText(Translator:translate("OverridesHeader_Second"))
    header:AddCell():AddText("")

    for _, player in ipairs(players) do
        local row = tableObj:AddRow()
        row:AddCell():AddText(player.name or "Unknown")

        local key = TrimGuid(player.uuid) or player.uuid
        local playerOverride = abilityOverrides[key] or abilityOverrides[player.uuid] or {}
        local firstVal = playerOverride.first or playerOverride[1] or "None"
        local secondVal = playerOverride.second or playerOverride[2] or "None"

        local firstCombo = row:AddCell():AddCombo("##LW_First_" .. tostring(player.uuid))
        firstCombo.Options = ABILITY_OPTIONS
        firstCombo.SelectedIndex = GetOptionIndex(ABILITY_OPTIONS, firstVal)
        firstCombo.Disabled = settings.requirePassive

        local secondCombo = row:AddCell():AddCombo("##LW_Second_" .. tostring(player.uuid))
        secondCombo.Options = ABILITY_OPTIONS
        secondCombo.SelectedIndex = GetOptionIndex(ABILITY_OPTIONS, secondVal)
        secondCombo.Disabled = settings.requirePassive

        firstCombo.OnChange = function() SavePlayerOverride(abilityOverrides, key, firstCombo, secondCombo) end
        secondCombo.OnChange = function() SavePlayerOverride(abilityOverrides, key, firstCombo, secondCombo) end

        local clearBtn = row:AddCell():AddButton(Translator:translate("OverridesButton_Clear"))
        clearBtn.Disabled = settings.requirePassive
        clearBtn.OnClick = function()
            firstCombo.SelectedIndex = 0
            secondCombo.SelectedIndex = 0
            SavePlayerOverride(abilityOverrides, key, firstCombo, secondCombo)
        end
    end
end

local function RefreshUI()
    if widgets.enableMod then widgets.enableMod.Checked = settings.enabled end
    if widgets.partyLimit then SetSliderValue(widgets.partyLimit, settings.partyLimit) end
    if widgets.requirePassive then widgets.requirePassive.Checked = settings.requirePassive end
    if widgets.coreBuffs then widgets.coreBuffs.Checked = settings.enableCoreBuffs end
    if widgets.hpMax then widgets.hpMax.Checked = settings.enableHpMax end
    if widgets.damageReduction then widgets.damageReduction.Checked = settings.enableDamageReduction end
    if widgets.statBoosts then widgets.statBoosts.Checked = settings.enableStatBoosts end
    if widgets.hpPercent then SetSliderValue(widgets.hpPercent, settings.hpPercent) end
    if widgets.drPercent then SetSliderValue(widgets.drPercent, settings.drPercent) end
    if widgets.abilityBonus then SetSliderValue(widgets.abilityBonus, settings.abilityBonus) end
    if widgets.drType then widgets.drType.SelectedIndex = GetOptionIndex(DR_TYPE_OPTIONS, settings.drType) end
    if widgets.actionPoints then SetSliderValue(widgets.actionPoints, settings.actionPoints) end
    if widgets.bonusActionPoints then SetSliderValue(widgets.bonusActionPoints, settings.bonusActionPoints) end
    if widgets.reactionPoints then SetSliderValue(widgets.reactionPoints, settings.reactionPoints) end
    if widgets.carryMultiplier then SetSliderValue(widgets.carryMultiplier, settings.carryMultiplier) end
    RebuildOverridesSection()
end

local function SetupMCM()
    if LoneWolfTab ~= nil then return end
    if not Mods.BG3MCM then
        Ext.Log.Print(Translator:translate("Warn_MCMNotFound"))
        return
    end

    Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, Translator:translate("TabName"), function(tabHeader)
        LoneWolfTab = tabHeader

        tabHeader:AddText(Translator:translate("Info_Intro"))
        tabHeader:AddSeparator()

        local generalHeader = tabHeader:AddCollapsingHeader(Translator:translate("Header_General"))
        generalHeader.DefaultOpen = true

        widgets.enableMod = generalHeader:AddCheckbox(Translator:translate("Checkbox_EnableMod"), settings.enabled)
        widgets.enableMod.OnChange = function(chk)
            settings.enabled = chk.Checked
            SyncToServer(200)
        end

        widgets.partyLimit = generalHeader:AddSliderInt(Translator:translate("Slider_PartyLimit"), settings.partyLimit, 0,
            10)
        widgets.partyLimit:Tooltip():AddText(Translator:translate("Tooltip_PartyLimit"))
        widgets.partyLimit.OnChange = function(slider)
            settings.partyLimit = GetSliderValue(slider, settings.partyLimit)
            SyncToServer(200)
        end

        widgets.requirePassive = generalHeader:AddCheckbox(Translator:translate("Checkbox_RequirePassive"),
            settings.requirePassive)
        widgets.requirePassive:Tooltip():AddText(Translator:translate("Tooltip_RequirePassive"))
        widgets.requirePassive.OnChange = function(chk)
            settings.requirePassive = chk.Checked
            SyncToServer(200)
            RebuildOverridesSection()
        end

        local effectsHeader = tabHeader:AddCollapsingHeader(Translator:translate("Header_Effects"))
        effectsHeader.DefaultOpen = true

        widgets.coreBuffs = effectsHeader:AddCheckbox(Translator:translate("Checkbox_CoreBuffs"),
            settings.enableCoreBuffs)
        widgets.coreBuffs.OnChange = function(chk)
            settings.enableCoreBuffs = chk.Checked
            SyncToServer(200)
        end

        widgets.hpMax = effectsHeader:AddCheckbox(Translator:translate("Checkbox_HpMax"), settings.enableHpMax)
        widgets.hpMax.OnChange = function(chk)
            settings.enableHpMax = chk.Checked
            SyncToServer(200)
        end

        widgets.damageReduction = effectsHeader:AddCheckbox(Translator:translate("Checkbox_DamageReduction"),
            settings.enableDamageReduction)
        widgets.damageReduction.OnChange = function(chk)
            settings.enableDamageReduction = chk.Checked
            SyncToServer(200)
        end

        widgets.statBoosts = effectsHeader:AddCheckbox(Translator:translate("Checkbox_StatBoosts"),
            settings.enableStatBoosts)
        widgets.statBoosts.OnChange = function(chk)
            settings.enableStatBoosts = chk.Checked
            SyncToServer(200)
        end

        widgets.hpPercent = effectsHeader:AddSliderInt(Translator:translate("Slider_HpPercent"), settings.hpPercent, 0,
            100)
        widgets.hpPercent:Tooltip():AddText(Translator:translate("Tooltip_HpPercent"))
        widgets.hpPercent.OnChange = function(slider)
            settings.hpPercent = GetSliderValue(slider, settings.hpPercent)
            SyncToServer(200)
        end

        widgets.drType = effectsHeader:AddCombo(Translator:translate("Dropdown_DrType"))
        widgets.drType.Options = DR_TYPE_OPTIONS
        widgets.drType.SelectedIndex = GetOptionIndex(DR_TYPE_OPTIONS, settings.drType)
        widgets.drType:Tooltip():AddText(Translator:translate("Tooltip_DrType"))
        widgets.drType.OnChange = function(combo)
            settings.drType = DR_TYPE_OPTIONS[combo.SelectedIndex + 1]
            SyncToServer()
        end

        widgets.drPercent = effectsHeader:AddSliderInt(Translator:translate("Slider_DrPercent"), settings.drPercent, 0,
            100)
        widgets.drPercent:Tooltip():AddText(Translator:translate("Tooltip_DrPercent"))
        widgets.drPercent.OnChange = function(slider)
            settings.drPercent = GetSliderValue(slider, settings.drPercent)
            SyncToServer(200)
        end

        widgets.abilityBonus = effectsHeader:AddSliderInt(Translator:translate("Slider_AbilityBonus"),
            settings.abilityBonus, 0, 10)
        widgets.abilityBonus:Tooltip():AddText(Translator:translate("Tooltip_AbilityBonus"))
        widgets.abilityBonus.OnChange = function(slider)
            settings.abilityBonus = GetSliderValue(slider, settings.abilityBonus)
            SyncToServer(200)
        end

        local coreHeader = effectsHeader:AddCollapsingHeader(Translator:translate("Header_CoreBuffs"))
        coreHeader.DefaultOpen = false

        widgets.actionPoints = coreHeader:AddSliderInt(Translator:translate("Slider_ActionPoints"), settings
            .actionPoints, 0, 5)
        widgets.actionPoints:Tooltip():AddText(Translator:translate("Tooltip_ActionPoints"))
        widgets.actionPoints.OnChange = function(slider)
            settings.actionPoints = GetSliderValue(slider, settings.actionPoints)
            SyncToServer(200)
        end

        widgets.bonusActionPoints = coreHeader:AddSliderInt(Translator:translate("Slider_BonusActionPoints"),
            settings.bonusActionPoints, 0, 5)
        widgets.bonusActionPoints:Tooltip():AddText(Translator:translate("Tooltip_BonusActionPoints"))
        widgets.bonusActionPoints.OnChange = function(slider)
            settings.bonusActionPoints = GetSliderValue(slider, settings.bonusActionPoints)
            SyncToServer(200)
        end

        widgets.reactionPoints = coreHeader:AddSliderInt(Translator:translate("Slider_ReactionPoints"),
            settings.reactionPoints, 0, 5)
        widgets.reactionPoints:Tooltip():AddText(Translator:translate("Tooltip_ReactionPoints"))
        widgets.reactionPoints.OnChange = function(slider)
            settings.reactionPoints = GetSliderValue(slider, settings.reactionPoints)
            SyncToServer(200)
        end

        widgets.carryMultiplier = coreHeader:AddSlider(Translator:translate("Slider_CarryMultiplier"),
            settings.carryMultiplier, 0.0, 10.0)
        widgets.carryMultiplier:Tooltip():AddText(Translator:translate("Tooltip_CarryMultiplier"))
        widgets.carryMultiplier.OnChange = function(slider)
            settings.carryMultiplier = GetSliderValue(slider, settings.carryMultiplier)
            SyncToServer(200)
        end

        tabHeader:AddSeparator()
        overridesSectionUI = tabHeader:AddCollapsingHeader(Translator:translate("Header_AbilityOverrides"))
        overridesSectionUI.DefaultOpen = false
        RebuildOverridesSection()

        tabHeader:AddSeparator()
        local resetButton = tabHeader:AddButton(Translator:translate("Button_Reset"))
        resetButton.OnClick = function()
            settings = Config.DeepCopy(Config.default)
            SyncToServer()
            RefreshUI()
        end
    end)
end

SetupMCM()
