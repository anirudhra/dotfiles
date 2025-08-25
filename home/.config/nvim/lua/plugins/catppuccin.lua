return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,

    specs = {
      {
        "akinsho/bufferline.nvim",
        after = "catppuccin",
        config = function()
          require("bufferline").setup({
            highlights = require("catppuccin.groups.integrations.bufferline").get_theme(),
          })
        end,
      },
    },

    config = function()
      require("catppuccin").setup()
      -- setup must be called before loading
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
