if !exists("g:csearchprg")
	let g:csearchprg="csearch -n"
endif

function! s:CSearch(cmd, args)
    if exists("g:csindex")
        let g:csindex = ""
    endif
    call FindCsearchindex()
    if !exists("g:csindex") || len(g:csindex)<=0
        echo "No index file found."
        return
    endif

    redraw
    echo "Searching ..."

    " If no pattern is provided, search for the word under the cursor
    if empty(a:args)
        let l:grepargs = expand("<cword>")
    else
        let l:grepargs = a:args
    end

    "把参数转为cmd的GBK编码，否则搜索不了中文；另一种方案是把quickfix搜索结果转为GBK编码
    let l:grepargs = iconv(l:grepargs, "utf-8", "cp936")

    let grepprg_bak=&grepprg
    let grepformat_bak=&grepformat
    try
        let &grepprg=g:csearchprg
        let &grepformat="%f:%l:%m"
        " silent execute a:cmd . " " . l:grepargs
        silent execute a:cmd ." -indexpath ".g:csindex ." ". l:grepargs 
    finally
        let &grepprg=grepprg_bak
        let &grepformat=grepformat_bak
    endtry

    " call QfMakeConv()

    if a:cmd =~# '^l'
        botright lopen
    else
        botright copen
    endif

    exec "nnoremap <silent> <buffer> q :ccl<CR>"
    exec "nnoremap <silent> <buffer> t <C-W><CR><C-W>T"
    exec "nnoremap <silent> <buffer> T <C-W><CR><C-W>TgT<C-W><C-W>"
    exec "nnoremap <silent> <buffer> o <CR>"
    exec "nnoremap <silent> <buffer> go <CR><C-W><C-W>"
    exec "nnoremap <silent> <buffer> v <C-W><C-W><C-W>v<C-L><C-W><C-J><CR>"
    exec "nnoremap <silent> <buffer> gv <C-W><C-W><C-W>v<C-L><C-W><C-J><CR><C-W><C-J>"

    " If highlighting is on, highlight the search keyword.
    if exists("g:csearchhighlight")
        let @/=a:args
        set hlsearch
    end

    redraw!
endfunction

function! s:CSearchFromSearch(cmd, args)
    let search =  getreg('/')
    " translate vim regular expression to perl regular expression.
    let search = substitute(search,'\(\\<\|\\>\)','\\b','g')
    call s:CSearch(a:cmd, '"' .  search .'" '. a:args)
endfunction

command! -bang -nargs=* -complete=file CSearch call s:CSearch('grep<bang>',<q-args>)
command! -bang -nargs=* -complete=file CSearchAdd call s:CSearch('grepadd<bang>', <q-args>)
command! -bang -nargs=* -complete=file CSearchFromSearch call s:CSearchFromSearch('grep<bang>', <q-args>)
command! -bang -nargs=* -complete=file LCSearch call s:CSearch('lgrep<bang>', <q-args>)
command! -bang -nargs=* -complete=file LCSearchAdd call s:CSearch('lgrepadd<bang>', <q-args>)

nmap csq :Csearch <C-R>=expand("<cword>")<CR><CR>

function! QfMakeConv()
   let qflist = getqflist()
   for i in qflist
      " let i.text = iconv(i.text, "cp936", "utf-8")
      let i.text = iconv(i.text, "utf-8", "cp936")
   endfor
   call setqflist(qflist)
endfunction

function! FindCsearchindex()
    let dir=expand("%:p:h")
    " if exists("g:csindex") && len(dir)>=len(g:csindex)
        " return
    " endif

    let prefixPath="/.KingConfig"
    let csindexfilename=".csearchindex"
    let dirLen=len(dir)
    while (g:iswindows==1 && dirLen>3) || (g:iswindows!=1 && dirLen>1)
        if isdirectory(dir.prefixPath) && filereadable(dir.prefixPath."/".csindexfilename)
           let g:csindex = dir.prefixPath."/".csindexfilename
           return 
        endif
        let dir=fnamemodify(dir, ':h')
        let dirLen=len(dir)
    endwhile
endfunction
