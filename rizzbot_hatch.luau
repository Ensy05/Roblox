-- RizzBot: Chat feed (TextChatService only)
-- Lightweight version for use with loadstring(AUTH_KEY)
-- Forwards chat messages to RizzBot

return function(AUTH_KEY, MATCH_USERNAME, LEGENDARY_MATCH_RARITY, LEGENDARY_MATCH_TYPES) -- Recieves external params
    -- Server Constants
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    
    local RemoteEvent = ReplicatedStorage.Shared.Framework.Utilities.SendSystemMessage.RemoteEvent

    -- Fetch and Store Functions
    local sub = string.sub
    local len = string.len
    local lower = string.lower
    local find = string.find
    local tonumber = tonumber
    
    -- Settings
    local URL = "https://1dc5ee43-672f-4bbf-b9e2-eef62b1dc204-00-1wr14944kuc07.riker.replit.dev/upload"

    -- Default Configuration
    local SECRET_CHANCE = 5e-08
    local USERNAME = (MATCH_USERNAME ~= false) and lower(Players.LocalPlayer.Name) or nil

    LEGENDARY_MATCH_RARITY = LEGENDARY_MATCH_RARITY + 1e-10 or 1e-06 + 1e-10
    
    LEGENDARY_MATCH_TYPES = LEGENDARY_MATCH_TYPES or {
        ["nil"]          = false,
        ["Shiny"]        = false,
        ["Mythic"]       = false,
        ["Shiny Mythic"] = true
    }
    
    -- Dictionaries
    -- Secret / T3 HEX codes
    local HEX_DICT = {
        ["#ff0064"] = "nil",
        ["#e3ff00"] = "Shiny",
        ["#ff8200"] = "Mythic",
        ["#00ff02"] = "Shiny Mythic"
    }

    local MULTIPLIER_DICT = {
        ["nil"]          = 1,
        ["Shiny"]        = 40,
        ["Mythic"]       = 100,
        ["Shiny Mythic"] = 4000
    }

    local OTHER_PETS = {
        ["Kitty Pot"]   = 2e-09,
        ["Super Shock"] = 1e-09,
        ["Ultimate Clover"] = 5e-09,
        ["Shattered Soul"] = 1e-09,
        ["OG Radiance"] = 2.5e-11,
        ["Andromeda"] = 0.00001,
        ["Ghost Wisps"] = 0.000025,
        ["Armageddon"] = 0.000005
    }

    local payload = {}

    -- External key support
    if AUTH_KEY then
        print("[RizzBot] External key received:", sub(AUTH_KEY, 1, 6) .. "...")
    else
        print("[RizzBot] Key not recieved, exiting")
        return
    end

    local function findHatch(text)
        local totalLen = len(text)
        if totalLen < 100 then return end

        local offset = 31
        local idEnd = offset + 20
        payload.player = sub(text, offset, idEnd)
        local ltPos = find(payload.player, "<", 1, true)
        if ltPos then
            payload.player = sub(payload.player, 1, ltPos - 1)
        end

        if USERNAME and lower(payload.player) ~= USERNAME then return end

        offset = offset + len(payload.player) + 36
        payload.color = sub(text, offset, offset + 6)
        payload.variant = HEX_DICT[payload.color]
        if not payload.variant then return end

        if payload.variant ~= "nil" then
            offset = offset + len(payload.variant) + 1
        end

        offset = offset + 9
        local parenPos = find(text, "(", offset, true)
        if not parenPos then return end
        payload.pet = sub(text, offset, parenPos - 2)
        payload.chance = OTHER_PETS[payload.pet]
        if payload.chance then
            payload.chance = payload.chance / MULTIPLIER_DICT[payload.variant]
            payload.rarity = "Secret"
            return payload
        end
    
        offset = parenPos + 1

        local numEnd = totalLen - 13
        local c = tonumber(sub(text, offset, numEnd))
        if not c and not payload.chance then return end
        payload.chance = c * 0.01
        if payload.chance >= LEGENDARY_MATCH_RARITY then return end

        local baseChance = payload.chance * MULTIPLIER_DICT[payload.variant]
        if baseChance <= SECRET_CHANCE then
            payload.rarity = "Secret"
        else
            payload.rarity = "Legendary"
        end
        if payload.rarity == "Legendary" and (not LEGENDARY_MATCH_TYPES[payload.variant] or baseChance > LEGENDARY_MATCH_RARITY) then
            return
        end

        return payload
    end

    local lastSend = 0
    local SEND_COOLDOWN = 0.5 -- seconds

    local function sendWebhook(payload)
        local now = tick()
        if now - lastSend < SEND_COOLDOWN then
            return false, "Debounced"
        end
        lastSend = now

        local ok, res = pcall(function()
            return HttpService:RequestAsync({
                Url = URL,
                Method = "POST",
                Headers = {
                    ["Authorization"] = AUTH_KEY,
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)

        if not ok then
            warn("[Webhook] RequestAsync failed:", res)
            return false, res
        end

        if res.Success and (res.StatusCode == 200 or res.StatusCode == 201) then
            print("WEBHOOK Post sent for", payload.pet)
            return true, res
        else
            warn("[Webhook] Non-OK response:", res.StatusCode, res.Body)
            return false, res
        end
    end


    -- Connection handler
    local connection = RemoteEvent.OnClientEvent:Connect(function(message)
        payload = {
                player = nil,
                color = nil,
                variant = nil,
                pet = nil,
                chance = nil,
                rarity = nil
        }
        local text = tostring(message)
        local data = findHatch(text)
        if data then
            sendWebhook(data)
        end
    end)

    -- Return a simple API for external control
    return {
        stop = function()
            if connection then
                connection:Disconnect()
                connection = nil
                -- print("[RizzBot] Chat feed stopped")
            end
        end
    }
end
