local browser = "omarchy-launch-browser"

-- 1. Unbind conflicting Omarchy defaults first
hl.unbind("SUPER + Q")
hl.unbind("SUPER + W")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + P")
hl.unbind("SUPER + G")

-- 2. Window Management
o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Window groups
-- SUPER + SHIFT + T = toggle grouping for the active window
o.bind("SUPER + SHIFT + T", "Toggle window grouping", hl.dsp.group.toggle())

-- Cycle through windows in the current group
o.bind("SUPER + TAB", "Next window in group", hl.dsp.group.next())
o.bind("ALT + TAB", "Previous window in group", hl.dsp.group.prev())

o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- 3. Custom Apps
o.bind("SUPER + C", "Change bor", "bash ~/.config/hypr/scripts/change_bor.sh")

-- 4. Web apps & utilities
o.bind("SUPER + M", "File manager", "uwsm app -- nautilus --new-window")
o.bind("SUPER + B", "Browser", browser)
o.bind("SUPER + SHIFT + B", "Browser (private)", browser .. " --private")
o.bind("SUPER + N", "Notion", "omarchy-launch-webapp 'https://www.notion.so/'")
o.bind("SUPER + G", "Gemini", "omarchy-launch-webapp 'https://gemini.google.com'")
o.bind("SUPER + A", "Claude", "omarchy-launch-webapp 'https://claude.ai/new'")
o.bind("SUPER + I", "GitHub", "omarchy-launch-webapp 'https://github.com'")
o.bind("SUPER + D", "Drive", "omarchy-launch-webapp 'https://drive.google.com/'")
o.bind("SUPER + E", "Email", "omarchy-launch-webapp 'https://app.hey.com'")
o.bind("SUPER + Y", "YouTube", "omarchy-launch-webapp 'https://www.youtube.com/'")
o.bind("SUPER + W", "WhatsApp", "omarchy-launch-or-focus-webapp WhatsApp 'https://web.whatsapp.com/'")
o.bind("SUPER + X", "X", "omarchy-launch-webapp 'https://x.com/'")
