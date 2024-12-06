if !has('vim9script') || v:version < 900
    finish
endif

# <DONE> add ability to enter buffers
# <DONE> add ability to clear not-found list
# <DONE> add ability to delete files
# <TODO> add ability to reorder files
# <TODO> add ability to call HarpyAdd() with file argument(s)
# <TODO> add arrow key support
# <DONE> structure as plugin
# <DONE> test on some other project dirs
# <DONE> add option dict instead of global
# <TODO> write docs

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

g:harpy_info = {show_help: 0}

if !hlexists('HarpySelectedFile')
    hi link HarpySelectedFile Normal
endif
if !hlexists('HarpyFileNotFound')
    hi link HarpyFileNotFound Comment
endif
if !hlexists('HarpyHelpText')
    hi link HarpyHelpText Comment
endif

prop_type_add('harpy_prop_file_not_found', {highlight: 'HarpyFileNotFound'})
prop_type_add('harpy_prop_selected_file', {highlight: 'HarpySelectedFile'})
prop_type_add('harpy_prop_help_text', {highlight: 'HarpyHelpText'})

export def HarpyRemoveMenuItem()
    if g:harpy_info.valid_files->len() == 0
        return
    endif
    remove(g:harpy_info.valid_files, g:harpy_info.sel_idx)
    echom "Removed an item"
    HarpySave()
    HarpyLoadFiles()
    g:harpy_info.menu = HarpyCreateMenu()
    HarpyRefreshWindow()
enddef

export def HarpyClearNotFound()
    if g:harpy_info.invalid_files->len() == 0
        return
    endif

    unlet g:harpy_info.invalid_files[:]
    HarpySave()
    HarpyLoadFiles()
    g:harpy_info.menu = HarpyCreateMenu()
    HarpyRefreshWindow()
enddef

export def HarpyHandleExit(winid: number, option: number)
    HarpySave()
enddef

export def HarpySave()
    var lines_to_write = [g:harpy_info.sel_idx] + g:harpy_info.valid_files + g:harpy_info.invalid_files
    writefile(lines_to_write, g:harpy_options.file_name)
enddef

export def HarpyLoadFiles()
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

export def HarpyAdd()
    HarpyLoadSettings()
    if !exists('g:harpy_info.valid_files')
        HarpyLoadFiles()
    endif

    var newfile = expand('%')
    if !filereadable(newfile)
        echom $'Invalid file for Harpy list: {newfile}'
        return
    endif

    if g:harpy_info.valid_files->index(newfile) >= 0
        echom $'{newfile} already in Harpy list.'
    else
        g:harpy_info.valid_files->add(newfile)
        HarpySave()
        echom $'Added {newfile} to Harpy list.'
    endif
enddef

export def HarpyRefreshWindow()
    if g:harpy_info.valid_files->len() == 0
        popup_settext(g:harpy_info.winid, g:harpy_info.menu)
        return
    endif

    var curr_ = g:harpy_info.sel_idx
    var prev_ = max([0, curr_ - 1])
    var next_ = min([curr_ + 1, g:harpy_info.valid_files->len() - 1])
    
    var prev_text = g:harpy_info.menu[prev_].text->substitute($'^{g:harpy_options.pointer}', g:harpy_options.no_pointer, 'g')
    var next_text = g:harpy_info.menu[next_].text->substitute($'^{g:harpy_options.pointer}', g:harpy_options.no_pointer, 'g')
    var curr_text = g:harpy_info.menu[curr_].text->substitute($'^{g:harpy_options.no_pointer}', g:harpy_options.pointer, 'g')

    g:harpy_info.menu[prev_] = {text: prev_text}
    g:harpy_info.menu[next_] = {text: next_text}
    g:harpy_info.menu[curr_] = HarpyFormatString(curr_text, 'harpy_prop_selected_file')

    popup_settext(g:harpy_info.winid, g:harpy_info.menu)
enddef

export def HarpyMakeHelpText(): any
    var help_lines = [{}]
    help_lines->add(HarpyFormatString($'Harpylist path: {g:harpy_options.file_name}', 'harpy_prop_help_text'))
    help_lines->add(HarpyFormatString($"Navigation: {join(g:harpy_options.keys_down + g:harpy_options.keys_up, '/')}", 'harpy_prop_help_text'))
    help_lines->add(HarpyFormatString($"Open file: {join(g:harpy_options.keys_open_file, '/')}", 'harpy_prop_help_text'))
    help_lines->add(HarpyFormatString($"Open in split on left (right): {join(g:harpy_options.keys_split_on_left, '/')} ({join(g:harpy_options.keys_split_on_right, '/')})", 'harpy_prop_help_text'))
    help_lines->add(HarpyFormatString($"Open in split on top (bottom): {join(g:harpy_options.keys_split_on_top, '/')} ({join(g:harpy_options.keys_split_on_bottom, '/')})", 'harpy_prop_help_text'))
    help_lines->add(HarpyFormatString($"Remove file from list: {join(g:harpy_options.keys_remove_entry, '/')}", 'harpy_prop_help_text'))
    help_lines->add(HarpyFormatString($"Clear missing files: {join(g:harpy_options.keys_clear_not_found, '/')}", 'harpy_prop_help_text'))
    return help_lines
enddef

export def HarpyToggleHelp()
    if g:harpy_info.show_help == 1
        g:harpy_info.menu->extend(HarpyMakeHelpText())
    else
        g:harpy_info.menu = g:harpy_info.menu[: -(HarpyMakeHelpText()->len() + 1)]
    endif
enddef

export def HarpyOpenWindowHandler(winid: number, option: string): bool
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

export def HarpyKeyHandler(winid: number, key: string): any
    var k_ = (key == ' ') ? '<Space>' : key
    k_ = (key == '') ? '<Enter>' : key

    if index(g:harpy_options.keys_split_on_right, k_) >= 0
        return HarpyOpenWindowHandler(winid, 'right')
    elseif index(g:harpy_options.keys_split_on_left, k_) >= 0
        return HarpyOpenWindowHandler(winid, 'left')
    elseif index(g:harpy_options.keys_split_on_bottom, k_) >= 0
        return HarpyOpenWindowHandler(winid, 'bottom')
    elseif index(g:harpy_options.keys_split_on_top, k_) >= 0
        return HarpyOpenWindowHandler(winid, 'top')
    elseif index(g:harpy_options.keys_open_file, k_) >= 0
        execute $'edit {g:harpy_info.valid_files[g:harpy_info.sel_idx]}'
        return popup_filter_menu(winid, '')
    elseif index(g:harpy_options.keys_down, k_) >= 0
        g:harpy_info.sel_idx = min([g:harpy_info.sel_idx + 1, g:harpy_info.valid_files->len() - 1])
        HarpyRefreshWindow()
    elseif index(g:harpy_options.keys_up, k_) >= 0
        g:harpy_info.sel_idx = max([g:harpy_info.sel_idx - 1, 0])
        HarpyRefreshWindow()
    elseif index(g:harpy_options.keys_clear_not_found, k_) >= 0
        HarpyClearNotFound()
        HarpyRefreshWindow()
    elseif index(g:harpy_options.keys_remove_entry, k_) >= 0
        HarpyRemoveMenuItem()
        HarpyRefreshWindow()
    elseif index(g:harpy_options.keys_toggle_help, k_) >= 0
        g:harpy_info.show_help = 1 - g:harpy_info.show_help
        HarpyToggleHelp()
        HarpyRefreshWindow()
    else # catch <Esc>, <C-c>, etc.
        return popup_filter_menu(winid, key)
    endif
    return true
enddef

export def HarpyFormatString(str: string, prop: string): any
    return {text: str, props: [{col: 1, length: str->len(), type: prop}]}
enddef

export def HarpyCreateMenu(): any
    var menu_lines = []
    if g:harpy_info.valid_files->len() == 0
        menu_lines += [{text: 'No valid files found!'}, {}]
    endif

    for [i, file] in items(g:harpy_info.valid_files)
        if i == g:harpy_info.sel_idx
            menu_lines->add(HarpyFormatString($'{g:harpy_options.pointer}{file}', 'harpy_prop_selected_file'))
        else
            menu_lines->add({text: $'{g:harpy_options.no_pointer}{file}'})
        endif
    endfor

    if g:harpy_info.invalid_files->len() > 0
        if g:harpy_info.valid_files->len() > 0
            menu_lines->add({})
        endif
        menu_lines->add(HarpyFormatString('Files not found:', 'harpy_prop_file_not_found'))
        for badfile in g:harpy_info.invalid_files
            menu_lines->add(HarpyFormatString($'- {badfile}', 'harpy_prop_file_not_found'))
        endfor
    endif

    menu_lines->add({})
    menu_lines->add(HarpyFormatString($"Toggle help: {join(g:harpy_options.keys_toggle_help, '/')}", 'harpy_prop_help_text'))

    if g:harpy_info.show_help
        menu_lines->extend(HarpyMakeHelpText())
    endif

    return menu_lines
enddef

export def HarpyLoadSettings()
    if exists('g:harpy_user_options')
        for [opt, val] in g:harpy_user_options->items()
            g:harpy_options[opt] = val
        endfor
    endif
enddef

export def Harpy()
    HarpyLoadSettings()
    HarpyLoadFiles()
    g:harpy_info.menu = HarpyCreateMenu()
    g:harpy_info.winid = popup_create(g:harpy_info.menu, {
        title: $' harpy ',
        drag: 1,
        border: [],
        borderhighlight: ['HarpyMenuBorder'],
        wrap: 0,
        padding: [1, 3, 1, 3], # U, R, D, L
        minwidth: g:harpy_options.min_width,
        filter: 'HarpyKeyHandler',
        mapping: 0,
        callback: 'HarpyHandleExit'
    })
enddef

command Harpy Harpy()
command HarpyAdd HarpyAdd()
