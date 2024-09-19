local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function pick_folder(opts, continuation)
  local shell_cmds = require("dotnet-plugin.shell_cmds")
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Folders",

    finder = finders.new_oneshot_job(shell_cmds.list_folders, {}),

    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()

        actions.close(prompt_bufnr)

        if selection then
          continuation(opts, selection)
        end
      end)
      return true
    end,
  }):find()
end

return pick_folder
