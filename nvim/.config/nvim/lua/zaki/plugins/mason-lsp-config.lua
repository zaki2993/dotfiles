return {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = {
        "jdtls",      -- Java (MOST IMPORTANT)
        "pyright",    -- Python
        "clangd",     -- C / C++
        "intelephense", -- PHP
        "gopls",      -- Go
      },
    })
  end,
}

