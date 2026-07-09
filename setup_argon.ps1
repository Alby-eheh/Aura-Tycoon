# Script to download and set up Argon CLI automatically for Windows
$ErrorActionPreference = "Stop"

$repo = "argon-rbx/argon"
Write-Host "Fetching latest release from GitHub API..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest"
$version = $release.tag_name
Write-Host "Latest Argon release found: $version"

# Find the windows x86_64 asset
$zipAsset = $release.assets | Where-Object { $_.name -like "*windows-x86_64.zip" }
if (-not $zipAsset) {
    throw "Could not find Windows x86_64 zip asset in the latest release."
}

$downloadUrl = $zipAsset.browser_download_url
$zipPath = Join-Path $PSScriptRoot "argon.zip"
$binDir = Join-Path $PSScriptRoot "bin"

Write-Host "Downloading Argon CLI from $downloadUrl..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

Write-Host "Extracting to $binDir..."
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}
Expand-Archive -Path $zipPath -DestinationPath $binDir -Force

Write-Host "Cleaning up zip file..."
Remove-Item $zipPath

Write-Host "Argon CLI successfully installed at: $binDir\argon.exe"
Write-Host "You can now run 'bin\argon' in this directory."
