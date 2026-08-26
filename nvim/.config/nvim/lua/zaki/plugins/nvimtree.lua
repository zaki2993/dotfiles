-- ~/.config/nvim/lua/zaki/plugins/nvimtree.lua
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- disable netrw so tree can take control
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("nvim-tree").setup({
      hijack_netrw = true,
      view = {
        width = 30,
        side = "left",
      },

      renderer = {
        group_empty = true,
        highlight_git = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          -- optional: explicit glyphs (fallback to web-devicons if available)
          glyphs = {
            default = "",
            symlink = "",
            git = {
              unstaged = "✗",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "★",
              deleted = "",
              ignored = "◌",
            },
            folder = {
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
            },
          },
        },
      },

      update_focused_file = {
        enable = false,
        update_root = false,
      },

      actions = {
        open_file = {
          -- CRITICAL: close the tree window when a file is opened
          quit_on_open = true,
          -- don't automatically resize the tree window
          resize_window = false,
        },
      },

      -- keep tree behavior conservative (do not change your cwd unexpectedly)
      respect_buf_cwd = false,
    })

    -- toggle mapping
    vim.keymap.set("n", "<leader>pv", "<cmd>NvimTreeToggle<CR>", { desc = "File tree" })

    -- Fallback: if using a version without quit_on_open, auto-close on file open
    -- This is safe to keep even if quit_on_open works.
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local ft = vim.bo.filetype
        if ft ~= "NvimTree" and vim.fn.exists(":NvimTreeClose") == 2 then
          -- if there is an nvim-tree window open, close it
          -- protect against errors with pcall
          pcall(vim.cmd, "silent! NvimTreeClose")
        end
      end,
      nested = true,
    })
  end,
}
