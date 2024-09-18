local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local execute_commands  = require("dotnet-plugin.utils").exec_on_cmd_line

local function pick_missing_projects(opts, continuation)
  opts = opts or {}

  local existing_projects_command = "dotnet sln list" ..
    (vim.fn.has('win32') == 1 and
      " | Select-Object -Skip 2" or
      " | tail -n +3")

  local existing_projects = vim.fn.system(existing_projects_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local all_projects_command = vim.fn.has('win32') == 1 and
    "Get-ChildItem -Filter *.csproj -Recurse | ForEach-Object { Resolve-Path -Relative $_.FullName }" or
    "git ls-files | rg \\.csproj$"

  local all_projects = vim.fn.system(all_projects_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local existing_projects_set = {}
  for project in existing_projects:gmatch("[^\r\n]+") do
    existing_projects_set['.\\' .. project] = true
  end

  local missing_projects = {}
  for project in all_projects:gmatch("[^\r\n]+") do
    if not existing_projects_set[project] then
      table.insert(missing_projects, project)
    end
  end

  if not missing_projects or #missing_projects == 0 then
    print("No missing projects found.")
    return
  end

  pickers.new(opts, {
    prompt_title = "Projects not in Solution",

    finder = finders.new_table({
      results = missing_projects,
    }),

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

local function add_projects(_, projects)
  local commands = {}
  for _, entry in pairs(projects) do
    table.insert(commands, "dotnet sln add " .. entry.value)
  end
  execute_commands(commands)
end

return function (opts) pick_missing_projects(opts, add_projects) end

