return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("Comment").setup()

    local map = vim.keymap.set

    -- Current line toggle
    map("n", "<leader>c", "<Plug>(comment_toggle_linewise_current)", {
      desc = "Comment: toggle current line",
      remap = true,
    })

    -- Operator-pending: <leader>cc + motion
    map("n", "<leader>cc", "<Plug>(comment_toggle_linewise)", {
      desc = "Comment: operator then motion",
      remap = true,
    })

    -- Visual mode
    map("x", "<leader>c", "<Plug>(comment_toggle_linewise_visual)", {
      desc = "Comment: toggle selection",
      remap = true,
    })

    -- Block comments
    map("n", "<leader>cb", "<Plug>(comment_toggle_blockwise_current)", {
      desc = "Comment: block current",
      remap = true,
    })

    map("x", "<leader>cb", "<Plug>(comment_toggle_blockwise_visual)", {
      desc = "Comment: block selection",
      remap = true,
    })
  end,
}

