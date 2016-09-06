set nocompatible "no vi


""""""""""""""""""""""""""""""""""""""""
""""""""""""""""syntax""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""
syntax on
syntax enable
let g:cpp_class_scope_highlight = 1



""""""""""""""""""""""""""""""""""""""""
""""""""""""color scheme""""""""""""""""
""""""""""""""""""""""""""""""""""""""""
let g:solarized_termcolors=256
set background=dark
colorscheme solarized
" colorscheme molokai
let g:Powerline_colorscheme='solarized256'
let g:Powerline_symbols = 'fancy'



""""""""""""""""""""""""""""""""""""""""
"""""""""""""indent"""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""
" autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 textwidth=79 expandtab
set shiftwidth=4 softtabstop=4 tabstop=4 expandtab
" Attempt to determine the type of a file based on its name and possibly its contents. Use this to allow intelligent auto-indenting for each filetype, and for plugins that are filetype specific.
filetype indent plugin on
" let g:indent_guides_enable_on_vim_startup=1 "auto start toggle it by [leader]ig
let g:indent_guides_start_level=3 "start guide after indent lever 3
let g:indent_guides_guide_size=1 "width of the colored guide
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=237
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=236
" When opening a new line and no filetype-specific indenting is enabled, keep the same indent as the line you're currently on. Useful for READMEs, etc.
set autoindent
 


""""""""""""""""""""""""""""""""""""""""
"""""""""""""fold"""""""""""""""""""""
""""""""""""""""""""""""""""""""""""""
" use za to open/close folding, use zM to close all folding, use zR to open all foldings
set foldmethod=indent "enable fold based on indent
set foldmethod=syntax "enable fold based on syntax
set nofoldenable "close foldmode when opening vim



""""""""""""""""""""""""""""""""""""""""
"""""""""""""""display""""""""""""""""""
""""""""""""""""""""""""""""""""""""""""
set wildmenu " Better command-line completion
set cursorline
set cursorcolumn
" set number
" highlight LineNr ctermfg=102  ctermbg=235
set showcmd " Show partial commands in the last line of the screen
set laststatus=2
" set cmdheight=2 " Set the command window height to 2 lines, to avoid many cases of having to 'press <Enter> to continue'
" Highlight searches (use <C-L> to temporarily turn off highlighting; see the " mapping of <C-L> below)
set hlsearch
set nostartofline " Stop certain movements from always going to the first character of a line.
" set mouse=a " Enable use of the mouse for all modes
set backspace=2 
" Use visual bell instead of beeping when doing something wrong
set visualbell


