-- TODO:
--  - add mappings to:
--      a) jump to line & close floating buffer
--          -> call normal {line}G | :close
--      b) align buffer to current line (without closing floating window)
--          -> call normal {line}G 
--  - add option to switch to vimscript regex instead of lua patterns?
--      -> see https://neovim.io/doc/user/lua.html#lua-regex
--  - add option to add line numbers
--  - add hierarchical matching
--      -> add option to provide several patterns
--      -> also add mapping to jump to upper level?
--
-- arguments: tables with a) pattern to match b) replacement (\1 or entire line) c) highlighting color (or just highlight yes/no?)

-- what pattern types should be made available?
-- 1) pattern without group -> e.g. function -> highlight function
-- 2) pattern with group -> e.g. section -> highlight section title (match)

-- global function
function navigex(pattern)
    Nav:navigate(pattern)
end

-- define class
Nav = {}

-- main function
function Nav:navigate(pattern)
    -- get matches
    self.matches = self:find_pattern(pattern)
    -- create scratch buffer for floating window
    self.buffer_handle = vim.api.nvim_create_buf(false, true)
    -- populate ui
    self:populate_ui()
    -- add mappings
    self:buffer_mappings()
    -- build ui
    self:create_window()
    -- something to return?
end

-- find pattern in current buffer
function Nav:find_pattern(pattern)
    -- move to function argument
    local plain = false
    -- read content of current buffer
    local buf_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- prepare output
    local out = {}
    -- iterate over content
    local i = 0
    local max = 0
    for k, line in pairs(buf_content) do
        -- match pattern? 
        s, e, m = line:find(pattern, 0, plain)
        if s ~= nil then
            i = i + 1
            out[i] = {
                row = k, 
                line = line, 
                index_start = s, 
                index_end = e, 
                match = m or line
            } 
        end
    end
    return {table = out, max = out[i].row}
end

-- create window
function Nav:create_window()
    -- get the current UI
    local ui = vim.api.nvim_list_uis()[1]
    -- define the size of the floating window
    local width = math.ceil(ui.width / 2)
    -- local height = ui.height / 2
    -- create the floating window
    local opts = {
        relative = 'editor',
        width = width,
        height = ui.height,
        col = ui.width - width,
        row = 0,
        anchor = 'NW',
        style = 'minimal'
        }
    local win = vim.api.nvim_open_win(self.buffer_handle, 1, opts)
    -- highlighting color (TODO: Add highlighting color as option)
    vim.fn.win_execute(win, 'hi def link navigexMatch GruvboxOrangeBold')
end

-- buffer mappings
function Nav:buffer_mappings()
    -- get current buffer number
    local bufnr = vim.fn.bufnr('%')
    -- define mappings
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', 'q', ':close<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', '<esc>', ':close<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', '<cr>', ':lua Nav:centering_line(' .. bufnr .. ')<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', 'h', ':normal! h<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', 'j', ':normal! j<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', 'k', ':normal! k<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', 'l', ':normal! l<cr>', {})
end

-- populate ui
function Nav:populate_ui()
    -- TODO: get max row number -> get floor(log10(max)) digits
    local digits = math.floor(math.log10(self.matches.max)) + 1
    -- fill buffer with matches
    -- style 1: row + line
    -- style 2: match only (with a centered dot as prefix?)
    -- for i, line in pairs(self.matches.table) do
    --     vim.api.nvim_buf_set_lines(self.buffer_handle, i - 1, -1, false, {
    --         string.format('%' .. digits .. 'd', line.row) .. ': ' .. line.line
    --     })
    --     vim.api.nvim_buf_add_highlight(self.buffer_handle, 0, 'navigexMatch', i - 1, 
    --         line.index_start + digits + 1, line.index_end + digits + 2)
    -- end
    for i, line in pairs(self.matches.table) do
        vim.api.nvim_buf_set_lines(self.buffer_handle, i - 1, -1, false, {
            '- ' .. line.match
        })
        vim.api.nvim_buf_add_highlight(self.buffer_handle, 0, 'navigexMatch', i - 1, 
            line.index_start + 1, line.index_end + 2)
    end
end

-- center current line (eventually transfer to vimscript?)
function Nav:centering_line(parent_buffer)
    local line = vim.fn.line('.')
    -- get match
    local m = self.matches.table[line]
    -- TODO: get row number from floating buffer
    vim.fn.win_execute(vim.fn.bufwinid(parent_buffer), 'normal ' .. m.row .. 'Gzz')
end
