# harpy

Some basic features from ![harpoon](https://github.com/ThePrimeagen/harpoon) for my personal use case, written in vim9script.

![](https://github.com/ycm/harpy/blob/master/gallery/splash.png)

Unlike harpoon, harpy's menu is not a regular text buffer - as such, harpy does not permit text-editing commands like inserting text, `dd`, etc. To hopefully offset this limitation, some basic menu management functionality is offered with customizable keys. On the other hand, this also means no need to `:w` to save the menu, and the menu can 'remember' the cursor position, show some more info, etc.

## Setup

Requires Vim 9+.

![vim-plug](https://github.com/junegunn/vim-plug):
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

## Basic usage

See `:h harpy`.

- Open the harpy menu with `:Harpy`
- Add the current file to the harpy list with `:HarpyAdd`
- Add another file with `:HarpyAdd path/to/file`
- Exit the menu with standard `popupwin` keys: `<Esc>`, `x`, `<C-c>`
- Remove the selected file with `X`
- Clear any deleted files with `D`
- Navigate the filelist with `j` and `k`
- Reorder files with `J` and `K`
- Open the selected file with `<Enter>` or `<Space>`
- Open the selected file as a vertical split with `V` or `v`
- Open the selected file as a horizontal split with `S` or `s`
- Show some help text with `h`

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
```

To set custom options, add a global dictionary called `g:harpy_user_opts` anywhere. 

```vim
vim9script
g:harpy_user_opts = {
    keys_up: ['k', 'l'],
    pointer: '-->',
    no_pointer: ' * ',
    min_width: 70
}
```

**Colors**

Below are the highlight groups that you can customize, along with their defaults.
```
hi default link HarpySelectedFile PMenuSel
hi default link HarpyFileNotFound WarningMsg
hi default link HarpyHelpText     Comment
hi default link HarpyMenuBg       PMenu
hi default link HarpyMenuBorder   PMenu
```

## TODOs
- [x] add ability to clear not-found list
- [x] add ability to enter buffers
- [x] add ability to delete files
- [x] structure as plugin
- [x] test on some other project dirs
- [x] add option dict instead of global
- [x] adding files from the command line (e.g. `:HarpyAdd path/to/file`)
- [x] reordering menu items
- [x] refactor and use autoload
- [ ] support arrow and modifier keys
- [ ] support multikey input (e.g. `dd` to delete)
- [ ] optimizing the logic overall (harpy is naively implemented right now)
- [x] write help
- [ ] undo delete?
