vim9script


export def Run()
    if !exists('g:harpy_info')
        Init()
    endif
    LoadFiles()
    g:harpy_info.menu_ = CreateMenu()
    g:harpy_info.winid = g:harpy_info.menu_->popup_create({
        minwidth: g:harpy_opts.min_width,
        title: ' harpy ',
        drag: true,
        border: [],
        borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
        borderhighlight: ['HarpyMenuBorder'],
        highlight: 'HarpyMenuBg',
        padding: [1, 3, 1, 3],
        filter: HandleInput,
        mapping: 0,
        callback: HandleExit
    })
enddef


export def Add(file: string = '%')
    if !'g:harpy_info'->exists()
        Init()
    endif
    if !'g:harpy_info.valid'->exists()
        LoadFiles()
    endif
    var newfile = file->expand()->fnamemodify(":~:.")
    if !newfile->filereadable()
        echom $'[harpy] invalid file: {newfile}'
        return
    endif
    if g:harpy_info.valid->index(newfile) >= 0
        echom $'[harpy] {newfile} already in list.'
    else
        g:harpy_info.valid->add(newfile)
        Save()
        echom $'[harpy] added {newfile}.'
    endif
enddef


def Remove()
    if g:harpy_info.valid->len() == 0
        return
    endif
    g:harpy_info.valid->remove(g:harpy_info.sel_idx)
    echom "[harpy] removed an item"
    Save()
    LoadFiles()
    g:harpy_info.menu_ = CreateMenu()
    Refresh()
enddef


def ClearNotFound()
    if g:harpy_info.invalid->len() == 0
        return
    endif
    unlet g:harpy_info.invalid[:]
    Save()
    LoadFiles()
    g:harpy_info.menu_ = CreateMenu()
    Refresh()
enddef


def Save()
    var lines = [g:harpy_info.sel_idx] + g:harpy_info.valid + g:harpy_info.invalid
    lines->writefile(g:harpy_opts.file_name)
enddef


def LoadFiles()
    if !g:harpy_opts.file_name->filereadable()
        [0]->writefile(g:harpy_opts.file_name)
    endif
    var file_list = g:harpy_opts.file_name->readfile()
    var found = []
    var not_found = []
    var sel_idx = file_list[0]->str2nr()
    for file in file_list[1 : ]
        if file->filereadable()
            found->add(file)
        else
            not_found->add(file)
        endif
    endfor
    g:harpy_info.valid = found
    g:harpy_info.invalid = not_found
    sel_idx = [sel_idx, 0]->max()
    sel_idx = [sel_idx, g:harpy_info.valid->len() - 1]->min()
    g:harpy_info.sel_idx = sel_idx
enddef


def Switch(i: number, j: number)
    if g:harpy_info.valid->len() == 0
        return
    endif
    [g:harpy_info.menu_[i], g:harpy_info.menu_[j]] =
        [g:harpy_info.menu_[j], g:harpy_info.menu_[i]]
    [g:harpy_info.valid[i], g:harpy_info.valid[j]] =
        [g:harpy_info.valid[j], g:harpy_info.valid[i]]
    Save()
enddef


def Refresh()
    if g:harpy_info.valid->len() == 0
        g:harpy_info.winid->popup_settext(g:harpy_info.menu_)
        return
    endif

    var curr_ = g:harpy_info.sel_idx
    var prev_ = [0, curr_ - 1]->max()
    var next_ = [curr_ + 1, g:harpy_info.valid->len() - 1]->min()

    var prev_text = g:harpy_opts.no_pointer
        .. g:harpy_info.menu_[prev_].text[g:harpy_opts.pointer->len() :]
    var next_text = g:harpy_opts.no_pointer
        .. g:harpy_info.menu_[next_].text[g:harpy_opts.pointer->len() :]
    var curr_text = g:harpy_opts.pointer
        .. g:harpy_info.menu_[curr_].text[g:harpy_opts.pointer->len() :]

    g:harpy_info.menu_[prev_] = FormatLine(prev_text, 'entry')
    g:harpy_info.menu_[next_] = FormatLine(next_text, 'entry')
    g:harpy_info.menu_[curr_] = FormatLine(curr_text, 'selected entry')

    g:harpy_info.winid->popup_settext(g:harpy_info.menu_)
enddef


def FormatLine(text: string, style: string): dict<any>
    if style == 'help'
        return {
            text: text,
            props: [{col: 1, length: text->len(), type: 'harpy_prop_HelpText'}]
        } 
    endif
    if style == 'not found'
        return {
            text: text,
            props: [{col: 1, length: text->len(), type: 'harpy_prop_FileNotFound'}]
        } 
    endif

    var pointer_len = g:harpy_opts.pointer->len()
    var path_len = text[pointer_len :]->len()
    var tail_len = fnamemodify(text[pointer_len :], ':t')->len()

    var path_prop = style == 'selected entry'
        ? 'harpy_prop_EntrySelected' : 'harpy_prop_Entry'
    var file_prop = style == 'selected entry'
        ? 'harpy_prop_EntrySelectedFile' : 'harpy_prop_EntryFile'

    return {
        text: text,
        props: [
            {col: 1, length: pointer_len + path_len - tail_len, type: path_prop},
            {col: pointer_len + path_len - tail_len + 1, length: tail_len, type: file_prop}
        ]}
enddef


def Init()
    g:harpy_info = {show_help: 0}
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
    if exists('g:harpy_user_opts')
        g:harpy_opts->extend(g:harpy_user_opts)
    endif
    var textcolors = [
        ['Entry', 'Normal'],
        ['EntryFile', 'Identifier'],
        ['EntrySelected', 'Normal'],
        ['EntrySelectedFile', 'Identifier'],
        ['FileNotFound', 'Removed'],
        ['HelpText', 'Comment'],
        ['MenuBg', 'PMenu'],
        ['MenuBorder', 'PMenu']
    ]

    for [group, link] in textcolors
        var hgroup = $'Harpy{group}'
        var prop = $'harpy_prop_{group}'
        execute $'hi default link {hgroup} {link}'
        if prop->prop_type_get() == {}
            prop->prop_type_add({highlight: hgroup})
        endif
    endfor

    g:harpy_info.help_lines = [{},
        FormatLine($'Harpylist filename: ' .. g:harpy_opts.file_name, 'help'),
        FormatLine('Navigation: ' ..
            (g:harpy_opts.keys_down + g:harpy_opts.keys_up)->join('/'), 'help'),
        FormatLine('Reorder: ' ..
            (g:harpy_opts.keys_move_down + g:harpy_opts.keys_move_up)->join('/'),
            'help'),
        FormatLine('Open file: ' .. g:harpy_opts.keys_open->join('/'), 'help'),
        FormatLine('Open file in new tab: ' ..
            g:harpy_opts.keys_open_in_tab->join('/'), 'help'),
        FormatLine('Open in split on left (right): ' ..
            g:harpy_opts.keys_split_left->join('/') ..
            $" ({g:harpy_opts.keys_split_right->join('/')})", 'help'),
        FormatLine('Open in split on top (bottom): ' ..
            g:harpy_opts.keys_split_top->join('/') ..
            $" ({g:harpy_opts.keys_split_bottom->join('/')})", 'help'),
        FormatLine('Remove file from list: ' ..
            g:harpy_opts.keys_remove_entry->join('/'), 'help'),
        FormatLine('Clear missing files: ' ..
            g:harpy_opts.keys_clear_not_found->join('/'), 'help')]
enddef


def ToggleHelp()
    if g:harpy_info.show_help == 1
        g:harpy_info.menu_->extend(g:harpy_info.help_lines)
    else
        g:harpy_info.menu_ = g:harpy_info.menu_[: -(g:harpy_info.help_lines->len() + 1)]
    endif
enddef


def OpenWindowHandler(winid: number, option: string): bool
    if g:harpy_info.valid->len() == 0
        return false
    endif

    var opened = 0

    var sr = &splitright
    var sb = &splitbelow

    if option == 'right'
        set splitright
        execute $'vsplit {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        opened = 1
    elseif option == 'left'
        set nosplitright
        execute $'vsplit {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        opened = 1
    elseif option == 'bottom'
        set splitbelow
        execute $'split {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        opened = 1
    elseif option == 'top'
        set nosplitbelow
        execute $'split {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        opened = 1
    endif
    if sr
        set splitright
    else
        set nosplitright
    endif
    if sb
        set splitbelow
    else
        set nosplitbelow
    endif
    if opened
        winid->popup_close()
    endif
    return opened
enddef


def CreateMenu(): list<dict<any>>
    var menu_ = []
    if g:harpy_info.valid->len() == 0
        menu_ += [{text: 'No valid files found!'}, {}]
    endif

    for [i, file] in items(g:harpy_info.valid)
        if i == g:harpy_info.sel_idx
            menu_->add(FormatLine($'{g:harpy_opts.pointer}{file}', 'selected entry'))
        else
            menu_->add(FormatLine($'{g:harpy_opts.no_pointer}{file}', 'entry'))
        endif
    endfor

    if g:harpy_info.invalid->len() > 0
        if g:harpy_info.valid->len() > 0
            menu_->add({})
        endif
        menu_->add(FormatLine('Files not found:', 'not found'))
        for badfile in g:harpy_info.invalid
            menu_->add(FormatLine($'- {badfile}', 'not found'))
        endfor
    endif

    menu_->add({})
    menu_->add(FormatLine(
        $"Toggle help: {join(g:harpy_opts.keys_toggle_help, '/')}",
        'help'))

    if g:harpy_info.show_help
        menu_->extend(g:harpy_info.help_lines)
    endif

    return menu_
enddef


# ref: https://github.com/vim/vim/blob/master/src/keymap.h
# certain keys are sent via 3-bytes code
var keycodes = {
    9: '<Tab>',
    13: '<Enter>',
    27: '<Esc>',
    32: '<Space>',
    'ku': '<Up>',
    'kd': '<Down>',
    'kl': '<Left>',
    'kr': '<Right>',
    'kb': '<Bksp>',
    'kD': '<Del>'
}


def HandleInput(winid: number, key: string): bool
    var k_ = key->len() == 3
    \   ? keycodes->get(key[1 :], key)
    \   : keycodes->get(char2nr(key), key)

    if g:harpy_opts.keys_split_right->index(k_) >= 0
        return OpenWindowHandler(winid, 'right')
    elseif g:harpy_opts.keys_split_left->index(k_) >= 0
        return OpenWindowHandler(winid, 'left')
    elseif g:harpy_opts.keys_split_bottom->index(k_) >= 0
        return OpenWindowHandler(winid, 'bottom')
    elseif g:harpy_opts.keys_split_top->index(k_) >= 0
        return OpenWindowHandler(winid, 'top')
    elseif g:harpy_opts.keys_open->index(k_) >= 0
        execute $'drop {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, nr2char(13))
    elseif g:harpy_opts.keys_open_in_tab->index(k_) >= 0
        execute $'tabnew {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, nr2char(13))
    elseif g:harpy_opts.keys_down->index(k_) >= 0
        g:harpy_info.sel_idx = [g:harpy_info.sel_idx + 1,
            g:harpy_info.valid->len() - 1]->min()
        Refresh()
    elseif g:harpy_opts.keys_up->index(k_) >= 0
        g:harpy_info.sel_idx = [g:harpy_info.sel_idx - 1, 0]->max()
        Refresh()
    elseif g:harpy_opts.keys_move_down->index(k_) >= 0
        var new_idx = [g:harpy_info.sel_idx + 1,
            g:harpy_info.valid->len() - 1]->min()
        Switch(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        Refresh()
    elseif g:harpy_opts.keys_move_up->index(k_) >= 0
        var new_idx = [g:harpy_info.sel_idx - 1, 0]->max()
        Switch(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        Refresh()
    elseif g:harpy_opts.keys_clear_not_found->index(k_) >= 0
        ClearNotFound()
        Refresh()
    elseif g:harpy_opts.keys_remove_entry->index(k_) >= 0
        Remove()
        Refresh()
    elseif g:harpy_opts.keys_toggle_help->index(k_) >= 0
        g:harpy_info.show_help = 1 - g:harpy_info.show_help
        ToggleHelp()
        Refresh()
    elseif k_ == '<Esc>' || k_ == 'x'
        return winid->popup_filter_menu(key)
    endif
    return true
enddef


def HandleExit(_, _)
    Save()

enddef
