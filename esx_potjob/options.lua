options = {
    shop = vec3(-1172.23, -1572.25, 3.4),

    deliveryLocations = {
        {
            position = vec3(-1058.02, -1540.34, 4.0),
            pay = 50.0
        },
        {
            position = vec3(-1064.41, -1158.9, 1.0),
            pay = 100.0
        },
        {
            position = vec3(-1076.2, -1620.49, 3.2),
            pay = 65.0
        }
    },

    car = {
        spawn = vec3(-1178.68, -1575.91, 3.0),
        heading = 215.80,
        -- make sure you use `` and not "" or '' for hash
        model = `Speedo2`
    },

    -- a legit time in seconds which player shouldn't be able to finish/deliver new location after an action
    -- dont make this too strict like for example when you have houses really close to eachother
    -- if you have a big distance between houses you can really higher this value which prevents attackers calling it every 10 seconds
    cooldown = 10,

    -- If you are **not** running onesync disable this, even though you probably should :p
    -- This allows more serverside checks for example coordinates
    onesync_checks = true
}