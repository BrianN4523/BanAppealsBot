local discordia = require('Discordia')
local json = require('json')
local client = discordia.Client()
local appealweb = "794419007633096725"
local appealtable = {}

-- any method that takes discord ids are strings

function timer(message)
end

function wait(a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

client:on("messageCreate", function(message)
    if message.webhookId == appealweb then
        message:addReaction("👍")
        message:addReaction("👎")
        register()
    end
end)

client:on("ready", function()
    wait(2)
    print(client:getChannel("759254539139285063"))
end)

client:run("Bot "..io.read())