local awful = require("awful")
local filesystem = require("gears.filesystem")

local cache_path = filesystem.get_cache_dir() .. "wttr"

local currentPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local weather_daemon = currentPath .. "awesome-wttr.sh " .. cache_path

local pid = awful.spawn(weather_daemon, false)

awesome.connect_signal("exit",
    function()
        awful.spawn.with_shell(string.format("kill %s", pid), false)
    end
)
