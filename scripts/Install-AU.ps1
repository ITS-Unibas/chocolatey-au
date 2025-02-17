<#
    Intall AU from git repository using given version. Can also be used to install development branches.
    Git tags are treated as autoritative AU release source.

    This script is used for build server.
#>

[CmdletBinding()]
param(
    # If parsable to [version], exact AU version will be installed. Example:  '2016.10.30'
    # If not parsable to [version] it is assumed to be name of the AU git branch. Example: 'master'
    # If empty string or $null, latest release (git tag) will be installed.
    [string] $Version
)

$ErrorActionPreference = 'STOP'
$git_url = 'https://github.com/ITS-Unibas/chocolatey-au.git'

if (!(Get-Command git -ea 0)) { throw 'Git must be installed' }
[version]$git_version = (git --version) -replace 'git|version|\.windows'
if ($git_version -lt [version]2.5) { throw 'Git version must be higher then 2.5' }

$is_latest = [string]::IsNullOrWhiteSpace($Version)
$is_branch = !($is_latest -or [version]::TryParse($Version, [ref]($_)))

Push-Location $PSScriptRoot\..

if ($is_latest) { $Version = (git tag | ForEach-Object { [version]$_ } | Sort-Object -desc | Select-Object -first 1).ToString() }
if ($is_branch) {
    $branches = git branch -r -q | ForEach-Object { $_.Replace('origin/','').Trim() }
    if ($branches -notcontains $Version) { throw "Chocolatey-AU branch '$Version' doesn't exist" }
    if ($Version -ne 'master') { git fetch -q origin "${Version}:${Version}" }
} else {
    $tags = git tag
    if ($tags -notcontains $Version ) { throw "Chocolatey-AU version '$Version' doesn't exist"}
}

git checkout -q $Version

./build.ps1 -Task Build
.\code_drop\temp\chocolateyPackage\tools\install.ps1

Pop-Location
