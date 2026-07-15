-- C/C++ helpers:
-- 1) Expand/continue /* */ blocks with correct indent
-- 2) Expand {|} (|) [|] on <CR> with correct indent (pure Lua — no key garbage)
-- 3) Prefer cindent over treesitter indent

local PAIRS = {
  ['{'] = '}',
  ['('] = ')',
  ['['] = ']',
}

local function line_indent_before_star(line)
  if line:match '^%s*/%*' or line:match '^%s*%*/' then
    return nil
  end
  return line:match '^(%s*)%*%s' or line:match '^(%s*)%*$'
end

local function expand_open_block()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)

  if not before:match '/%*%s*$' then
    return false
  end
  if not after:match '^%s*%*/' then
    return false
  end

  local indent = line:match '^(%s*)' or ''
  if after:sub(1, 2) == '*/' then
    after = after:sub(3)
  elseif after:match '^%s*%*/' then
    after = after:gsub('^%s*%*/', '', 1)
  end

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
    before,
    indent .. ' * ',
    indent .. ' */' .. after,
  })
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent + 3 })
  return true
end

local function continue_middle_block()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local indent = line_indent_before_star(line)
  if not indent then
    return false
  end

  local before = line:sub(1, col)
  local after = line:sub(col + 1):gsub('^%s*', '')

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
    before,
    indent .. '* ' .. after,
  })
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent + 2 })
  return true
end

-- Expand {|} / (|) / [|] into:
-- {
--     |
-- }
local function expand_brace_pair()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  if col < 1 then
    return false
  end

  local open = line:sub(col, col)
  local close = PAIRS[open]
  if not close then
    return false
  end
  if line:sub(col + 1, col + 1) ~= close then
    return false
  end

  local before = line:sub(1, col)
  local after = line:sub(col + 1) -- starts with closing pair
  local indent = line:match '^(%s*)' or ''
  local sw = vim.fn.shiftwidth()
  local mid = indent .. string.rep(' ', sw)

  vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
    before,
    mid,
    indent .. after,
  })
  vim.api.nvim_win_set_cursor(0, { row + 1, #mid })
  return true
end

function _G.__c_cr_handle()
  if expand_open_block() or continue_middle_block() or expand_brace_pair() then
    return
  end
  -- Plain newline + let cindent fix the new line
  local keys = vim.api.nvim_replace_termcodes('<CR>', true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end

local function should_special_cr()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)

  if before:match '/%*%s*$' and after:match '^%s*%*/' then
    return true
  end
  if line_indent_before_star(line) then
    return true
  end
  if col >= 1 then
    local open = line:sub(col, col)
    local close = PAIRS[open]
    if close and line:sub(col + 1, col + 1) == close then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp', 'h' },
  callback = function()
    vim.opt_local.formatoptions:append 'ro'
    vim.opt_local.comments = 'sO:* -,mO:*  ,exO:*/,s1:/*,mb:*,ex:*/,://'
    vim.bo.cindent = true

    -- Non-expr map: all buffer edits are legal (no E565, no keycode garbage)
    vim.keymap.set('i', '<CR>', function()
      if should_special_cr() then
        _G.__c_cr_handle()
        return
      end
      -- Normal Enter; cindent reindents the new line (if/for/while bodies)
      local keys = vim.api.nvim_replace_termcodes('<CR>', true, false, true)
      vim.api.nvim_feedkeys(keys, 'n', false)
    end, {
      buffer = true,
      desc = 'C-aware Enter (comments, braces, cindent)',
    })
  end,
})

return {}
