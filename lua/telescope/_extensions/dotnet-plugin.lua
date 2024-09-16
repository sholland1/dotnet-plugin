return require("telescope").register_extension({
  exports = {
    ["dotnet-plugin"] = require("dotnet-plugin").plugin_command_list,
    dotnet_command_list = require("dotnet-plugin").plugin_command_list,
  },
})
