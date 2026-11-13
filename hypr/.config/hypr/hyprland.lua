-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })


-- Always open terminals on workspace 1.
o.window("^(foot|org.codeberg.dnkl.foot)$", { workspace = "1" })
o.window("^com.t3tools.T3Code$", { workspace = "2" })
o.window("^chrome-(chatgpt.com|gemini.google.com|claude.ai)__.*", { workspace = "3" })
o.window("^chromium$", { workspace = "4" })
o.window("^org.pwmt.zathura$", { workspace = "5" })
o.window("^chrome-(web.whatsapp.com|x.com)__.*", { workspace = "9" })
o.window("^chrome-www.youtube.com__.*", { workspace = "10" })
