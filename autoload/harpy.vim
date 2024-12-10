vim9script


export def Run()
    if !exists('g:harpy_info')
        Init()
    endif
    LoadFiles()
    g:harpy_info.menu_ = CreateMenu()
    g:harpy_info.winid = popup_create(g:harpy_info.menu_, {
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
    if !exists('g:harpy_info')
        Init()
    endif
    if !exists('g:harpy_info.valid')
        LoadFiles()
    endif
    var newfile = fnamemodify(expand(file), ":~:.")
    if !filereadable(newfile)
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
    remove(g:harpy_info.valid, g:harpy_info.sel_idx)
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
    writefile(lines, g:harpy_opts.file_name)
enddef


def LoadFiles()
    if !filereadable(g:harpy_opts.file_name)
        writefile([0], g:harpy_opts.file_name)
    endif
    var file_list = readfile(g:harpy_opts.file_name)
    var found = []
    var not_found = []
    var sel_idx = str2nr(file_list[0])
    for file in file_list[1 : ]
        if filereadable(file)
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
        popup_settext(g:harpy_info.winid, g:harpy_info.menu_)
        return
    endif

    var curr_ = g:harpy_info.sel_idx
    var prev_ = max([0, curr_ - 1])
    var next_ = min([curr_ + 1, g:harpy_info.valid->len() - 1])
    
    var prev_text = g:harpy_info.menu_[prev_].text->substitute(
        $'^{g:harpy_opts.pointer}', g:harpy_opts.no_pointer, 'g')
    var next_text = g:harpy_info.menu_[next_].text->substitute(
        $'^{g:harpy_opts.pointer}', g:harpy_opts.no_pointer, 'g')
    var curr_text = g:harpy_info.menu_[curr_].text->substitute(
        $'^{g:harpy_opts.no_pointer}', g:harpy_opts.pointer, 'g')

    g:harpy_info.menu_[prev_] = FormatLine(prev_text, 'entry')
    g:harpy_info.menu_[next_] = FormatLine(next_text, 'entry')
    g:harpy_info.menu_[curr_] = FormatLine(curr_text, 'selected entry')

    popup_settext(g:harpy_info.winid, g:harpy_info.menu_)
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
    var head = fnamemodify(text, ':h')
    var headlen = head == '.' ? 0 : head->len()
    var path_prop = style == 'selected entry' ? 'harpy_prop_EntrySelected' : 'harpy_prop_Entry'
    var file_prop = style == 'selected entry' ? 'harpy_prop_EntrySelectedFile' : 'harpy_prop_EntryFile'
    return {
        text: text,
        props: [
            {col: 1, length: headlen + 1, type: path_prop},
            {col: headlen + 2, length: text->len() - headlen - 1, type: file_prop}
        ]
    }
enddef

def Init()
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
        for [opt, val] in g:harpy_user_opts->items()
            g:harpy_opts[opt] = val
        endfor
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
        if prop_type_get(prop) == {}
            prop_type_add(prop, {highlight: hgroup})
        endif
    endfor

    g:harpy_info.help_lines = [{},
        FormatLine($'Harpylist filename: ' .. g:harpy_opts.file_name, 'help'),
        FormatLine('Navigation: ' ..
            join(g:harpy_opts.keys_down + g:harpy_opts.keys_up, '/'), 'help'),
        FormatLine('Reorder: ' ..
            join(g:harpy_opts.keys_move_down + g:harpy_opts.keys_move_up, '/'),
            'help'),
        FormatLine('Open file: ' .. join(g:harpy_opts.keys_open, '/'), 'help'),
        FormatLine('Open file in new tab: ' ..
            join(g:harpy_opts.keys_open_in_tab, '/'), 'help'),
        FormatLine('Open in split on left (right): ' ..
            join(g:harpy_opts.keys_split_left, '/') .. 
            $" ({join(g:harpy_opts.keys_split_right, '/')})", 'help'),
        FormatLine('Open in split on top (bottom): ' ..
            join(g:harpy_opts.keys_split_top, '/') ..
            $" ({join(g:harpy_opts.keys_split_bottom, '/')})", 'help'),
        FormatLine('Remove file from list: ' ..
            join(g:harpy_opts.keys_remove_entry, '/'), 'help'),
        FormatLine('Clear missing files: ' ..
            join(g:harpy_opts.keys_clear_not_found, '/'), 'help')]
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
        popup_close(winid)
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


def HandleInput(winid: number, key: string): bool
    var k_ = (key == ' ') ? '<Space>' : key
    k_ = (key == '') ? '<Enter>' : key

    if index(g:harpy_opts.keys_split_right, k_) >= 0
        return OpenWindowHandler(winid, 'right')
    elseif index(g:harpy_opts.keys_split_left, k_) >= 0
        return OpenWindowHandler(winid, 'left')
    elseif index(g:harpy_opts.keys_split_bottom, k_) >= 0
        return OpenWindowHandler(winid, 'bottom')
    elseif index(g:harpy_opts.keys_split_top, k_) >= 0
        return OpenWindowHandler(winid, 'top')
    elseif index(g:harpy_opts.keys_open, k_) >= 0
        execute $'drop {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, '')
    elseif index(g:harpy_opts.keys_open_in_tab, k_) >= 0
        execute $'tabnew {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, '')
    elseif index(g:harpy_opts.keys_down, k_) >= 0
        g:harpy_info.sel_idx = [g:harpy_info.sel_idx + 1,
            g:harpy_info.valid->len() - 1]->min()
        Refresh()
    elseif index(g:harpy_opts.keys_up, k_) >= 0
        g:harpy_info.sel_idx = [g:harpy_info.sel_idx - 1, 0]->max()
        Refresh()
    elseif index(g:harpy_opts.keys_move_down, k_) >= 0
        var new_idx = [g:harpy_info.sel_idx + 1,
            g:harpy_info.valid->len() - 1]->min()
        Switch(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        Refresh()
    elseif index(g:harpy_opts.keys_move_up, k_) >= 0
        var new_idx = [g:harpy_info.sel_idx - 1, 0]->max()
        Switch(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        Refresh()
    elseif index(g:harpy_opts.keys_clear_not_found, k_) >= 0
        ClearNotFound()
        Refresh()
    elseif index(g:harpy_opts.keys_remove_entry, k_) >= 0
        Remove()
        Refresh()
    elseif index(g:harpy_opts.keys_toggle_help, k_) >= 0
        g:harpy_info.show_help = 1 - g:harpy_info.show_help
        ToggleHelp()
        Refresh()
    else # catch <Esc>, <C-c>, etc.
        return popup_filter_menu(winid, key)
    endif
    return true
enddef


def HandleExit(_, _)
    Save()
enddef
