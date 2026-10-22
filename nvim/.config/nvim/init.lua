-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
-- Remove borders from all LSP floating windows
vim.lsp.handlers["textDocument/hover"] =
  vim.lsp.with(vim.lsp.handlers.hover, { border = "none" })

vim.lsp.handlers["textDocument/signatureHelp"] =
  vim.lsp.with(vim.lsp.handlers.signature_help, { border = "none" })


