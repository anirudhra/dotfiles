return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,

    config = function()
      require("catppuccin").setup()
      -- setup must be called before loading
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
