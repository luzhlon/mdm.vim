
if !exists('g:mdm#tab#enable')
    let g:mdm#tab#enable = 1
endif

com! MdmSmartList call mdm#SmartList()
com! MdmSmartHeader call mdm#SmartHeader()
com! -nargs=+ MdmTable call mdplus#gen(<args>)
com! MdmTableEnable let g:mdm#tab#enable = 1
com! MdmTableDisable let g:mdm#tab#enable = 0
