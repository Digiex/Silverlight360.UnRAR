<#
.SYNOPSIS
Builds unrar360.xex from scratch and publishes it on GitHub Releases, with what an app needs beside it.

.DESCRIPTION
As Silverdash360's and XboxNGen's tools\Release.ps1 do:
1. The release is made from a commit as it is, which GitHub has: nothing may be uncommitted, and the commit must be
   pushed already. Nothing is pushed.
2. The version is -Version if given, else the last release's (the highest v<version> tag) with its patch (or -Bump's
   part) raised; the first release is 0.1.0. It is tagged v<version> on the commit, by gh.
3. The DLL is built from scratch in WSL (make clean, then make), with what tools\Configure.ps1 set up: xsdk's
   dll-modules build and its toolchain (config.mk), and UnRAR's source it fetched.
4. Silverlight360.UnRAR.dll and Silverlight360.UnRAR.xml are built from csharp\Silverlight360.UnRAR.csproj by Silverlight360's tools\Build-XboxApp.ps1.
5. build\release\Silverlight360.UnRAR-<version>.zip has, in a Silverlight360.UnRAR folder, unrar360.xex,
   Silverlight360.UnRAR.dll and Silverlight360.UnRAR.xml, README.md, LICENSE.md, THIRD-PARTY-NOTICES.md,
   licenses\ and BUILD.txt: what was built from what.
6. The release's notes are the commits since the last release, and the zip is its file.
The build isn't run: test it first (docs\testing.md). Needs tools\Configure.ps1 run, and the GitHub CLI (gh),
signed in, unless -DryRun.

.EXAMPLE
.\tools\Release.ps1 -DryRun

Shows the version, builds and zips, and shows the notes, without publishing.

.EXAMPLE
.\tools\Release.ps1 -Bump Minor
#>
param(
    # The version to release, when it isn't the last one's raised.
    [ValidatePattern('^\d+\.\d+\.\d+$')] [string]$Version = '',
    # The part of the last release's version to raise.
    [ValidateSet('Patch', 'Minor', 'Major')] [string]$Bump = 'Patch',
    # Shows what would be released, without publishing.
    [switch]$DryRun,
    [switch]$Prerelease
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repository = 'Digiex/Silverlight360.UnRAR'

# UTF-8 without a byte order mark, which GitHub would show in the notes.
function Write-Utf8([string]$path, [string[]]$lines) {
    [IO.File]::WriteAllLines($path, $lines, (New-Object Text.UTF8Encoding $false))
}
function Invoke-Git { $output = & git.exe -C $root @args; if ($LASTEXITCODE) { throw "git $args failed" }; $output }
# The commit a checkout is at, and its branch.
function Get-Commit([string]$folder) {
    '{0} ({1})' -f (& git.exe -C $folder rev-parse --short=12 HEAD), (& git.exe -C $folder rev-parse --abbrev-ref HEAD)
}

# 1. The commit, and the submodules at the commits it records.
if (Invoke-Git status --porcelain --untracked-files=no) { throw 'There are changes not committed. Commit them, or stash them, first.' }
$unrarMarker = Join-Path $root 'third_party\unrar\.unrarsrc'
$unrarVersion = if (Test-Path -LiteralPath $unrarMarker) { (Get-Content -LiteralPath $unrarMarker -Raw).Trim() } else { '' }
if (-not $unrarVersion) { throw 'UnRAR''s source isn''t fetched: run .\tools\Configure.ps1.' }
$xsdk = & (Join-Path $PSScriptRoot 'Config.ps1') Xsdk
$toolchain = & (Join-Path $PSScriptRoot 'Config.ps1') Toolchain
$sdk = & (Join-Path $PSScriptRoot 'Config.ps1') Silverlight360
if (-not $xsdk -or -not $toolchain -or -not (Test-Path -LiteralPath (Join-Path $root 'config.mk'))) {
    throw 'xsdk or its toolchain isn''t configured: run .\tools\Configure.ps1.'
}
if (-not $sdk) {
    throw 'Silverlight360 isn''t configured, which builds Silverlight360.UnRAR.dll: run .\tools\Configure.ps1.'
}
Invoke-Git fetch --quiet --tags origin
$commit = Invoke-Git rev-parse HEAD
if (-not $DryRun) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'The GitHub CLI (gh) is needed to publish: https://cli.github.com' }
    if (-not (Invoke-Git branch -r --contains $commit)) { throw "Commit $commit isn't on GitHub yet. Push it first." }
}

# 2. The version.
$released = @(foreach ($t in (Invoke-Git tag --list 'v*')) {
    $parsed = $null
    if ([version]::TryParse($t.Substring(1), [ref]$parsed)) { [pscustomobject]@{ Tag = $t; Version = $parsed } }
})
$last = $released | Sort-Object Version -Descending | Select-Object -First 1
if (-not $Version) {
    $Version = if (-not $last) { '0.1.0' } else {
        $v = $last.Version
        switch ($Bump) {
            'Major' { "$($v.Major + 1).0.0" }
            'Minor' { "$($v.Major).$($v.Minor + 1).0" }
            default { "$($v.Major).$($v.Minor).$([Math]::Max($v.Build, 0) + 1)" }
        }
    }
} elseif ($last -and [version]$Version -le $last.Version) { throw "$Version isn't higher than $($last.Tag)." }
$tag = "v$Version"
if ($released | Where-Object { $_.Tag -eq $tag }) { throw "$tag is released already." }
Write-Host ("Version $Version" + $(if ($last) { ", after $($last.Tag)" } else { ', the first release' }))

# 3. The DLL, from scratch.
wsl --cd $root -e bash -lc 'set -e; make clean; make -j$(nproc)'
if ($LASTEXITCODE) { throw 'The build failed.' }
foreach ($built in 'unrar360.xex') {
    if (-not (Test-Path -LiteralPath (Join-Path $root $built))) { throw "The build made no $built." }
}
$toolchainName = wsl -e bash -lc "${toolchain}gcc --version | head -n 1"
# The C# side as Silverlight360.UnRAR.dll, with its XML documentation, by Silverlight360's build.
& (Join-Path $sdk 'tools\Build-XboxApp.ps1') -Project (Join-Path $root 'csharp\Silverlight360.UnRAR.csproj')
$library = Join-Path $root 'csharp\bin\Release'
foreach ($built in 'Silverlight360.UnRAR.dll', 'Silverlight360.UnRAR.xml') {
    if (-not (Test-Path -LiteralPath (Join-Path $library $built))) { throw "The C# build made no $built." }
}

# 4. The zip.
$name = "Silverlight360.UnRAR $Version"
$out = Join-Path $root 'build\release'
$staging = Join-Path $out 'Silverlight360.UnRAR'
if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Recurse -Force }
$files = @(Invoke-Git ls-files README.md LICENSE.md THIRD-PARTY-NOTICES.md licenses) +
    'unrar360.xex'
foreach ($f in $files) {
    $to = Join-Path $staging $f
    $null = New-Item -ItemType Directory (Split-Path $to -Parent) -Force
    Copy-Item -LiteralPath (Join-Path $root $f) -Destination $to
}
foreach ($f in 'Silverlight360.UnRAR.dll', 'Silverlight360.UnRAR.xml') {
    Copy-Item -LiteralPath (Join-Path $library $f) -Destination $staging
}
$build = @"
$name
https://github.com/$repository

Built from commit $($commit.Substring(0, 12)), with:
- UnRAR $unrarVersion's source (unrarsrc-$unrarVersion.tar.gz from rarlab.com)
- xsdk $(Get-Commit $xsdk), with its elf2xex.py and libxsdk.a
- $toolchainName
- Silverlight360 $(Get-Commit $sdk), for Silverlight360.UnRAR.dll

unrar360.xex is the DLL, at base 0x8F000000, which goes beside an app's default.xex. Silverlight360.UnRAR.dll is the
C# side, RarExtractor, with Silverlight360.UnRAR.xml, its documentation for IntelliSense; it needs
Silverlight360.Common, which an app built with Silverlight360 has. See https://digiex.github.io/Silverlight360.UnRAR/using/.

UnRAR's license, licenses\unrar.txt, and THIRD-PARTY-NOTICES.md go with unrar360.xex.
"@
Write-Utf8 (Join-Path $staging 'BUILD.txt') ($build -split "`r?`n")
$zip = Join-Path $out "Silverlight360.UnRAR-$Version.zip"
Compress-Archive -Path $staging -DestinationPath $zip

# 5. The notes: the commits since the last release before this commit.
$previous = $null
foreach ($candidate in ($released | Sort-Object Version -Descending)) {
    & git.exe -C $root merge-base --is-ancestor $candidate.Tag $commit
    if ($LASTEXITCODE -eq 0) { $previous = $candidate.Tag; break }
}
$range = if ($previous) { "$previous..$commit" } else { $commit }
$notes = @(if ($previous) { "## Changes since $previous" } else { '## Changes' }) + ''
$notes += Invoke-Git log $range --no-merges --format='- %s (%h)'
$notes += '', ("From $($commit.Substring(0, 7)). The zip has unrar360.xex, to go beside an app's default.xex, " +
    'Silverlight360.UnRAR.dll with its XML documentation, and UnRAR''s license, which goes with them: see BUILD.txt ' +
    'in it.')
$notesFile = Join-Path $out 'notes.md'
Write-Utf8 $notesFile $notes

Write-Host "$name ($tag)"
Write-Host "Zip: $zip"
Write-Host ''
Get-Content -LiteralPath $notesFile | Write-Host
if ($DryRun) { Write-Host ''; Write-Host 'Dry run: nothing published.'; return }

$arguments = @('release', 'create', $tag, $zip, '--repo', $repository, '--target', $commit, '--title', $name,
    '--notes-file', $notesFile)
if ($Prerelease) { $arguments += '--prerelease' }
& gh @arguments
if ($LASTEXITCODE) { throw 'gh release create failed.' }
Invoke-Git fetch --quiet --tags origin
