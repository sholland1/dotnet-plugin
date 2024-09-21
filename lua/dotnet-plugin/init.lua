local M = {}

local default_config = {
  shell = "sh",
  execute_with = "cmd_line",
}

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
  require('telescope').load_extension("dotnet-plugin")
end

M.plugin_command_list = require("dotnet-plugin.plugin_command_list")
M.dotnet_new_item = require("dotnet-plugin.new_item")
M.dotnet_new_project = require("dotnet-plugin.new_project")
M.dotnet_nuget_add = require("dotnet-plugin.nuget_add")
M.dotnet_nuget_remove = require("dotnet-plugin.nuget_remove")
M.dotnet_nuget_update = require("dotnet-plugin.nuget_update")
M.dotnet_nuget_update_all = require("dotnet-plugin.nuget_update_all")
M.dotnet_reference_add = require("dotnet-plugin.reference_add")
M.dotnet_reference_remove = require("dotnet-plugin.reference_remove")
M.dotnet_sln_project_add = require("dotnet-plugin.project_add")
M.dotnet_sln_project_remove = require("dotnet-plugin.project_remove")

return M
