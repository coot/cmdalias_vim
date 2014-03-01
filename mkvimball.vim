let g:vimball_home = "."
new
call setline(1, 'plugin/cmd_alias.vim')
call append('$', 'doc/cmd_alias.txt')
%MkVimball! crdispatcher
bw!
q
