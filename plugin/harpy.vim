if !has('vim9script') || v:version < 900
    finish
endif

vim9script

# <DONE> add ability to enter buffers
# <DONE> add ability to clear not-found list
# <DONE> add ability to delete files
# <TODO> add ability to reorder files
# <TODO> add ability to call HarpyAdd() with file argument(s)
# <TODO> add arrow key support
# <TODO> structure as plugin
# <TODO> test on some other project dirs
# <TODO> add option dict instead of global
# <TODO> write docs

g:harpy_file_name = '.harpylist'
g:harpy_info_text = $'Harpylist path: {g:harpy_file_name}'

g:harpy_options = {
    pointer: '> ',
    no_pointer: '  '
}

export def HarpyRemoveMenuItem()
    if g:harpy_valid_files->len() == 0
        return
    endif
    remove(g:harpy_valid_files, g:harpy_sel_idx)
    HarpySave()
    HarpyLoadFiles()
    g:harpy_menu = HarpyCreateMenu()
enddef

export def HarpyClearNotFound()
    g:harpy_invalid_files = []
    HarpySave()
    HarpyLoadFiles()
    g:harpy_menu = HarpyCreateMenu()
enddef

export def HarpyHandleExit(winid: number, option: number)
    HarpySave()
enddef

export def HarpySave()
    var lines_to_write = [g:harpy_sel_idx] + g:harpy_valid_files + g:harpy_invalid_files
    writefile(lines_to_write, g:harpy_file_name)
enddef

export def HarpyLoadFiles()
    if !filereadable(g:harpy_file_name)
        writefile([0], g:harpy_file_name)
    endif
    g:harpy_file_list = readfile(g:harpy_file_name)
    var found = []
    var not_found = []
    var sel_idx = str2nr(g:harpy_file_list[0])
    for file in g:harpy_file_list[1 : ]
        if filereadable(file)
            add(found, file)
        else
            add(not_found, file)
        endif
    endfor
    g:harpy_valid_files = found
    g:harpy_invalid_files = not_found

    g:harpy_n_valid_files = g:harpy_valid_files->len()

    sel_idx = max([sel_idx, 0])
    sel_idx = min([sel_idx, g:harpy_n_valid_files - 1])

    g:harpy_sel_idx = sel_idx
enddef

export def HarpyAdd()
    if !exists('g:harpy_valid_files')
        HarpyLoadFiles()
    endif

    var newfile = expand('%')
    if !filereadable(newfile)
        echom $'Invalid file for Harpy list: {newfile}'
        return
    endif

    if index(g:harpy_valid_files, newfile) >= 0
        echom $'{newfile} already in Harpy list.'
    else
        add(g:harpy_valid_files, newfile)
        HarpySave()
        echom $'Added {newfile} to Harpy list.'
    endif
enddef

export def HarpyRefreshWindow(winid: number)
    if g:harpy_valid_files->len() == 0
        return
    endif

    var curr_ = g:harpy_sel_idx
    var prev_ = max([0, curr_ - 1])
    var next_ = min([curr_ + 1, g:harpy_n_valid_files - 1])
    
    var prev_text = g:harpy_menu[prev_].text->substitute($'^{g:harpy_options.pointer}', g:harpy_options.no_pointer, 'g')
    var next_text = g:harpy_menu[next_].text->substitute($'^{g:harpy_options.pointer}', g:harpy_options.no_pointer, 'g')
    var curr_text = g:harpy_menu[curr_].text->substitute($'^{g:harpy_options.no_pointer}', g:harpy_options.pointer, 'g')

    g:harpy_menu[prev_] = {text: prev_text}
    g:harpy_menu[next_] = {text: next_text}
    g:harpy_menu[curr_] = HarpyFormatString(curr_text, 'harpy_prop_selected_file')

    popup_settext(winid, g:harpy_menu)
enddef

export def HarpyOpenWindowHandler(winid: number, option: string): bool
    if g:harpy_valid_files->len() == 0
        return false
    endif

    var opened = 0

    var sr = &splitright
    var sb = &splitbelow

    if option == 'right'
        set splitright
        execute $'vsplit {g:harpy_valid_files[g:harpy_sel_idx]}'
        opened = 1
    elseif option == 'left'
        set nosplitright
        execute $'vsplit {g:harpy_valid_files[g:harpy_sel_idx]}'
        opened = 1
    elseif option == 'bottom'
        set splitbelow
        execute $'split {g:harpy_valid_files[g:harpy_sel_idx]}'
        opened = 1
    elseif option == 'top'
        set nosplitbelow
        execute $'split {g:harpy_valid_files[g:harpy_sel_idx]}'
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
    if key == 'v'
        return HarpyOpenWindowHandler(winid, 'right')
    elseif key == 'V'
        return HarpyOpenWindowHandler(winid, 'left')
    elseif key == 's'
        return HarpyOpenWindowHandler(winid, 'bottom')
    elseif key == 'S'
        return HarpyOpenWindowHandler(winid, 'top')
    elseif key == ''
        execute $'edit {g:harpy_valid_files[g:harpy_sel_idx]}'
        return popup_filter_menu(winid, '')
    elseif key == 'j'
        g:harpy_sel_idx = min([g:harpy_sel_idx + 1, g:harpy_n_valid_files - 1])
        HarpyRefreshWindow(winid)
    elseif key == 'k'
        g:harpy_sel_idx = max([g:harpy_sel_idx - 1, 0])
        HarpyRefreshWindow(winid)
    elseif key == 'D'
        HarpyClearNotFound()
        HarpyRefreshWindow(winid)
    elseif key == 'X'
        HarpyRemoveMenuItem()
        HarpyRefreshWindow(winid)
    else # catch <Esc>, <C-c>, etc.
        return popup_filter_menu(winid, key)
    endif
    return true
enddef

prop_type_add('harpy_prop_file_not_found', {highlight: 'HarpyFileNotFound'})
prop_type_add('harpy_prop_selected_file', {highlight: 'HarpySelectedFile'})

export def HarpyFormatString(str: string, prop: string): any
    return {
        text: str, props: [{col: 1, length: str->len(), type: prop}]
    }
enddef

export def HarpyCreateMenu(): any
    var menu_lines = []
    if g:harpy_n_valid_files == 0
        menu_lines += [{text: 'No valid files found!'}, {}]
    endif

    for [i, file] in items(g:harpy_valid_files)
        if i == g:harpy_sel_idx
            add(menu_lines, HarpyFormatString($'{g:harpy_options.pointer}{file}', 'harpy_prop_selected_file'))
        else
            add(menu_lines, {text: $'{g:harpy_options.no_pointer}{file}'})
        endif
    endfor

    if g:harpy_invalid_files->len() > 0
        if g:harpy_n_valid_files > 0
            add(menu_lines, {})
        endif
        add(menu_lines, HarpyFormatString('Files not found:', 'harpy_prop_file_not_found'))
        for badfile in g:harpy_invalid_files
            add(menu_lines, HarpyFormatString($'- {badfile}', 'harpy_prop_file_not_found'))
        endfor
    endif

    menu_lines += [{}, {text: g:harpy_info_text}]
    return menu_lines
enddef

export def Harpy()
    HarpyLoadFiles()
    g:harpy_menu = HarpyCreateMenu()
    g:harpy_winid = popup_create(g:harpy_menu, {
        title: ' harpy ',
        drag: 1,
        border: [],
        borderhighlight: ['GenericYellowPop'],
        wrap: 0,
        padding: [1, 3, 1, 3], # U, R, D, L
        minwidth: 70,
        filter: 'HarpyKeyHandler',
        mapping: 0,
        callback: 'HarpyHandleExit'
    })
enddef

command Harpy Harpy()
command HarpyAdd HarpyAdd()
