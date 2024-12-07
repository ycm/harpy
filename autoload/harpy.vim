vim9script


export def Run()
    LoadUserOpts()
    LoadFiles()
    g:harpy_info.menu_ = CreateMenu()
    g:harpy_info.winid = popup_create(g:harpy_info.menu_, {
        minwidth: g:harpy_opts.min_width,
        title: ' harpy ',
        drag: true,
        resize: true,
        border: [],
        borderhighlight: ['HarpyMenuBorder'],
        highlight: 'HarpyMenuBg',
        padding: [1, 3, 1, 3], # U, R, D, L
        filter: HandleInput,
        mapping: 0,
        callback: HandleExit
    })
enddef


export def Add(file: string = '%')
    LoadUserOpts()
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
    var lines_to_write = [
        g:harpy_info.sel_idx] + g:harpy_info.valid + g:harpy_info.invalid
    writefile(lines_to_write, g:harpy_opts.file_name)
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
    sel_idx = max([sel_idx, 0])
    sel_idx = min([sel_idx, g:harpy_info.valid->len() - 1])
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

    g:harpy_info.menu_[prev_] = {text: prev_text}
    g:harpy_info.menu_[next_] = {text: next_text}
    g:harpy_info.menu_[curr_] = FormatString(curr_text, 'harpy_prop_selected')

    popup_settext(g:harpy_info.winid, g:harpy_info.menu_)
enddef


def FormatHelp(): any
    var help_lines = [{}]
    help_lines->add(FormatString($'Harpylist filename: ' .. 
        g:harpy_opts.file_name,
        'harpy_prop_help'))
    help_lines->add(FormatString('Navigation: ' ..
        join(g:harpy_opts.keys_down + g:harpy_opts.keys_up, '/'),
        'harpy_prop_help'))
    help_lines->add(FormatString('Reorder: ' ..
        join(g:harpy_opts.keys_move_down + g:harpy_opts.keys_move_up, '/'),
        'harpy_prop_help'))
    help_lines->add(FormatString('Open file: ' ..
        join(g:harpy_opts.keys_open, '/'), 
        'harpy_prop_help'))
    help_lines->add(FormatString('Open in split on left (right): ' ..
        join(g:harpy_opts.keys_split_left, '/') .. 
        $" ({join(g:harpy_opts.keys_split_right, '/')})",
        'harpy_prop_help'))
    help_lines->add(FormatString('Open in split on top (bottom): ' ..
        join(g:harpy_opts.keys_split_top, '/') ..
        $" ({join(g:harpy_opts.keys_split_bottom, '/')})",
        'harpy_prop_help'))
    help_lines->add(FormatString('Remove file from list: ' ..
        join(g:harpy_opts.keys_remove_entry, '/'),
        'harpy_prop_help'))
    help_lines->add(FormatString('Clear missing files: ' ..
        join(g:harpy_opts.keys_clear_not_found, '/'),
        'harpy_prop_help'))
    return help_lines
enddef


def ToggleHelp()
    if g:harpy_info.show_help == 1
        g:harpy_info.menu_->extend(FormatHelp())
    else
        g:harpy_info.menu_ = g:harpy_info.menu_[: -(FormatHelp()->len() + 1)]
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


def FormatString(str: string, prop: string): any
    return {text: str, props: [{col: 1, length: str->len(), type: prop}]}
enddef


def CreateMenu(): any
    var menu_ = []
    if g:harpy_info.valid->len() == 0
        menu_ += [{text: 'No valid files found!'}, {}]
    endif

    for [i, file] in items(g:harpy_info.valid)
        if i == g:harpy_info.sel_idx
            menu_->add(FormatString($'{g:harpy_opts.pointer}{file}',
                'harpy_prop_selected'))
        else
            menu_->add({text: $'{g:harpy_opts.no_pointer}{file}'})
        endif
    endfor

    if g:harpy_info.invalid->len() > 0
        if g:harpy_info.valid->len() > 0
            menu_->add({})
        endif
        menu_->add(FormatString('Files not found:', 'harpy_prop_not_found'))
        for badfile in g:harpy_info.invalid
            menu_->add(FormatString($'- {badfile}', '_prop_file_not_found'))
        endfor
    endif

    menu_->add({})
    menu_->add(FormatString(
        $"Toggle help: {join(g:harpy_opts.keys_toggle_help, '/')}",
        'harpy_prop_help'))

    if g:harpy_info.show_help
        menu_->extend(FormatHelp())
    endif

    return menu_
enddef


def LoadUserOpts()
    if get(g:, 'harpy_user_opts', false)
        for [opt, val] in g:harpy_user_opts->items()
            g:harpy_opts[opt] = val
        endfor
    endif
enddef


def HandleInput(winid: number, key: string): any
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
        execute $'edit {g:harpy_info.valid[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, '')
    elseif index(g:harpy_opts.keys_down, k_) >= 0
        g:harpy_info.sel_idx = min([g:harpy_info.sel_idx + 1,
            g:harpy_info.valid->len() - 1])
        Refresh()
    elseif index(g:harpy_opts.keys_up, k_) >= 0
        g:harpy_info.sel_idx = max([g:harpy_info.sel_idx - 1, 0])
        Refresh()
    elseif index(g:harpy_opts.keys_move_down, k_) >= 0
        var new_idx = min([g:harpy_info.sel_idx + 1,
            g:harpy_info.valid->len() - 1])
        Switch(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        Refresh()
    elseif index(g:harpy_opts.keys_move_up, k_) >= 0
        var new_idx = max([g:harpy_info.sel_idx - 1, 0])
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


def HandleExit(winid: number, option: number)
    Save()
enddef
