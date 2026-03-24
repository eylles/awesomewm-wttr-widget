local awesome = awesome
local awful = require("awful")
local wibox = require("wibox")

local weather = wibox.widget {
  widget = wibox.widget.textbox,
  align = "center",
  valign = "center",
  markup = "wttr.in"
}

local tooltip = awful.tooltip({})

tooltip:add_to_object(weather)
tooltip.text = "wttr.in"

function weather:update_textbox(c)
    self.markup = c
end

function weather:update_tooltip(c)
    tooltip.text = c
end

awesome.connect_signal("wttr::tooltip", function(s)
    weather:update_tooltip(s)
end)

awesome.connect_signal("wttr::textbox", function(s)
    weather:update_textbox(s)
end)

return weather
