local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local pick_projects = require("dotnet-plugin.project_picker")
local execute_commands  = require("dotnet-plugin.utils").exec_on_cmd_line

local function pick_reference_to_add(opts, selection)
  opts = opts or {}

  local project = selection[1].value

  local existing_references_command =
    string.format(
      vim.fn.has('win32') == 1 and
        "cd %s; (dotnet list %s reference | Select-Object -Skip 2 | ForEach-Object { Resolve-Path $_ }).Path" or
        "cd %s && dotnet list %s reference | tail -n +3 | sed 's/\\\\/\\//g' | xargs -r realpath",
      vim.fn.fnamemodify(project, ":h"),
      vim.fn.fnamemodify(project, ":t"))

  local existing_references = vim.fn.system(existing_references_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local existing_projects_command = "dotnet sln list" ..
    (vim.fn.has('win32') == 1 and
      " | Select-Object -Skip 2" or
      " | tail -n +3")

  local existing_projects = vim.fn.system(existing_projects_command)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local existing_references_set = {}
  for reference in existing_references:gmatch("[^\r\n]+") do
    reference = vim.fn.fnamemodify(reference, ":p")
    existing_references_set[reference] = true
  end
  local temp = vim.fn.fnamemodify(project, ":p")
  existing_references_set[temp] = true

  local unreferenced_projects = {}
  for proj in existing_projects:gmatch("[^\r\n]+") do
    if not existing_references_set[vim.fn.fnamemodify(proj, ":p")] then
      table.insert(unreferenced_projects, proj)
    end
  end

  if not unreferenced_projects or #unreferenced_projects == 0 then
    print("No unreferenced projects found.")
    return
  end

  pickers.new(opts, {
    prompt_title = "Unreferenced Projects",

    finder = finders.new_table({
      results = unreferenced_projects,
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

        local commands = {}
        for _, entry in pairs(selections) do
          table.insert(commands, string.format("dotnet add %s reference %s", project, entry.value))
        end
        table.insert(commands, "dotnet restore")

        execute_commands(commands)
      end)
      return true
    end,
  }):find()
end

return function (opts) pick_projects(opts, pick_reference_to_add) end

