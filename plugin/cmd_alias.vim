" Author: Marcin Szamotulski
" Email: mszamot [AT] gmail [DOT] com
" Copyright: © Marcin Szamotulski, 2012-2014
" License: vim-license, see :help license

if !exists("s:aliases")
    let s:aliases = {}
    " entries are dictionaries:
    " { 
    " 'alias': alias, 
    " 'cmd': cmd,
    " 'history': 1/0, 
    " 'buflocal': ['list of buffer numbers, include 0 for global'], 
    " 'default_range': range,
    " 'match_end': 1/0 
    " }
endif
if !exists("s:idx")
    " Used to sort aliases, the latest are tried first.
    let s:idx = 0
endif

let s:AliasToggle = 1

let s:system = !empty(globpath(&rtp, 'plugin/system.vim'))
fun! ReWriteCmdLine(dispatcher) " {{{
    " a:dispatcher: is crdispatcher#CRDispatcher dict
    if a:dispatcher.cmdtype !=# ':' || !s:AliasToggle
	let a:dispatcher.state = 2
	return
    endif
    let a:dispatcher.state = 1
    let cmd = a:dispatcher.cmd
    let cmdline = cmd.cmd
    let range = cmd.range
    let test=0
    for alias in sort(values(s:aliases), "<SID>CompareLA")
	let match = matchstr(cmdline, '\C^[[:space:]:]*'.alias['alias'].(alias['match_end'] ? '\ze\%($\|[^[:alpha:]]\)' : ''))
	if match != '' && 
		    \ (index(alias['buflocal'], 0) != -1 || index(alias['buflocal'],  bufnr('%')) != -1)
	    let test=1
	    break
	endif
    endfor
    if test
	let cmd_ = alias['cmd'].cmdline[len(match):]
	" Default: if empty(range) use alias range otherwise use range:
	if empty(range)
	    let range = alias['default_range']
	endif
	if alias['cmd'][0] != '!' && get(alias, 'history', 0)
	    call histadd(":", getcmdline())
	    let cmd_ .= "|call histdel(':', -1)"
	endif
	let cmd.cmd = cmd_
    endif
    if cmd.Join() !~ 'cmd_alias_debug' && exists("g:cmd_alias_debug")
	call add(g:cmd_alias_debug, { 'cmdline' : cmd.Join(), 'alias' : alias, 'cmd' : cmd})
    endif
endfunc "}}}
try
    call add(crdispatcher#CRDispatcher['callbacks'], function('ReWriteCmdLine'))
catch /E121:/
    echohl ErrorMsg
    echom 'CommandAlias Plugin: please install "https://github.com/coot/CRDispatcher".'
    echohl Normal
    finish
endtry

fun! <SID>Compare(i1,i2) "{{{
   return (a:i1['alias'] == a:i2['alias'] ? 0 : a:i1['alias'] > a:i2['alias'] ? 1 : -1)
endfunc "}}}
fun! <SID>CompareLA(i1,i2) "{{{
   if (index(a:i1['buflocal'], 0) == -1) == (index(a:i2['buflocal'], 0) == -1)
       return (a:i1['idx'] == a:i2['idx'] ? 0 : a:i1['idx'] > a:i2['idx'] ? -1 : 1)
   else
       if index(a:i1['buflocal'], 0) == -1
	   return -1
       else
	   return 1
       endif
   endif
endfunc "}}}
fun! Cmd_Alias(alias, cmd, ...) " {{{
    " This is the same as the cmdalias plugin
    " https://github.com/vim-scripts/cmdalias.vim
    "
    " The reason for this function is that for users with aliases within the
    " cmdlias.vim plugin it is just to copy-paste the old config and add one
    " underscore.
    let [default_range, cmd, error] = vimlparsers#ParseRange(a:cmd)
    let hist = (a:0 >= 1 ? a:1 : 0)
    let buflocal = (a:0 >= 2 && a:2 ? bufnr("%") : 0 )
    let match_end = (a:0 >= 3 ? a:3 : 1)
    if !has_key(s:aliases, a:alias)
	let s:aliases[a:alias] = { 
	    \ 'alias': a:alias,
	    \ 'cmd': cmd,
	    \ 'history': hist,
	    \ 'buflocal':[buflocal],
	    \ 'default_range': default_range,
	    \ 'match_end': match_end, 
	    \ 'idx': s:idx,
	    \ }
	let s:idx += 1
    else
	let s:aliases[a:alias]['cmd']=cmd
	let s:aliases[a:alias]['history']=hist
	if index(s:aliases[a:alias]['buflocal'], buflocal) == -1
	    call add(s:aliases[a:alias]['buflocal'], buflocal)
	endif
	let s:aliases[a:alias]['default_range']=default_range
	let s:aliases[a:alias]['match_end']=match_end
    endif
endfun " }}}
fun! <SID>RegAlias(bang,...) " {{{
    if a:0 == 0 || a:0 == 1 && a:bang == ""
	let alias_arg = ( a:0 ? a:1 : '')
	let lmax = max(map(values(s:aliases), "len(v:val['alias'])"))
	let rmax = max(map(values(s:aliases), "len(v:val['cmd'])+len(v:val['default_range'])"))
	echohl Title
	echo " alias".repeat(" ", lmax)."cmd".repeat(" ", 5+rmax-3)."history"
	echohl Normal
	let compare = ( a:bang == "" ? "<SID>Compare" : "<SID>CompareLA")
	for alias in sort(values(s:aliases), compare)
	    if index(alias['buflocal'], 0) != -1 || index(alias['buflocal'], bufnr('%')) != -1
		if empty(alias_arg) || alias_arg =~ alias['alias'] || 
			    \ substitute(alias['alias'], '\\%\?[\|\]\|\\%\?(\|\\)', '', 'g') =~ '^'.alias_arg
		    echo (index(alias['buflocal'], 0) == -1 ? '@' : ' ').
			\ alias['alias'].repeat(" ", (5+lmax-len(alias['alias']))).
			\ alias['default_range'].alias['cmd'].repeat(" ", (5+rmax-len(alias['default_range'].alias['cmd']))).
			\ (alias['history'] ? 'yes' : '  ' ).repeat(" ", 4)
		endif
	    endif
	endfor
    else
	if a:bang == "!"
	    if a:0 == 0
		echoerr 'you have to specify the alias to remove'
	    endif
	    try
		unlet s:aliases[a:1]
	    catch /E716:/
		echohl ErrorMsg
		echomsg 'alias "'.a:1.'" does not exists'
		echohl Normal
	    endtry
	    return
	endif
	if a:0 < 2
	    echohl ErrorMsg
	    echoerr 'you have to specify the alias and the command'
	    echohl Normal
	    return
	endif
	call Cmd_Alias(a:1, a:2, (a:0 >=3 ? a:3 : 0), (a:0 >=4 && a:4 ? bufnr('%') : 0), (a:0>=5 ? a:5 : 1))
    endif
endfun " }}}
fun! <SID>CompleteAliases(A,B,C) " {{{
    return join(keys(s:aliases), "\n")
endfun " }}}
com! -bang -nargs=* -complete=custom,<SID>CompleteAliases CmdAlias :call <SID>RegAlias(<q-bang>,<f-args>)
fun! <SID>AliasToggle() " {{{
    let s:AliasToggle = !s:AliasToggle
endfun " }}}
com! -nargs=0 CmdAliasToggle :call <SID>AliasToggle()
nnoremap <F12> :CmdAliasToggle<CR>
