return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,

    config = function()
      require("catppuccin").setup({
        default_integrations = true,
        transparent_background = true,
        fzf = true,
        markdown = true,
        mason = true,
        noice = true,
        cmp = true,
        copilot_vim = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        treesitter_context = true,
        notify = false,
        snacks = {
            enabled = true,
            indent_scope_color = "lavendar", -- catppuccin color (eg. `lavender`) Default: text
        },
        mini = {
            enabled = true,
            indentscope_color = "",
        },
      })
      vim.cmd.colorscheme "catppuccin-mocha"
    end
  }
}
