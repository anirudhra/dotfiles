return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,

    -- opts = function(_, opts)
    --   local module = require("catppuccin.groups.integrations.bufferline")
    --   if module then
    --     module.get = module.get_theme
    --   end
    --   return opts
    -- end,

    -- until lazyvim fixes the get() to get_theme() method, temp fix
    {
      "akinsho/bufferline.nvim",
      optional = true,
      opts = function(_, opts)
        if (vim.g.colors_name or ""):find("catppuccin") then
          local ok, mod = pcall(require, "catppuccin.groups.integrations.bufferline")
          if ok then
            local get = mod.get_theme or mod.get
            if type(get) == "function" then
              opts.highlights = get({})
            end
          end
        end
      end,
    },

    config = function()
      require("catppuccin").setup()
      -- setup must be called before loading
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
