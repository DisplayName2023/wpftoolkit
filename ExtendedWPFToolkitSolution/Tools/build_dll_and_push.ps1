
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

# Use reflection to get the version from the DLL
if (Test-Path $mainDllFile) {
  $assembly = [System.Reflection.Assembly]::LoadFrom($mainDllFile)
  $version = $assembly.GetName().Version.ToString()
  Write-Host "DLL Version: $version"
} else {
  Write-Error "Main DLL not found at $mainDllFile"
  exit 1
}
# If $version has 4 parts and the last part is "0", trim to 3 parts
$versionParts = $version -split '\.'
if ($versionParts.Length -eq 4 -and $versionParts[3] -eq '0') {
  $version = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2])"
  Write-Host "Trimmed DLL Version: $version"
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