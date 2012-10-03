" Author: Marcin Szamotulski
" Email: mszamot [AT] gmail [DOT] com
" Copyright: © Marcin Szamotulski, 2012
" License: vim-license, see :help license
"
" Description
" ===========
"
" Note: the interface has changed slightly (in version 2): buflocal aliases
" added. To redefine default range add it to the cmd rather than to the alias
" (this seems to be more intuitive).
"
"
" This plugin implements aliases for command names, wihtout vim restriction:
" user defined commands via :command must begin with a captial letter. Using
" this plugin you make an alias to a command where the alias, is any sequence.
" You can also register a defult range or count with the alias. In this way
" you can change the default range or count of vim commands.
" To define alias use the command: 
" ```
" :CmdAlias {alias} [range]{command} [history] [buflocal] [match_end] 
" ```
" where {alias} is the alias name, {command} is the command that should be
" executed. You might pretend new default [range] or count to the command. The
" {alias} is any vim pattern that will be used to match what you are entering in
" the ':' command line (the pattern will have pretended '\C^' and appended '\\>'
" - the later one unless [match_end] is specified and equal 0). For commands
" which do not run external programs you can also set [history]=1 (default is
" 0), then the command history will remember what you have typped rather than
" what was executed. But usage of it is limited, for example you can use with
" commands that echo some output because it will be hidden by next call to
" histdel() vim function. If [buflocal] has true value (1 for example) then the
" alias will be only valid in the current buffer (it will be denotes with @ when
" listing the aliases as Vim does for maps).
"
" Note: If you define [match_end] = 0 you might fall into troubles, simply
" because a the plugin might substitute part of a command name. So don't use
" it unless you really want to experiment - you've been warned ;).
"
" Fork me on GitHub:
" https://github.com/coot/cmdalias_vim
"
" If you don't provide any argument to the :CmdAlias command it will list all
" aliases.
"
" Examples: 
" ---------
" ```
" :CmdAlias ali\%[as] CmdAlias
" ```
" Note: this alias would not work if we defined it with [history]=1.
" ```
" :CmdAlias s %s
" ```
" Change the default range of :s command from the current line to whole
" buffer. Note that :su will act with vim default range (the current line).
" ```
" :CmdAlias a\%[ppend] Append 
" ```
" define alias to the user command Append which will overwrite the vim command
" :append. The  \%[...] allows that if you type: 'a' or 'ap' or 'app', ...
" or 'append' then the Append command will be used (as with vim many commands)
" ```
" :CmdAlias bc\%[lose] BufClose
" ``` 
" You will find the handy BufClose command in BufClose plugin by Christian
" Robinson.
"
" Tip: to find if an alias is not coliding type ':\<alias\>\<C-d\>'.
" See ':help c^D'.
"
" ```
" :CmdAlias SP  1,/\\\\begin{document}/-1s
" ```
" The :SP command will substitute in the LaTeX preambule (which starts in the
" first line and ends before `\begin{document}`). Note that the Vim pattern to
" find `\begin...` is `\\begin...` and each backslash needs to be escaped onece
" more. Thus we have four slashes (like in *Python* :).
"
" VIMRC
" -----
"
" To configure aliases on startup you haveto add the following lines to your
" vimrc file:
" ```
" augroup VIMRC_aliases
"   au!
"   au VimEnter * CmdAlias ...
"   ...
" augroup END
" ```
"
" Other Commands and Maps:
" ------------------------
"
" ```
" :CmdAliasToggle 
" ```
" toggles on/of the aliases. Since the plugin remaps \<CR\> in the command line
" this just delets/sets up the \<CR\> map.  When you want to type a function:
" ```
" :fun! X()
" ```
" or use the expression register @= you need to switch aliases
" off. The plugin also defines \<C-M\> map to \<CR\> which doesn't trigger
" aliasing mechanism. So you can type ':fun! X()\<C-M\>' on the command line.
" ```
" :CmdAlias! {alias} 
" ```
" removes {alias}, this command has a nice completion.
"
" Note: If you have installed my [system plugin](http://www.vim.org/scripts/script.php?script_id=4224)
" you need to update it to version 3 (otherwise you will get an error).
"
" There is another [plugin](http://www.vim.org/scripts/script.php?script_id=746)
" with the same functionality, but different implementation and thus a different
" limitations.  It uses cabbreviations.  The problem with them is that it is
" more difficult to get the command bang working (what was the purpose of
" implementing this plugin). The range and the count probably could be
" implemented using the same range parser used by this plugin. The advantage of
" the cabbreviations approach is that after hitting the ' ' you get the real
" command together with its completion.  Implementing completion for aliases
" within this approach would be quite tedious.
"
" The aliasing works also when joining commands on the command line with "|",
" for example with a dummy alias:
" ```
"  Alias S %s
" ```  
" you can run:
" ```
" :S/aaa/yyy/|S/bbb/xxx
" ```
" Note: the first command has to end with / (to use |, this is a vim
" requirement.)
"
" Note: using the expression register:
" Since \<C-R\> is remapped in command line, you can not use it when you enter
" the expression register (:help ^R=). There is a patch on the way which fixes
" this disabling maps in expression register. Before it get accepted the
" plugin defies a map:
" ```
" cnoremap <C-M> <CR>
" ```
" It will not trigger aliases, any way it might be a good idea to have such
" a map in case you want to avoid aliases.
"
" If you want to debug define a list
" ```
" let g:cmd_alias_debug = []
" ``` 
" and for all calls an entry to this list will be appended.
" (except command lines which matches cmd_alias_debug since we don't want to
" record accessing to this variable)

" INTERNALS {{{
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
let s:system = !empty(globpath(&rtp, 'plugin/system.vim'))
fun! ParseRange(cmdline) " {{{
    let range = ""
    let cmdline = a:cmdline
    while len(cmdline)
	let cl = cmdline
	if cmdline =~ '^\s*%'
	    let range = matchstr(cmdline, '^\s*%\s*')
	    return [range, cmdline[len(range):], 0]
	elseif cmdline =~ '^\s*\d'
	    let add = matchstr(cmdline, '^\s*\d\+')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range
	elseif cmdline =~ '^\.\s*'
	    let add = matchstr(cmdline, '^\s*\.\%([+-]\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range
	elseif cmdline =~ '^\s*\/'
	    let add = matchstr(cmdline, '^\s*\/\%([^/]\|\\\@<=\/\)*\/\%([-+]\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range . "<F>".cmdline."<"
	elseif cmdline =~ '^\s*?'
	    let add = matchstr(cmdline, '^\s*?\%([^?]\|\\\@<=?\)*?\%([-+]\d*\)\=')
	    let range .= add
	    let cmdline = cmdline[len(add):]
	    " echom range . "<?>".cmdline."<"
	elseif cmdline =~ '^\s*\$'
	    let add = matchstr(cmdline, '^\s*\$\%(-\d*\)\=')
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
	" XXX: detect verbose, silent and redir keywords.
	let decorator = matchstr(cmdline, '^\s*\(sil\%[ent]!\=\s*\|debug\s*\|\d*verb\%[ose]\s*\)*')
	let cmdline = cmdline[len(decorator):]
	let test=0
	let [range, cmdline, error] = ParseRange(cmdline)
	for alias in values(s:aliases)
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
cnoremap <silent> <CR> <C-\>eReWriteCmdLine()<CR><CR>

fun! <SID>Compare(i1,i2) "{{{
   return (a:i1['alias'] == a:i2['alias'] ? 0 : a:i1['alias'] > a:i2['alias'] ? 1 : -1)
endfunc "}}}
fun! Cmd_Alias(alias, cmd, ...) " {{{
    " This is the same as the cmdalias plugin
    " https://github.com/vim-scripts/cmdalias.vim
    "
    " The reason for this function is that for users with aliases within the
    " cmdlias.vim plugin it is just to copy past the old config and add one
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
	    \ }
    else
	if index(s:aliases[a:alias]['buflocal'], buflocal) == -1
	    call add(s:aliases[a:alias]['buflocal'], buflocal)
	endif
    endif
endfun " }}}
fun! <SID>RegAlias(bang,...) " {{{
    if a:0 == 0
	let lmax = max(map(values(s:aliases), "len(v:val['alias'])"))
	let rmax = max(map(values(s:aliases), "len(v:val['cmd'])+len(v:val['default_range'])"))
	let g:lmax = lmax
	let g:rmax = rmax
	echohl Title
	echo " alias".repeat(" ", lmax)."cmd".repeat(" ", 5+rmax-3)."his"
	echohl Normal
	for alias in sort(values(s:aliases), "<SID>Compare")
	    if index(alias['buflocal'], 0) != -1 || index(alias['buflocal'], bufnr('%')) != -1
		echo (index(alias['buflocal'], 0) == -1 ? '@' : ' ').
			\ alias['alias'].repeat(" ", (5+lmax-len(alias['alias']))).
			\ alias['default_range'].alias['cmd'].repeat(" ", (5+rmax-len(alias['default_range'].alias['cmd']))).
			\ (alias['history'] ? 'yes' : '  ' ).repeat(" ", 4)
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
" }}}
