-- TODO:
--  - add mappings to:
--      a) jump to line & close floating buffer
--          -> call normal {line}G | :close
--      b) align buffer to current line (without closing floating window)
--          -> call normal {line}G 
--  - add option to switch to vimscript regex instead of lua patterns?

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
    -- TODO: get max row number -> get floor(log10(max)) digits
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
