if !has('vim9script') || v:version < 900
    finish
endif

vim9script

if get(g:, 'loaded_harpy', false)
  finish
endif
g:loaded_harpy = true

import autoload "../autoload/harpy.vim"

hi default link HarpySelectedFile PMenuSel
hi default link HarpyFileNotFound WarningMsg
hi default link HarpyHelpText     Comment
hi default link HarpyMenuBg       PMenu
hi default link HarpyMenuBorder   PMenu

if prop_type_get('harpy_prop_not_found') == {}
    prop_type_add('harpy_prop_not_found', {highlight: 'HarpyFileNotFound'})
endif
if prop_type_get('harpy_prop_selected') == {}
    prop_type_add('harpy_prop_selected', {highlight: 'HarpySelectedFile'})
endif
if prop_type_get('harpy_prop_help') == {}
    prop_type_add('harpy_prop_help', {highlight: 'HarpyHelpText'})
endif

g:harpy_info = {show_help: 0}

g:harpy_opts = {
    file_name: '.harpylist',
    min_width: 40,
    pointer:    ' > ',
    no_pointer: '   ',
    keys_down:            ['j'],
    keys_up:              ['k'],
    keys_move_down:       ['J'],
    keys_move_up:         ['K'],
    keys_open:            ['<Enter>', '<Space>'],
    keys_clear_not_found: ['D'],
    keys_remove_entry:    ['X'],
    keys_split_top:       ['S'],
    keys_split_bottom:    ['s'],
    keys_split_left:      ['V'],
    keys_split_right:     ['v'],
    keys_toggle_help:     ['h']
}

command! Harpy harpy.Run()
command! -nargs=? HarpyAdd harpy.Add(<f-args>)
