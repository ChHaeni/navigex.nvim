
-- iterator over lines
local function iterlines(s)
        if s:sub(-1) ~= "\n" then s = s .. "\n" end
        return s:gmatch("(.-)\n")
end

-- find pattern in current buffer
function navigex_find(pattern)
    -- move to function argument
    local plain = false
    -- read content of current buffer
    local buf_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- prepare output
    local out = {}
    -- iterate over content
    local i = 0
    for k, line in pairs(buf_content) do
        -- match pattern? 
        s, e, m = line:find('(' .. pattern .. ')', 0, plain)
        if s ~= nil then
            i = i + 1
            out[i] = {
                row = k, 
                line = line, 
                index_start = s, 
                index_end = e, 
                match = m
            } 
        end
    end
    return out
end


function navigex(pattern)
    -- get current buffer number
    local bufnr = vim.fn.bufnr('%')
    -- get the current UI
    local ui = vim.api.nvim_list_uis()[1]
    -- create the scratch buffer displayed in the floating window
    local buf = vim.api.nvim_create_buf(false, true)
    -- get matches
    local matches = navigex_find(pattern)
    -- fill buffer with matches
    for i, line in pairs(matches) do
        vim.api.nvim_buf_set_lines(buf, i - 1, -1, false, {
            string.format('%3d', line.row) .. ': ' .. line.line
        })
        vim.api.nvim_buf_add_highlight(buf, 0, 'navigexMatch', i - 1, line.index_start + 4, line.index_end + 5)
    end
    -- define the size of the floating window
    local width = ui.width / 4 * 3
    local height = ui.height / 4 * 3
    -- create the floating window
    local opts = {
        relative = 'editor',
        width = math.ceil(width),
        height = math.ceil(height),
        col = math.ceil((ui.width / 2) - (width / 2)), 
        row = math.ceil((ui.height / 2) - (height / 2)), 
        anchor = 'NW',
        style = 'minimal'
        }
    local win = vim.api.nvim_open_win(buf, 1, opts)
end

--      add function to open new buffer with matched content
-- " https =//www.statox.fr/posts/2021/03/breaking_habits_floating_window/
-- function! Rhelp(text, ...) abort

--     " Create the scratch buffer displayed in the floating window
--     let buf = nvim_create_buf(v:false, v:true)

--     " Get the current UI
--     let ui = nvim_list_uis()[0]

--     " Define the size of the floating window
--     let width = ui.width / 4 * 3
--     let height = ui.height / 4 * 3

--     " call R help
--     if a:0 > 0
--         let packages = '\"' .. a:1 .. '\"'
--     else
--         let packages = 'dir(.libPaths())'
--     endif
--     let cmd = 'Rscript -e "help(\"' .. a:text .. '\", ' .. packages .. ')" | tr -d "_\b\r"'
--     let helptext = systemlist(cmd)

--     " check if multiple matches -> first line 'Help on topic ...'
--     let filetype = ''
--     if helptext[0] =~ "^Help on topic"
--         let line = 3
--         while v:true
--             let sub = line - 2 .. ':' .. substitute(helptext[line], '^\s*', ' ', '')
--             call nvim_buf_set_lines(buf, line - 3, -1, v:false, [sub])
--             " add mapping to select line by number
--             call nvim_buf_set_keymap(buf, 'n', string(line - 2), ':normal! ' .. string(line - 2) .. 'G<cr>', 
--                 \ {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--             let line = line + 1
--             if helptext[line] =~ "^\s*$"
--                 break
--             endif
--         endwhile
--         " add mapping to call <cr> with help & package
--         call nvim_buf_set_keymap(buf, 'n', '<cr>', ':call GetPackage()<cr>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--         " set buffer variable
--         call nvim_buf_set_var(buf, 'rhelp', a:text)
--         " set filetype
--         call nvim_buf_set_option(buf, 'filetype', 'rhelp_select')
--     else
--         " add all text (:h nvim_buf_set_lines())
--         call nvim_buf_set_lines(buf, 0, -1, v:false, helptext)
--         " set filetype
--         call nvim_buf_set_option(buf, 'filetype', 'rhelp_pages')
--         " add mapping to follow 'See Also'
--         call nvim_buf_set_keymap(buf, 'n', '<cr>', 'yiw :call Rhelp(@")<cr>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--     endif

--     " Set mappings in the buffer to close the window easily
--     " let closingKeys = ['<Esc>', '<CR>', '<Leader>']
--     let closingKeys = ['<Esc>', 'q']
--     for closingKey in closingKeys
--         call nvim_buf_set_keymap(buf, 'n', closingKey, ':close<CR>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--     endfor
--     " restore hjkl
--     call nvim_buf_set_keymap(buf, 'n', 'h', ':normal! h<cr>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--     call nvim_buf_set_keymap(buf, 'n', 'j', ':normal! j<cr>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--     call nvim_buf_set_keymap(buf, 'n', 'k', ':normal! k<cr>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
--     call nvim_buf_set_keymap(buf, 'n', 'l', ':normal! l<cr>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})

--     " Create the floating window
--     " :h nvim_open_win()
--     let opts = {'relative': 'editor',
--                 \ 'width': width,
--                 \ 'height': height,
--                 \ 'col': (ui.width/2) - (width/2),
--                 \ 'row': (ui.height/2) - (height/2),
--                 \ 'anchor': 'NW',
--                 \ 'style': 'minimal',
--                 \ }
--     let win = nvim_open_win(buf, 1, opts)
-- endfunction
