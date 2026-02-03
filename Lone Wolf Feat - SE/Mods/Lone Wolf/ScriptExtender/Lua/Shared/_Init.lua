-- Lone Wolf shared initialization
Ext.Require("Shared/Config.lua")
Ext.Require("Shared/Translator.lua")

---@diagnostic disable-next-line: redundant-parameter
Ext.Vars.RegisterModVariable(ModuleUUID, "LoneWolfData", {
    Server = true,
    Client = true,
    WriteableOnServer = true,
    WriteableOnClient = true,
    SyncToClient = true,
    SyncToServer = true
})
