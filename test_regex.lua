
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
    print(vim.inspect(pattern))
    -- iterate over content
    for k, line in pairs(buf_content) do
        -- match pattern? 
        s, e, m = line:find('(' .. pattern .. ')', 0, plain)
        if s ~= nil then
            print('here we go!!!!')
            print(k .. ': ' .. s .. '/' .. e .. ' = ' .. m)
        end
    end
end

-- TODO: 
--      fill table with matched content
--      add function to open new buffer with matched content
