local dotnet = require("dotnet-plugin")

return require("telescope").register_extension({
  exports = {
    ["dotnet-plugin"] = dotnet.plugin_command_list,
    command_list = dotnet.plugin_command_list,
    new_item = dotnet.dotnet_new_item,
    new_project = dotnet.dotnet_new_project,
    nuget_add = dotnet.dotnet_nuget_add,
    nuget_remove = dotnet.dotnet_nuget_remove,
    nuget_update = dotnet.dotnet_nuget_update,
    nuget_update_all = dotnet.dotnet_nuget_update_all,
    reference_add = dotnet.dotnet_reference_add,
    reference_remove = dotnet.dotnet_reference_remove,
    sln_project_add = dotnet.dotnet_sln_project_add,
    sln_project_remove = dotnet.dotnet_sln_project_remove,
  },
})
