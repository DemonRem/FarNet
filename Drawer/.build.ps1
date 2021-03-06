
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

param(
	$Platform = (property Platform x64)
)
$FarHome = "C:\Bin\Far\$Platform"
$ModuleHome = "$FarHome\FarNet\Modules\Drawer"

task . Build, Clean

# Build and install
task Build {
	Set-Alias MSBuild (Resolve-MSBuild)
	exec { MSBuild Drawer.csproj /p:Configuration=Release /p:FarHome=$FarHome }
}

# New About-Drawer.htm
task Help {
	exec { MarkdownToHtml "From = About-Drawer.text; To = About-Drawer.htm" }
}

task Clean {
	remove z, bin, obj, About-Drawer.htm, FarNet.Drawer.*.nupkg
}

task Version {
	$dll = Get-Item -LiteralPath $ModuleHome\Drawer.dll
	assert ($dll.VersionInfo.FileVersion -match '^(\d+\.\d+\.\d+)\.0$')
	($script:Version = $matches[1])
}

task Package Help, {
	$toModule = 'z\tools\FarHome\FarNet\Modules\Drawer'

	remove z
	$null = mkdir $toModule

	Copy-Item -Destination $toModule `
	About-Drawer.htm,
	History.txt,
	LICENSE.txt,
	$ModuleHome\Drawer.dll
}

task NuGet Package, Version, {
	$text = @'
Drawer is the FarNet module for Far Manager.

It provides a few editor color tools (drawers).

---

To install FarNet packages, follow these steps:

https://raw.githubusercontent.com/nightroman/FarNet/master/Install-FarNet.en.txt

---
'@
	# nuspec
	Set-Content z\Package.nuspec @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata>
		<id>FarNet.Drawer</id>
		<version>$Version</version>
		<owners>Roman Kuzmin</owners>
		<authors>Roman Kuzmin</authors>
		<projectUrl>https://github.com/nightroman/FarNet</projectUrl>
		<iconUrl>https://raw.githubusercontent.com/wiki/nightroman/FarNet/images/FarNetLogo.png</iconUrl>
		<licenseUrl>https://raw.githubusercontent.com/nightroman/FarNet/master/Drawer/LICENSE.txt</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<summary>$text</summary>
		<description>$text</description>
		<releaseNotes>https://raw.githubusercontent.com/nightroman/FarNet/master/Drawer/History.txt</releaseNotes>
		<tags>FarManager FarNet Module</tags>
	</metadata>
</package>
"@
	# pack
	exec { NuGet pack z\Package.nuspec -NoPackageAnalysis }
}
