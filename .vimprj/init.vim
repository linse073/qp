"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Project config
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
noremap <silent> <leader>pc :call TagCocos2d()<cr>
noremap <silent> <leader>pt :call TagProject()<cr>
noremap <silent> <leader>pd :call RunDebugProject()<cr>
noremap <silent> <leader>pl :call RunReleaseProject()<cr>
set tags+=.vimprj/cocos2d_tags
set tags+=.vimprj/tags
set wildignore+=*/samples/*,*/template/*,*/templates/*,*/welcome/*

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Project helper function
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TagCocos2d()
    if isdirectory(g:project_root_marker)
        silent execute '!start cmd /c "ctags -R --c++-kinds=+p --fields=-f -f '.g:project_root_marker.'/cocos2d_tags E:\chess\dymj\frameworks"'
        execute 'NeoCompleteTagMakeCache'
    endif
endfunction

function! TagProject()
    if isdirectory(g:project_root_marker)
        silent execute '!start cmd /c "ctags -R --c++-kinds=+p --fields=-f -f '.g:project_root_marker.'/tags E:\chess\dymj\src"'
        execute 'NeoCompleteTagMakeCache'
    endif
endfunction

function! RunDebugProject()
    silent execute '!start cmd /c "E:\chess\dymj\simulator\win32\dymj"'
endfunction

function! RunReleaseProject()
    silent execute '!start cmd /c "E:\chess\dymj\simulator\win32\dymj"'
endfunction
