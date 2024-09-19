local config = require("dotnet-plugin").config

return {
  projects = "dotnet sln list" ..
    (config.shell == "powershell" and
      " | Select-Object -Skip 2" or
      " | tail -n +3 | sed 's/\\\\/\\//g'"),

  references = function(project)
    return string.format("dotnet list %s reference", project) ..
      (config.shell == "powershell" and
        " | Select-Object -Skip 2" or
        " | tail -n +3 | sed 's/\\\\/\\//g'")
  end,

  remove_reference = function(project, reference)
    return string.format("dotnet remove %s reference %s", project, reference)
  end,

  restore = "dotnet restore",

  existing_references = function (project)
    return string.format(
      config.shell == "powershell" and
        "cd %s; (dotnet list %s reference | Select-Object -Skip 2 | ForEach-Object { Resolve-Path $_ }).Path" or
        "cd %s && dotnet list %s reference | tail -n +3 | sed 's/\\\\/\\//g' | xargs -r realpath",
      vim.fn.fnamemodify(project, ":h"),
      vim.fn.fnamemodify(project, ":t"))
  end,

  existing_projects = "dotnet sln list" ..
    (config.shell == "powershell" and
      " | Select-Object -Skip 2" or
      " | tail -n +3"),

  add_reference = function(project, reference)
    return string.format("dotnet add %s reference %s", project, reference)
  end,

  fixed_existing_projects = "dotnet sln list" ..
    (config.shell == "powershell" and
      " | Select-Object -Skip 2 | ForEach-Object { '.\\' + $_ }" or
      " | tail -n +3"),

  all_projects = config.shell == "powershell" and
    "Get-ChildItem -Filter *.csproj -Recurse | ForEach-Object { Resolve-Path -Relative $_.FullName }" or
    "find . -name '*.csproj' -type f | sed 's|^./||'",

  add_project = function(project) return "dotnet sln add " .. project end,

  outdated_packages = "dotnet list package --outdated --format=json",
  installed_packages = "dotnet list package --format=json",

  nuget_api_query = function(query)
    local url = "https://azuresearch-usnc.nuget.org/query\\?q\\="
    return string.format(
      config.shell == "powershell" and
      "Invoke-RestMethod -Uri '%s%s' | ConvertTo-Json" or
      "curl -s %s%s",
      url, query)
  end,

  update_package = function(project_path, package_name, version)
    return string.format(
      "dotnet add %s package %s --version %s",
      project_path, package_name, version)
  end,

  remove_package = function(project_path, package_name)
    return string.format(
      "dotnet remove %s package %s",
      project_path, package_name)
  end,

  add_package = function(project_path, package_name)
    return string.format(
      "dotnet add %s package %s",
      project_path, package_name)
  end,

  list_item = config.shell == "powershell" and
    {"powershell.exe", "-c", "dotnet new list --type=item | Select-Object -Skip 4"} or
    {"sh", "-c", "dotnet new list --type=item | tail -n +5"},

  list_project = config.shell == "powershell" and
    {"powershell.exe", "-c", "dotnet new list --type=project | Select-Object -Skip 4"} or
    {"sh", "-c", "dotnet new list --type=project | tail -n +5"},

  pushd = function(dir) return "pushd " .. dir end,
  popd = "popd",

  add_new_item = function(item_type, item_name)
    return string.format("dotnet new %s -n %s", item_type, item_name)
  end,

  add_new_project = function(project_type, project_name)
    return string.format("dotnet new %s -o %s", project_type, project_name)
  end,

  projects2 = config.shell == "powershell" and
    {"powershell.exe", "-c", "dotnet sln list | Select-Object -Skip 2"} or
    {"sh", "-c", "dotnet sln list | tail -n +3"},

  list_folders = config.shell == "powershell" and
    {"powershell.exe", "-c", "git ls-files | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique"} or
    {"sh", "-c", "git ls-files | xargs -n1 dirname | sort -u"},

  project_remove = function(project) return "dotnet sln remove " .. project end,
}
