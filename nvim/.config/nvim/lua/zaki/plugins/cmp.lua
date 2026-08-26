return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        -- Confirm suggestion
        ["<Tab>"] = cmp.mapping.confirm({ select = true }),

        -- Navigate suggestions
        ["<M-n>"] = cmp.mapping.select_next_item(),
        ["<M-p>"] = cmp.mapping.select_prev_item(),
      }),

      sources = {
        { name = "nvim_lsp" },
      },
    })
  end,
}

