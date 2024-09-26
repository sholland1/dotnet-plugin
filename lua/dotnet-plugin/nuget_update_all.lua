local utils = require("dotnet-plugin.utils")

local update_all_packages = function()
  local shell_cmds = require("dotnet-plugin.shell_cmds")

  local result = vim.fn.system(shell_cmds.outdated_packages)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local json = vim.json.decode(result)
  local results = {}
  for _, project in ipairs(json.projects or {}) do
    for _, framework in ipairs(project.frameworks or {}) do
      for _, pkg in ipairs(framework.topLevelPackages or {}) do
        table.insert(results, {
          id = pkg.id,
          latestVersion = pkg.latestVersion,
          projectPath = string.format("'%s'", project.path),
        })
      end
    end
  end

  if not results or #results == 0 then
    print("No outdated packages found.")
    return
  end

  local commands = {}
  for _, entry in pairs(results) do
    local update_command = shell_cmds.update_package(
      entry.projectPath,
      entry.id,
      entry.latestVersion)
    table.insert(commands, update_command)
  end

  utils.execute_commands(commands)
end

return update_all_packages
