local jdtls = require("jdtls")

local root_markers = { "gradlew", "mvnw", ".git" }
local root_dir = require("jdtls.setup").find_root(root_markers)

if root_dir == nil then
  return
end

local workspace = vim.fn.stdpath("data")
  .. "/jdtls-workspace/"
  .. vim.fn.fnamemodify(root_dir, ":p:h:t")

local config = {
  cmd = { "jdtls" },
  root_dir = root_dir,
  settings = {
    java = {
      errors = {
        incompleteClasspath = {
          severity = "warning",
        },
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
    },
  },
  init_options = {
    bundles = {},
  },
}

jdtls.start_or_attach(config)
vim.keymap.set("n", "<leader>oi", function()
  require("jdtls").organize_imports()
end, { buffer = true, desc = "Organize imports" })


