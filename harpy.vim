vim9script

g:harpy_file_name = "harpylist.txt"
g:harpy_info_text = 'Harpylist path: ' .. g:harpy_file_name .. '.'

export def HarpySave(winid: number, option: number)
    var lines_to_write = [g:harpy_sel_idx] + g:harpy_valid_files + g:harpy_invalid_files
    writefile(lines_to_write, g:harpy_file_name)
enddef

# <TODO>
export def HarpyAddFileToList()
enddef

# <TODO>
export def HarpyRemoveFileFromList()
enddef

export def HarpyUpdate(winid: number)
    var curr_ = g:harpy_sel_idx
    var prev_ = max([0, curr_ - 1])
    var next_ = min([curr_ + 1, g:harpy_n_valid_files - 1])
    var filename = g:harpy_menu[curr_].text

    g:harpy_menu[prev_] = {text: g:harpy_menu[prev_].text}
    g:harpy_menu[next_] = {text: g:harpy_menu[next_].text}
    g:harpy_menu[curr_] = HarpyFormatString(filename, 'harpy_prop_selected_file')

    popup_settext(winid, g:harpy_menu)
enddef

export def HarpyKeyHandler(winid: number, key: string): any
    if key == '' || key == ''
        # have popup_filter_menu close the window
        return popup_filter_menu(winid, key)
    endif
    if g:harpy_n_valid_files == 0
        return true # returning true: nothing happens
    endif

    # <TODO> add other keys
    if key == 'j'
        g:harpy_sel_idx = min([
            g:harpy_sel_idx + 1,
            g:harpy_n_valid_files - 1
        ])
        HarpyUpdate(winid)
    endif
    if key == 'k'
        g:harpy_sel_idx = max([g:harpy_sel_idx - 1, 0])
        HarpyUpdate(winid)
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

export def HarpyCreateMenu(file_list: list<string>): any
    var found = []
    var not_found = []
    var sel_idx = str2nr(file_list[0])
    for file in file_list[1 : ]
        if filereadable(file)
            add(found, file)
        else
            add(not_found, file)
        endif
    endfor
    g:harpy_valid_files = found
    g:harpy_invalid_files = not_found

    g:harpy_n_valid_files = found->len()

    sel_idx = max([sel_idx, 0])
    sel_idx = min([sel_idx, g:harpy_n_valid_files - 1])

    g:harpy_sel_idx = sel_idx

    var menu_lines = []
    if g:harpy_n_valid_files == 0
        menu_lines += [{text: 'No valid files found!'}, {}]
    endif

    for [i, file] in items(found)
        if i == sel_idx
            add(menu_lines, HarpyFormatString(file, 'harpy_prop_selected_file'))
        else
            add(menu_lines, {text: file})
        endif
    endfor

    if g:harpy_n_valid_files > 0
        add(menu_lines, {})
    endif
    if not_found->len() > 0
        add(menu_lines, HarpyFormatString('Files not found: (D to clear list)', 'harpy_prop_file_not_found'))
        for badfile in not_found
            add(menu_lines, HarpyFormatString('- ' .. badfile, 'harpy_prop_file_not_found'))
        endfor
    endif

    menu_lines += [{}, {text: g:harpy_info_text}]
    return menu_lines
enddef

export def Harpy()
    g:harpy_file_list = readfile(g:harpy_file_name)
    g:harpy_menu = HarpyCreateMenu(g:harpy_file_list)
    g:harpy_winid = popup_create(g:harpy_menu, {
        title: ' harpy ',
        drag: 1,
        border: [],
        borderhighlight: ['Constant'],
        wrap: 0,
        padding: [1, 3, 1, 3], # U, R, D, L
        minwidth: 70,
        filter: 'HarpyKeyHandler',
        mapping: 0,
        callback: 'HarpySave'
    })
enddef

command Harpy Harpy()
nnoremap <silent> <leader>l :Harpy<cr>
