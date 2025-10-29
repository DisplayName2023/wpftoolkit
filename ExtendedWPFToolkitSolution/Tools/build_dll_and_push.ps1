
Write-Host "Script Path: ${PSScriptRoot}"

$previousLocation = Get-Location

Set-Location -Path ${PSScriptRoot}

$solutionDir = "${PSScriptRoot}\.."
$solutionFile = "${solutionDir}\Xceed.Wpf.Toolkit.NET5.sln"

$nuget = "${PSScriptRoot}\nuget.exe"




$childFolders = Get-ChildItem -Path $solutionDir\Src -Directory
# Iterate over each child folder
foreach ($folder in $childFolders) {
  # Get the path of the bin\Release\ subfolder
  $releasePath = Join-Path -Path $folder.FullName -ChildPath "bin\Release"
  # Check if the subfolder exists
  if (Test-Path -Path $releasePath) {
    # Get all the .nupkg files in the subfolder
    $nupkgFiles = Get-ChildItem -Path $releasePath -Filter "*.nupkg"
    # Iterate over each .nupkg file
    foreach ($file in $nupkgFiles) {
      # Delete the file
      Remove-Item -Path $file.FullName
    }
  }
}


&dotnet build $solutionFile --configuration Release 

$mainDllFile = "${solutionDir}\Src\Xceed.Wpf.Toolkit\bin\Release\net8.0-windows\Xceed.Wpf.Toolkit.dll"

# use reflection to get the version of the main dll
$assembly = [System.Reflection.Assembly]::LoadFile($mainDllFile)
$version = $assembly.GetName().Version.ToString()
Write-Host "Extracted DLL Version: $version"

if ($false)
{
  # Extract BaseVersion from AssemblyVersionInfo.cs
  $assemblyInfoPath = "${solutionDir}\Src\Xceed.Wpf.Toolkit\AssemblyVersionInfo.cs"
  $baseVersionLine = Get-Content $assemblyInfoPath | Where-Object { $_ -match 'public const string BaseVersion' }
  if ($baseVersionLine -match '"([0-9]+\.[0-9]+)"') {
    $version = $matches[1] + ".0"
    Write-Host "Extracted BaseVersion: $version"
  } else {
    Write-Error "Could not extract BaseVersion from $assemblyInfoPath"
    exit 1
  }
}



&dotnet pack $solutionFile --configuration Release -p:PackageVersion=$version

# Iterate over each child folder
foreach ($folder in $childFolders) {
  # Get the path of the bin\Release\ subfolder
  $releasePath = Join-Path -Path $folder.FullName -ChildPath "bin\Release"
  # Check if the subfolder exists
  if (Test-Path -Path $releasePath) {
    # Get all the .nupkg files in the subfolder
    $nupkgFiles = Get-ChildItem -Path $releasePath -Filter "*$version.nupkg" -Recurse
    # Iterate over each .nupkg file
    foreach ($file in $nupkgFiles) {
      # Upload the file, but need high version of Gitlab to use dotnet cli with API key
      # &dotnet nuget push $file.FullName --source Gitlab

      if ($file.FullName -like "*LiveExplorer*") {
        Write-Host "Skipping LiveExplorer package upload: $($file.FullName)"
        continue
      }

      # check file.FuleName is not null
      if ([string]::IsNullOrWhiteSpace($file.FullName) -or $file.FullName.Length -eq 0) {
        Write-Error "File.FullName is null or empty"
        continue
      }
      
      # Upload the file with NuGet.exe
      & $nuget push $file.FullName -Source Gitlab
    }
  }
}



Set-Location -Path ${previousLocation}