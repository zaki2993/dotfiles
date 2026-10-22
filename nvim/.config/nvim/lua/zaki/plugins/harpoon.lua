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
    for i = 1, 4 do
      map("n", "<leader>" .. i, function() harpoon:list():select(i) end, { desc = "Harpoon File " .. i })
    end
  end,
}
