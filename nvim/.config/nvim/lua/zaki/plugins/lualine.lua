return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  config = function()
    require("lualine").setup({
      options = {
        theme = "auto",
        globalstatus = true,
        icons_enabled = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
        disabled_filetypes = { statusline = { "dashboard", "alpha" } },
        always_divide_middle = true,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },

      sections = {
        lualine_a = {
          {
            "mode",
            icon = "󰘳",
          },
        },

        lualine_b = {
          {
            "branch",
            icon = "",
          },
          {
            "diff",
            symbols = {
              added = " ",
              modified = "󰝤 ",
              removed = " ",
            },
          },
        },

        lualine_c = {
          {
            "filename",
            path = 1,
            symbols = {
              modified = "●",
              readonly = "",
              unnamed = "[No Name]",
              newfile = "[New]",
            },
          },
        },

        lualine_x = {
          {
            "diagnostics",
            symbols = {
              error = " ",
              warn  = " ",
              info  = " ",
              hint  = "󰌶 ",
            },
          },
          {
            "filetype",
            icon_only = false,
            colored = true,
            icon = nil,
          },
        },

        lualine_y = {
          {
            "progress",
            icon = "󰄉",
          },
        },

        lualine_z = {
          {
            "location",
            icon = "",
          },
        },
      },

      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filename",
            path = 1,
            symbols = {
              modified = "●",
              readonly = "",
              unnamed = "[No Name]",
              newfile = "[New]",
            },
          },
        },
        lualine_x = {
          "location",
        },
        lualine_y = {},
        lualine_z = {},
      },

      tabline = {
        lualine_a = {
          {
            "tabs",
            mode = 2,
            max_length = vim.o.columns,
            use_mode_colors = true,
            tabs_color = {
              active = "lualine_a_normal",
              inactive = "lualine_b_normal",
            },
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },

      extensions = { "neo-tree", "lazy", "mason", "trouble" },
    })
  end,
}
