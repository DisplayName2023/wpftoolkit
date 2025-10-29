$msbuild = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
               -latest -products * -requires Microsoft.Component.MSBuild `
               -find MSBuild\**\Bin\MSBuild.exe
$msbuild