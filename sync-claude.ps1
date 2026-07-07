# Stopgap: one-way sync of customized ~/.claude files into this repo's dot_claude/.
# Temporary - delete once chezmoi manages these dotfiles.
#
# Copies only an explicit whitelist (Files + Dirs) so new secrets/caches in ~/.claude
# can never leak into the repo. One-way only: never writes back to ~/.claude, and the
# Remove-Item below only ever targets paths under the script-owned dot_claude/.
# Windows counterpart of sync-claude.sh - keep both in sync when editing.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Src = Join-Path $env:USERPROFILE '.claude'
$Dest = Join-Path $PSScriptRoot 'dot_claude'

# Top-level customization files.
$Files = @('CLAUDE.md', 'engineering-practices.md', 'statusline.sh', 'settings.json', 'keybindings.json')

# Fully user-owned directories, mirrored whole (new files inside picked up automatically).
$Dirs = @('hooks', 'skills', 'agents', 'commands')

foreach ($f in $Files) {
    $srcPath = Join-Path $Src $f
    if (Test-Path -LiteralPath $srcPath -PathType Leaf) {
        Copy-Item -LiteralPath $srcPath -Destination (Join-Path $Dest $f) -Force
        Write-Host "synced  $f"
    } else {
        Write-Warning "skip    $f (absent)"
    }
}

foreach ($d in $Dirs) {
    $srcDir = Join-Path $Src $d
    if ((Test-Path -LiteralPath $srcDir -PathType Container) -and (Get-ChildItem -LiteralPath $srcDir -Force | Select-Object -First 1)) {
        $destDir = Join-Path $Dest $d
        if (Test-Path -LiteralPath $destDir) {
            Remove-Item -LiteralPath $destDir -Recurse -Force
        }
        Copy-Item -LiteralPath $srcDir -Destination $destDir -Recurse -Force
        Write-Host "synced  $d/ (dir)"
    } else {
        Write-Warning "skip    $d/ (absent or empty)"
    }
}

Write-Host "Done. Review 'git status' / 'git diff' before committing."
