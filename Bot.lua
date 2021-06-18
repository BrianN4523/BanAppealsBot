local discordia = require('Discordia')
local json = require('json')
local cron = require('cron.cron')
local data
local client = discordia.Client()
local pause = 5
local appealweb = "794419007633096725"
local botuserid = "855084568407048192"
local appealchannel
local appealtable = {}
local cronstorage = {}

function overwritedata(new)
    local temp = io.open("data.json", "r+")
    temp:write(json.encode(new))
    temp:close()
end

-- any method that takes discord ids are strings

function periodiccheck(message)
    local liked, disliked
    for _,v in message.reactions:__pairs() do
        if v.emojiHash == "👍" then
            liked = v
        elseif v.emojiHash == "👎" then
            disliked = v
        end
    end
    message:reply("This appeal has been approved with a "..math.floor(liked.count/(liked.count + disliked.count)*100+5).."% rating!")
end

function register(message)
    appealtable[message.id] = message
    message:addReaction("👍")
    message:addReaction("👎")
    table.insert(cronstorage, cron.after(os.time() + pause, periodiccheck, appealtable[message.id]))
end

function runcron()
    for _,v in pairs(cronstorage) do
        v:update(os.time())
    end
end

client:on("reactionAddUncached", function(channel, messageId, hash, userId)
    print(1)
end)

client:on("reactionAdd", function(reaction, userId)
    if userId ~= botuserid then
        appealtable[reaction.message.id] = reaction.message
    end
end)


client:on("messageCreate", function(message)
    runcron()
    if message.webhookId == appealweb then
        register(message)
    elseif message.content:find('^"') then
        local cmd = message.content:match("^[^%s]+") cmd = cmd:sub(2,cmd:len())
        print(cmd)
    end
end)

client:on("ready", function()
    file = io.open("data.json", "r+")
    data = json.decode(file:read())
    io.close(file)
    appealchannel = client:getChannel(data.appealchannel)
end)

-- delete this before pushing to github xd ODU1MDg0NTY4NDA3MDQ4MTky.YMtVjw.ev7c6kP8Cf3Chp0ycx8R484R6mM
client:run("Bot ODU1MDg0NTY4NDA3MDQ4MTky.YMtVjw.ev7c6kP8Cf3Chp0ycx8R484R6mM")