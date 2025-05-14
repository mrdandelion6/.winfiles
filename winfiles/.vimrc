set clipboard=unnamed,unnamedplus
set backspace=indent,eol,start
syntax on
nnoremap c "_c
nnoremap C "_C
nnoremap x "_x
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" remove trailing whitespace automatically when saving
autocmd BufWritePre * %s/\s\+$//e

" show trailing spaces
set list
set listchars=trail:·
highlight SpecialKey ctermfg=238 guifg=#444444
