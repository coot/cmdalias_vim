Description
===========

This plugin implements aliases for command names, wihtout vim restriction:
user defined commands via |:command| must begin with a captial letter. Using
this plugin you make an alias to a command where the alias, is any sequence.
You can also register a defult range or count with the alias. In this way
you can change the default range or count of vim commands.
To define alias use the command: 
      :CmdAlias {alias} {command} [history] [match_end] 
where {alias} is the alias name (you might pretend to it the default range
or count), {command} is the command that should be executed. The {alias} is
any vim pattern that will be used to match what you are entering in the ':'
command line (the pattern will have pretended '\C^' and appended '\>' - the
later one unless [match_end] is specified and equal 0). For commands which
do not run external programs you can also set [history]=1 (default is 0),
then the command history will remember what you have typped rather than what
was executed. But usage of it is limited, for example you can use with
commands that echo some output because it will be hidden by next call to
histdel() vim function.


Note: If you define [match_end] = 0 you might fall into troubles, simply
because a the plugin might substitute part of a command name. So don't use
it unless you really want to experiment - you've been warned ;).


If you don't provide any argument to the :CmdAlias command it will list all
aliases.

Examples: 
---------
```vim
   :CmdAlias ali\%[as] CmdAlias
```
Note: this alias would not work if we defined it with [history]=1.
```vim
   :CmdAlias %s s
```
Change the default range of |:s| command from the current line to whole
buffer. Note that :su will act with vim default range (the current line).
```vim
  :CmdAlias a\%[ppend] Append 
```
define alias to the user command Append which will overwrite the vim command
|:append|. The  \%[...] allows that if you type: 'a' or 'ap' or 'app', ...
or 'append' then the Append command will be used (as with vim many commands)
```vim
  :CmdAlias bc\%[lose] BufClose
``` 
You will find the handy BufClose command in BufClose plugin by Christian
Robinson.

Tip: to find if an alias is not coliding type ':<alias><C-d>'.
See ':help c^D'.

---------------------------------------------------------------------------

```vim
  :CmdAliasToggle 
```
toggles on/of the aliases. Since the plugin remaps <CR> in the command line
this just delets/sets up the <CR> map.  When you want to type a function:
':fun! X()' or use the expression register |@=| you need to switch aliases
off. The plugin also defines <C-M> map to <CR> which doesn't trigger
aliasing mechanism. So you can type ':fun! X()<C-M>' on the command line.
```vim
  :CmdAlias! {alias} 
```
removes {alias}, this command has a nice completion.

Note: If you have installed system.vim plugin (script id 4224) you need to
update to version 3 (otherwise you will get an error).

There is another plugin with the same functionality, but different
implementation and thus a different limitations.
http://www.vim.org/scripts/script.php?script_id=746 It uses cabbreviations.
The problem with them is that it is more difficult to get the command bang
working (what was the purpose of implementing this plugin). The range and
the count probably could be implemented using the same range parser used by
this plugin. The advantage of the cabbreviations approach is that after
hitting the ' ' you get the real command together with its completion.
Implementing completion for aliases within this approach would be quite
tedious.

The aliasing works also when joining commands on the command line with "|",
for example with a dummy alias:
```vim
  Alias S %s
```  
you can run:
```vim
:S/aaa/yyy/|S/bbb/xxx
```
Note: the first command has to end with / (to use |, this is a vim
requirement.)

Note: using the expression register:
Since <C-R> is remapped in command line, you can not use it when you enter
the expression register (:help ^R=). There is a patch on the way which fixes
this disabling maps in expression register. Before it get accepted the
plugin defies a map:
cnoremap <C-M> <CR>
It will not trigger aliases, any way it might be a good idea to have such
a map in case you want to avoid aliases.

If you want to debug define a list
```vim
 let g:cmd_alias_debug = []
``` 
and for all calls an entry to this list will be appended.
(except command lines which matches cmd_alias_debug since we don't want to
record accessing to this variable)


Author: Marcin Szamotulski

Email: mszamot [AT] gmail [DOT] com

Copyright: © Marcin Szamotulski, 2012

License: vim-license, see :help license

