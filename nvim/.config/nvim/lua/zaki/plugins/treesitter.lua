return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  main = "nvim-treesitter",
  opts = {
    ensure_installed = {
      "go", "python", "java", "php", "lua",
      "html", "css", "javascript", "typescript",
      "json", "yaml", "toml", "sql",
      "bash", "markdown", "markdown_inline",
      "vim", "vimdoc", "query",
    },
    auto_install = true,
    highlight = {
      enable = true,
      disable = function(_, buf)
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > 500 * 1024 then return true end
      end,
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection    = "<C-space>",
        node_incremental  = "<C-space>",
        node_decremental  = "<BS>",
        scope_incremental = false,
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start     = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
      },
      swap = {
        enable = true,
        swap_next     = { ["<leader>sn"] = "@parameter.inner" },
        swap_previous = { ["<leader>sp"] = "@parameter.inner" },
      },
    },
  },
}
