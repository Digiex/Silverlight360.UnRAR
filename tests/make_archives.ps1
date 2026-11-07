<#
.SYNOPSIS
Makes the archives the sample extracts, in <ContentRoot>\UnRarTest\in.

.DESCRIPTION
Writes the test tree with make_tree.py into <Work>, archives it six ways with
WinRAR's Rar.exe, and copies -Large in as large.rar for the cancel and
full-size cases. Run the sample in xenia-edge with --content_root=<ContentRoot>,
then check the files with verify_output.py.

.EXAMPLE
.\make_archives.ps1 -ContentRoot $env:TEMP\unrar-content -Work $env:TEMP\unrar-tree -Large path\to\large.rar
#>
param(
    [Parameter(Mandatory)] [string]$ContentRoot,
    [Parameter(Mandatory)] [string]$Work,
    # A large archive for the cancel and full-size cases; the sample expects one.
    [Parameter(Mandatory)] [string]$Large,
    [string]$Rar = "$env:ProgramFiles\WinRAR\Rar.exe"
)

$ErrorActionPreference = 'Stop'
$in = Join-Path $ContentRoot 'UnRarTest\in'
New-Item -ItemType Directory $in -Force | Out-Null
python -I (Join-Path $PSScriptRoot 'make_tree.py') $Work
if ($LASTEXITCODE) { throw 'make_tree.py failed' }

# The cases MainPage.xaml.cs extracts.
$archives = [ordered]@{
    'rar5.rar' = @('-ma5', '-m3')
    'rar4.rar' = @('-ma4', '-m3')
    'store.rar' = @('-ma5', '-m0')
    'solid.rar' = @('-ma5', '-m5', '-s')
    'password.rar' = @('-ma5', '-m3', '-pxbox360')
    'split.rar' = @('-ma5', '-m0', '-v2m')
}
Push-Location (Join-Path $Work 'tree')
try {
    foreach ($name in $archives.Keys) {
        & $Rar a -r -idq -ep1 -o+ @($archives[$name]) (Join-Path $in $name) * | Out-Null
        if ($LASTEXITCODE) { throw "Rar.exe failed on $name" }
    }
}
finally {
    Pop-Location
}
Copy-Item $Large (Join-Path $in 'large.rar')
Get-ChildItem $in | Select-Object Name, Length
