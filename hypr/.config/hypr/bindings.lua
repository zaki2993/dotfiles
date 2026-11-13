local browser = "omarchy-launch-browser"

-- ============================================================
-- 1. Unbind conflicting Omarchy defaults
-- ============================================================

hl.unbind("SUPER + Q")
hl.unbind("SUPER + W")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + P")
hl.unbind("SUPER + L")
hl.unbind("SUPER + G")
hl.unbind("SUPER + T")
hl.unbind("SUPER + CTRL + C")

-- Group navigation keys
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")


-- ============================================================
-- 2. Window Management
-- ============================================================

o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Close window
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())


-- ============================================================
-- 3. Window Groups
-- ============================================================

-- SUPER + SHIFT + T = toggle grouping for active window
o.bind(
    "SUPER + SHIFT + T",
    "Toggle window grouping",
    hl.dsp.group.toggle()
)

-- SUPER + SHIFT + TAB = next window in group
o.bind(
    "SUPER + N",
    "Next window in group",
    hl.dsp.group.next()
)

-- SUPER + TAB = previous window in group
o.bind(
    "SUPER + P",
    "Previous window in group",
    hl.dsp.group.prev()
)


-- ============================================================
-- 4. Custom Apps
-- ============================================================

o.bind(
    "SUPER + C",
    "Change bor",
    "bash ~/.config/hypr/scripts/change_bor.sh"
)

o.bind(
    "SUPER + CTRL + C",
    "Next wallpaper",
    "bash ~/.config/hypr/scripts/live_wallpaper.sh next"
)


-- ============================================================
-- 5. Web Apps & Utilities
-- ============================================================

o.bind(
    "SUPER + M",
    "File manager",
    "uwsm app -- nautilus --new-window"
)

o.bind(
    "SUPER + B",
    "Browser",
    browser
)

o.bind(
    "SUPER + SHIFT + B",
    "Browser (private)",
    browser .. " --private"
)

o.bind(
    "SUPER + G",
    "Gemini",
    "omarchy-launch-webapp 'https://gemini.google.com'"
)

o.bind(
    "SUPER + R",
    "GPT",
    "omarchy-launch-webapp 'https://chatgpt.com'"
)

o.bind(
    "SUPER + A",
    "Claude",
    "omarchy-launch-webapp 'https://claude.ai/new'"
)

o.bind(
    "SUPER + I",
    "GitHub",
    "omarchy-launch-webapp 'https://github.com'"
)

o.bind(
    "SUPER + D",
    "Drive",
    "omarchy-launch-webapp 'https://drive.google.com/'"
)

o.bind(
    "SUPER + E",
    "Email",
    "omarchy-launch-webapp 'https://app.hey.com'"
)

hl.unbind("SUPER + T")
o.bind("SUPER + T", "T3 Code", { launch = "t3code-nightly" })

o.bind(
    "SUPER + Z",
    "perplexity",
    "omarchy-launch-webapp 'https://www.perplexity.ai/'"
)

o.bind(
    "SUPER + Y",
    "YouTube",
    "omarchy-launch-webapp 'https://www.youtube.com/'"
)

o.bind(
    "SUPER + W",
    "WhatsApp",
    "omarchy-launch-or-focus-webapp WhatsApp 'https://web.whatsapp.com/'"
)

-- >>> nudge keybinds >>>
hl.bind("SUPER + ALT + Y", hl.dsp.exec_cmd("/home/zakarch/.local/bin/nudge allow"), { description = "Allow agent permission request" })
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd("/home/zakarch/.local/bin/nudge deny"), { description = "Deny agent permission request" })
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd("/home/zakarch/.local/bin/nudge open"), { description = "Open agent permission request" })
-- <<< nudge keybinds <<<

hl.bind("CTRL + SHIFT + code:11", hl.dsp.global("com.t3tools.T3Code:capture-window"))
