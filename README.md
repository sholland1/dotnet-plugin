# .NET Commands plugin

## Features

- [x] Nuget Packages - add, update, remove
- [x] Project References - add, remove
- [x] Projects in Solution - add, remove
- [x] Add new project from templates
- [x] Add new file from templates
- [x] Previews
- [x] List available commands
- [x] Powershell, sh
- [ ] Other nuget sources
- [x] Update all nuget packages command
- [ ] Add package, choose version
- [ ] Update single package, choose version
- [ ] New project, choose target framework
- [ ] New project, choose language
- [ ] Handle fsproj and vbproj

## Installation

### lazy.nvim
```lua
  {
    -- required config
    "sholland1/dotnet-plugin",
    dependencies = "nvim-telescope/telescope.nvim",

    -- optional config
    opts = {
      shell = vim.fn.has('win32') == 1 and "powershell" or "sh",
      --execute_with = "cmd_line",
      -- or
      --execute_with = "terminal",
    },
    keys = {
      {'<leader>.', '<cmd>Telescope dotnet-plugin theme=ivy<cr>', { desc = '.NET Command List' }},
    },
  },
```

## Options

| Name | Choices | Default | Description |
|------|---------|---------|-------------|
| shell | sh, powershell | sh | Specifies the shell to use for executing commands. |
| execute_with | cmd_line, terminal | cmd_line | Determines how commands are executed. (command line or terminal window) |

## Exports

The following lua functions are exported.

```lua
  -- declare desired telescope opts
  local telescope_opts = {}

  -- require the plugin
  local dotnet = require("dotnet-plugin")

  -- call a function
  dotnet.plugin_command_list(telescope_opts)
  dotnet.dotnet_new_item(telescope_opts)
  dotnet.dotnet_new_project(telescope_opts)
  dotnet.dotnet_nuget_add(telescope_opts)
  dotnet.dotnet_nuget_remove(telescope_opts)
  dotnet.dotnet_nuget_update(telescope_opts)
  dotnet.dotnet_nuget_update_all()
  dotnet.dotnet_reference_add(telescope_opts)
  dotnet.dotnet_reference_remove(telescope_opts)
  dotnet.dotnet_sln_project_add(telescope_opts)
  dotnet.dotnet_sln_project_remove(telescope_opts)
```

## Powershell configuration

To configure Neovim to use powershell instead of cmd on Windows, put the following in your Neovim config.
```lua
if vim.fn.has('win32') == 1 then
    vim.opt.shell = 'powershell'
    vim.opt.shellcmdflag = [[-NoLogo -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues['Out-File:Encoding']='utf8';]]
    vim.opt.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
    vim.opt.shellpipe  = '2>&1 | %%{ "$_" } | tee %s; exit $LastExitCode'
    vim.opt.shellquote = ''
    vim.opt.shellxquote = ''
end
```

## Dependencies

dotnet

### Linux shell commands
cd, curl, dirname, find, git ls-files, popd, pushd, realpath, sed, sort, tail, xargs

## Other .NET Neovim plugins

- [MoaidHathot/dotnet.nvim](https://github.com/MoaidHathot/dotnet.nvim)
- [GustavEikaas/easy-dotnet.nvim](https://github.com/GustavEikaas/easy-dotnet.nvim)
