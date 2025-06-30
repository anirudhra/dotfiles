return {
   {
       "nvim-lualine/lualine.nvim",
       dependencies = { "nvim-tree/nvim-web-devicons" },
       event = "VeryLazy", -- Or "VeryLazy" to load after all other plugins
       config = function()
           require('lualine').setup {
               -- your lualine configuration here
           }
       end
   }
}
