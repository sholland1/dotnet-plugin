local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")
local execute_commands = utils.exec_on_cmd_line

local function pick_project_type(opts, continuation)
  opts = opts or {}

  local job_command = vim.fn.has('win32') == 1 and
    {"powershell.exe", "-c", "dotnet new list --type=project | Select-Object -Skip 4"} or
    {"sh", "-c", "dotnet new list --type=project | tail -n +5"}

  pickers.new(opts, {
    prompt_title = "New Project",

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

local function add_project(_, project)
  local project_name = vim.fn.input("Enter project name: ")
  if project_name == "" then
    vim.print("Project name cannot be empty.")
    return
  end

  local commands = {
    string.format("dotnet new %s -o %s", project.value.short_name, project_name),
    string.format("dotnet sln add %s/%s.csproj", project_name, project_name),
  }
  execute_commands(commands)
end

return function(opts) pick_project_type(opts, add_project) end

