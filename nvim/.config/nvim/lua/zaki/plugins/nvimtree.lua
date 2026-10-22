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
        width = 32,
        side = "left",
      },

      renderer = {
        group_empty = true,
        root_folder_label = function(path)
          return "󰝰 " .. vim.fn.fnamemodify(path, ":~")
        end,
        highlight_git = "name",
        highlight_diagnostics = "name",
        highlight_opened_files = "name",
        indent_markers = {
          enable = true,
        },
        icons = {
          git_placement = "right_align",
          modified_placement = "right_align",
          diagnostics_placement = "signcolumn",
          show = {
            file = true,
            folder = true,
            folder_arrow = false,
            git = true,
            modified = true,
            diagnostics = true,
          },
          glyphs = {
            default = "󰈔",
            symlink = "󰌷",
            modified = "●",
            git = {
              unstaged = "󰏫",
              staged = "󰄬",
              unmerged = "󰘬",
              renamed = "󰁕",
              untracked = "󰎔",
              deleted = "󰆴",
              ignored = "◌",
            },
            folder = {
              default = "󰉋",
              open = "󰝰",
              empty = "󰉖",
              empty_open = "󰷏",
              symlink = "󰉒",
              symlink_open = "󰉒",
            },
          },
        },
      },

      diagnostics = {
        enable = true,
        show_on_dirs = true,
        icons = { error = "󰅚", warning = "󰀪", info = "󰋽", hint = "󰌶" },
      },

      modified = {
        enable = true,
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

    -- Transparent tree that blends with the editor; re-applied on theme change
    local function tree_highlights()
      for _, group in ipairs({ "NvimTreeNormal", "NvimTreeNormalNC", "NvimTreeEndOfBuffer", "NvimTreeSignColumn" }) do
        vim.api.nvim_set_hl(0, group, { bg = "none" })
      end
      vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { link = "Comment" })
      vim.api.nvim_set_hl(0, "NvimTreeIndentMarker", { link = "Comment" })
      vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { link = "Title", bold = true })
    end
    tree_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = tree_highlights })

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
