---@diagnostic disable: undefined-field, inject-field

local Translator = LoneWolf.Translator
local Config = LoneWolf.Config

local config = Config.Read()
local widgets = {}
local LoneWolfTab = nil

local function SaveAndSync()
    config = Config.ApplyDefaults(config)
    Config.Save(config)
    Ext.Net.PostMessageToServer("LoneWolf_ConfigChanged", Ext.Json.Stringify(config))
end

local function RefreshUI()
    if widgets.enableMod then widgets.enableMod.Checked = config.enabled end
    if widgets.partyLimit then widgets.partyLimit.Value = { config.partyLimit, 0, 0, 0 } end
    if widgets.requirePassive then widgets.requirePassive.Checked = config.requirePassive end
    if widgets.coreBuffs then widgets.coreBuffs.Checked = config.enableCoreBuffs end
    if widgets.hpMax then widgets.hpMax.Checked = config.enableHpMax end
    if widgets.damageReduction then widgets.damageReduction.Checked = config.enableDamageReduction end
    if widgets.statBoosts then widgets.statBoosts.Checked = config.enableStatBoosts end
end

local function SetupMCM()
    if LoneWolfTab ~= nil then return end
    if not Mods.BG3MCM then
        Ext.Log.Print(Translator:translate("Warn_MCMNotFound"))
        return
    end

    local ok, err = pcall(function()
        Mods.BG3MCM.IMGUIAPI:InsertModMenuTab(ModuleUUID, Translator:translate("TabName"), function(tabHeader)
            LoneWolfTab = tabHeader

            tabHeader:AddText(Translator:translate("Info_Intro"))
            tabHeader:AddSeparator()

            local generalHeader = tabHeader:AddCollapsingHeader(Translator:translate("Header_General"))
            generalHeader.DefaultOpen = true

            widgets.enableMod = generalHeader:AddCheckbox(Translator:translate("Checkbox_EnableMod"), config.enabled)
            widgets.enableMod.OnChange = function(chk)
                config.enabled = chk.Checked
                SaveAndSync()
            end

            widgets.partyLimit = generalHeader:AddSliderInt(Translator:translate("Slider_PartyLimit"), config.partyLimit, 0, 10)
            widgets.partyLimit:Tooltip():AddText(Translator:translate("Tooltip_PartyLimit"))
            widgets.partyLimit.OnChange = function(slider)
                if type(slider.Value) == "table" and slider.Value[1] then
                    config.partyLimit = slider.Value[1]
                    SaveAndSync()
                end
            end

            widgets.requirePassive = generalHeader:AddCheckbox(Translator:translate("Checkbox_RequirePassive"), config.requirePassive)
            widgets.requirePassive:Tooltip():AddText(Translator:translate("Tooltip_RequirePassive"))
            widgets.requirePassive.OnChange = function(chk)
                config.requirePassive = chk.Checked
                SaveAndSync()
            end

            local effectsHeader = tabHeader:AddCollapsingHeader(Translator:translate("Header_Effects"))
            effectsHeader.DefaultOpen = true

            widgets.coreBuffs = effectsHeader:AddCheckbox(Translator:translate("Checkbox_CoreBuffs"), config.enableCoreBuffs)
            widgets.coreBuffs.OnChange = function(chk)
                config.enableCoreBuffs = chk.Checked
                SaveAndSync()
            end

            widgets.hpMax = effectsHeader:AddCheckbox(Translator:translate("Checkbox_HpMax"), config.enableHpMax)
            widgets.hpMax.OnChange = function(chk)
                config.enableHpMax = chk.Checked
                SaveAndSync()
            end

            widgets.damageReduction = effectsHeader:AddCheckbox(Translator:translate("Checkbox_DamageReduction"), config.enableDamageReduction)
            widgets.damageReduction.OnChange = function(chk)
                config.enableDamageReduction = chk.Checked
                SaveAndSync()
            end

            widgets.statBoosts = effectsHeader:AddCheckbox(Translator:translate("Checkbox_StatBoosts"), config.enableStatBoosts)
            widgets.statBoosts.OnChange = function(chk)
                config.enableStatBoosts = chk.Checked
                SaveAndSync()
            end

            tabHeader:AddSeparator()
            local resetButton = tabHeader:AddButton(Translator:translate("Button_Reset"))
            resetButton.OnClick = function()
                config = Config.DeepCopy(Config.default)
                SaveAndSync()
                RefreshUI()
            end
        end)
    end)

    if not ok then
        Ext.Log.Print(tostring(err))
    end
end

SetupMCM()
