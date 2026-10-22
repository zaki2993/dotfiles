-- lua/zaki/remap.lua

-- 1. Leader
vim.g.mapleader = " "

local map = vim.keymap.set
local opts = { noremap = true, silent = true }
-- The "normal! m'" saves your current spot to the jumplist first
vim.keymap.set('n', 'gd', "<cmd>normal! m'<CR><cmd>lua vim.lsp.buf.definition()<CR>")

-- 2. Core keymaps

map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })

-- Escape insert mode and move right
map("i", "<Esc>", "<Esc>l", opts)

-- Scroll
map("n", "<C-j>", "<C-d>", opts)
map("n", "<C-k>", "<C-u>", opts)

-- Start/end of file
map({ "n", "v" }, "gg", "gg0", opts)
map({ "n", "v" }, "G", "G$", opts)


-- 3. LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)

    local bufnr = ev.buf

    local bufopts = {
      buffer = bufnr,
      noremap = true,
      silent = true,
    }

    -- Go to definition
    map("n", "gd", vim.lsp.buf.definition, bufopts)

    -- Find references
    map("n", "gr", vim.lsp.buf.references, bufopts)

    -- Hover information
    map("n", "K", vim.lsp.buf.hover, bufopts)

    -- Rename
    map("n", "<leader>rn", vim.lsp.buf.rename, bufopts)

    -- Code actions
    map("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)

    -- Diagnostics
    map("n", "[d", vim.diagnostic.goto_prev, bufopts)
    map("n", "]d", vim.diagnostic.goto_next, bufopts)

    -- Diagnostic popup
    map("n", "<leader>xs", function()
      vim.diagnostic.open_float(nil, {
        scope = "cursor",
        focusable = true,
      })
    end, bufopts)

  end,
})


-- 4. Detect Java package

local function detect_package()

  for i = 1, math.min(40, vim.api.nvim_buf_line_count(0)) do

    local line =
      vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]

    if not line then
      break
    end

    local pkg =
      line:match("^%s*package%s+([%w%.]+);")

    if pkg then
      return pkg
    end

  end

  return nil
end


-- 5. Run command in terminal

local function run_in_terminal(cmd)

  vim.cmd("botright split | resize 12 | terminal " .. cmd)

  vim.cmd("startinsert")

end


-- 6. Run current file

map("n", "<leader>r", function()

  vim.cmd("w")

  local ft = vim.bo.filetype
  local file = vim.fn.expand("%")
  local name = vim.fn.expand("%:t:r")

  local cmd = ""

  if ft == "python" then

    cmd = "python3 " .. file

  elseif ft == "c" then

    cmd =
      "gcc " .. file ..
      " -o " .. name ..
      " && clear && ./" .. name

  elseif ft == "cpp" then

    cmd =
      "g++ " .. file ..
      " -o " .. name ..
      " && clear && ./" .. name

  elseif ft == "dart" then

    cmd = "dart run " .. file

  elseif ft == "java" then

    local pkg = detect_package()

    local fqcn = name

    local compile =
      string.format("javac -d . %s", file)

    if pkg then
      fqcn = pkg .. "." .. name
    end

    cmd =
      string.format(
        "%s && clear && java -cp . %s",
        compile,
        fqcn
      )

  else

    print(
      "No run command for filetype: " .. ft
    )

    return

  end

  if cmd ~= "" then
    run_in_terminal(cmd)
  end

end, {
  desc = "Run current file (smart)",
})


-- 7. TMUX helpers

map("n", "<leader>fr", function()

  vim.fn.system(
    "tmux send-keys -t :2 r"
  )

  print("Reload sent to Window 2")

end, {
  desc = "Tmux: Reload",
})


map("n", "<leader>fhr", function()

  vim.fn.system(
    "tmux send-keys -t :2 R"
  )

  print("Restart sent to Window 2")

end, {
  desc = "Tmux: Restart",
})


-- 8. Close floating windows with Esc

vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()

    local ok, win_config =
      pcall(vim.api.nvim_win_get_config, 0)

    if not ok or not win_config then
      return
    end

    if win_config.relative
      and win_config.relative ~= "" then

      map(
        "n",
        "<Esc>",
        "<cmd>close<CR>",
        {
          buffer = true,
          silent = true,
        }
      )

    end

  end,
})
