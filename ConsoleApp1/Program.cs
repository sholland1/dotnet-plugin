using MoreLinq;

string[] items = ["hello", "world", "dotnet", "plugin"];
var result = items.ToDelimitedString(", ");
Console.WriteLine(result);
