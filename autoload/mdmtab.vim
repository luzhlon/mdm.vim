" =============================================================================
" Filename:    mdmtab.vim
" Author:      luzhlon
" Date:        2017-08-31
" Description: Utility to format table in markdown
" =============================================================================
" Get the markdown table object from current buffer
fun! s:gettab()
    if !exists('b:mdtab')
        let b:mdtab = {
            \'head': 0, 'tail': 0,
            \'scanline': funcref('s:scanline'),
            \'scan': funcref('s:scan'),
            \'scanall': funcref('s:scanall'),
            \'linetext': funcref('s:linetext'),
            \'upline': funcref('s:upline'),
            \'fmtline': funcref('s:fmtline'),
            \'fmtall': funcref('s:fmtall'),
            \'format': funcref('s:format'),
            \'curcol': funcref('s:curcol'),
            \'colcol': funcref('s:colcol'),
            \'jump': funcref('s:jump'),
            \'jump2nc': funcref('s:jump2nc'),
            \'intable': funcref('s:intable'),
            \'growto': funcref('s:growto')
        \}
    endif
    return b:mdtab
endf

fun! mdmtab#jump(k)
    if g:mdm#tab#enable
        let tab = s:gettab()
        call tab.format()
        if a:k == 'l'
            if !tab.jump2nc()
                let nl = line('.')+1
                call tab.growto(nl)
                call tab.jump(nl, 1)
            endif
        elseif a:k == 'h'
            if !tab.jump2nc(-1)
                let nl = line('.')-1
                if tab.intable(nl)
                    call tab.jump(nl, tab.width)
                endif
            endif
        elseif a:k == 'j'
            let nl = line('.')+1
            call tab.growto(nl)
            call tab.jump(nl, tab.curcol())
        elseif a:k == 'k'
            let nl = line('.')-1
            if tab.intable(nl)
                call tab.jump(nl, tab.curcol())
            endif
        endif
    endif
    return ''
endf
" Ensure that the length of l not less _len
fun! s:ensurelen(l, _len)
    let s = a:_len - len(a:l)
    if s > 0
        call extend(a:l, repeat([0],s))
    endif
endf
" Scan a line, return columns of a line
fun! s:scanline(n) dict
    let ll = split(getline(a:n), '\s*|\s*', 1)
    if len(ll) | let ll = ll[1:-2] | endif
    let self.updated = 0
    if len(ll)          " Split success, it's a table line
        if ll[0] =~ '^:\?-\+:\?$' | return ll | endif
        call s:ensurelen(self.colsmax, len(ll))
        call s:ensurelen(self.colsmaxline, len(ll))
        let i = 0
        for item in ll
            " Update column's maximum width info
            let dw = strdisplaywidth(item)
            let maxcol = self.colsmax[i]
            if dw < maxcol && self.colsmaxline[i] == a:n
                " The line of the max col is changed
                for line in self.lines
                    " Find the next max col in this column
                    let ct = line[i]
                    if ct =~ '^:\?-\+:\?$' | continue | endif
                    let ndw = strdisplaywidth(line[i])
                    if ndw > dw | let dw = ndw | endif
                endfo
                let self.colsmax[i] = dw
                let self.updated = 1
            elseif dw > self.colsmax[i]
                let self.colsmax[i] = dw
                let self.colsmaxline[i] = a:n
                let self.updated = 1
            endif
            let i += 1
        endfo
        if self.updated
            let self.width = len(self.colsmax)
        endif
        return ll
    endif
    return []
endf
" Scan line from start with direction
fun! s:scan(start, dir) dict
    let lines = []
    let i = a:start
    let ll = self.scanline(i)
    while !empty(ll)
        call add(lines, ll)
        let i += a:dir
        let ll = self.scanline(i)
    endw
    return lines
endf
" Scan a new table
fun! s:scanall() dict
    let curn = line('.')
    let self.colsmax = []
    let self.colsmaxline = []
    " Scan lines before current
    let lines = reverse(self.scan(curn - 1, -1))
    let self.head = curn - len(lines)
    " Scan lines after current
    let lines += self.scan(curn, 1)
    let self.lines = lines
    let self.width = len(self.colsmax)
    let self.tail = self.head + len(lines) - 1
endf
" Get items of line n(in buffer)
fun! s:linetext(n) dict
    let nl = self.lines[a:n-self.head]
    let line = ['| ']
    let j = 0
    if len(nl) && nl[0] =~ '^:\?-\+:\?$'
        for w in self.colsmax
            call add(line, repeat('-', w))
            call add(line, ' | ')
            let j += 1
        endfo
    else
        " align with widest column
        for item in nl
            let dw = self.colsmax[j] - strdisplaywidth(item)
            if dw > 0
                let item .= repeat(' ', dw)
            endif
            call add(line, item)
            call add(line, ' | ')
            let j += 1
        endfo
    endif
    " fill the rest columns
    while j < self.width
        call add(line, repeat(' ', self.colsmax[j]))
        call add(line, ' | ')
        let j +=1
    endw
    let line[-1] = ' |'
    return join(line, '')
endf
" Format line(in buffer) in the table
fun! s:fmtline(n) dict
    call setline(a:n, self.linetext(a:n))
endf
" Format the table
fun! s:fmtall() dict
    let i = self.head
    while i <= self.tail
        call self.fmtline(i)
        let i += 1
    endw
endf
" Current column that cursor placed
fun! s:curcol() dict
    let str = strpart(getline('.'), 0, col('.'))
    let i = 0 | let j = 0
    while 1
        let j = stridx(str, '|', j)
        if j == -1 | break | endif
        let i += 1 | let j += 1
    endw
    return i
endf
" Get column number of table's column in buffer
fun! s:colcol(c, ...) dict
    let col = a:c
    if !col | return 0 | endif
    let line = getline(a:0 ? a:1 : line('.'))
    let i = 0 | let j = 0
    while i < col
        let j = stridx(line, '|', j)
        if j == -1 | break | endif
        let i += 1 | let j += 1
    endw
    return j + 1
endf
" Update items of line n(in buffer)
fun! s:upline(n) dict
    let self.lines[a:n-self.head] = self.scanline(a:n)
endf
" Get the boundary
fun! s:bound(line)
    let i = a:line
    while getline(i) =~ '^\s*|' | let i -= 1 | endw
    let head = i + 1
    let i = a:line + 1
    while getline(i) =~ '^\s*|' | let i += 1 | endw
    let tail = i - 1
    return [head, tail]
endf
" Format table at line l
fun! s:format(...) dict
    let l = a:0 ? a:1 : line('.')
    try | undojoin | catch | endt
    if self.intable(l)
        let [head, tail] = s:bound(l)
        if head == self.head && tail == self.tail
            call self.upline(l)
            if self.updated | call self.fmtall()
            else | call self.fmtline(l) | endif
            return len(self.lines)
        endif
    endif
    call self.scanall()
    call self.fmtall()
    return len(self.lines)
endf
" Jump to line x (in buffer) column y (in table)
fun! s:jump(x, y) dict
    let coln = self.colcol(a:y)
    if coln > 0
        call cursor(a:x, coln+1)
        return 1
    else
        return 0
    endif
endf
" Jump to next column
fun! s:jump2nc(...) dict
    let c = col('.')
    if c == 1 || c==col('$')-1
        return 0
    endif
    let dir = a:0 ? -1: 1
    let ccol = self.curcol()
    return self.jump(line('.'), ccol+dir)
endf
" Check if a line is placed in a table
fun! s:intable(n) dict
    return a:n >= self.head && a:n <= self.tail
endf
" Grow tail to line n (in buffer)
fun! s:growto(n) dict
    if a:n == self.tail + 1
        let l = copy(self.colsmax)
        let i = 0
        for w in l
            let l[i] = repeat(' ', w)
            let i += 1
        endfo
        call add(self.lines, [])
        call append(self.tail, self.linetext(self.tail + 1))
        let self.tail += 1
    endif
endf
" Generate a table with x lines and y columns
fun! mdmtab#gen(x, y)
    let n = line('.')
    let l = repeat('|   ', a:y) . '|'
    echom l
    let i = 0
    let x = a:x + 1
    while i < x
        call append(n+i, l)
        let i += 1
    endw
    call append(n + 1, repeat('|---', a:y) . '|')
endf

" Toggle tasklist
fun! mdmtab#togtask()
    let l = matchlist(getline('.'), '^\s*[\*-+]\s\+\[\(.\{-}\)\]')
    if empty(l)
        sil! s/^\s*[\*+-]/& [ ]
    elseif l[1] == 'x'
        s/^\s*[\*-+]\s\+\[\zs.\ze\]/ /
    else
        s/^\s*[\*-+]\s\+\[\zs.\ze\]/x/
    endif
endf
