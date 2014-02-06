Description
===========

Note: the interface has changed slightly: buflocal aliases added. To redefine
default range add it to the cmd rather than to the alias (this seems to be
more intuitive).


This plugin implements aliases for command names, without vim restriction:
user defined commands via :command must begin with a capital letter. Using
this plugin you make an alias to a command where the alias, is any sequence.
You can also register a default range or count with the alias. In this way
you can change the default range or count of vim commands.
To define alias use the command: 
```viml
:CmdAlias [alias] [range][command] [history] [buflocal] [match_end] 
```
where `[alias]` is the alias name, `[command]` is the command that should be
executed. You might pretend new default `[range]` or count to the command. The
`[alias]` is any vim pattern that will be used to match what you are entering in
the `:` command line (the pattern will have pretended `\C^` and appended `\\>` -
the later one unless [match&#95;end] is specified and equal `0`). For
commands which do not run external programs you can also set `[history]=1`
(default is `0`), then the command history will remember what you have typped
rather than what was executed. But usage of it is limited, for example you can
use with commands that echo some output because it will be hidden by next call
to `histdel()` vim function. If `[buflocal]` has true value (`1` for example)
then the alias will be only valid in the current buffer (it will be denotes
with @ when listing the aliases as Vim does for maps).


Note: If you define `[match_end] = 0` you might fall into troubles, simply
because the plugin might substitute part of a command name.  So don't use
it unless you really want to experiment - you've been warned ;).


If you don't provide any argument to the `:CmdAlias` command it will list all
aliases.


The order in which you define aliases matters. More recent aliases are matched
first. If you want to list the aliases in alphabetic order use:
```viml
:CmdAlias
```
If you want to list them in the order they are tried:
```viml
:CmdAlias!
```
Note that
```viml
:CmdAlias {alias}
```
will list all aliases which starts with {alias} but
```viml
:CmdAlias! {alias}
```
will remove the {alias} (has to be equal to the registered alias).


Examples: 
---------
```viml
:CmdAlias ali\%[as] CmdAlias
```
Note: this alias would not work if we defined it with `[history]=1`.
```viml
:CmdAlias s %s
```
Change the default range of `:s` command from the current line to whole
buffer. Note that `:su` will act with vim default range (the current line).
```viml
:CmdAlias a\%[ppend] Append 
```
define alias to the user command Append which will overwrite the vim command
:append. The  `\%[...]` allows that if you type: 'a' or 'ap' or 'app', ...
or 'append' then the Append command will be used (as with vim many commands)
```viml
:CmdAlias bc\%[lose] BufClose
``` 
You will find the handy BufClose command in BufClose plugin by Christian
Robinson.

Tip: to find if an alias is not coliding type ':\<alias\>\<C-d\>'.
See `:help c^D`.

```viml
:CmdAlias SP  1,/\\\\begin{document}/-1s
```
The :SP command will substitute in the LaTeX preambule (which starts in the
first line and ends before `\begin{document}`). Note that the Vim pattern to
find `\begin...` is `\\begin...` and each backslash needs to be escaped onece
more. Thus we have four slashes (like in *Python* :).


VIMRC
-----

To configure aliases on startup you have to add the following lines to your
vimrc file:
```viml
augroup VIMRC_aliases
    au!
    au VimEnter * CmdAlias ...
    ...
augroup END
```

Other Commands and Maps:
------------------------

```viml
:CmdAliasToggle 
```
toggles on/of the aliases. Since the plugin remaps \<CR\> in the command line
this just deletes/sets up the \<CR\> map.  When you want to type a function:
```viml
:fun! X()
```
The plugin also defines \<C-M\> map to \<CR\> which doesn't trigger
aliasing mechanism. So you can type ':fun! X()\<C-M\>' on the command line.
```viml
:CmdAlias! {alias} 
```
removes {alias}, this command has a nice completion.

Note: If you have installed my [system plugin](http://www.vim.org/scripts/script.php?script_id=4224)
you need to update it to version 3 (otherwise you will get an error).

There is another [plugin](http://www.vim.org/scripts/script.php?script_id=746)
with the same functionality, but different implementation and thus a different
limitations.  It uses cabbreviations.  The problem with them is that it is
more difficult to get the command bang working (what was the purpose of
implementing this plugin). The range and the count probably could be
implemented using the same range parser used by this plugin. The advantage of
the cabbreviations approach is that after hitting the ' ' you get the real
command together with its completion.  Implementing completion for aliases
within this approach would be quite tedious.

The aliasing works also when joining commands on the command line with "|",
for example with a dummy alias:
```viml
  Alias S %s
```  
you can run:
```viml
:S/aaa/yyy/|S/bbb/xxx
```
Note: the first command has to end with / (to use |, this is a vim
requirement.)

Note: using the expression register: you need Vim 7.3.686. There is also:
```viml
 cnoremap <C-M> <CR>
```
It will not trigger aliases, any way it might be a good idea to have such
a map in case you want to avoid aliases.

If you want to debug define a list
```viml
 let g:cmd_alias_debug = []
``` 
and for all calls an entry to this list will be appended.
(except command lines which matches `cmd_alias_debug` since we don't want to
record accessing to this variable)


Ideas for aliases:
```viml
CmdAlias h\%[elp] top\ help   " very useful if you use 'splitbelow', but you want help to split above
CmdAlias re reg\ "0-*+/ 1
CmdAlias rn reg\ 123456789 1
CmdAlias ra reg abcdefghijklmnopqrstuwxyz 1
CmdAlias bc\%[close] BufClose
```
For the last alias one you need the
[BufClose](http://www.vim.org/scripts/script.php?script_id=559) plugin.


Author: Marcin Szamotulski
Email: mszamot [AT] gmail [DOT] com
Copyright: © Marcin Szamotulski, 2012-2014
License: vim-license, see `:help license`
