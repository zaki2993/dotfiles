return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")

    harpoon:setup()

    local map = vim.keymap.set

    -- Add file
    map("n", "<leader>a", function()
      harpoon:list():add()
    end, { desc = "Harpoon Add File" })

    -- Toggle menu
    map("n", "<C-y>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Harpoon Menu" })

    -- Go to files 1-4
    map("n", "<C-u>", function() harpoon:list():select(1) end)
    map("n", "<C-i>", function() harpoon:list():select(2) end)
    map("n", "<C-o>", function() harpoon:list():select(3) end)
    map("n", "<C-p>", function() harpoon:list():select(4) end)
  end,
}
