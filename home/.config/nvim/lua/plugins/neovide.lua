return {
  "neovide/neovide", -- This is just a placeholder for the file loading
  config = function()
    -- Set your preferred font and size here
    -- The :h12 specifies a font size of 12
    vim.o.guifont = "JetBrainsMono Nerd Font:h12"

    -- Enable smooth scrolling (optional, good for Neovide)
    vim.g.neovide_scroll_animation_length = 0.3

    -- Fix for high DPI screens
    vim.g.neovide_scale_factor = 1.0
  end,
}
