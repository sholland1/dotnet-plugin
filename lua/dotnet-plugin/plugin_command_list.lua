local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local commands = {
  {
    name = "Plugin Command List",
    command = nil, -- Set below
    shell_commands = {"[No shell commands]"},
    description = "List of commands available for this plugin",
  },

  {
    name = ".NET New Item",
    command = require("dotnet-plugin.new_item"),
    shell_commands = {"dotnet new list --type=item", "git ls-files", "dotnet new <item template> -n <item name>"},
    description = "Add a new item to a project from the list of installed templates",
  },

  {
    name = ".NET New Project",
    command = require("dotnet-plugin.new_project"),
    shell_commands = {"dotnet new list --type=project", "dotnet new <project template> -n <project name>", "dotnet sln add <project file path>"},
    description = "Add a new project to a solution from the list of installed templates",
  },

  {
    name = ".NET Add Nuget Packages",
    command = require("dotnet-plugin.nuget_add"),
    shell_commands = {"curl -s <nuget url>?q=<package query>", "dotnet sln list", "dotnet add <project name> package <package name>"},
    description = "Search for Nuget packages to add to a project",
  },

  {
    name = ".NET Remove Nuget Packages",
    command = require("dotnet-plugin.nuget_remove"),
    shell_commands = {"dotnet list package", "dotnet remove <project name> package <package name>"},
    description = "Remove installed Nuget packages from projects",
  },

  {
    name = ".NET Update Nuget Packages",
    command = require("dotnet-plugin.nuget_update"),
    shell_commands = {"dotnet list package --outdated", "dotnet add <project name> package <package name> --version <package version>"},
    description = "Update installed Nuget packages",
  },

  {
    name = ".NET Add Project References",
    command = require("dotnet-plugin.reference_add"),
    shell_commands = {"dotnet sln list", "dotnet list %s reference", "dotnet add <project name> reference <reference name>", "dotnet restore"},
    description = "Add project references to a project",
  },

  {
    name = ".NET Remove Project References",
    command = require("dotnet-plugin.reference_remove"),
    shell_commands = {"dotnet sln list", "dotnet list %s reference", "dotnet remove <project name> reference <reference name>", "dotnet restore"},
    description = "Remove project references from projects",
  },

  {
    name = ".NET Add Projects to Solution",
    command = require("dotnet-plugin.project_add"),
    shell_commands = {"dotnet sln list", "find . -name '*.csproj' -type f", "dotnet sln add <project path>"},
    description = "Add projects to solution",
  },

  {
    name = ".NET Remove Projects from Solution",
    command = require("dotnet-plugin.project_remove"),
    shell_commands = {"dotnet sln list", "dotnet sln remove <project path>"},
    description = "Remove projects from solution",
  },
}

local function command_list(opts)
  -- Calculate max widths for each property
  local max_widths = {
    name = 0,
    description = 0,
  }
  for _, entry in ipairs(commands) do
    max_widths.name = math.max(max_widths.name, #entry.name)
    max_widths.description = math.max(max_widths.description, #entry.description)
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = max_widths.name },
      { width = max_widths.description },
    },
  })
  pickers.new(opts, {
    prompt_title = "Commands",

    finder = finders.new_table({
      results = commands,

      entry_maker = function(entry)
        return {
          value = entry,
          display = function (ntry)
            return displayer({
              ntry.value.name,
              ntry.value.description,
            })
          end,
          ordinal = entry.name,
        }
      end,
    }),

    sorter = conf.generic_sorter(opts),

    previewer = previewers.new_buffer_previewer({
      title = "Shell Commands",
      define_preview = function(self, entry, _)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.shell_commands)
      end,
    }),

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

commands[1].command = command_list

return command_list

