return {
  "stevearc/oil.nvim",
  dependencies = {
    { "nvim-mini/mini.icons", lazy = false },
    { "nvim-tree/nvim-web-devicons" },
  },
  config = function()
    local oil = require("oil")
    oil.setup()
    vim.keymap.set("n", "fo", oil.toggle_float, {})
  end,
  lazy = false,
}
