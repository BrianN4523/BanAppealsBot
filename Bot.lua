local discordia = require('discordia')
local json = require('json')
local cron = require('cron.cron')
local http = require('coro-http')
local login = io.open("login.txt", "r+")
local data
local client = discordia.Client()
local date = discordia.Date()
local pause, appealchannel, logchannel, approvalcount, approvalratio, appealweb, logweb
local botuserid = "855084568407048192"
local uptime = os.time()
local appealtable = {}
local awaiting = {}
local cronstorage = {}
local templog = {}

function getusername(userid)
    local result, body = http.request("GET", "https://users.roblox.com/v1/users/"..userid)
    return json.decode(body)
end

if login:read() == nil then
    print("Please enter a login token")
    login:write(io.read())
    login:close()
end

function getidfromappeal(message)
    return message.embed.fields[1].value:match("[%S^%c]+$")
end

function overwritedata(new)
    local temp = io.open("settings.json", "r+")
    temp:write(json.encode(new))
    temp:close()
    appealchannel = client:getChannel(data.appealchannel)
    logchannel = client:getChannel(data.logchannel)
    pause = data.pause
    approvalcount = data.approvalcount
    approvalratio = data.approvalratio
    appealweb = data.appealweb
    logweb = data.logweb
    autodelete = data.autodelete
end

-- any method that takes discord ids are strings

function awaitembed(userid, count, ratio)
    local message = appealtable[userid]
    local embed = message.embed
    local player = getusername(userid).name
    awaiting[userid] = {message, message:reply{
        embed = {
            title = "Ban Appeal Approved!", 
            description = string.format("[%s](https://discord.com/channels/%s/%s/%s) has been unbanned with a like count of %s and a like ratio of %d%%.", player, message.guild.id, message.channel.id, message.id, count, ratio),
            color = discordia.Color.fromRGB(255,150,50).value,
            footer = {
                text = "This message and the message linked above will be deleted once the user is unbanned."
            }
        }
    }}
    for _,v in templog:__pairs() do
        if v.embed then
            if v.embed.color == 16751710 then
                local euserid = v.embed.fields[1].value:match("%b()"):match("%d+")
                if euserid == userid then
                    if date.parseISO(v.timestamp) > date.parseISO(message.timestamp) then
                        if awaiting[euserid] then
                            awaiting[euserid][1]:delete()
                            awaiting[euserid][2]:delete()
                            awaiting[euserid] = nil
                            appealtable[userid] = nil
                        end
                    end
                end
            end
        end
    end
end

function fetchstats(userid)
    local liked, disliked
    local message = appealtable[userid]
    if message ~= nil then
        for _,v in message.reactions:__pairs() do
            if v.emojiHash == "👍" then
                liked = v.count - 1
            elseif v.emojiHash == "👎" then
                disliked = v.count - 1
            end
        end
        if liked ~= nil and disliked ~= nil then
            local ratio = math.floor(liked/(liked + disliked)*100+.5)
            if ratio ~= ratio then
                ratio = 0
            end
            return liked, disliked, ratio
        end
    end
end

function periodiccheck(userid)
    local message = appealtable[userid]
    if message ~= nil and awaiting[userid] == nil then
        local liked, disliked, ratio = fetchstats(userid)
        if liked ~= nil and disliked ~= nil then
            if liked >= approvalcount and ratio > approvalratio then
                awaitembed(userid, liked, ratio)
            else
                appealtable[userid] = nil
                message:delete()
            end
        end
    end
end

function register(message)
    local userid = getidfromappeal(message)
    appealtable[userid] = message
    message:addReaction("👍")
    message:addReaction("👎")
    --[[ Check if there's an unban log already
    for _,v in templog:__pairs() do
        if v.embed then
            if v.embed.color == 16751710 then
                local euserid = v.embed.fields[1].value:match("%b()"):match("%d+")
                if euserid == userid then
                    message:delete()
                    return
                end
            end
        end
    end]]--
    -- Check reaction count
    checkreactions(message)
    table.insert(cronstorage, cron.after(date.parseISO(message.timestamp) + pause, periodiccheck, userid))
end

function checkreactions(message)
    local userid = getidfromappeal(message)
    local liked, disliked, ratio = fetchstats(userid)
    if disliked ~= nil and disliked >= autodelete then
        message:delete()
        appealtable[userid] = nil
        awaiting[userid] = nil
        return
    elseif liked ~= nil and liked >= approvalcount and ratio > approvalratio and awaiting[userid] == nil then
        awaitembed(userid, liked, ratio)
    end
end

function runcron()
    for i,v in pairs(cronstorage) do
        if v:update(os.time()) then
            cronstorage[i] = nil
        else
            v:reset()
        end
    end
end

function initializenew()
    templog = logchannel:getMessages(100)
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

--[[client:on("reactionAddUncached", function(channel, messageId, hash, userId)
    if userId ~= botuserid and userId == appealweb then
        local message = appealchannel:getMessage(messageId)
        local userid = message.author.username:match("%b[]"):match("%d+")
        appealtable[userid] = message
        CheckDislike(message)
    end
end)]]--

client:on("reactionAdd", function(reaction, userId)
    if userId ~= botuserid and reaction.message.author.id == appealweb then
        local userid = getidfromappeal(reaction.message)
        appealtable[userid] = reaction.message
        checkreactions(reaction.message)
    end
end)


client:on("messageCreate", function(message)
    local success, result = pcall(function()
        runcron()
    end)
    if not success then print(result) end
    if message.webhookId == appealweb then
        register(message)
    elseif message.webhookId == logweb then
        if message.embed.color == 16751710 then
            local userid = message.embed.fields[1].value:match("%b()"):match("%d+")
            if appealtable[userid] then
                if awaiting[userid] then
                    awaiting[userid][1]:delete()
                    awaiting[userid][2]:delete()
                    awaiting[userid] = nil
                end
                appealtable[userid] = nil
            end
        end
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
            elseif cmd:lower() == "linit" then
                local extracted = message.content:match("[^%s]+$")
                if client:getChannel(extracted) then
                    overwritedata(data)
                    data.logchannel = extracted
                    message:reply(string.format("Successfully changed logs channel to <#%s>.", extracted))
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
            elseif cmd:lower() == "setautodelete" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.autodelete = tonumber(extracted)
                    overwritedata(data)
                    message:reply(string.format("Set auto-deletion count to %s votes.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "setappealweb" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.appealweb = extracted
                    overwritedata(data)
                    message:reply(string.format("Appeals webhook set to %s.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "setlogweb" then
                local extracted = message.content:match("[^%s]+$")
                if tonumber(extracted) ~= nil then
                    data.logweb = extracted
                    overwritedata(data)
                    message:reply(string.format("Logs webhook set to %s.", extracted))
                else
                    message:reply("Invalid number.")
                end
            elseif cmd:lower() == "uptime" then
                message:reply(string.format("This bot has been up for %d seconds.", os.time() - uptime))
            end
        end
    end
end)

client:on("ready", function()
    local file = io.open("settings.json", "r+")
    data = json.decode(file:read())
    io.close(file)
    appealchannel = client:getChannel(data.appealchannel)
    logchannel = client:getChannel(data.logchannel)
    pause = data.pause
    approvalcount = data.approvalcount
    approvalratio = data.approvalratio
    appealweb = data.appealweb
    logweb = data.logweb
    autodelete = data.autodelete
    initializenew()
    runcron()
end)

client:run("Bot "..io.open("login.txt", "r"):read())