
fun! mdm#code()
    return mode()==#'V'? "s```\<cr>```\<esc>P" : "s``\<esc>P"
endf

fun! mdm#quote()
    return (mode()==?'v'?"\<c-v>": '') . "0I> \<esc>"
endf

fun! mdm#bold()
    return (mode()=='n'?"viw": '') . "s****\<esc>hP"
endf

fun! mdm#list()
    return (mode()==?'v'?"\<c-v>": '') . "0I* \<esc>"
endf

fun! s:orderlist(n)
    let l = getline(a:n)
    return matchlist(l, '^\(\s*\)[（(]\?\(\d\)\+[）)]\?[\.、]\?\s*\(.*\)$')
endf

fun! mdm#SmartList(...)
    let n = a:0 ? a:1 : line('.')
    let l = getline(n)
    " Try as ordered list
    let ml = s:orderlist(n)
    let i = n
    while !empty(ml)
        call setline(i, join([ml[1], ml[2], '. ', ml[3]], ''))
        let i += 1
        let ml = s:orderlist(i)
    endw
    " If is unordered list
    if i == n
        let dc = indent(i)
        while indent(i) == dc && !empty(getline(i))
            exe i 's/^\(\s*\)[\*·]\?\s*\(.*\)$/\1* \2/'
            let i += 1
        endw
    endif
endf

fun! mdm#SmartHeader()
    let h = '##'
    while 1
        let n = search(@/, 'W')
        if n < 1 | break | endif
        let mid = matchadd('Search', '\%' . n . 'l')
        redraw
        echo 'Markdown header (enter/no/cancel/2/3/..) ?'
        let k = getchar()
        call matchdelete(mid)
        if k == 13 || k >= 50 && k <= 53
            " 2 .. 5
            if k != 13 | let h = repeat('#', k - 48) | endif
            " enter
            call setline(n, h . ' ' . getline(n))
        elseif k == 27 || k == 99
            break       " esc cancel
        endif
        call cursor(n, col('$'))
    endw
endf
