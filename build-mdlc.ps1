# Fabrique le paquet fpdm.mdlc (Marabook DownLoadable Content) : un zip qui
# porte module.json a sa racine, plus le dossier achievements\ s'il existe
# (les images des succes, <id>.png). Le nom de l'asset est STABLE : la
# release GitHub publie fpdm.mdlc, Marabook le cherche sous ce nom.
#
# Usage : powershell -NoProfile -ExecutionPolicy Bypass -File build-mdlc.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifest = Join-Path $root 'module.json'
if (-not (Test-Path $manifest)) { throw "module.json introuvable dans $root" }
# Le manifeste doit etre du JSON lisible (une virgule de trop casse tout).
$null = Get-Content -Raw -Encoding UTF8 $manifest | ConvertFrom-Json
$out = Join-Path $root 'fpdm.mdlc'
if (Test-Path $out) { Remove-Item $out -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($out, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $manifest, 'module.json')
    $extras = Join-Path $root 'achievements'
    if (Test-Path $extras) {
        Get-ChildItem -Path $extras -File -Recurse | ForEach-Object {
            $relative = $_.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
            $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relative)
        }
    }
} finally {
    $zip.Dispose()
}
Write-Host "Paquet : $out"
