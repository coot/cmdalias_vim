" Author: Marcin Szamotulski
" Email: mszamot [AT] gmail [DOT] com
" Copyright: © Marcin Szamotulski, 2012
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
let s:system = !empty(globpath(&rtp, 'plugin/system.vim'))
fun! ParseRange(cmdline) " {{{
    let range = ""
    let cmdline = a:cmdline
    while len(cmdline)
	let cl = cmdline
	if cmdline =~ '^\s*%'
	    let range = matchstr(cmdline, '^\s*%\s*')
	    return [range, cmdline[len(range):], 0]
	elseif &cpoptions !~ '\*' && cmdline =~ '\s*\*'
	    let range = matchstr(cmdline, '^\s*\*\s*')
	    return [range, cmdline[len(range):], 0]
	elseif cmdline =~ '^\s*\d'
	    let add = matchstr(cmdline, '^\s*\d\+')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range
	elseif cmdline =~ '^\.\s*'
	    let add = matchstr(cmdline, '^\s*\.\%([+-]\+\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range
	elseif cmdline =~ '^\s*\\[&/?]'
	    let add = matchstr(cmdline, '^\s*\\[/&?]\%(\s*[-+]\+\d*\)')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range
	elseif cmdline =~ '^\s*\/'
	    let add = matchstr(cmdline, '^\s*\/\%([^/&?]\|\\\@<=\/\)*\/\%([-+]\+\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range . "<F>".cmdline."<"
	elseif cmdline =~ '^\s*?'
	    let add = matchstr(cmdline, '^\s*?\%([^?]\|\\\@<=?\)*?\%([-+]\+\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range . "<?>".cmdline."<"
	elseif cmdline =~ '^\s*\$'
	    let add = matchstr(cmdline, '^\s*\$\%(-\+\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range
	elseif cmdline =~ '^\s*\\\%(\/\|?\|&\)'
	    let add = matchstr(cmdline, '^\s*\\\%(\/\|?\|&\)')
	    let range .== add
	    let cmdine = cmdline[add:]
	    " echom range
	elseif cmdline =~ '^\s*[;,]'
	    let add = matchstr(cmdline, '^\s*[;,]')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range . "<;>".cmdline
	elseif cmdline =~ '^\s*\w'
	    return [ range, cmdline, 0]
	endif
	if cl == cmdline
	    " Parser didn't make a step (so it falls into a loop)
	    " XXX: when this might happen?
	    return [ '', a:cmdline, 1]
	endif
    endwhile
    " If a:cmdline == '1000' we return here:
    return [ '', a:cmdline, 2]
endfun " }}}
fun! ReWriteCmdLine() " {{{
    if getcmdtype() != ":"
	return getcmdline()
    endif
    let cmdlines = split(getcmdline(), '\\\@<!|')
    let scmdlines = copy(cmdlines)

    let n_cmdlines = []
    for cmdline in cmdlines
	if s:system && cmdline[0:1] == "! "
	    if !exists("*WrapCmdLine")
		echoe 'You need to update system.vim plugin to version 3'
		break
	    else
		let cmdline = WrapCmdLine()
	    endif
	    call add(n_cmdlines, cmdline)
	    let alias = "! " " This is for debuging
	    let cmd = "!"
	    continue
	endif
	" XXX: detect verbose, silent and debug keywords.
	let decorator = matchstr(cmdline, '^\s*\(sil\%[ent]!\=\s*\|debug\s*\|\d*verb\%[ose]\s*\)*')
	let cmdline = cmdline[len(decorator):]
	let test=0
	let [range, cmdline, error] = ParseRange(cmdline)
	for alias in sort(values(s:aliases), "<SID>CompareLA")
	    if cmdline =~# '^\s*'.alias['alias'].(alias['match_end'] ? '\>' : '') && 
			\ (index(alias['buflocal'], 0) != -1 || index(alias['buflocal'],  bufnr('%')) != -1)
		let test=1
		break
	    endif
	endfor
	if test
	    let m = matchstr(cmdline, '\C^\s*'.alias['alias'].(alias['match_end'] ? '\>' : ''))
	    let cmd = alias['cmd'].cmdline[len(m):]
	    " Default: if empty(range) use alias range otherwise use range:
	    if empty(range)
		let range = alias['default_range']
	    endif
	    if alias['cmd'][0] != '!' && get(alias, 'history', 0)
		call histadd(":", getcmdline())
		let cmd .= "|call histdel(':', -1)"
	    endif
	else
	    let cmd = cmdline
	endif
	call add(n_cmdlines, decorator.range.cmd)
    endfor
    let cmdline = join(n_cmdlines, "|")
    if cmdline !~ 'cmd_alias_debug' && exists("g:cmd_alias_debug")
	call add(g:cmd_alias_debug, { 'cmdline' : cmdline, 'alias' : alias, 'cmd' : cmd, 'scmdlines' : scmdlines})
    endif
    return cmdline
endfunc "}}}
cnoremap <C-M> <CR>
cnoremap <CR> <C-\>eReWriteCmdLine()<CR><CR>

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
    let [default_range, cmd, error] = ParseRange(a:cmd)
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
	echo " alias".repeat(" ", lmax)."cmd".repeat(" ", 5+rmax-3)."his"
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
	    unlet s:aliases[a:1]
	    return
	endif
	if a:0 < 2
	    echoerr 'you have to specify the alias and the command'
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
    if !empty(maparg('<CR>', 'c'))
	echo 'cmd_alias: off'
	cunmap <CR>
    else
	echo 'cmd_alias: on'
	cnoremap <silent> <CR> <C-\>eReWriteCmdLine()<CR><CR>
    endif
endfun " }}}
com! -nargs=0 CmdAliasToggle :call <SID>AliasToggle()
nnoremap <F12> :CmdAliasToggle<CR>
