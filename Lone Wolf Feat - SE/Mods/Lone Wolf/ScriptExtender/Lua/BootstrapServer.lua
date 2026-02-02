local opts = {
    Server = true,
    Client = false,
    WriteableOnServer = true,
    WriteableOnClient = false,
    Persistent = true,
    SyncToClient = false,
    SyncToServer = true,
    SyncOnWrite = false,
    DontCache = false
}
---@diagnostic disable-next-line: redundant-parameter
Ext.Vars.RegisterModVariable(ModuleUUID, "LoneWolf", opts)
Ext.Require("Server/_Core.lua")