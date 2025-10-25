-- RizzBot: capture chat for 20 seconds, then stop
-- Compatible with TextChatService and legacy Player.Chatted
-- Delta Executor compatible

return function(secretKey)
    if secretKey then
        print("[RizzBot] Received external key: " .. tostring(secretKey))
    end

    local Players = game:GetService("Players")
    local TextChatService = game:GetService("TextChatService")

    local FOLDER = "RizzBot"
    local FILE_NAME = FOLDER .. "/ChatLog.txt"
    local DURATION = secretKey -- seconds

    local has_isfile = type(isfile) == "function"
    local has_writefile = type(writefile) == "function"
    local has_appendfile = type(appendfile) == "function"
    local has_makefolder = type(makefolder) == "function"

    local connections = {}
    local chatMode = "Unknown"

    local function timestamp()
        return DateTime.now():ToIsoDate()
    end

    local function ensure_path()
        if has_makefolder then pcall(function() makefolder(FOLDER) end) end
        if has_isfile and isfile(FILE_NAME) then return end
        if has_writefile then
            writefile(FILE_NAME, string.format("RizzBot chat log started %s\n", timestamp()))
        end
    end

    local function log(line)
        print(line)
        if has_appendfile then
            appendfile(FILE_NAME, line .. "\n")
        end
    end

    ensure_path()

    local function hook_textchat()
        local ok, conn = pcall(function()
            if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                conn = TextChatService.MessageReceived:Connect(function(msg)
                    local author = (msg.TextSource and msg.TextSource.Name) or "System"
                    local out = string.format("[%s] %s: %s", timestamp(), author, msg.Text)
                    log(out)
                end)
                chatMode = "TextChatService"
                return conn
            end
        end)
        if ok and conn then
            table.insert(connections, conn)
            return true
        end
        return false
    end

    local function hook_legacy()
        local function hook_player(plr)
            local conn = plr.Chatted:Connect(function(msg)
                local out = string.format("[%s] %s: %s", timestamp(), plr.Name, msg)
                log(out)
            end)
            table.insert(connections, conn)
        end
        for _, plr in ipairs(Players:GetPlayers()) do hook_player(plr) end
        table.insert(connections, Players.PlayerAdded:Connect(hook_player))
        chatMode = "LegacyChat"
    end

    if not hook_textchat() then
        hook_legacy()
    end

    -- Only log once (no double print)
    local startMsg = string.format("RizzBot logging via %s for %d seconds... (Saved to %s)", chatMode, DURATION, FILE_NAME)
    log(startMsg)

    task.delay(DURATION, function()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        local stopMsg = string.format("RizzBot stopped logging after %d seconds. (Mode: %s)", DURATION, chatMode)
        log(stopMsg)
    end)
end
