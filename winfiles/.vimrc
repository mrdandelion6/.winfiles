let mapleader = " "
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
highlight SpecialKey ctermfg=7 guifg=#c0c0c0

" ===== COLEMAK LAYOUT SUPPORT =====
let g:current_layout = 'qwerty'
" path to the local settings file
let g:settings_file = expand('~/AppData/Local/nvim/.localsettings.json')

" function to read layout from json settings file
function! ReadLayout()
    if !filereadable(g:settings_file)
        echo "Settings file not found: " . g:settings_file
        return 'qwerty'
    endif

    try
        let content = join(readfile(g:settings_file), '')
        " extract layout value using regex
        let layout_match = matchlist(content, '"layout":\s*"\([^"]*\)"')
        if len(layout_match) > 1
            return layout_match[1]
        else
            return 'qwerty'
        endif
    catch
        echo "Error reading settings file: " . v:exception
        return 'qwerty'
    endtry
endfunction

" function to update only the layout in the json file
function! UpdateLayout(new_layout)
    if !filereadable(g:settings_file)
        echo "Settings file not found: " . g:settings_file
        return
    endif

    try
        let content = join(readfile(g:settings_file), '')
        " replace the layout value while preserving everything else
        let updated_content = substitute(content, '"layout":\s*"[^"]*"', '"layout": "' . a:new_layout . '"', '')

        call writefile([updated_content], g:settings_file)
    catch
        echo "Error updating settings file: " . v:exception
    endtry
endfunction

" function to apply colemak remaps
function! ApplyColemakRemaps()
    " movement keys - colemak: k=left, n=down, e=up, i=right
    nnoremap k h
    nnoremap n j
    nnoremap e k
    nnoremap i l
    nnoremap K H
    nnoremap N J
    nnoremap E K
    nnoremap I L

    " visual mode
    vnoremap k h
    vnoremap n j
    vnoremap e k
    vnoremap i l
    vnoremap K H
    vnoremap N J
    vnoremap E K
    vnoremap I L

    " remap displaced keys (not symmetrical)
    nnoremap h n
    nnoremap j e
    nnoremap l i
    nnoremap H N
    nnoremap J E
    nnoremap L I

    vnoremap h n
    vnoremap j e
    vnoremap l i
    vnoremap H N
    vnoremap J E
    vnoremap L I

    " buffer jumping
    silent! nunmap <C-h>
    silent! nunmap <C-j>
    silent! nunmap <C-k>
    silent! nunmap <C-l>

    nnoremap <C-k> <C-w>h
    nnoremap <C-n> <C-w>j
    nnoremap <C-e> <C-w>k
    nnoremap <C-i> <C-w>l

    let g:current_layout = 'colemak'
endfunction

" function to remove colemak remaps (restore qwerty)
function! RemoveColemakRemaps()
    " remove all the custom mappings
    silent! nunmap k
    silent! nunmap n
    silent! nunmap e
    silent! nunmap i
    silent! nunmap K
    silent! nunmap N
    silent! nunmap E
    silent! nunmap I
    silent! nunmap h
    silent! nunmap j
    silent! nunmap l
    silent! nunmap H
    silent! nunmap J
    silent! nunmap L

    " remove visual mode mappings
    silent! vunmap k
    silent! vunmap n
    silent! vunmap e
    silent! vunmap i
    silent! vunmap K
    silent! vunmap N
    silent! vunmap E
    silent! vunmap I
    silent! vunmap h
    silent! vunmap j
    silent! vunmap l
    silent! vunmap H
    silent! vunmap J
    silent! vunmap L

    " buffer jumping
    silent! nunmap <C-k>
    silent! nunmap <C-n>
    silent! nunmap <C-e>
    silent! nunmap <C-i>

    nnoremap <C-h> <C-w>h
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-l> <C-w>l

    let g:current_layout = 'qwerty'
endfunction

" function to toggle between colemak and qwerty
function! ToggleLayout()
    if g:current_layout == 'qwerty'
        call ApplyColemakRemaps()
        call UpdateLayout('colemak')
        echo "Using Colemak-DH"
    else
        call RemoveColemakRemaps()
        call UpdateLayout('qwerty')
        echo "Using QWERTY"
    endif
endfunction

" initialize layout based on settings file
function! InitializeLayout()
    let layout = ReadLayout()

    if layout == 'colemak'
        call ApplyColemakRemaps()
        echo "Using Colemak-DH"
    else
        nnoremap <C-h> <C-w>h
        nnoremap <C-j> <C-w>j
        nnoremap <C-k> <C-w>k
        nnoremap <C-l> <C-w>l
        let g:current_layout = 'qwerty'
        echo "Using QWERTY"
    endif
endfunction

" key mapping for toggle
nnoremap <Leader>tc :call ToggleLayout()<CR>
" initialize layout when vim starts
autocmd VimEnter * call InitializeLayout()

" ===== TERMINAL SETTINGS =====
" set default shell to powershell
if has('win32') || has('win64')
    set shell=powershell.exe
    set shellcmdflag=-NoProfile\ -ExecutionPolicy\ RemoteSigned\ -Command
    set shellquote=\"
    set shellxquote=
endif
" override :term to open vertical terminal with powershell
command! -nargs=* Term :botright vertical terminal <args>
cnoreabbrev term Term

" allow :q and :qa to quit even with running terminal jobs
set confirm
autocmd TerminalOpen * set bufhidden=hide
" double escape to exit terminal mode to normal mode
tnoremap <Esc><Esc> <C-\><C-n>
