---@diagnostic disable: duplicate-set-field

LoneWolf = LoneWolf or {}
LoneWolf.Translator = LoneWolf.Translator or {}
local Translator = LoneWolf.Translator
local translationTable = Translator._table or {}
Translator._table = translationTable

function Translator:RegisterHandles(handleMap)
    for key, value in pairs(handleMap) do
        translationTable[key] = value
    end
end

function Translator:translate(key)
    local handle = translationTable[key]
    if handle then
        return Ext.Loca.GetTranslatedString(handle, key)
    else
        return key
    end
end

Translator:RegisterHandles({
    ["TabName"] = "hace1e8d1b8eb489888aa180e20e85321049e",
    ["Info_Intro"] = "h1943ecd841964045b8cbdad06feafbc0803g",
    ["Header_General"] = "ha797eca6400e423cb3f3c66c0a1eacfaac63",
    ["Header_Effects"] = "hf53e3929e59a4f85af841aa82668318c43e4",
    ["Checkbox_EnableMod"] = "hb4650452f82641f8b829ab01ea12072d6e57",
    ["Slider_PartyLimit"] = "h3287ab42ce0845f9b56512d60db6544b3a13",
    ["Tooltip_PartyLimit"] = "h9a27580149974da68bdb93f6c05295fceee2",
    ["Checkbox_RequirePassive"] = "hb169d72a9a414bc39ac8dcec4bd6741a5f8g",
    ["Tooltip_RequirePassive"] = "h2a42644f63a6470ca4e18c13435645310885",
    ["Checkbox_CoreBuffs"] = "h2329b286163c440ebed00334dc08aef8fe66",
    ["Checkbox_HpMax"] = "h580865f081ca482fad5fc0bba28562dfc673",
    ["Checkbox_DamageReduction"] = "hd8c93ee0185b436681efaa216c1947bf43cg",
    ["Checkbox_StatBoosts"] = "hbfec879989874c7a8b3bceb5b70186a34c6d",
    ["Button_Reset"] = "haea556b9a28b46c182f4bebc560d717014b3",
    ["Warn_MCMNotFound"] = "hb1b273af9f9b428a952a25eefbe318153fc8",
})

return Translator