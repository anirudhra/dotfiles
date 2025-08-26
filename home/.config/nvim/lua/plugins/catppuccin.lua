return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,

    opts = function(_, opts)
      local module = require("catppuccin.groups.integrations.bufferline")
      if module then
        module.get = module.get_theme
      end
      return opts
    end,

    config = function()
      require("catppuccin").setup()
      -- setup must be called before loading
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
