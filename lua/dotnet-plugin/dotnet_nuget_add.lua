local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")
local execute_commands = utils.exec_on_cmd_line

local function pick_project(opts, continuation)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Choose a project",

    finder = finders.new_table({
      results = utils.get_projects(),
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        if vim.tbl_isempty(multi) then
          multi = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        continuation(opts, multi)
      end)
      return true
    end,
  }):find()
end

local function select_nuget_package(opts, continuation)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Choose a nuget package to add",

    finder = finders.new_dynamic({
      fn = function(prompt)
        local url = "https://azuresearch-usnc.nuget.org/autocomplete?q="
        local nuget_search_command = string.format("curl -s %s%s", url, prompt)


        local handle = io.popen(nuget_search_command)
        if handle == nil then
          print("Failed to execute shell command.")
          return
        end

        local result = handle:read("*a")
        handle:close()

        local json = vim.json.decode(result)
        local packages = json.data

        return packages
      end,

      entry_maker = function (entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function (prompt_bufnr, _)
      actions.select_default:replace(function ()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        if vim.tbl_isempty(multi) then
          multi = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        continuation(opts, multi)
      end)
      return true
    end,
  }):find()
end

local function add_packages(packages, projects)
  local commands = {}
  for _, pkg in pairs(packages or {}) do
    for _, proj in pairs(projects or {}) do
      local update_command = string.format(
        "dotnet add %s package %s",
        proj.value, pkg.value)
      table.insert(commands, update_command)
    end
  end

  execute_commands(commands)
end

return function (opts)
  select_nuget_package(opts,
    function(opts0, packages) pick_project(opts0,
      function(_, projects) add_packages(packages, projects) end) end)
end

