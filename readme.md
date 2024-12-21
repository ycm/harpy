### Deprecated!

[poplar.vim](https://github.com/ycm/poplar.vim) is better and includes a filetree.

<h1 align="center">harpy</h1>

<p align="center">A small set of <a href="https://github.com/ThePrimeagen/harpoon">harpoon</a>-like features for my personal use case.</p>

![demo](https://github.com/ycm/harpy/blob/master/gallery/demo.gif)

(gif made with [asciinema](https://asciinema.org/))

Unlike harpoon, harpy's menu is not a regular text buffer - as such, harpy does not permit text-editing commands like inserting text, `dd`, etc. To hopefully offset this limitation, some basic menu management functionality is offered with customizable keys. On the other hand, this also means no need to `:w` to save the menu, and the menu can 'remember' the cursor position, show some more info, etc.

## Setup

Requires Vim 9+.

[vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'ycm/harpy'
```

Manual installation:
```
mkdir -p ~/.vim/pack/ycm/start && cd ~/.vim/pack/ycm/start
git clone https://github.com/ycm/harpy.git
vim -u NONE -c "helptags harpy/doc" -c q
```

Note: `set autochdir` is not recommended, since harpy stores its filelist in the cwd. This also means you might want to `ignore` the filelist in your project. 
```bash
echo ".harpylist" >> .gitignore
```

## Configs

**Sample mappings**

```vim
nnoremap <silent> <leader>ll :Harpy<cr>
nnoremap <silent> <leader>la :HarpyAdd<cr>
```

**Default options**
```vim
g:harpy_opts = {
    file_name: '.harpylist',
    min_width: 40,
    pointer:    ' > ',
    no_pointer: '   ',
    keys_down:            ['j', '<Down>'],
    keys_up:              ['k', '<Up>'],
    keys_move_down:       ['J'],
    keys_move_up:         ['K'],
    keys_open:            ['<Enter>', '<Space>'],
    keys_open_in_tab:     ['t'],
    keys_clear_not_found: ['D'],
    keys_remove_entry:    ['X'],
    keys_split_top:       ['S'],
    keys_split_bottom:    ['s'],
    keys_split_left:      ['V'],
    keys_split_right:     ['v'],
    keys_toggle_help:     ['h']
}
```

To set custom options, add a global dictionary called `g:harpy_user_opts`. This
dictionary is loaded when you first run `:Harpy` or `:HarpyAdd`. If you modify
these configs after using harpy, you should restart Vim for the changes to take
effect.
```vim
vim9script
g:harpy_user_opts = {
    keys_up: ['k', 'l'],
    pointer: '>',
    no_pointer: ' ',
    min_width: 70
}
```

**Colors**

Harpy also comes with these highlight links:
```vim
HarpyEntry             -> Normal
HarpyEntryFile         -> Identifier
HarpyEntrySelected     -> Normal
HarpyEntrySelectedFile -> Identifier
HarpyFileNotFound      -> Removed
HarpyHelpText          -> Comment
HarpyMenuBg            -> PMenu
HarpyMenuBorder        -> PMenu
```

You can play around with these as you would any other highlight group.
