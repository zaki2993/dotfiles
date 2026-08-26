local theme_file = vim.fn.stdpath("data") .. "/colorscheme.txt"

-- 1. Function to load the saved theme
local function load_theme()
  local f = io.open(theme_file, "r")
  if f then
    local theme = f:read("*l")
    f:close()
    if theme and theme ~= "" then
      pcall(vim.cmd.colorscheme, theme)
      return
    end
  end
  pcall(vim.cmd.colorscheme, "tokyonight")
end

-- 2. Function to save the theme
local function save_theme(theme)
  if not theme or theme == "" then return end 
  local f = io.open(theme_file, "w")
  if f then
    f:write(theme)
    f:close()
  end
end

-- 3. Auto-save, fix Lualine, and FORCE transparency
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    if vim.g.colors_name then
      save_theme(vim.g.colors_name)
    end
    
    -- Force Neovim to be transparent to fix the terminal border gaps
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
    
    local ok, lualine = pcall(require, "lualine")
    if ok then
      lualine.refresh()
    end
  end,
})

-- 4. FIX: Use "LazyDone" instead of "UIEnter" 
-- This applies the theme before icons and buffers are drawn, keeping your Git colors intact.
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    load_theme()
  end,
})

-- 5. Your Lazy.nvim plugin list
return {
  -- 1. TokyoNight (set to the softer 'storm' style)
  { 
    "folke/tokyonight.nvim", 
    lazy = false, 
    priority = 1000, 
    opts = { style = "storm", transparent = true } 
  },

  -- 2. Catppuccin (set to the medium-dark 'macchiato' flavor)
  { 
    "catppuccin/nvim", 
    name = "catppuccin", 
    lazy = false, 
    priority = 1000, 
    opts = { flavour = "macchiato", transparent_background = true } 
  },

  -- 3. Rosé Pine (set to the warm, muted 'moon' variant)
  { 
    "rose-pine/neovim", 
    name = "rose-pine", 
    lazy = false, 
    priority = 1000, 
    opts = { variant = "moon", styles = { transparency = true } } 
  },
}
