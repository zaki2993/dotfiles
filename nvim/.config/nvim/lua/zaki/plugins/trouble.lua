return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("trouble").setup({
      auto_close = false,
      auto_open = false,
      use_diagnostic_signs = true,
    })

    -- Open diagnostics (project)
    vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (project)" })

    -- Open diagnostics (current file)
    vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Diagnostics (file)" })

    -- LSP references / definitions
    vim.keymap.set("n", "<leader>xr", "<cmd>Trouble lsp toggle<CR>", { desc = "LSP references" })

    -- Close Trouble with Esc
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "trouble",
      callback = function()
        vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = true, silent = true })
      end,
    })
  end,
}

