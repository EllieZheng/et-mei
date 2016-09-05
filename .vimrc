set nocompatible "no vi
"""""""syntax******
syntax on
syntax enable
let g:cpp_class_scope_highlight = 1

"""""color scheme******
let g:solarized_termcolors=256
set background=dark
colorscheme solarized
" colorscheme molokai
let g:Powerline_colorscheme='solarized256'
let g:Powerline_symbols = 'fancy'

" set number
highlight LineNr ctermfg=18

""""""indent******
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 textwidth=79 expandtab
set tabstop=4 shiftwidth=4
" Attempt to determine the type of a file based on its name and possibly its
" contents. Use this to allow intelligent auto-indenting for each filetype,
" and for plugins that are filetype specific.
filetype indent plugin on
let g:indent_guides_enable_on_vim_startup=1 "auto start
let g:indent_guides_start_level=3 "start guide after indent lever 3
let g:indent_guides_guide_size=1 "width of the colored guide
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=grey
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=darkgrey


""""""fold""""""
" use za to open/close folding, use zM to close all folding, use zR to open
" all foldings
set foldmethod=indent "enable fold based on indent
set foldmethod=syntax "enable fold based on syntax
set nofoldenable "close foldmode when opening vim
" Vim with default settings does not allow easy switching between multiple files
" in the same editor window. Users can use multiple split windows or multiple
" tab pages to edit multiple files, but it is still best to enable an option to
" allow easier switching between files.
"
" One such option is the 'hidden' option, which allows you to re-use the same
" window and switch from an unsaved buffer without saving it first. Also allows
" you to keep an undo history for multiple files when re-using the same window
" in this way. Note that using persistent undo also lets you undo in multiple
" files even in the same window, but is less efficient and is actually designed
" for keeping undo history after closing Vim entirely. Vim will complain if you
" try to quit without saving, and swap files will keep you safe if your computer
" crashes.
set hidden
 
" Note that not everyone likes working this way (with the hidden option).
" Alternatives include using tabs or split windows instead of re-using the same
" window as mentioned above, and/or either of the following options:
" set confirm
" set autowriteall
 
" Better command-line completion
set wildmenu
 
" Show partial commands in the last line of the screen
set showcmd
set cursorline
set laststatus=2
" Highlight searches (use <C-L> to temporarily turn off highlighting; see the
" mapping of <C-L> below)
set hlsearch
" When opening a new line and no filetype-specific indenting is enabled, keep
" the same indent as the line you're currently on. Useful for READMEs, etc.
set autoindent
 
" Stop certain movements from always going to the first character of a line.
" While this behaviour deviates from that of Vi, it does what most users
" coming from other editors would expect.
set nostartofline
" Enable use of the mouse for all modes
" set mouse=a
set backspace=2 
" Set the command window height to 2 lines, to avoid many cases of having to
" "press <Enter> to continue"
" set cmdheight=2
" Use visual bell instead of beeping when doing something wrong
set visualbell

