local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function command_list(opts)
  local commands = {}
  for key, value in pairs(require("dotnet-plugin")) do
    table.insert(commands, {name = key, command = value})
  end

  pickers.new(opts, {
    prompt_title = ".NET Command List",

    finder = finders.new_table({
      results = commands,

      entry_maker = function (entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
        }
      end
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()

        actions.close(prompt_bufnr)

        selection.value.command(opts)
      end)
      return true
    end,
  }):find()
end

return command_list

