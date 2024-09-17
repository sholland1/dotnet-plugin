local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function pick_folder(opts, continuation)
  opts = opts or {}

  local job_command = vim.fn.has('win32') == 1 and
      {"powershell.exe", "-c", "git ls-files | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique"} or
      {"sh", "-c", "git ls-files | xargs -n1 dirname | sort -u"}

  pickers.new(opts, {
    prompt_title = "Folders",

    finder = finders.new_oneshot_job(job_command, {}),

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
