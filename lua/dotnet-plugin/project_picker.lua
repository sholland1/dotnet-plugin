local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function pick_projects(opts, continuation)
  opts = opts or {}

  local job_command = vim.fn.has('win32') and
    {"powershell.exe", "-c", "dotnet sln list | Select-Object -Skip 2"} or
    {"sh", "-c", "dotnet sln list | tail -n +3"}

  pickers.new(opts, {
    prompt_title = "Projects",

    finder = finders.new_oneshot_job(job_command, {}),

    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          selections = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        continuation(opts, selections)
      end)
      return true
    end,
  }):find()
end

return pick_projects
