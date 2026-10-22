return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  -- main branch does not support lazy-loading
  lazy = false,
  dependencies = {
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
  },
  config = function()
    local parsers = {
      "go", "python", "java", "php", "lua",
      "html", "css", "javascript", "typescript",
      "json", "yaml", "toml", "sql",
      "bash", "markdown", "markdown_inline",
      "vim", "vimdoc", "query",
    }
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local buf = args.buf
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > 500 * 1024 then return end

        -- fails when no parser exists for this filetype
        if pcall(vim.treesitter.start, buf) then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    -- Incremental selection (uses built-in an/in)
    vim.keymap.set("n", "<C-space>", "van", { remap = true, desc = "Select node" })
    vim.keymap.set("x", "<C-space>", "an", { remap = true, desc = "Expand selection" })
    vim.keymap.set("x", "<BS>", "in", { remap = true, desc = "Shrink selection" })

    -- Textobjects
    require("nvim-treesitter-textobjects").setup({
      select = { lookahead = true },
      move = { set_jumps = true },
    })

    local select = require("nvim-treesitter-textobjects.select")
    local objects = {
      af = "@function.outer", ["if"] = "@function.inner",
      ac = "@class.outer", ic = "@class.inner",
      aa = "@parameter.outer", ia = "@parameter.inner",
      ab = "@block.outer", ib = "@block.inner",
    }
    for key, query in pairs(objects) do
      vim.keymap.set({ "x", "o" }, key, function()
        select.select_textobject(query, "textobjects")
      end)
    end

    local move = require("nvim-treesitter-textobjects.move")
    local map = vim.keymap.set
    map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end)
    map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end)
    map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end)
    map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end)

    local swap = require("nvim-treesitter-textobjects.swap")
    map("n", "<leader>sn", function() swap.swap_next("@parameter.inner") end)
    map("n", "<leader>sp", function() swap.swap_previous("@parameter.inner") end)
  end,
}
