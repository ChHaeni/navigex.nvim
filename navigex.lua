-- TODO:
--  - add hierarchical matching
--      -> also add mapping to jump to upper level?
--
-- arguments: tables with a) pattern to match b) replacement (\1 or entire line) c) highlighting color (or just highlight yes/no?)
-- CHECK -> non-matching group in lua?
-- TODO how are options set in a lua plugin?

-- TODO: 
--      - set cursor at current (latest) match

-- ideas from last night:
--  b) add ui argument (same way as options)
--  c) solve issue with returning entire line + highlighting vs. returning match only
--      -> provide option match_only? -> but what if group exists

-- global function
function navigex(pattern, options)
    Nav:navigate(pattern, options)
end

-- define class
Nav = {
    options = {
        line_numbers = true,
        list_symbol = {'a) ', 'b) ', 'c) ', 'd) '},
        highlighting_color = {"String", "Type", "Identifier", "Constant"},
        indentation = 2,
        trim_whitespace = false
    }
}

-- main function
function Nav:navigate(pattern, options)
    -- check options argument
    self:check_options(options)
    -- initialize patterns
    self:initalize_pattern(pattern)
    -- get matches
    self:find_pattern()
    -- populate ui
    self:populate_ui()
    -- add mappings
    self:buffer_mappings()
    -- build ui
    self:create_window()
    -- something to return?
end

-- check options
function Nav:check_options(opts)
    if not opts then
        return nil
    end
    for k, v in pairs(opts) do
        -- check if option exists
        if not self.options[k] then
            return nil, print("navigex: option " .. k .. " does not exist")
        end
        -- check type
        local expect = type(self.options[k])
        if not (type(v) == expect) then
            return nil, print("navigex: option " .. k .. ": expected " .. 
                expect .. ", got " .. type(v))
        end
        -- assign to options
        self.options[k] = v
    end
end

-- initialize patterns
function Nav:initalize_pattern(pattern)
    -- convert single pattern string to table
    if type(pattern) == "string" then
        pattern = {pattern}
    elseif type(pattern) ~= "table" then
        return nil, print("navigex: argument 'pattern': expected table or string, got " .. type(pattern))
    end
    -- remove indicator if only one level
    if #pattern == 1 then
        self.options.list_symbol = ''
    end
    -- loop over patterns and add options
    self.patterns = {}
    for i, t in ipairs(pattern) do
        self.patterns[i] = {}
        -- initialize pattern table
        for k, v in pairs(self.options) do
            if type(v) == "table" then
                local len = #v
                local ind = (i - 1) % len + 1
                self.patterns[i][k] = v[ind]
            elseif i == 1 and k == "indentation" then
                -- set first indent to 0 by default
                self.patterns[i][k] = 0
            else
                self.patterns[i][k] = v
            end
        end
        -- insert existing values
        if type(t) == "string" then
            self.patterns[i].pattern = t
        else
            for k, v in pairs(t) do
                -- recycle & add correct layer value
                if type(v) == "table" then
                    local len = #v
                    local ind = (i - 1) % len + 1
                    self.patterns[i][k] = v[ind]
                else
                    self.patterns[i][k] = v
                end
            end
        end
        -- check pattern argument
        if not self.patterns[i].pattern then
            return nil, print("navigex: 'pattern': expected string, got " .. type(self.patterns[i].pattern) ..
                " - did you forget to name the table entry 'pattern'?")
        elseif not (type(self.patterns[i].pattern) == "string") then 
            return nil, print("navigex: 'pattern': expected string, got " .. type(self.patterns[i].pattern))
        end
    end
    -- fix indentation & add highlighting group
    local indent = 0
    for i = 1, #self.patterns do
        -- indent
        indent = indent + self.patterns[i].indentation
        self.patterns[i].indentation = indent
        self.patterns[i].indent_string = string.rep(' ', indent)
        -- highlighting
        self.patterns[i].hi_group = "navigexMatch" .. i
    end
end

-- find pattern in current buffer
function Nav:find_pattern()
    -- TODO
    --  - add option to switch to vimscript regex instead of lua patterns?
    --      -> see https://neovim.io/doc/user/lua.html#lua-regex
    -- move to function argument
    local plain = false
    -- read content of current buffer
    local buf_content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- prepare output
    local out = {}
    -- iterate over content
    local i = 0
    for k, line in pairs(buf_content) do
        -- iterate over patterns
        for ip, tab in ipairs(self.patterns) do
            -- match pattern? 
            s, e, m = line:find(tab.pattern, 0, plain)
            if s ~= nil then
                -- create string to show
                -- trim whitespace (not used yet)
                -- add symbol and indentation to line
                local display_string = self.patterns[ip].indent_string .. self.patterns[ip].list_symbol .. line
                -- fix s & e -> what if group is provided?
                --  -> I guess that string.find provides s & e for entire match -> rerun find with m as pattern
                if m then
                    s, e, _ = line:find(m, 0, true)
                end
                -- add indentation to indices
                s = s + self.patterns[ip].indentation + #self.patterns[ip].list_symbol
                e = e + self.patterns[ip].indentation + #self.patterns[ip].list_symbol
                -- update index
                i = i + 1
                out[i] = {
                    -- we need: line number, string to show, highlighting start/end, level
                    row = k, 
                    display = display_string,
                    index_start = s, 
                    index_end = e,
                    level = ip
                } 
            end
        end
    end
    self.matches, self.max_row = out, out[i].row
end

-- populate ui
function Nav:populate_ui()
    -- create scratch buffer for floating window
    self.buffer_handle = vim.api.nvim_create_buf(false, true)
    -- get max row number to align after row numbers
    local digits = math.floor(math.log10(self.max_row)) + 1
    -- fill buffer with matches
    for i, line in pairs(self.matches) do
        if self.patterns[line.level].line_numbers then
            -- style 1: line number + line/match
            vim.api.nvim_buf_set_lines(self.buffer_handle, i - 1, -1, false, {
                string.format('%' .. digits .. 'd', line.row) .. ': ' .. line.display
            })
            vim.api.nvim_buf_add_highlight(self.buffer_handle, 0, 
                self.patterns[line.level].hi_group,
                -- 'navigexMatch',
                i - 1, line.index_start + digits + 1, line.index_end + digits + 2)
        else
            -- style 2: line/match only
            vim.api.nvim_buf_set_lines(self.buffer_handle, i - 1, -1, false, {
                line.display
            })
            vim.api.nvim_buf_add_highlight(self.buffer_handle, 0, 
                self.patterns[line.level].hi_group,
                i - 1, line.index_start - 1, line.index_end)
        end
    end
end

-- create window
function Nav:create_window()
    -- get the current UI
    local ui = vim.api.nvim_list_uis()[1]
    -- define the size of the floating window
    local wborder = 3
    local hborder = 1
    local width = math.ceil(ui.width * 0.45) - wborder
    local height = math.ceil(ui.height * 0.9) - 2 * hborder
    -- create the floating window
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = ui.width - width - wborder,
        row = hborder,
        anchor = 'NW',
        border = 'rounded'
        -- style = 'minimal'
        }
    local win = vim.api.nvim_open_win(self.buffer_handle, 1, opts)
    -- highlighting color (TODO: Add highlighting color as option)
    for i = 1, #self.patterns do
        vim.fn.win_execute(win, 'hi def link ' .. self.patterns[i].hi_group .. ' ' .. self.patterns[i].highlighting_color)
    end
    -- set nomodifiable
    vim.fn.win_execute(win, 'set nomodifiable')
end

-- buffer mappings
function Nav:buffer_mappings()
    -- TODO: add user defined keymappings -> how?
    --  - add mappings to:
    --      a) jump to line & close floating buffer
    --          -> call normal {line}G | :close
    -- get current buffer number
    local bufnr = vim.fn.bufnr('%')
    -- define mappings
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', 'q', ':close<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', '<esc>', ':close<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', '<cr>', ':lua Nav:centering_line(' .. bufnr .. ')<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', '<c-j>', 
        ':normal! j<cr><bar>:lua Nav:centering_line(' .. bufnr .. ')<cr>', {})
    vim.api.nvim_buf_set_keymap(self.buffer_handle, 'n', '<c-k>', 
        ':normal! k<cr><bar>:lua Nav:centering_line(' .. bufnr .. ')<cr>', {})
end

-- center current line (eventually transfer to vimscript?)
function Nav:centering_line(parent_buffer)
    local line = vim.fn.line('.')
    -- get match
    local m = self.matches[line]
    -- TODO: get row number from floating buffer
    vim.fn.win_execute(vim.fn.bufwinid(parent_buffer), 'normal ' .. m.row .. 'Gzz')
end
