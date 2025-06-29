return {
  "christoomey/vim-tmux-navigator",
  lazy = false, -- Ensure it's loaded on startup
  -- Optional: Configure keymaps here if you want to override defaults,
  -- or if you have issues with LazyVim's default mappings overriding these.
  -- keys = {
  --   { "<C-h>", "<cmd> TmuxNavigateLeft<CR>" },
  --   { "<C-j>", "<cmd> TmuxNavigateDown<CR>" },
  --   { "<C-k>", "<cmd> TmuxNavigateUp<CR>" },
  --   { "<C-l>", "<cmd> TmuxNavigateRight<CR>" },
  -- },
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
    { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
    { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
    { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
    { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
  },
}
