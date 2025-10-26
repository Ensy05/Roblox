-- RizzBot: Chat feed (TextChatService only)
-- Lightweight version for use with loadstring(AUTH_KEY)
-- Forwards chat messages to RizzBot

return function(AUTH_KEY)
    -- Server Constants
    local TextChatService = game:GetService("TextChatService")
    local HttpService = game:GetService("HttpService")

    -- Settings
    local URL = "https://1dc5ee43-672f-4bbf-b9e2-eef62b1dc204-00-1wr14944kuc07.riker.replit.dev/"
    local matchUsername = true
    local minSMTierThreeRarity = 2.5e-07 -- 1 in 4 Million

    local hexDict = {
        ["#ff0064"] = "nil",
        ["#e3ff00"] = "Shiny",
        ["#ff8200"] = "Mythic",
        ["#00ff02"] = "Shiny Mythic"
    }

    local multiDict = {
        ["nil"] = 1,
        ["Shiny"] = 40,
        ["Mythic"] = 100,
        ["Shiny Mythic"] = 4000
    }

    -- Variables
    local userId = nil

	-- External key support
	if AUTH_KEY then
		print("[RizzBot] External key received:", AUTH_KEY)
    else
        print("[RizzBot] Key not recieved, exiting")
        return
	end

    if matchUsername then
	    local Players = game:GetService("Players")
        userId = Players.LocalPlayer.Name
    end

    local function findHatch(text)
        text = text:sub(1, -14)

        -- Check for valid starting char
        if utf8.char(utf8.codepoint(text, 1)) ~= "🎉" then
            return
        end

        local offset = 31 -- Holds the total offset the string will have.
        local foundUserId = text:sub(offset, offset + 20):match("([^<]+)") -- Verify that the userId matches if it exists.

        if userId ~= nil and userId ~= foundUserId then
            return
        end

        offset = offset + string.len(foundUserId) + 36 -- Offset to account for username length
        local hexCode = text:sub(offset, offset + 6)
        local variant = hexDict[hexCode]

        if variant == nil then
            return
        end

        if variant ~= "nil" then
            offset = offset + string.len(variant) + 1
        end


        offset = offset + 9
        local petName = text:sub(offset):match("([%w%s]+)%(")
        if petName == nil then
            return
        end

        petName = petName:sub(1, -2)
        offset = offset + string.len(petName) + 2

        local chance = tonumber(text:sub(offset)) / 100
        local baseChance = chance * multiDict[variant]

        local rarity = "Legendary"
        if baseChance <= 5e-08 then
            rarity = "Secret"
        end

        if rarity ~= "Secret" or (baseChance > minSMTierThreeRarity and variant ~= "Shiny Mythic") then
            return
        end

        local returnDict = {
            ["player"] = foundUserId,
            ["pet"] = petName,
            ["color"] = hexCode,
            ["variant"] = variant,
            ["chance"] = chance,
            ["rarity"] = rarity
        }

        return returnDict
    end

    local function sendWebhook(payload)
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

        -- res is a table with StatusCode, Body, Headers
        if res.Success and (res.StatusCode == 200 or res.StatusCode == 201) then
            print("WEBHOOK Post sent for ", payload.pet)
            return true, res
        else
            warn("[Webhook] Non-OK response:", res.StatusCode, res.Body)
            return false, res
        end
    end

	-- Connection handler
	local connection = TextChatService.MessageReceived:Connect(function(message)
		local text = message.Text
		local data = findHatch(text)
        if data ~= nil then
            sendWebhook(data)
        end
	end)

	-- Return a simple API for external control
	return {
		stop = function()
			if connection then
				connection:Disconnect()
				connection = nil
				print("[RizzBot] Chat feed stopped")
			end
		end
	}
end
