RegisterNetEvent("esx_potjob:start")
RegisterNetEvent("esx_potjob:delivered")
RegisterNetEvent("esx_potjob:finished")

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local sessions = {}

function IsClientTooFast(source)
    -- calculate if client isn't doing stuff too fast for a time which can't be legit
    local tooFast = (sessions[source].last + (options.cooldown * 1000) > GetGameTimer())

    if tooFast then
        print(string.format("%s %s delivered too fast, is they hacking or did you configure cooldown wrong?", 
            GetPlayerName(source), GetPlayerIdentifier(source, 0)))
    end

    return tooFast
end

function IsLegitLocation(source, location)
    -- checks if location hasn't already been delivered and exists
    return (not IsLocationAlreadyDelivered(source, location) and options.deliveryLocations[location] ~= nil)
end

function IsLocationAlreadyDelivered(source, location)
    for _, loc in pairs(sessions[source].visited) do
        if loc == location then
            return true
        end
    end

    return false
end

AddEventHandler("esx_potjob:start", function()
    sessions[source] = {
        visited = {},
        -- save when this was triggered to check if times are legit
        last = GetGameTimer()
    }
end)

-- we are not accepting an amount of money but the location id which server can then lookup later
AddEventHandler("esx_potjob:delivered", function(id)
    -- only continue if player has already started job
    if sessions[source] and IsLegitLocation(source, id) and not IsClientTooFast(source) then
        local clean = true
        local distance

        -- do checks if onesync
        if options.onesync_checks then
            distance = #(GetEntityCoords(GetPlayerPed(source)) - options.deliveryLocations[id].position)

            -- checking from a distance of 15 because it might not be 100% correct
            if distance > 15 then
                clean = false
            end
        end

        if clean then
            table.insert(sessions[source].visited, id)
            sessions[source].last = GetGameTimer()
        else
            print(string.format("%s %s delivered from a too big distance (%s), is they hacking?", GetPlayerName(source), GetPlayerIdentifier(source, 0), math.floor(distance)))
        end
    end
end)

AddEventHandler("esx_potjob:finished", function()
    if sessions[source] then
        -- client isn't sending anything only that he's done, we already know what he did so we can calculate the payment
        local xPlayer = ESX.GetPlayerFromId(source)
        local money = 0

        for _, i in pairs(sessions[xPlayer.source].visited) do
            -- the client send us what he did so now we can see what money that location has
            local location = options.deliveryLocations[i]

            money = money + location.pay
        end

        -- give player money
        xPlayer.addMoney(money)

        -- clean up
        sessions[xPlayer.source] = nil
    end
end)

AddEventHandler("playerDropped", function (source, reason)
    if sessions[source] then
        sessions[source] = nil
    end
end)