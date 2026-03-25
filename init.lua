local awesome = awesome
local awful = require("awful")
local wibox = require("wibox")
local t_popup = require('awesomewm-wttr-widget.terminal-popup')
local filesystem = require("gears.filesystem")
local mouse = mouse
local beautiful = require('beautiful')

local weather_widget = {}

local function worker (user_args)
    local args = user_args or {}
    local function hover_connect(c, cursor_name)
        local wb = mouse.current_wibox
        old_cursor, old_wibox = wb.cursor, wb
        wb.cursor = cursor_name
    end

    local function hover_disconnect(c)
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end

    local cache_path = filesystem.get_cache_dir() .. "wttr"
    local my_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
    local forecast_viewer = my_path .. "ForecastView"
    local forecast_path = cache_path .. "/fullcast"


    weather_widget = wibox.widget {
        widget = wibox.widget.textbox,
        align = "center",
        valign = "center",
        markup = "wttr.in",
        font = beautiful.font,
    }

    weather_widget:connect_signal("mouse::enter", function(c) hover_connect(c, "hand1") end)
    weather_widget:connect_signal("mouse::leave", function(c) hover_disconnect(c) end)

    local terminal = args.terminal or 'urxvt'
    weather_widget:buttons(
        awful.util.table.join(
            awful.button({}, 1,
                function()
                    t_popup.new(
                        {
                            terminal = terminal,
                            program = forecast_viewer,
                            options = forecast_path,
                            gx = 125,
                            gy = 40,
                            x = 20,
                            y = beautiful.wibar_height
                        }
                    )
                end
            )
        )
    )

    local tooltip = awful.tooltip({})

    tooltip:add_to_object(weather_widget)
    tooltip.text = "wttr.in"

    function weather_widget:update_textbox(c)
        self.markup = c
    end

    function weather_widget:update_tooltip(c)
        tooltip.text = c
    end

    awesome.connect_signal("wttr::tooltip", function(s)
        weather_widget:update_tooltip(s)
    end)

    awesome.connect_signal("wttr::textbox", function(s)
        weather_widget:update_textbox(s)
    end)

    return weather_widget
end

return setmetatable(weather_widget, { __call = function(_, ...) return worker(...) end })
