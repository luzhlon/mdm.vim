
if !exists('g:mdm#tab#enable')
    let g:mdm#tab#enable = 1
endif

com! -nargs=+ MdmTable call mdplus#gen(<args>)
com! MdmTableEnable let g:mdm#tab#enable = 1
com! MdmTableDisable let g:mdm#tab#enable = 0
