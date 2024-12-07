vim9script

def harpy#Run()
    harpy#LoadSettings()
    harpy#LoadFiles()
    g:harpy_info.menu_lines = harpy#CreateMenu()
    g:harpy_info.winid = popup_create(g:harpy_info.menu_lines, {
        minwidth: g:harpy_options.min_width,
        title: ' harpy ',
        drag: true,
        resize: true,
        border: [],
        borderhighlight: ['HarpyMenuBorder'],
        highlight: 'HarpyMenuBg',
        padding: [1, 3, 1, 3], # U, R, D, L
        filter: 'harpy#KeyHandler',
        mapping: 0,
        callback: 'harpy#HandleExit'
    })
enddef

def harpy#Add(file: string = '%')
    harpy#LoadSettings()
    if !exists('g:harpy_info.valid_files')
        harpy#LoadFiles()
    endif
    var newfile = fnamemodify(expand(file), ":~:.")
    if !filereadable(newfile)
        echom $'[harpy] invalid file: {newfile}'
        return
    endif
    if g:harpy_info.valid_files->index(newfile) >= 0
        echom $'[harpy] {newfile} already in list.'
    else
        g:harpy_info.valid_files->add(newfile)
        harpy#Save()
        echom $'[harpy] added {newfile}.'
    endif
enddef

def harpy#RemoveMenuItem()
    if g:harpy_info.valid_files->len() == 0
        return
    endif
    remove(g:harpy_info.valid_files, g:harpy_info.sel_idx)
    echom "[harpy] removed an item"
    harpy#Save()
    harpy#LoadFiles()
    g:harpy_info.menu_lines = harpy#CreateMenu()
    harpy#RefreshWindow()
enddef

def harpy#ClearNotFound()
    if g:harpy_info.invalid_files->len() == 0
        return
    endif
    unlet g:harpy_info.invalid_files[:]
    harpy#Save()
    harpy#LoadFiles()
    g:harpy_info.menu_lines = harpy#CreateMenu()
    harpy#RefreshWindow()
enddef

def harpy#HandleExit(winid: number, option: number)
    harpy#Save()
enddef

def harpy#Save()
    var lines_to_write = [g:harpy_info.sel_idx] + g:harpy_info.valid_files + g:harpy_info.invalid_files
    writefile(lines_to_write, g:harpy_options.file_name)
enddef

def harpy#LoadFiles()
    if !filereadable(g:harpy_options.file_name)
        writefile([0], g:harpy_options.file_name)
    endif
    var file_list = readfile(g:harpy_options.file_name)
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
    g:harpy_info.valid_files = found
    g:harpy_info.invalid_files = not_found
    sel_idx = max([sel_idx, 0])
    sel_idx = min([sel_idx, g:harpy_info.valid_files->len() - 1])
    g:harpy_info.sel_idx = sel_idx
enddef

def harpy#SwitchFiles(i: number, j: number)
    if g:harpy_info.valid_files->len() == 0
        return
    endif
    [g:harpy_info.menu_lines[i], g:harpy_info.menu_lines[j]] =
        [g:harpy_info.menu_lines[j], g:harpy_info.menu_lines[i]]
    [g:harpy_info.valid_files[i], g:harpy_info.valid_files[j]] =
        [g:harpy_info.valid_files[j], g:harpy_info.valid_files[i]]
    harpy#Save()
enddef

def harpy#RefreshWindow()
    if g:harpy_info.valid_files->len() == 0
        popup_settext(g:harpy_info.winid, g:harpy_info.menu_lines)
        return
    endif

    var curr_ = g:harpy_info.sel_idx
    var prev_ = max([0, curr_ - 1])
    var next_ = min([curr_ + 1, g:harpy_info.valid_files->len() - 1])
    
    var prev_text = g:harpy_info.menu_lines[prev_].text->substitute($'^{g:harpy_options.pointer}', g:harpy_options.no_pointer, 'g')
    var next_text = g:harpy_info.menu_lines[next_].text->substitute($'^{g:harpy_options.pointer}', g:harpy_options.no_pointer, 'g')
    var curr_text = g:harpy_info.menu_lines[curr_].text->substitute($'^{g:harpy_options.no_pointer}', g:harpy_options.pointer, 'g')

    g:harpy_info.menu_lines[prev_] = {text: prev_text}
    g:harpy_info.menu_lines[next_] = {text: next_text}
    g:harpy_info.menu_lines[curr_] = harpy#FormatString(curr_text, 'harpy_prop_selected_file')

    popup_settext(g:harpy_info.winid, g:harpy_info.menu_lines)
enddef

def harpy#MakeHelpText(): any
    var help_lines = [{}]
    help_lines->add(harpy#FormatString($'Harpylist filename: {g:harpy_options.file_name}', 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Navigation: {join(g:harpy_options.keys_down + g:harpy_options.keys_up, '/')}", 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Reorder: {join(g:harpy_options.keys_reorder_down + g:harpy_options.keys_reorder_up, '/')}", 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Open file: {join(g:harpy_options.keys_open_file, '/')}", 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Open in split on left (right): {join(g:harpy_options.keys_split_on_left, '/')} ({join(g:harpy_options.keys_split_on_right, '/')})", 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Open in split on top (bottom): {join(g:harpy_options.keys_split_on_top, '/')} ({join(g:harpy_options.keys_split_on_bottom, '/')})", 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Remove file from list: {join(g:harpy_options.keys_remove_entry, '/')}", 'harpy_prop_help_text'))
    help_lines->add(harpy#FormatString($"Clear missing files: {join(g:harpy_options.keys_clear_not_found, '/')}", 'harpy_prop_help_text'))
    return help_lines
enddef

def harpy#ToggleHelp()
    if g:harpy_info.show_help == 1
        g:harpy_info.menu_lines->extend(harpy#MakeHelpText())
    else
        g:harpy_info.menu_lines = g:harpy_info.menu_lines[: -(harpy#MakeHelpText()->len() + 1)]
    endif
enddef

def harpy#OpenWindowHandler(winid: number, option: string): bool
    if g:harpy_info.valid_files->len() == 0
        return false
    endif

    var opened = 0

    var sr = &splitright
    var sb = &splitbelow

    if option == 'right'
        set splitright
        execute $'vsplit {g:harpy_info.valid_files[g:harpy_info.sel_idx]}'
        opened = 1
    elseif option == 'left'
        set nosplitright
        execute $'vsplit {g:harpy_info.valid_files[g:harpy_info.sel_idx]}'
        opened = 1
    elseif option == 'bottom'
        set splitbelow
        execute $'split {g:harpy_info.valid_files[g:harpy_info.sel_idx]}'
        opened = 1
    elseif option == 'top'
        set nosplitbelow
        execute $'split {g:harpy_info.valid_files[g:harpy_info.sel_idx]}'
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

def harpy#KeyHandler(winid: number, key: string): any
    var k_ = (key == ' ') ? '<Space>' : key
    k_ = (key == '') ? '<Enter>' : key
    if index(g:harpy_options.keys_split_on_right, k_) >= 0
        return harpy#OpenWindowHandler(winid, 'right')
    elseif index(g:harpy_options.keys_split_on_left, k_) >= 0
        return harpy#OpenWindowHandler(winid, 'left')
    elseif index(g:harpy_options.keys_split_on_bottom, k_) >= 0
        return harpy#OpenWindowHandler(winid, 'bottom')
    elseif index(g:harpy_options.keys_split_on_top, k_) >= 0
        return harpy#OpenWindowHandler(winid, 'top')
    elseif index(g:harpy_options.keys_open_file, k_) >= 0
        execute $'edit {g:harpy_info.valid_files[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, '')
    elseif index(g:harpy_options.keys_down, k_) >= 0
        g:harpy_info.sel_idx = min([g:harpy_info.sel_idx + 1, g:harpy_info.valid_files->len() - 1])
        harpy#RefreshWindow()
    elseif index(g:harpy_options.keys_up, k_) >= 0
        g:harpy_info.sel_idx = max([g:harpy_info.sel_idx - 1, 0])
        harpy#RefreshWindow()
    elseif index(g:harpy_options.keys_reorder_down, k_) >= 0
        var new_idx = min([g:harpy_info.sel_idx + 1, g:harpy_info.valid_files->len() - 1])
        harpy#SwitchFiles(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        harpy#RefreshWindow()
    elseif index(g:harpy_options.keys_reorder_up, k_) >= 0
        var new_idx = max([g:harpy_info.sel_idx - 1, 0])
        harpy#SwitchFiles(g:harpy_info.sel_idx, new_idx)
        g:harpy_info.sel_idx = new_idx
        harpy#RefreshWindow()
    elseif index(g:harpy_options.keys_clear_not_found, k_) >= 0
        harpy#ClearNotFound()
        harpy#RefreshWindow()
    elseif index(g:harpy_options.keys_remove_entry, k_) >= 0
        harpy#RemoveMenuItem()
        harpy#RefreshWindow()
    elseif index(g:harpy_options.keys_toggle_help, k_) >= 0
        g:harpy_info.show_help = 1 - g:harpy_info.show_help
        harpy#ToggleHelp()
        harpy#RefreshWindow()
    else # catch <Esc>, <C-c>, etc.
        return popup_filter_menu(winid, key)
    endif
    return true
enddef

def harpy#FormatString(str: string, prop: string): any
    return {text: str, props: [{col: 1, length: str->len(), type: prop}]}
enddef

def harpy#CreateMenu(): any
    var menu_lines = []
    if g:harpy_info.valid_files->len() == 0
        menu_lines += [{text: 'No valid files found!'}, {}]
    endif

    for [i, file] in items(g:harpy_info.valid_files)
        if i == g:harpy_info.sel_idx
            menu_lines->add(harpy#FormatString($'{g:harpy_options.pointer}{file}', 'harpy_prop_selected_file'))
        else
            menu_lines->add({text: $'{g:harpy_options.no_pointer}{file}'})
        endif
    endfor

    if g:harpy_info.invalid_files->len() > 0
        if g:harpy_info.valid_files->len() > 0
            menu_lines->add({})
        endif
        menu_lines->add(harpy#FormatString('Files not found:', 'harpy_prop_file_not_found'))
        for badfile in g:harpy_info.invalid_files
            menu_lines->add(harpy#FormatString($'- {badfile}', 'harpy_prop_file_not_found'))
        endfor
    endif

    menu_lines->add({})
    menu_lines->add(harpy#FormatString($"Toggle help: {join(g:harpy_options.keys_toggle_help, '/')}", 'harpy_prop_help_text'))

    if g:harpy_info.show_help
        menu_lines->extend(harpy#MakeHelpText())
    endif

    return menu_lines
enddef

def harpy#LoadSettings()
    if exists('g:harpy_user_options')
        for [opt, val] in g:harpy_user_options->items()
            g:harpy_options[opt] = val
        endfor
    endif
enddef
