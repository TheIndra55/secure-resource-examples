# Secure Resoruce Examples

This is a bunch of FiveM example resources, they are not meant to have any fancy animations or be advanced they are meant to be an example how to implement your events more secure

## esx_potjob

This is a simple job, it's just driving to different locations but instead of most jobs keep all calculations of the money at the client we are storing a lot on the server check out this bad example how some resources might do it serverside

```lua
-- bad example
AddEventHandler("esx_potjob:pay", function(money)
    local xPlayer = ESX.GetPlayerFromId(source)

    -- we are literally blindlessly accepting the money input, every attacker could trigger this event with any amount
    xPlayer.addMoney(money)
end)
```

Instead we are sending every of our deliveries and when we start to the server so we can do some time checks and calculating the money itself