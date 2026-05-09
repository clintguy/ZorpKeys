local prefix = "ZORPKEYS"
C_ChatInfo.RegisterAddonMessagePrefix(prefix)

local lastUsed = 0
local cooldown = 60

-- Function to get and format the current character's key info
local function GetKeyString()
    local mapID = C_Keystone.GetKeystoneMapID()
    local level = C_Keystone.GetKeystoneLevel()
    
    if mapID and level and level > 0 then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        return string.format("%s - %s %d", UnitName("player"), name, level)
    end
    return nil
end

-- Slash Command Handler
SLASH_ZORPKEYS1 = "/zorpkeys"
SlashCmdList["ZORPKEYS"] = function()
    local currentTime = GetTime()
    


    -- Check the 60-second internal cooldown
    if (currentTime - lastUsed) < cooldown then
        local remaining = math.ceil(cooldown - (currentTime - lastUsed))
        print(string.format("|cFFFF0000ZorpKeys:|r On cooldown! Wait %d more seconds.", remaining))
        return
    end

    lastUsed = currentTime
    local myKey = GetKeyString()
    if myKey then
        if IsInGroup() then
            C_ChatInfo.SendAddonMessage(prefix, "REQUEST_KEYS", "PARTY")
            SendChatMessage(myKey, "PARTY")
        else
            print(myKey)
        end
    end
end

-- Listener for Addon Messages
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, event, msgPrefix, message, channel, sender)
    if msgPrefix == prefix and message == "REQUEST_KEYS" then
        -- Only respond if it came from someone else in the party
        if Ambiguate(sender, "none") ~= UnitName("player") then
            local myKey = GetKeyString()
            if myKey then
                SendChatMessage(myKey, "PARTY")
            end
        end
    end
end)