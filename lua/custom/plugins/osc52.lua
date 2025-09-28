return {
  'ojroques/nvim-osc52',
  config = function()
    require('osc52').setup {
      silent = true, -- no message on copy
    }

    -- Disable default clipboard integration
    vim.opt.clipboard = ''

    -- Hook up the system clipboard registers to osc52
    local function copy(lines, _)
      require('osc52').copy(table.concat(lines, '\n'))
    end
    local function paste()
      return { vim.fn.split(vim.fn.getreg '+', '\n'), vim.fn.getregtype '+' }
    end
    vim.g.clipboard = {
      name = 'osc52',
      copy = { ['+'] = copy, ['*'] = copy },
      paste = { ['+'] = paste, ['*'] = paste },
    }

    -- Optional: mappings for convenience
    vim.keymap.set('n', '<leader>y', '"+yy', { desc = 'Yank line to system clipboard' })
    vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Yank selection to system clipboard' })
  end,
}
