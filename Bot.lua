local discordia = require('Discordia')
local json = require('json')
local cron = require('cron.cron')
local data
local client = discordia.Client()
local date = discordia.Date()
local pause = 5
local appealchannel
local approvalcount
local approvalratio
local appealweb
local logweb
local botuserid = "855084568407048192"
local appealtable = {}
local awaiting = {}
local cronstorage = {}

function overwritedata(new)
    local temp = io.open("settings.json", "r+")
    temp:write(json.encode(new))
    temp:close()
    appealchannel = client:getChannel(data.appealchannel)
    pause = data.pause
    approvalcount = data.approvalcount
    approvalratio = data.approvalratio
    appealweb = data.appealweb
    logweb = data.logweb
end

-- any method that takes discord ids are strings

function awaitembed(message, count, ratio)
    local embed = message.embed
    local player, userid = message.author.username:match("^[^%s]+"), message.author.username:match("%b[]")
    userid = userid:match("%d+")
    awaiting[player] = {message}
    message:reply{
        embed = {
            title = "Ban Appeal Approved!", 
            description = string.format("[%s](https://discord.com/channels/%s/%s/%s) has been unbanned with a like count of %s and a like ratio of %d%%.", player, message.guild.id, message.channel.id, message.id, count, ratio),
            color = discordia.Color.fromRGB(255,150,50).value,
            footer = {
                text = "This message and the message linked above will be deleted once the user is unbanned."
            }
        }
    }
end

function periodiccheck(message)
    local liked, disliked
    for _,v in message.reactions:__pairs() do
        if v.emojiHash == "👍" then
            liked = v
        elseif v.emojiHash == "👎" then
            disliked = v
        end
    end
    if liked.count >= approvalcount and math.floor(liked.count/(liked.count + disliked.count)*100+.5) > approvalratio then
        coroutine.resume(coroutine.create(function()
            awaitembed(message, liked.count, math.floor(liked.count/(liked.count + disliked.count)*100+.5))
        end))
    else
        appealtable[message.id] = nil
        message:delete()
    end
end

function register(message)
    appealtable[message.id] = message
    message:addReaction("👍")
    message:addReaction("👎")
    table.insert(cronstorage, cron.after(date.parseISO(message.timestamp) + pause, periodiccheck, appealtable[message.id]))
end

function runcron()
    for i,v in pairs(cronstorage) do
        v:reset()
        if v:update(os.time()) then
            cronstorage[i] = nil
        end
    end
end

function initializenew()
    local messages = appealchannel:getMessages(100)
    appealtable = {}
    for _,v in messages:__pairs() do
        if v.webhookId == appealweb then
            register(v)
        elseif v.author.id == botuserid then
            v:delete()
        end
    end
end

client:on("reactionAddUncached", function(channel, messageId, hash, userId)
    if userId ~= botuserid and userid == appealweb then
        appealtable[messageId] = appealchannel:getMessage(messageId)
    end
end)

client:on("reactionAdd", function(reaction, userId)
    if userId ~= botuserid and userid == appealweb then
        appealtable[reaction.message.id] = reaction.message
    end
end)


client:on("messageCreate", function(message)
    local success, result = pcall(function()
        runcron()
    end)
    if not success then print(result) end
    if message.webhookId == appealweb then
        register(message)
    elseif message.author.id == "201461802406641664" then
        if message.content:find('^"') then
            local cmd = message.content:match("^[^%s]+") cmd = cmd:sub(2,cmd:len())
            if cmd:lower() == "ainit" then
                local extracted = message.content:match("[^%s]+$")
                if client:getChannel(extracted) then
                    overwritedata(data)
                    data.appealchannel = extracted
                    message:reply(string.format("Successfully changed ban appeals channel to <#%s>.", extracted))
                    initializenew()
                else
                    message:reply("Invalid channel ID.")
                end
            elseif cmd:lower() == "setpause" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.pause = tonumber(extracted)
                    overwritedata(data)
                    message:reply(string.format("Changed time to check votes to %s seconds.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "setapprovalcount" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.approvalcount = tonumber(extracted)
                    overwritedata(data)
                    message:reply(string.format("Approval count set to %s votes.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "setapprovalratio" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.approvalratio = tonumber(extracted)
                    overwritedata(data)
                    message:reply(string.format("Approval ratio set to %s%%.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "setappealweb" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.appealweb = tonumber(extracted)
                    overwritedata(data)
                    message:reply(string.format("Appeals webhook set to %s.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "setlogweb" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.logweb = tonumber(extracted)
                    overwritedata(data)
                    message:reply(string.format("Logs webhook set to %s.", extracted))
                else
                    message:reply("Invalid number.")
                end
            end
        end
    end
end)

client:on("ready", function()
    local file = io.open("settings.json", "r+")
    data = json.decode(file:read())
    io.close(file)
    appealchannel = client:getChannel(data.appealchannel)
    pause = data.pause
    approvalcount = data.approvalcount
    approvalratio = data.approvalratio
    appealweb = data.appealweb
    logweb = data.logweb
    initializenew()
    runcron()
end)

-- delete this before pushing to github xd 
client:run("Bot "..io.read())