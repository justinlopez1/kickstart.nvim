-- autopairs
-- https://github.com/windwp/nvim-autopairs
--
-- Block-comment Enter expansion for C lives in lua/custom/plugins/c_commands.lua
-- so indent is preserved (treesitter indent was fighting a key-sequence approach).

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    local npairs = require 'nvim-autopairs'
    local Rule = require 'nvim-autopairs.rule'

    npairs.setup {}

    -- Pair /* with */; <CR> handling is buffer-local in c_commands.lua
    npairs.add_rules {
      Rule('/*', '*/', { 'c', 'cpp', 'h' }),
    }
  end,
}
