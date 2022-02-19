--Require modules
local discordia, json, cron, http = require('discordia'), require('json'), require('cron.cron'), require('coro-http')

-- Variables
local login = io.open("login.txt", "w")
local settings
local client = discordia.Client()
local date = discordia.Date()
local suffix = '"'
local botUserId = "944417999715197068"
local reactionCount, reactionRatio, pause, auto, logWeb, appealWeb, logChannel, appealChannel

-- Commands
local commands = {
    {
        "setappealchannel",
        function(id)
            if client:getChannel(id) then
                settings.appealchannel = id
                appealChannel = id
                overwrite()
            end
        end
    }
}

-- Parse message if command
function parseUser(message)
    if message.content:match('^"') then
        for _,command in pairs(commands) do
            if command[1] == message.content:match('"([^%s]+)'):lower() then
                command[2](message.content:match('"[^%s]+ (.+)'))
            end
        end
    end
end

-- Make changes to settings.json
function overwrite()
    local file = io.open("settings.json", "r+")
    file:write(json.encode(settings))
    io.close(file)
end

-- Yield so user can input login token
if login:read() == nil then
    print("Please enter a login token")
    login:write(io.read())
    login:close()
end

-- Get a player's username through id
function getUsername(userid)
    local result, body = http.request("GET", "https://users.roblox.com/v1/users/"..userid)
    return json.decode(body)
end

function awaitembed(userid, count, ratio)

end

function periodiccheck(userid)

end

function register(message)

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

client:on("messageCreate", function(message)
    if message.author.id == "201461802406641664" then
        parseUser(message)
    end
end)

client:on("ready", function()
    local file = io.open("settings.json", "r")
    settings = json.decode(file:read())
    io.close(file)
    reactionCount = settings.approvalcount
    reactionRatio = settings.approvalratio
    pause = settings.pause
    auto = settings.auto
    logWeb = settings.logweb
    appealWeb = settings.appealweb
    logChannel = settings.logchannel
end)

client:run("Bot "..io.open("login.txt", "r"):read())