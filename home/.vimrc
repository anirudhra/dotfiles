set nocompatible
"source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim
"syntax enable
set number
set tabstop=4
set expandtab
set softtabstop=4
set showcmd
set cursorline
filetype indent on
set wildmenu
set lazyredraw
set showmatch
set incsearch
set hlsearch
"set foldenable
" Detect constrained embedded / router platforms
let s:is_embedded = ($MACHINE_TYPE ==# 'embedded' || $MACHINE_TYPE ==# 'router' ||
      \ filereadable('/etc/openwrt_release') || filereadable('/etc/openwrt_version') ||
      \ filereadable('/etc/defaults.bin') || filereadable('/etc/asus_build_info') ||
      \ filereadable('/etc/buildroot-version'))

" Truecolor (24-bit): only on desktops/servers with capable terminals; safe ANSI 16-color on embedded
if !s:is_embedded && has('termguicolors')
  set termguicolors
endif

"pathogen plugin manager
"execute pathogen#infect()
filetype plugin indent on
"syntax on

" Backup and swap directories: use /tmp on embedded to avoid flash wear
if s:is_embedded
  set backupdir=/tmp
  set directory=/tmp
else
  if !isdirectory(expand('~/.vim-tmp'))
    silent! call mkdir(expand('~/.vim-tmp'), 'p')
  endif
  set backup
  set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
  set backupskip=/tmp/*,/private/tmp/*
  set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
  set writebackup
endif

" Persistent undo: enabled on desktop/server, disabled on embedded to save storage
if !s:is_embedded && has('persistent_undo')
  if !isdirectory(expand('~/.vim/undo'))
    silent! call mkdir(expand('~/.vim/undo'), 'p')
  endif
  set undodir=~/.vim/undo
  set undofile
endif

"set guifont=Menlo\ Regular:h15
"set guifont=Monospace\ Regular:h12
"colorscheme lucario
if !s:is_embedded
  silent! colorscheme catppuccin_macchiato
endif
set guioptions-=T

"set diffexpr=MyDiff()
"function MyDiff()
"  let opt = '-a --binary '
"  if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
"  if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
"  let arg1 = v:fname_in
"  if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
"  let arg2 = v:fname_new
"  if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
"  let arg3 = v:fname_out
"  if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
"  if $VIMRUNTIME =~ ' '
"    if &sh =~ '\<cmd'
"      if empty(&shellxquote)
"        let l:shxq_sav = ''
"        set shellxquote&
"      endif
"      let cmd = '"' . $VIMRUNTIME . '\diff"'
"    else
"      let cmd = substitute($VIMRUNTIME, ' ', '" ', '') . '\diff"'
"    endif
"  else
"    let cmd = $VIMRUNTIME . '\diff'
"  endif
"  silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3
"  if exists('l:shxq_sav')
"    let &shellxquote=l:shxq_sav
"  endif
"endfunction

