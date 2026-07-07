# Stopgap: one-way restore of this repo's dot_claude/ files into ~/.claude.
# Reverse of sync-claude.ps1. Temporary - delete once chezmoi manages these dotfiles.
#
# Copies only files present under dot_claude/. Never deletes anything in ~/.claude:
# files that exist locally but not in the repo are left untouched. One-way only -
# never reads back from ~/.claude.
# Windows counterpart of restore-claude.sh - keep both in sync when editing.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Src = Join-Path $PSScriptRoot 'dot_claude'
$Dest = Join-Path $env:USERPROFILE '.claude'

# Top-level customization files.
$Files = @('CLAUDE.md', 'engineering-practices.md', 'statusline.sh', 'settings.json', 'keybindings.json')

# User-owned directories to walk. Each file inside is copied to the mirrored path;
# extra files already at the destination (not present in the repo) are preserved.
$Dirs = @('hooks', 'skills', 'agents', 'commands')

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

foreach ($f in $Files) {
    $srcPath = Join-Path $Src $f
    if (Test-Path -LiteralPath $srcPath -PathType Leaf) {
        Copy-Item -LiteralPath $srcPath -Destination (Join-Path $Dest $f) -Force
        Write-Host "restored  $f"
    } else {
        Write-Warning "skip      $f (absent)"
    }
}

foreach ($d in $Dirs) {
    $srcDir = Join-Path $Src $d
    if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) {
        Write-Warning "skip      $d/ (absent)"
        continue
    }
    $srcFiles = Get-ChildItem -LiteralPath $srcDir -Recurse -File
    if (-not $srcFiles) {
        Write-Warning "skip      $d/ (empty)"
        continue
    }
    foreach ($file in $srcFiles) {
        $rel = $file.FullName.Substring($Src.Length + 1)
        $destPath = Join-Path $Dest $rel
        New-Item -ItemType Directory -Force -Path (Split-Path $destPath -Parent) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destPath -Force
        Write-Host "restored  $rel"
    }
}

Write-Host "Done. Review ~/.claude to confirm."
