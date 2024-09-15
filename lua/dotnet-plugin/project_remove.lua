local execute_commands  = require("dotnet-plugin.utils").exec_on_cmd_line
local pick_projects = require("dotnet-plugin.project_picker")

local function remove_projects(_, projects)
  local commands = {}
  for _, entry in pairs(projects) do
    table.insert(commands, "dotnet sln remove " .. entry.value)
  end
  execute_commands(commands)
end

return function (opts) pick_projects(opts, remove_projects) end

