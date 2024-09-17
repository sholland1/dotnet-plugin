local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")
local execute_commands = utils.exec_on_cmd_line

local pick_projects = require("dotnet-plugin.project_picker")

local function pick_item_type(opts, continuation)
  opts = opts or {}

  local job_command = vim.fn.has('win32') == 1 and
    {"powershell.exe", "-c", "dotnet new list --type=item | Select-Object -Skip 4"} or
    {"sh", "-c", "dotnet new list --type=item | tail -n +5"}

  pickers.new(opts, {
    prompt_title = "New Item",

    finder = finders.new_oneshot_job(job_command, {
      entry_maker = function(entry)
        local columns = {}
        for _, col in pairs(utils.split_into_columns(entry)) do
          table.insert(columns, col)
        end
        local new_entry = {
          template_name = columns[1],
          short_name = columns[2],
          language = columns[3],
          tags = columns[4],
        }
        return {
          value = new_entry,
          display = entry,
          ordinal = new_entry.template_name,
        }
      end
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()

        actions.close(prompt_bufnr)

        continuation(opts, selection)
      end)
      return true
    end,
  }):find()
end

local function add_item_to_project(_, item, project)
  local item_name = vim.fn.input("Enter item name: ")
  if item_name == "" then
    vim.print("Item name cannot be empty.")
    return
  end

  local commands = {
    "pushd " .. vim.fn.fnamemodify(project.value, ":h"),
    "dotnet new " .. item.value.short_name .. " -n " .. item_name,
    "popd",
  }
  execute_commands(commands)
end

return function(opts)
  pick_item_type(opts,
    function(opts0, item)
      pick_projects(opts0,
        function(opts1, projects)
          add_item_to_project(opts1, item, projects[1])
        end)
    end)
end

