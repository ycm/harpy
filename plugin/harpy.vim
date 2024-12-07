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

if prop_type_get('harpy_prop_file_not_found') == {}
    prop_type_add('harpy_prop_file_not_found', {highlight: 'HarpyFileNotFound'})
endif
if prop_type_get('harpy_prop_selected_file') == {}
    prop_type_add('harpy_prop_selected_file', {highlight: 'HarpySelectedFile'})
endif
if prop_type_get('harpy_prop_help_text') == {}
    prop_type_add('harpy_prop_help_text', {highlight: 'HarpyHelpText'})
endif

g:harpy_info = {show_help: 0}

g:harpy_options = {
    file_name: '.harpylist',
    min_width: 40,
    pointer:    ' > ',
    no_pointer: '   ',
    keys_down:            ['j'],
    keys_up:              ['k'],
    keys_reorder_down:    ['J'],
    keys_reorder_up:      ['K'],
    keys_open_file:       ['<Enter>', '<Space>'],
    keys_clear_not_found: ['D'],
    keys_remove_entry:    ['X'],
    keys_split_on_top:    ['S'],
    keys_split_on_bottom: ['s'],
    keys_split_on_left:   ['V'],
    keys_split_on_right:  ['v'],
    keys_toggle_help:     ['h']
}

command! Harpy harpy.HarpyRun()
command! -nargs=? HarpyAdd harpy.HarpyAdd(<f-args>)
