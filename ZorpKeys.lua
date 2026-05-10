local prefix = "ZORPKEYS"
C_ChatInfo.RegisterAddonMessagePrefix(prefix)



local lastUsed = 0
local cooldown = 60
local partyCooldownActive = false

-- Function to get and format the current character's key info
local function GetKeyString()
    -- Loop through all bags (0-4 are main bags, -1 is the key ring if still exists and relevant)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                if string.find(itemLink, "Keystone:") then
                    return itemLink -- Return the full item link
                end
            end
        end -- Close for slot
    end -- Close for bag

    print(string.format("|cFFFF0000ZorpKeys:|r DEBUG - No valid keystone found in inventory."))
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

    -- Check if a party-wide cooldown is active
    if IsInGroup() and partyCooldownActive then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000ZorpKeys:|r Party-wide cooldown active. Please wait."))
        return
    end

    lastUsed = currentTime
    -- If in a group, initiate party-wide cooldown and broadcast it
    if IsInGroup() then
        partyCooldownActive = true
        C_ChatInfo.SendAddonMessage(prefix, "COOLDOWN_START", "PARTY")
        -- Set a timer to clear the party-wide cooldown flag
        C_Timer.After(cooldown, function()
            partyCooldownActive = false

        end)
    end
    
    local myKey = GetKeyString()
    local messageToDisplay = myKey or "No keystone found."

    if IsInGroup() then
        -- Initiator sends a request to others
        C_ChatInfo.SendAddonMessage(prefix, "REQUEST_KEYS", "PARTY")
        -- Initiator also reports their own key to party chat
        SendChatMessage(messageToDisplay, "PARTY")
    else
        -- Initiator reports their own key to system message if alone
        DEFAULT_CHAT_FRAME:AddMessage(messageToDisplay)
    end
end

-- Listener for Addon Messages
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, event, msgPrefix, message, channel, sender)
    if msgPrefix == prefix then
        local messageType = string.match(message, "(%S+)") -- Only need the messageType for the request
        if messageType == "REQUEST_KEYS" then
            -- Only respond if it came from someone else in the party AND we are in a group
            if IsInGroup() and Ambiguate(sender, "none") ~= UnitName("player") then
                local myKey = GetKeyString()
                local messageToDisplay = myKey or "No keystone found."
                SendChatMessage(messageToDisplay, "PARTY")
            end
        elseif messageType == "COOLDOWN_START" then
            -- A party member initiated a cooldown
            if IsInGroup() and Ambiguate(sender, "none") ~= UnitName("player") then
                partyCooldownActive = true
                -- Set a timer to clear the party-wide cooldown flag
                C_Timer.After(cooldown, function()
                    partyCooldownActive = false
                end)
            end
        end
    end
end)