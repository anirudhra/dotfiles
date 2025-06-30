vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "

vim.opt.swapfile = false

-- Navigate vim panes better
vim.keymap.set('n', '<c-k>', ':wincmd k<CR>')
vim.keymap.set('n', '<c-j>', ':wincmd j<CR>')
vim.keymap.set('n', '<c-h>', ':wincmd h<CR>')
vim.keymap.set('n', '<c-l>', ':wincmd l<CR>')

vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')
vim.wo.number = true

-- new additions
-- vim.g.maplocalleader "\\"
vim.g.snacks_animate = true
vim.g.deprecation_warnings = false
vim.g.autoformat = true
vim.g.lazyvim_picker = "auto"


local opt = vim.opt

opt.ignorecase = true
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"
opt.autowrite = true
opt.confirm = true
opt.cursorline = true
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldlevel = 99
opt.mouse = "a"
opt.linebreak = true
opt.laststatus = 3
opt.relativenumber = false
opt.showmode = false
opt.smartcase = true
opt.smartindent = true
-- opt.spellang = { "en" }
opt.termguicolors = true
opt.undofile = true
opt.undolevels = 1000
opt.wrap = true
opt.smoothscroll = true
-- end new additions
