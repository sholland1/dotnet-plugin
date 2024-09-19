local utils  = require("dotnet-plugin.utils")
local pick_projects = require("dotnet-plugin.project_picker")

local function remove_projects(_, projects)
  local shell_cmds = require("dotnet-plugin.shell_cmds")
  local commands = {}
  for _, entry in pairs(projects) do
    table.insert(commands, shell_cmds.project_remove(entry.value))
  end
  utils.execute_commands(commands)
end

return function (opts) pick_projects(opts, remove_projects) end

