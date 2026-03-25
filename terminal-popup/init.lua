-- This file is code extracted from https://github.com/gobolinux/gobo-awesome-sound
-- licensed under the following MIT type license
--
-- Copyright 2016 Hisham Muhammad
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local awful = require('awful')
local gears = require('gears')
local mouse = mouse
local timer = gears.timer

local M = {}

function M.new(args)
    local y = args.y or 24
    local x = mouse.screen.geometry.width - args.x
    local gy = args.gy or 20
    local gx = args.gx or 100
    local terminal = args.terminal
    local program = args.program
    local options = args.options or ""
    local killed = false
        for c in awful.client.iterate(function (c) return c.name == program end, nil, mouse.screen) do
            c:kill()
            killed = true
        end
        if not killed then
            awful.util.spawn(terminal.." -g "..gx.."x"..gy.."+"..x.."+"..y.." -T "..program.." -e "..program.." "..options.."")
            local t
            t = timer.start_new(0.5, function()
                for c in awful.client.iterate(function (c) return c.name == program end, nil, mouse.screen) do
                    c:connect_signal("unfocus", function(cl) cl:kill() end)
                end
                t:stop()
            end)
        end
end

return M
