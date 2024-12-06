# harpy

[WIP] Vim9script implementation of a few basic features in ![harpoon](https://github.com/ThePrimeagen/harpoon) for my personal use case.

![](https://github.com/ycm/harpy/blob/master/gallery/splash.png)

Unlike harpoon, harpy's menu is not a regular text buffer - as such, harpy does not permit text-editing commands like inserting text, `dd`, etc. To hopefully offset this limitation, some basic menu management functionality is offered with customizable keys. On the other hand, this also means no need to `:w` to save the menu, and the menu can 'remember' the cursor position, show some more info, etc.

## Setup

Requires Vim 9+.

Install with a plugin manager like ![vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'ycm/harpy'
```

Manual installation: Add `harpy.vim` to `.vim/plugin/`, or use the Vim8+ pack system, etc.

⚠️ **NOTE**: `set autochdir` is **not recommended**, as it renders harpy mostly useless.

## Usage

- Invoke harpy menu: `:Harpy`
- Add the current file to harpy list: `:HarpyAdd`

Sample mappings:
```vim
nnoremap <silent> <leader>ll :Harpy<cr>
nnoremap <silent> <leader>la :HarpyAdd<cr>
```

## Configs

**Default options**
```vim
g:harpy_options = {
    file_name: '.harpylist',
    pointer: '> ',
    no_pointer: '  ',
    min_width: 50,
    keys_down: ['j'],
    keys_up: ['k'],
    keys_open_file: ['<Enter>', '<Space>'],
    keys_clear_not_found: ['D'],
    keys_remove_entry: ['X'],
    keys_split_on_top: ['S'],
    keys_split_on_bottom: ['s'],
    keys_split_on_left: ['V'],
    keys_split_on_right: ['v'],
    keys_toggle_help: ['h']
}
```

To set custom options, add a global dictionary called `g:harpy_user_options` anywhere. 

Vim9script:
```vim
g:harpy_user_options = {
    keys_up: ['k', 'K'],
    pointer: '-->',
    no_pointer: ' * ',
    min_width: 70
}
```

Legacy vimscript:
```vim
let g:harpy_user_options = {
    \ 'keys_up': ['k', 'K'],
    \ 'pointer': '-->',
    \ 'no_pointer': ' * ',
    \ 'min_width': 70
    \ }
```

**Colors**

The following highlight groups can be customized:
```
HarpySelectedFile
HarpyFileNotFound
HarpyHelpText
HarpyMenuBorder
```
