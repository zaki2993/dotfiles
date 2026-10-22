-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
vim.diagnostic.config({
  virtual_text = false,
  float = false,      
  signs = true,
  underline = true,
  update_in_insert = false,
})

-- core
require("zaki.set")
require("zaki.remap")

-- plugins
require("lazy").setup("zaki.plugins")
-- Remove borders from all floating windows (LSP hover, signature help, ...)
vim.o.winborder = "none"


