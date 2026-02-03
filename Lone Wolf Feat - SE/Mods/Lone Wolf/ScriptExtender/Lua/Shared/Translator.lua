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
    ["Slider_HpPercent"] = "h6e7e620b89e14804915a58178c40a495c630",
    ["Tooltip_HpPercent"] = "h86648818dbc64417ae5ebce80b2a4658517g",
    ["Slider_DrPercent"] = "hb72c9e67b0c5495eb283f7ed8f7f61c5cac8",
    ["Tooltip_DrPercent"] = "h4a4f984b6059414595d176f7a1ab4d3daa2b",
    ["Dropdown_DrType"] = "h8583172e6dbb4b37b97b0064cbb07ad7d174",
    ["Tooltip_DrType"] = "h852e0f9043264275b9b135ef296c1c6a7a4c",
    ["Slider_AbilityBonus"] = "ha9d0d3afaabb4512a247985012146feec793",
    ["Tooltip_AbilityBonus"] = "he346582068c44f3789ada48f061a20afbd48",
    ["Header_CoreBuffs"] = "hf136472e0b9c4d17b9016c10b88c4d3f5d61",
    ["Slider_ActionPoints"] = "h8e0c8975f8a74d12b7a2ee3f2ea431d96b6f",
    ["Tooltip_ActionPoints"] = "hbebfdf79ebf2449b996c8e89d45ef4bf3ec0",
    ["Slider_BonusActionPoints"] = "h02967c88f4744f88a239d3376a8f0b96cba5",
    ["Tooltip_BonusActionPoints"] = "h982774b8c7c24b7e8f7b6d56d0c4054c1525",
    ["Slider_ReactionPoints"] = "h8f1f0479e0a343d0b7a8d0b1d8b8cd0d2f56",
    ["Tooltip_ReactionPoints"] = "h1bf2168a1c5c4f6e8c6a7a3a9df1a1d6f9b1",
    ["Slider_CarryMultiplier"] = "hf6e0d769d6ef4a25a2c8b6f9d6cfa4c5db93",
    ["Tooltip_CarryMultiplier"] = "h308d9bb8d8a2451f87f1d6e5ce5e7f4a1fb7",
    ["Header_AbilityOverrides"] = "h2b7e0428f5af4e0d8ef0a9b5fb7e79e7d9f1",
    ["AbilityOverridesNote"] = "h0b6d0939f1a64a02b04e3f3ad5e9e6e3d2a0",
    ["AbilityOverridesEmpty"] = "hf56f6b3e17174c408971bc0782827ac5e8d7",
    ["OverridesHeader_Name"] = "hf9f929ce47a645f08c2f32a0eaa30e15275c",
    ["OverridesHeader_First"] = "hd3c6328d3f134dcc81d34a9a95c71ad81513",
    ["OverridesHeader_Second"] = "hbdf8e02d5c9642beb3bfe1431be35c56df81",
    ["OverridesButton_Clear"] = "h8c41ac3762b04b7ea7be6426ee3cab8d4841",
    ["Button_RefreshParty"] = "h484f10d9c40c4a2d8d4c47d7f4a0f7b6b1d9",
    ["Button_Reset"] = "haea556b9a28b46c182f4bebc560d717014b3",
    ["Warn_MCMNotFound"] = "hb1b273af9f9b428a952a25eefbe318153fc8",
})

return Translator
