return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        -- require("plugins.treesitter").setup({
        auto_install = true,
        ensure_installed = {
          "c",
          "python",
          "bash",
          "regex",
          --          "ruby",
          "html",
          "css",
          "scss",
          --          "javascript",
          --          "typescript",
          "json",
          "lua",
        },
        highlight = { enable = true },
        indent = { enable = false },
      })
    end,
  },
}
