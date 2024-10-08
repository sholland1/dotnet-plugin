local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")
local pick_projects = require("dotnet-plugin.project_picker")

local function select_nuget_package(opts, continuation)
  local shell_cmds = require("dotnet-plugin.shell_cmds")
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Choose a nuget package to add",

    finder = finders.new_dynamic({
      fn = function(prompt)
        local result = vim.fn.system(shell_cmds.nuget_api_query(prompt))
        if vim.v.shell_error ~= 0 then
          print("Failed to execute shell command.")
          return
        end

        local json = vim.json.decode(result)
        local packages = json.data

        return packages
      end,

      entry_maker = function (entry)
        return {
          value = entry,
          display = entry.id,
          ordinal = entry.id,
        }
      end
    }),

    sorter = conf.generic_sorter(opts),

    previewer = previewers.new_buffer_previewer({
      title = "Nuget Package Preview",
      define_preview = function (self, entry)
        local bufLines = {
          "Name: " .. (entry.value.id or ""),
          "Author: " .. ((entry.value.authors or {""})[1] or ""),
          "Latest Version: " .. (entry.value.version or ""),
          "Total Downloads: " .. utils.format_number(entry.value.totalDownloads),
          "Description:"
        }
        local description_lines = vim.split(entry.value.description or "", "\n")
        for _, line in ipairs(description_lines) do
            table.insert(bufLines, line)
        end

        vim.api.nvim_buf_set_option(self.state.bufnr, 'wrap', true)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, bufLines)
      end,
    }),

    attach_mappings = function (prompt_bufnr, _)
      actions.select_default:replace(function ()
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

local function add_packages(packages, projects)
  local shell_cmds = require("dotnet-plugin.shell_cmds")
  local commands = {}
  for _, pkg in pairs(packages or {}) do
    for _, proj in pairs(projects or {}) do
      local add_command = shell_cmds.add_package(proj.value, pkg.value.id)
      table.insert(commands, add_command)
    end
  end

  utils.execute_commands(commands)
end

return function (opts)
  select_nuget_package(opts,
    function(opts0, packages) pick_projects(opts0,
      function(_, projects) add_packages(packages, projects) end) end)
end

