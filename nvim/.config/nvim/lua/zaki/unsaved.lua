-- ~/.config/nvim/lua/zaki/unsaved.lua
local M = {}

function M.modified()
  if vim.bo.modified then
    return "●"
  end
  return ""
end

return M

