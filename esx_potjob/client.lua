local onDelivery = false
local closeToShop = false

local closeLocations = {}
local deliveredLocations = {}
local shouldDrawQuitMarker = false
local deliverVan = nil

function DrawMissionMarker(pos, scale, r, g, b)
    DrawMarker(1, pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, r, g, b, 100, false, false, 0, false, nil, nil, false)
end

function AddBlip(pos, name, sprite, shortRange)
    local blip = AddBlipForCoord(pos) 
    if sprite then 
        SetBlipSprite(blip, sprite) 
    end
    SetBlipAsShortRange(blip, shortRange)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)

    return blip
end

function SetupDeliveryLocations()
    for i, location in pairs(options.deliveryLocations) do
        local blip = AddBlip(location.position, "Delivery location " .. i)
        options.deliveryLocations[i].blip = blip
    end
end

function AlreadyDelivered(index)
    for _, location in pairs(deliveredLocations) do
        if index == location then
            return true
        end
    end

    return false
end

function GetCloseLocations()
    local locations = {}

    for k, location in pairs(options.deliveryLocations) do
        -- only draw close markers
        if #(location.position - GetEntityCoords(PlayerPedId())) < 100.0 and not AlreadyDelivered(k) then
            table.insert(locations, k)
        end
    end

    return locations
end

function ShowSubtitle(text, time)
    BeginTextCommandPrint(text)    
    EndTextCommandPrint(time, 1);
end

function CleanUp()
    onDelivery = false
    shouldDrawQuitMarker = false
    
    deliveredLocations = {}
    for _, v in pairs(options.deliveryLocations) do
        if DoesBlipExist(v.blip) then 
            RemoveBlip(v.blip)
        end
    end

    DeleteVehicle(deliverVan)
end

CreateThread(function()
    AddTextEntry("potshop_start_text", "Press ~INPUT_CONTEXT~ to start the ~g~pot delivery~s~.")
    AddTextEntry("potshop_start_subtitle", "Deliver the pot to the ~y~locations~s~, return to the potshop after.")
    AddTextEntry("potshop_deliver_text", "Press ~INPUT_CONTEXT~ to deliver this guy's ~g~pot~s~.")
    AddTextEntry("potshop_delivered_subtitle", "Thanks for the delivery, go back to the potshop or deliver some more.")
    AddTextEntry("potshop_stop_text", "Press ~INPUT_CONTEXT~ to end the delivery")

    -- https://docs.fivem.net/game-references/blips/
    AddBlip(options.shop, "Potshop Delivery", 140, true)

    -- request vehicle model
    RequestModel(options.car.model)
    while not HasModelLoaded(options.car.model) do
        Wait(0)
    end

    while true do
        Wait(0)

        if not onDelivery and closeToShop then
            DrawMissionMarker(options.shop, vec3(1.3, 1.3, 1.0), 0, 179, 60)

            -- show message if close
            if #(options.shop - GetEntityCoords(PlayerPedId())) < 1.5 then
                DisplayHelpTextThisFrame("potshop_start_text")

                -- start delivery if key is pressed
                -- https://docs.fivem.net/game-references/controls/#controls
                if IsControlJustPressed(0, 51) then
                    onDelivery = true

                    SetupDeliveryLocations()

                    deliverVan = CreateVehicle(options.car.model, options.car.spawn, options.car.heading, true, false)
                    SetEntityAsMissionEntity(deliverVan)
                    SetPedIntoVehicle(PlayerPedId(), deliverVan, -1)

                    ShowSubtitle("potshop_start_subtitle", 4000)

                    -- tell server we are starting our job
                    TriggerServerEvent("esx_potjob:start")
                end
            end
        end
    end
end)

-- slower thread to not flood natives
CreateThread(function()
    while true do
        Wait(1000)

        if onDelivery then
            closeLocations = GetCloseLocations()

            shouldDrawQuitMarker = (#deliveredLocations >= 1 and #(options.car.spawn - GetEntityCoords(PlayerPedId())) < 100.0)
        end

        if not onDelivery then 
            closeToShop = (#(options.shop - GetEntityCoords(PlayerPedId())) < 100.0)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if onDelivery then
            for _, i in pairs(closeLocations) do
                local location = options.deliveryLocations[i]

                DrawMissionMarker(location.position, vec3(1.3, 1.3, 1.0), 0, 179, 60)

                if #(location.position - GetEntityCoords(PlayerPedId())) < 1.5 then
                    DisplayHelpTextThisFrame("potshop_deliver_text")

                    if IsControlJustPressed(0, 51) then
                        ShowSubtitle("potshop_delivered_subtitle", 3000)

                        -- mark as done and reparse location list
                        table.insert(deliveredLocations, i)
                        closeLocations = GetCloseLocations()

                        RemoveBlip(location.blip)

                        -- tell server we delivered something
                        TriggerServerEvent("esx_potjob:delivered", i)
                    end
                end
            end

            if shouldDrawQuitMarker then
                DrawMissionMarker(options.car.spawn, vec3(3.0, 3.0, 1.0), 0, 179, 60)

                if #(options.car.spawn - GetEntityCoords(PlayerPedId())) < 3.0 then
                    DisplayHelpTextThisFrame("potshop_stop_text")

                    if IsControlJustPressed(0, 51) then
                        CleanUp()

                        -- tell server we are done and to give our money
                        TriggerServerEvent("esx_potjob:finished")
                    end
                end
            end
        end
    end
end)