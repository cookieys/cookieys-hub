local function getExecutorLevel()
    local executorName = "Unknown Executor"
    local executorLevel = "Low Level"

    if syn and syn.protect_function then
        executorName = "Synapse X"
        executorLevel = "High Level"
    elseif KRNL_LOADED then
        executorName = "Krnl"
        executorLevel = "Medium Level"
    elseif getexecutorname and getexecutorname() == "ScriptWare" then
        executorName = "ScriptWare"
        executorLevel = "High Level"
    elseif getgenv().IsRBXLegacy then
        executorName = "Sentinel"
        executorLevel = "Medium Level"
    elseif is_sirhurt_closure then
        executorName = "SirHurt"
        executorLevel = "Medium Level"
    elseif pebc_execute then
        executorName = "Pebble"
        executorLevel = "Low Level" -- Might be Medium depending on version
    elseif gethui then
        executorName = "Oxygen U"
        executorLevel = "Low Level" -- Might be Medium depending on version
    elseif secure_loadstring then
        executorName = "Fluxus"
        executorLevel = "Medium Level"
    elseif __namecall and hookfunction then -- Less reliable, might catch others
        executorName = "Electron or Similar"
        executorLevel = "Low to Medium Level"
    elseif getreg()['FireNetwork'] then -- Even less reliable, very generic check
        executorName = "Possible Medium Level Executor"
        executorLevel = "Low to Medium Level"
    end

    print("Executor Name: " .. executorName)
    print("Executor Level: " .. executorLevel)
    return executorName, executorLevel
end

return getExecutorLevel()
