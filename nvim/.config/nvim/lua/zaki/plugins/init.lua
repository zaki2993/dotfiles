-- Combine all plugin specifications
local plugins = {}

-- Import and merge all plugin specs
for _, spec in ipairs(require("zaki.plugins.colorscheme")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.telescope")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.treesitter")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.lualine")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.cmp")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.autopairs")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.comments")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.gitsigns")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.nvimtree")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.trouble")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.harpoon")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.which_key")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.mason")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.mason-lsp-config")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.lsp-servers")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.none-ls")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.lsp")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.jdtls")) do
  table.insert(plugins, spec)
end

for _, spec in ipairs(require("zaki.plugins.blade")) do
  table.insert(plugins, spec)
end

return plugins
